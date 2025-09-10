import 'dart:async';
import 'dart:math';

import '../models/provider_id.dart';
import '../models/ride_offer.dart';
import '../models/search_query.dart';
import '../models/vehicle_class.dart';
import '../models/service_tag.dart';
import 'quote_provider.dart';

class MockQuoteProvider implements QuoteProvider {
  final _rnd = Random();
  static const _vehicleClasses = VehicleClass.values;
  static const _providers = ProviderId.values;

  List<ServiceTag> _deriveTags(VehicleClass c) {
    switch (c) {
      case VehicleClass.economy:
        return [ServiceTag.eco];
      case VehicleClass.comfort:
        return [ServiceTag.eco, ServiceTag.womenPreferred];
      case VehicleClass.premium:
        return [ServiceTag.luxury, ServiceTag.womenPreferred];
      case VehicleClass.van:
        return [ServiceTag.van, ServiceTag.petsAllowed];
    }
  }

  List<RideOffer> _generate(SearchQuery query) {
    final list = [
      for (final p in _providers)
        () {
          final cls = _vehicleClasses[_rnd.nextInt(_vehicleClasses.length)];
          return RideOffer(
            provider: p,
            vehicleClass: cls,
            estimatedPrice: 6 + _rnd.nextDouble() * 24,
            etaDriver: Duration(minutes: 2 + _rnd.nextInt(12)),
            timestamp: DateTime.now(),
            tags: _deriveTags(cls),
          );
        }()
    ];
    list.sort((a, b) {
      final priceCmp = a.estimatedPrice.compareTo(b.estimatedPrice);
      if (priceCmp != 0) return priceCmp;
      return a.etaDriver.compareTo(b.etaDriver);
    });
    return list;
  }

  @override
  Future<List<RideOffer>> fetchOnce(SearchQuery query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _generate(query);
  }

  @override
  Stream<List<RideOffer>> watchQuotes(SearchQuery query) async* {
    while (true) {
      yield _generate(query);
      await Future.delayed(const Duration(seconds: 30));
    }
  }
}
