import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/ride_offer.dart';
import '../models/search_query.dart';
import 'quote_provider.dart';
import '../utils/app_logger.dart';

class ApiQuoteProvider implements QuoteProvider {
  final String baseUrl;
  final Duration pollingInterval;
  final bool enableSse;
  final int maxSseRetries;
  final Duration baseBackoff;
  ApiQuoteProvider({
    required this.baseUrl,
    this.pollingInterval = const Duration(seconds: 20),
    this.enableSse = true,
    this.maxSseRetries = 5,
    this.baseBackoff = const Duration(seconds: 2),
  });

  Uri _offersUri(SearchQuery q) => Uri.parse('$baseUrl/offers').replace(queryParameters: {
        'origin': q.pickupAddress,
        'destination': q.destinationAddress,
      });

  Uri _streamUri(SearchQuery q) => Uri.parse('$baseUrl/offers/stream').replace(queryParameters: {
        'origin': q.pickupAddress,
        'destination': q.destinationAddress,
      });

  @override
  Future<List<RideOffer>> fetchOnce(SearchQuery query) async {
    final resp = await http.get(_offersUri(query));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final offers = (data['offers'] as List).map((e) => RideOffer.fromApi(e as Map<String, dynamic>)).toList();
    return offers;
  }

  @override
  Stream<List<RideOffer>> watchQuotes(SearchQuery query) async* {
    if (enableSse) {
      try {
        yield* _sseWithRetry(query);
        return;
      } catch (e) {
        logDebug('SSE désactivé après échecs: $e');
      }
    }
    yield* _pollingStream(query);
  }

  Stream<List<RideOffer>> _pollingStream(SearchQuery query) async* {
    final controller = StreamController<List<RideOffer>>();
    Timer? timer;
    Future<void> poll() async {
      try {
        final offers = await fetchOnce(query);
        controller.add(offers);
      } catch (e) {
        logDebug('Erreur polling offers', error: e);
      }
    }
    await poll();
    timer = Timer.periodic(pollingInterval, (_) => poll());
    controller.onCancel = () => timer?.cancel();
    yield* controller.stream;
  }

  Stream<List<RideOffer>> _sseWithRetry(SearchQuery query) async* {
    int attempt = 0;
    while (attempt <= maxSseRetries) {
      try {
        logDebug('Connexion SSE tentative ${attempt + 1}');
        yield* _sseStream(query);
        return; // sortie si flux se termine naturellement
      } catch (e) {
        attempt++;
        if (attempt > maxSseRetries) {
          throw Exception('Max SSE retries atteint');
        }
        final backoff = _computeBackoff(attempt);
        logDebug('SSE erreur: $e -> retry dans ${backoff.inMilliseconds}ms');
        await Future.delayed(backoff);
      }
    }
  }

  Duration _computeBackoff(int attempt) {
    final exp = baseBackoff * pow(2, attempt - 1).toInt();
    final jitterMs = Random().nextInt(400); // +-400ms
    return exp + Duration(milliseconds: jitterMs);
  }

  Stream<List<RideOffer>> _sseStream(SearchQuery query) async* {
    final uri = _streamUri(query);
    final client = HttpClient();
    HttpClientRequest request;
    try {
      request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
    } catch (e) {
      client.close(force: true);
      rethrow;
    }
    request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
    final response = await request.close();
    if (response.statusCode != 200) {
      client.close(force: true);
      throw HttpException('SSE status ${response.statusCode}');
    }
    final stream = response.transform(utf8.decoder).transform(const LineSplitter());
    List<String> buffer = [];
    try {
      await for (final line in stream) {
        if (line.isEmpty) {
          final dataLine = buffer.firstWhere((l) => l.startsWith('data:'), orElse: () => '');
          if (dataLine.isNotEmpty) {
            final jsonStr = dataLine.substring(5).trim();
            try {
              final payload = json.decode(jsonStr) as Map<String, dynamic>;
              final offers = (payload['offers'] as List).map((e) => RideOffer.fromApi(e as Map<String, dynamic>)).toList();
              yield offers;
            } catch (e) {
              logDebug('Parse SSE payload error', error: e);
            }
          }
          buffer.clear();
        } else {
          buffer.add(line);
        }
      }
    } finally {
      client.close(force: true);
    }
  }
}
