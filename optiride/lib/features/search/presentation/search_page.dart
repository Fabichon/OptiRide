import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/search_query.dart';
import 'widgets/destination_autocomplete_field.dart';
import 'widgets/search_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});
  @override
  ConsumerState<SearchView> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchView> {
  final _pickupCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  SearchQuery _query = const SearchQuery(pickupAddress: '', destinationAddress: '');
  bool _resolving = false;

  Future<void> _reverseAndSet(double lat, double lng) async {
    setState(() => _resolving = true);
    final svc = ref.read(reverseGeocodingServiceProvider);
    final addr = await svc.reverse(lat, lng).catchError((_) => null);
    final display = addr ?? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    _pickupCtrl.text = display;
    setState(() {
      _query = _query.copyWith(
        pickupAddress: display,
        pickupLat: lat,
        pickupLng: lng,
      );
      _resolving = false;
    });
  }

  void _update() {
    setState(() {
      _query = _query.copyWith(
        pickupAddress: _pickupCtrl.text,
        destinationAddress: _destCtrl.text,
      );
    });
    ref.read(destinationQueryProvider.notifier).state = _destCtrl.text;
  }

  @override
  void initState() {
    super.initState();
    _pickupCtrl.addListener(_update);
    _destCtrl.addListener(_update);
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OptiRide - Recherche')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchMap(
              onPickOrigin: (latLng) => _reverseAndSet(latLng.latitude, latLng.longitude),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pickupCtrl,
              decoration: InputDecoration(
                labelText: 'Départ',
                suffixIcon: _resolving ? const SizedBox(width: 18, height: 18, child: Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 2))) : null,
              ),
            ),
            const SizedBox(height: 12),
            DestinationAutocompleteField(controller: _destCtrl),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _query.isComplete ? () => context.push('/offers', extra: _query) : null,
              child: const Text('Comparer les offres'),
            ),
          ],
        ),
      ),
    );
  }
}
