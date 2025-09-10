import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers.dart';

class SearchMap extends ConsumerStatefulWidget {
  final void Function(LatLng latLng)? onPickOrigin;
  const SearchMap({super.key, this.onPickOrigin});
  @override
  ConsumerState<SearchMap> createState() => _SearchMapState();
}

class _SearchMapState extends ConsumerState<SearchMap> {
  LatLng? _origin;

  @override
  Widget build(BuildContext context) {
    final posAsync = ref.watch(currentPositionProvider);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: posAsync.when(
          data: (pos) {
            final center = pos != null ? LatLng(pos.latitude, pos.longitude) : const LatLng(48.8566, 2.3522);
            return GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: 13),
              myLocationButtonEnabled: true,
              myLocationEnabled: pos != null,
              markers: {
                if (_origin != null) Marker(markerId: const MarkerId('origin'), position: _origin!),
              },
              onTap: (latLng) {
                setState(() => _origin = latLng);
                widget.onPickOrigin?.call(latLng);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Carte indisponible')),
        ),
      ),
    );
  }
}
