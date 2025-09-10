import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/quote_provider.dart';
import 'core/services/mock_quote_provider.dart';
import 'core/services/api_quote_provider.dart';
import 'core/models/search_query.dart';
import 'core/models/vehicle_class.dart';
import 'core/models/ride_offer.dart';
import 'core/services/places_service.dart';
import 'core/models/place_suggestion.dart';
import 'core/services/reverse_geocoding_service.dart';
import 'core/models/service_tag.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

final apiBaseUrlProvider = Provider<String>((_) => 'http://localhost:8081');

final quoteProviderImpl = Provider<QuoteProvider>((ref) {
  final base = ref.watch(apiBaseUrlProvider);
  return _selectProvider(base);
});

Future<QuoteProvider> _healthCheck(String base) async {
  try {
    final uri = Uri.parse('$base/health');
    final resp = await http.get(uri).timeout(const Duration(seconds: 2));
    if (resp.statusCode == 200) {
      return ApiQuoteProvider(baseUrl: base);
    }
  } catch (_) {}
  return MockQuoteProvider();
}

QuoteProvider _selectProvider(String base) {
  final completer = Completer<QuoteProvider>();
  _healthCheck(base).then(completer.complete);
  return _DeferredQuoteProvider(completer.future);
}

class _DeferredQuoteProvider implements QuoteProvider {
  final Future<QuoteProvider> _innerFuture;
  _DeferredQuoteProvider(this._innerFuture);
  Future<QuoteProvider> get _inner async => await _innerFuture;
  @override
  Stream<List<RideOffer>> watchQuotes(SearchQuery query) async* {
    final impl = await _inner;
    yield* impl.watchQuotes(query);
  }

  @override
  Future<List<RideOffer>> fetchOnce(SearchQuery query) async {
    final impl = await _inner;
    return impl.fetchOnce(query);
  }
}

final searchQueryProvider = StateProvider<SearchQuery>((ref) => const SearchQuery(pickupAddress: '', destinationAddress: ''));

final vehicleClassFilterProvider = StateProvider<Set<VehicleClass>>((ref) => <VehicleClass>{});
final serviceTagFilterProvider = StateProvider<Set<ServiceTag>>((ref) => <ServiceTag>{});

final offersStreamProvider = StreamProvider.autoDispose((ref) {
  final query = ref.watch(searchQueryProvider);
  final filters = ref.watch(vehicleClassFilterProvider);
  final tagFilters = ref.watch(serviceTagFilterProvider);
  if (!query.isComplete) {
    return const Stream<List<RideOffer>>.empty();
  }
  final qp = ref.watch(quoteProviderImpl);
  return qp.watchQuotes(query).map((list) {
    var out = list;
    if (filters.isNotEmpty) {
      out = out.where((o) => filters.contains(o.vehicleClass)).toList();
    }
    if (tagFilters.isNotEmpty) {
      out = out.where((o) => tagFilters.every((t) => o.tags.contains(t))).toList();
    }
    return out;
  });
});

final mapsApiKeyProvider = Provider<String>((_) => const String.fromEnvironment('MAPS_API_KEY', defaultValue: ''));

final currentPositionProvider = FutureProvider<Position?>((ref) async {
  if (!await Geolocator.isLocationServiceEnabled()) return null;
  LocationPermission perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
  }
  return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
});

final placesServiceProvider = Provider<PlacesService>((ref) {
  final key = ref.watch(mapsApiKeyProvider);
  return PlacesService(key);
});

final destinationQueryProvider = StateProvider<String>((_) => '');

final _debounceDurationProvider = Provider<Duration>((_) => const Duration(milliseconds: 350));

final placeSuggestionsProvider = StreamProvider.autoDispose<List<PlaceSuggestion>>((ref) {
  final svc = ref.watch(placesServiceProvider);
  final debounce = ref.watch(_debounceDurationProvider);
  final controller = StreamController<List<PlaceSuggestion>>();
  Timer? timer;
  void listener() {
    timer?.cancel();
    final query = ref.read(destinationQueryProvider);
    if (query.trim().isEmpty) {
      controller.add(const []);
      return;
    }
    timer = Timer(debounce, () async {
      try {
        final res = await svc.autocomplete(query);
        controller.add(res);
      } catch (_) {
        controller.add(const []);
      }
    });
  }
  final sub = ref.listen<String>(destinationQueryProvider, (_, __) => listener());
  listener();
  ref.onDispose(() {
    timer?.cancel();
    sub.close();
    controller.close();
  });
  return controller.stream;
});

final reverseGeocodingServiceProvider = Provider<ReverseGeocodingService>((ref) {
  final key = ref.watch(mapsApiKeyProvider);
  return ReverseGeocodingService(key);
});
