import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiride/providers.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;

class SearchMap extends ConsumerStatefulWidget {
  final void Function(LatLng latLng)? onPickOrigin;
  final void Function(LatLng latLng)? onMoveDestination;
  final bool fullScreen;
  final LatLng? origin;
  final LatLng? destination;
  final List<LatLng>? routePolyline;
  const SearchMap({
    super.key,
    this.onPickOrigin,
    this.onMoveDestination,
    this.fullScreen = false,
    this.origin,
    this.destination,
    this.routePolyline,
  });
  @override
  ConsumerState<SearchMap> createState() => _SearchMapState();
}

class _SearchMapState extends ConsumerState<SearchMap> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  AnimationController? _animationController;
  List<LatLng> _animatedPolylinePoints = [];
  Timer? _animationTimer;
  LatLng? _pendingCenter; // Centre à appliquer dès que la carte est prête
  bool _centeredFromCurrent = false; // Évite de recentrer plusieurs fois

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Quand la position courante est récupérée pour la première fois, centrer la carte
    ref.listen<AsyncValue<Position?>>(currentPositionProvider, (prev, next) {
      next.whenData((pos) {
        if (!mounted || pos == null || _centeredFromCurrent) return;
        // Ne pas surcentrer si une origine a déjà été choisie
        if (widget.origin == null) {
          final target = LatLng(pos.latitude, pos.longitude);
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(target, 15),
            );
            _centeredFromCurrent = true;
          } else {
            // Carte pas encore prête, mémoriser pour onMapCreated
            _pendingCenter = target;
          }
        }
      });
    });
  }

  @override
  void didUpdateWidget(SearchMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Déclencher l'animation quand une nouvelle route est disponible
    if (widget.routePolyline != null && 
        widget.routePolyline!.isNotEmpty &&
        (oldWidget.routePolyline != widget.routePolyline ||
         oldWidget.routePolyline == null ||
         oldWidget.routePolyline!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startRouteAnimation(widget.routePolyline!);
      });
    }

    // Si l'origine a changé, recentrer la carte dessus
    if (oldWidget.origin != widget.origin && widget.origin != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(widget.origin!, 15));
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _animationTimer?.cancel();
    super.dispose();
  }

  void _startRouteAnimation(List<LatLng> route) {
    if (route.isEmpty || _animationController == null || _mapController == null) return;
    
    _animationController!.reset();
    _animatedPolylinePoints.clear();
    
    // Animation de zoom pour voir les deux points
    _fitBoundsToRoute(route);
    
    // Animation du tracé de la route
    _animationTimer?.cancel();
    
    const int totalSteps = 50;
    int currentStep = 0;
    
    _animationTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (currentStep >= totalSteps || !mounted) {
        timer.cancel();
        return;
      }
      
      final progress = currentStep / totalSteps;
      final pointIndex = (progress * (route.length - 1)).round();
      
      if (pointIndex < route.length && !_animatedPolylinePoints.contains(route[pointIndex])) {
        setState(() {
          _animatedPolylinePoints = route.take(pointIndex + 1).toList();
        });
      }
      
      currentStep++;
    });
    
    _animationController!.forward();
  }

  void _fitBoundsToRoute(List<LatLng> route) {
    if (route.isEmpty || _mapController == null) return;

    double minLat = route.first.latitude;
    double maxLat = route.first.latitude;
    double minLng = route.first.longitude;
    double maxLng = route.first.longitude;

    for (final point in route) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    // Ajouter une marge
    const double padding = 0.01;
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  Widget build(BuildContext context) {
    final posAsync = ref.watch(currentPositionProvider);
    final mapWidget = posAsync.when(
      data: (pos) {
        final LatLng center = widget.origin ?? (pos != null ? LatLng(pos.latitude, pos.longitude) : const LatLng(48.8566, 2.3522));
        
        final Set<Marker> markers = {};
        if (widget.origin != null) {
          markers.add(Marker(
            markerId: const MarkerId('origin'),
            position: widget.origin!,
            draggable: true,
            onDragEnd: (newPosition) {
              if (widget.onPickOrigin != null) {
                widget.onPickOrigin!(newPosition);
              }
            },
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan), // Couleur proche #64A9A7 pour départ
            infoWindow: const InfoWindow(title: 'Départ'),
          ));
        }
        if (widget.destination != null) {
          markers.add(Marker(
            markerId: const MarkerId('destination'),
            position: widget.destination!,
            draggable: true,
            onDragEnd: (newPosition) {
              if (widget.onMoveDestination != null) {
                widget.onMoveDestination!(newPosition);
              }
            },
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // Variation pour distinction
            infoWindow: const InfoWindow(title: 'Destination'),
          ));
        }
        final Set<Polyline> polylines = {};
        
        // Polyline de base (gris clair) pour montrer le trajet complet
        if (widget.routePolyline != null && widget.routePolyline!.isNotEmpty) {
          polylines.add(Polyline(
            polylineId: const PolylineId('route_base'),
            points: widget.routePolyline!,
            color: Colors.grey.shade300,
            width: 6,
          ));
        }
        
        // Polyline animée (bleu turquoise) qui se dessine progressivement
        if (_animatedPolylinePoints.isNotEmpty) {
          polylines.add(Polyline(
            polylineId: const PolylineId('route_animated'),
            points: _animatedPolylinePoints,
            color: const Color(0xFF64A9A7), // Couleur principale
            width: 5,
            patterns: const [], // Ligne continue
          ));
        }
        return GoogleMap(
          initialCameraPosition: CameraPosition(target: center, zoom: 14),
          markers: markers,
          polylines: polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          compassEnabled: true,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: true,
          zoomGesturesEnabled: true,
          zoomControlsEnabled: true, // Activer les boutons de zoom
          // Pas de style personnalisé - couleurs par défaut de Google Maps
          onMapCreated: (GoogleMapController controller) async {
            _mapController = controller;
            // Si une position est en attente et aucune origine définie, centrer maintenant
            if (widget.origin == null && _pendingCenter != null && !_centeredFromCurrent) {
              await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_pendingCenter!, 15));
              _centeredFromCurrent = true;
              _pendingCenter = null;
            } else if (widget.origin != null) {
              await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(widget.origin!, 15));
            }
          },
          onTap: (LatLng position) {
            // Si on n'a pas d'origine, définir le point tapé comme origine
            if (widget.origin == null && widget.onPickOrigin != null) {
              widget.onPickOrigin!(position);
            }
            // Si on a une origine mais pas de destination, définir comme destination
            else if (widget.destination == null && widget.onMoveDestination != null) {
              widget.onMoveDestination!(position);
            }
            // Si on a les deux, mettre à jour la destination
            else if (widget.onMoveDestination != null) {
              widget.onMoveDestination!(position);
            }
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
            const Text('Vérifie la clé API, le package et les permissions.' , style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );

    if (widget.fullScreen) {
      return Positioned.fill(child: mapWidget);
    }

    // Prendre tout l'espace disponible au lieu d'AspectRatio
    return mapWidget;
  }
}
