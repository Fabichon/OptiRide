import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiride/core/services/quote_provider.dart';
import 'package:optiride/core/services/mock_quote_provider.dart';
import 'package:optiride/core/services/api_quote_provider.dart';
import 'package:optiride/core/models/search_query.dart';
import 'package:optiride/core/models/vehicle_class.dart';
import 'package:optiride/core/models/ride_offer.dart';
import 'package:optiride/core/services/places_service.dart';
import 'package:optiride/core/models/place_suggestion.dart';
import 'package:optiride/core/services/reverse_geocoding_service.dart';
import 'package:optiride/core/models/service_tag.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:optiride/core/services/directions_service.dart';

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

// Requête de recherche
final searchQueryProvider = StateProvider<SearchQuery>(
  (ref) => const SearchQuery(pickupAddress: '', destinationAddress: ''),
);

// Filtrage par classe de véhicule
final vehicleClassFilterProvider = StateProvider<Set<VehicleClass>>(
  (ref) => <VehicleClass>{},
);
// Filtrage par étiquette de service
final serviceTagFilterProvider = StateProvider<Set<ServiceTag>>(
  (ref) => <ServiceTag>{},
);

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
  const settings = LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5);
  return Geolocator.getCurrentPosition(locationSettings: settings);
});

final placesServiceProvider = Provider<PlacesService>((ref) {
  final key = ref.watch(mapsApiKeyProvider);
  return PlacesService(key);
});

// Texte de la saisie de destination
final destinationQueryProvider = StateProvider<String>(
  (ref) => '',
);

// Texte de la saisie d'origine
final originQueryProvider = StateProvider<String>(
  (ref) => '',
);

final _debounceDurationProvider = Provider<Duration>((_) => const Duration(milliseconds: 150));

// Provider pour les suggestions de destination
final destinationSuggestionsProvider = StreamProvider.autoDispose<List<PlaceSuggestion>>((ref) {
  final svc = ref.watch(placesServiceProvider);
  final debounce = ref.watch(_debounceDurationProvider);
  final controller = StreamController<List<PlaceSuggestion>>();
  Timer? timer;
  void listener() {
    timer?.cancel();
    final query = ref.read(destinationQueryProvider);
    if (query.trim().length < 1) {
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

// Provider pour les suggestions d'origine
final originSuggestionsProvider = StreamProvider.autoDispose<List<PlaceSuggestion>>((ref) {
  final svc = ref.watch(placesServiceProvider);
  final debounce = ref.watch(_debounceDurationProvider);
  final controller = StreamController<List<PlaceSuggestion>>();
  Timer? timer;
  void listener() {
    timer?.cancel();
    final query = ref.read(originQueryProvider);
    if (query.trim().length < 1) {
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
  final sub = ref.listen<String>(originQueryProvider, (_, __) => listener());
  listener();
  ref.onDispose(() {
    timer?.cancel();
    sub.close();
    controller.close();
  });
  return controller.stream;
});

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

// Contrôleur de la GoogleMap (stocké quand prêt)
final mapControllerProvider = StateProvider<GoogleMapController?>((ref) => null);

final directionsServiceProvider = Provider<DirectionsService>((ref) {
  final key = ref.watch(mapsApiKeyProvider);
  return DirectionsService(key);
});

// Stockage du dernier tracé calculé
final routePolylineProvider = StateProvider<List<List<double>>>((_) => const []);
final routeDistanceProvider = StateProvider<int>((_) => 0); // mètres
final routeDurationProvider = StateProvider<int>((_) => 0); // secondes
final routeCacheProvider = Provider<Map<String, DirectionsRoute>>((_) => <String, DirectionsRoute>{});
final routeAnimationProgressProvider = StateProvider<double>((_) => 1.0); // 0..1 proportion du tracé affiché
