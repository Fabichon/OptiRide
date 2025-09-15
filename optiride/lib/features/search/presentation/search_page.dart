import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:optiride/core/models/search_query.dart';
import 'package:optiride/features/search/presentation/widgets/destination_autocomplete_field.dart';
import 'package:optiride/features/search/presentation/widgets/search_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiride/providers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:optiride/core/services/directions_service.dart';
import 'dart:async';

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
  LatLng? _originLatLng;
  LatLng? _destinationLatLng;
  bool _routing = false;

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
    // Récupération initiale de la position pour pré-remplir
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pos = await ref.read(currentPositionProvider.future).catchError((_) => null);
      if (pos != null && mounted && (_query.pickupAddress.isEmpty)) {
        _originLatLng = LatLng(pos.latitude, pos.longitude);
        await _reverseAndSet(pos.latitude, pos.longitude);
        final controller = ref.read(mapControllerProvider);
        if (controller != null) {
          controller.moveCamera(CameraUpdate.newLatLngZoom(_originLatLng!, 14));
        }
      }
    });
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
      body: Stack(
        children: [
          SearchMap(
            fullScreen: true,
            origin: _originLatLng,
            destination: _destinationLatLng,
            onPickOrigin: (latLng) {
              setState(() => _originLatLng = latLng);
              _reverseAndSet(latLng.latitude, latLng.longitude);
            },
          ),
          // Overlay gradient pour lisibilité
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
        gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
          Colors.black.withValues(alpha: 0.35),
          Colors.black.withValues(alpha: 0.15),
          Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Contenu des champs
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('OptiRide', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Row(children: [
                            IconButton(
                              tooltip: 'Localiser',
                              icon: const Icon(Icons.my_location, color: Colors.white),
                              onPressed: () async {
                                final pos = await ref.refresh(currentPositionProvider.future).catchError((_) => null);
                                if (pos != null) {
                                  _originLatLng = LatLng(pos.latitude, pos.longitude);
                                  await _reverseAndSet(pos.latitude, pos.longitude);
                                  final controller = ref.read(mapControllerProvider);
                                  if (controller != null) {
                                    await controller.animateCamera(
                                      CameraUpdate.newLatLngZoom(_originLatLng!, 15),
                                    );
                                  }
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Inverser',
                              icon: const Icon(Icons.swap_vert, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  final oldPickup = _pickupCtrl.text;
                                  final oldDest = _destCtrl.text;
                                  _pickupCtrl.text = oldDest;
                                  _destCtrl.text = oldPickup;
                                  final oldOrigin = _originLatLng;
                                  _originLatLng = _destinationLatLng;
                                  _destinationLatLng = oldOrigin;
                                  _query = _query.copyWith(
                                    pickupAddress: _pickupCtrl.text,
                                    destinationAddress: _destCtrl.text,
                                    pickupLat: _originLatLng?.latitude,
                                    pickupLng: _originLatLng?.longitude,
                                    destinationLat: _destinationLatLng?.latitude,
                                    destinationLng: _destinationLatLng?.longitude,
                                  );
                                });
                                final controller = ref.read(mapControllerProvider);
                                if (controller != null && _originLatLng != null) {
                                  controller.animateCamera(CameraUpdate.newLatLng(_originLatLng!));
                                }
                              },
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _pickupCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Départ',
                                  suffixIcon: _resolving ? const SizedBox(width: 18, height: 18, child: Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 2))) : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: DestinationAutocompleteField(
                                      controller: _destCtrl,
                                      onSelected: (_) async {
                                        // Lire les coords mises dans searchQueryProvider
                                        final q = ref.read(searchQueryProvider);
                                        if (q.destinationLat != null && q.destinationLng != null) {
                                          setState(() {
                                            _destinationLatLng = LatLng(q.destinationLat!, q.destinationLng!);
                                          });
                                          final controller = ref.read(mapControllerProvider);
                                          if (controller != null) {
                                            await controller.animateCamera(CameraUpdate.newLatLngZoom(_destinationLatLng!, 14));
                                          }
                                          // Calcul route si origine présente
                                          if (_originLatLng != null) {
                                            setState(() => _routing = true);
                                            final svc = ref.read(directionsServiceProvider);
                                            final cache = ref.read(routeCacheProvider);
                                            final key = '${_originLatLng!.latitude},${_originLatLng!.longitude}->${_destinationLatLng!.latitude},${_destinationLatLng!.longitude}';
                                            DirectionsRoute? route = cache[key];
                                            route ??= await svc.route(
                                              originLat: _originLatLng!.latitude,
                                              originLng: _originLatLng!.longitude,
                                              destLat: _destinationLatLng!.latitude,
                                              destLng: _destinationLatLng!.longitude,
                                            );
                                            if (route != null) {
                                              cache[key] = route;
                                            }
                                            if (route != null && mounted) {
                                              ref.read(routePolylineProvider.notifier).state = route.polyline;
                                              ref.read(routeDistanceProvider.notifier).state = route.distanceMeters;
                                              ref.read(routeDurationProvider.notifier).state = route.durationSeconds;
                                              // Fit bounds
                                              final controller = ref.read(mapControllerProvider);
                                              if (controller != null && route.polyline.isNotEmpty) {
                                                double minLat = route.polyline.first[0];
                                                double maxLat = minLat;
                                                double minLng = route.polyline.first[1];
                                                double maxLng = minLng;
                                                for (final p in route.polyline) {
                                                  if (p[0] < minLat) minLat = p[0];
                                                  if (p[0] > maxLat) maxLat = p[0];
                                                  if (p[1] < minLng) minLng = p[1];
                                                  if (p[1] > maxLng) maxLng = p[1];
                                                }
                                                final bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
                                                await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
                                              }
                                              // Animation polyline
                                              ref.read(routeAnimationProgressProvider.notifier).state = 0.0;
                                              const steps = 25;
                                              const totalMs = 800;
                                              for (int i = 1; i <= steps; i++) {
                                                await Future.delayed(const Duration(milliseconds: totalMs ~/ steps));
                                                ref.read(routeAnimationProgressProvider.notifier).state = i / steps;
                                              }
                                            }
                                            if (mounted) setState(() => _routing = false);
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  if (_destCtrl.text.isNotEmpty)
                                    IconButton(
                                      tooltip: 'Effacer',
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _destCtrl.clear();
                                          _destinationLatLng = null;
                                          ref.read(routePolylineProvider.notifier).state = const [];
                                          ref.read(routeDistanceProvider.notifier).state = 0;
                                          ref.read(routeDurationProvider.notifier).state = 0;
                                          _query = _query.copyWith(destinationAddress: '', clearDestinationCoords: true);
                                        });
                                      },
                                    ),
                                ],
                              ),
                              // TODO: quand une suggestion est validée, setter _destinationLatLng si on a les coords (implémentation future de geocoding direct autocomplete -> place details)
                              const SizedBox(height: 20),
                              Consumer(builder: (context, ref, _) {
                                final dist = ref.watch(routeDistanceProvider);
                                final dur = ref.watch(routeDurationProvider);
                                if (_routing) {
                                  return const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)));
                                }
                                if (dist > 0) {
                                  final km = (dist / 1000).toStringAsFixed(dist >= 10000 ? 0 : 1);
                                  final mins = (dur / 60).round();
              final eta = DateTime.now().add(Duration(seconds: dur));
              final hh = eta.hour.toString().padLeft(2, '0');
              final mm = eta.minute.toString().padLeft(2, '0');
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Chip(label: Text('$km km')),
                                        const SizedBox(width: 8),
                                        Chip(label: Text('~$mins min')),
                const SizedBox(width: 8),
                Chip(label: Text('Arrivée $hh:$mm')),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.compare_arrows),
                                  onPressed: _query.isComplete ? () => context.push('/offers', extra: _query) : null,
                                  label: const Text('Comparer les offres'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
