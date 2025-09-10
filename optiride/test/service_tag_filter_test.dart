import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiride/core/models/ride_offer.dart';
import 'package:optiride/core/models/provider_id.dart';
import 'package:optiride/core/models/vehicle_class.dart';
import 'package:optiride/core/models/service_tag.dart';
import 'package:optiride/core/models/search_query.dart';
import 'package:optiride/providers.dart';
import 'package:optiride/core/services/quote_provider.dart';

class _FakeProvider implements QuoteProvider {
  final List<RideOffer> _offers;
  _FakeProvider(this._offers);
  @override
  Future<List<RideOffer>> fetchOnce(SearchQuery query) async => _offers;
  @override
  Stream<List<RideOffer>> watchQuotes(SearchQuery query) async* { yield _offers; }
}

void main() {
  test('Filtrage sur tags combine VehicleClass + ServiceTag', () async {
    final offers = [
      RideOffer(provider: ProviderId.uber, vehicleClass: VehicleClass.economy, estimatedPrice: 10, etaDriver: const Duration(minutes: 5), timestamp: DateTime.now(), tags: const [ServiceTag.eco]),
      RideOffer(provider: ProviderId.bolt, vehicleClass: VehicleClass.premium, estimatedPrice: 25, etaDriver: const Duration(minutes: 3), timestamp: DateTime.now(), tags: const [ServiceTag.luxury, ServiceTag.womenPreferred]),
      RideOffer(provider: ProviderId.heetch, vehicleClass: VehicleClass.van, estimatedPrice: 30, etaDriver: const Duration(minutes: 8), timestamp: DateTime.now(), tags: const [ServiceTag.van, ServiceTag.petsAllowed]),
    ];

    final container = ProviderContainer(overrides: [
      quoteProviderImpl.overrideWithValue(_FakeProvider(offers)),
      searchQueryProvider.overrideWith((ref) => const SearchQuery(pickupAddress: 'A', destinationAddress: 'B')),
    ]);

    // Sans filtres => 3
    final all = await container.read(offersStreamProvider.future);
    expect(all.length, 3);

    // Ajout filtre VehicleClass premium => 1
    container.read(vehicleClassFilterProvider.notifier).state = {VehicleClass.premium};
    final premiumOnly = await container.read(offersStreamProvider.future);
    expect(premiumOnly.length, 1);

    // Ajout tag luxury (déjà dans l'offre premium) => 1
    container.read(serviceTagFilterProvider.notifier).state = {ServiceTag.luxury};
    final premiumLuxury = await container.read(offersStreamProvider.future);
    expect(premiumLuxury.length, 1);

    // Tag qui exclut tout (petsAllowed + VehicleClass.premium) => 0
    container.read(serviceTagFilterProvider.notifier).state = {ServiceTag.petsAllowed};
    final none = await container.read(offersStreamProvider.future);
    expect(none.isEmpty, true);
  });
}
