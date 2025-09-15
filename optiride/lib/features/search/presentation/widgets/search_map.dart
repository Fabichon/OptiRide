import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiride/providers.dart';

class SearchMap extends ConsumerStatefulWidget {
  final void Function(LatLng latLng)? onPickOrigin;
  final void Function(LatLng latLng)? onMoveDestination;
  final bool fullScreen;
  final LatLng? origin;
  final LatLng? destination;
  const SearchMap({super.key, this.onPickOrigin, this.onMoveDestination, this.fullScreen = false, this.origin, this.destination});
  @override
  ConsumerState<SearchMap> createState() => _SearchMapState();
}

class _SearchMapState extends ConsumerState<SearchMap> {
  LatLng? _origin; // interne si non fourni

  @override
  Widget build(BuildContext context) {
    final posAsync = ref.watch(currentPositionProvider);
    final mapWidget = posAsync.when(
      data: (pos) {
        final center = pos != null ? LatLng(pos.latitude, pos.longitude) : const LatLng(48.8566, 2.3522);
        final effectiveOrigin = widget.origin ?? _origin;
        final polyPoints = ref.watch(routePolylineProvider);
        return GoogleMap(
          initialCameraPosition: CameraPosition(target: center, zoom: 13),
          myLocationButtonEnabled: true,
          myLocationEnabled: pos != null,
          markers: {
            if (effectiveOrigin != null)
              Marker(
                markerId: const MarkerId('origin'),
                position: effectiveOrigin,
                draggable: true,
                onDragEnd: (p) {
                  if (widget.onPickOrigin != null) {
                    widget.onPickOrigin!(p);
                  }
                },
              ),
            if (widget.destination != null)
              Marker(
                markerId: const MarkerId('destination'),
                position: widget.destination!,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                draggable: true,
                onDragEnd: (p) => widget.onMoveDestination?.call(p),
              ),
          },
          polylines: {
            if (polyPoints.isNotEmpty)
              () {
                final progress = ref.watch(routeAnimationProgressProvider).clamp(0.0, 1.0);
                final count = (polyPoints.length * progress).clamp(2, polyPoints.length).toInt();
                final shown = polyPoints.take(count).map((e) => LatLng(e[0], e[1])).toList();
                return Polyline(
                  polylineId: const PolylineId('route'),
                  width: 4,
                  color: Colors.blueAccent,
                  points: shown,
                );
              }(),
          },
          onTap: (latLng) {
            if (widget.origin == null) {
              setState(() => _origin = latLng);
            }
            widget.onPickOrigin?.call(latLng);
          },
          onMapCreated: (c) {
            // stocker dans provider
            ref.read(mapControllerProvider.notifier).state = c;
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('Carte indisponible'),
            Text(
              e.toString(),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text('Vérifie la clé API et les permissions.' , style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );

    if (widget.fullScreen) {
      return Positioned.fill(child: mapWidget);
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: mapWidget,
      ),
    );
  }
}
