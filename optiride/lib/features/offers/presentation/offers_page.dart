import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/ride_offer.dart';
import '../../../core/models/search_query.dart';
import '../../../core/models/vehicle_class.dart';
import '../../../core/models/service_tag.dart';
import '../../../core/models/provider_id.dart';
import '../../../providers.dart';

class ResultsView extends ConsumerWidget {
  const ResultsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = GoRouterState.of(context).extra as SearchQuery?;
    if (query != null) {
      ref.read(searchQueryProvider.notifier).state = query; // inject query
    }
    final asyncOffers = ref.watch(offersStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Offres')),
      body: query == null
          ? const Center(child: Text('Aucune requête'))
          : asyncOffers.when(
              data: (offers) => _OffersList(offers: offers),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Erreur: $e')),
            ),
    );
  }
}

class _OffersList extends StatelessWidget {
  final List<RideOffer> offers;
  const _OffersList({required this.offers});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return const Center(child: Text('Aucune offre pour le moment'));
    }
    return const _OffersWithFilters();
  }
}

class _OffersWithFilters extends ConsumerWidget {
  const _OffersWithFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(offersStreamProvider).value ?? const <RideOffer>[];
    final selected = ref.watch(vehicleClassFilterProvider);
    final selectedTags = ref.watch(serviceTagFilterProvider);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              for (final vc in VehicleClass.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(vc.label),
                    selected: selected.contains(vc),
                    onSelected: (s) {
                      final set = {...selected};
                      if (s) {
                        set.add(vc);
                      } else {
                        set.remove(vc);
                      }
                      ref.read(vehicleClassFilterProvider.notifier).state = set;
                    },
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final tag in ServiceTag.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    avatar: Icon(tag.icon, size: 16),
                    label: Text(tag.label),
                    selected: selectedTags.contains(tag),
                    onSelected: (s) {
                      final set = {...selectedTags};
                      if (s) set.add(tag); else set.remove(tag);
                      ref.read(serviceTagFilterProvider.notifier).state = set;
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {},
            child: ListView.separated(
              itemCount: offers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final o = offers[index];
                return ListTile(
                  title: Text('${o.provider.displayName} • ${o.vehicleClass.label}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ETA ${o.etaDriver.inMinutes} min • ~${o.estimatedPrice.toStringAsFixed(2)}€'),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          for (final t in o.tags)
                            Chip(
                              visualDensity: VisualDensity.compact,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                              avatar: Icon(t.icon, size: 14),
                              label: Text(t.label, style: const TextStyle(fontSize: 11)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: FilledButton(
                    onPressed: () {},
                    child: const Text('Réserver'),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
