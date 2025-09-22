import 'package:flutter/material.dart';
import 'package:optiride/core/models/search_query.dart';
import 'package:optiride/features/search/presentation/widgets/address_autocomplete_field.dart';
import 'package:optiride/features/search/presentation/widgets/search_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:optiride/providers.dart';
import 'dart:math' as math;
import 'package:optiride/comparator/comparator_page.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});
  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  late SearchQuery _query;
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  bool _routing = false;
  bool _searchingOffers = false; // état de chargement pour le bouton
  double _distance = 0;
  int _duration = 0;
  List<LatLng> _routePolyline = const [];

  @override
  void initState() {
    super.initState();
    _query = const SearchQuery(
      pickupAddress: '',
      destinationAddress: '',
    );
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _swapLocations() {
    setState(() {
      // Échanger les valeurs dans le modèle
      _query = _query.copyWith(
        pickupAddress: _query.destinationAddress,
        destinationAddress: _query.pickupAddress,
        pickupLat: _query.destinationLat,
        pickupLng: _query.destinationLng,
        destinationLat: _query.pickupLat,
        destinationLng: _query.pickupLng,
      );
      
      // Échanger les textes dans les contrôleurs
      final tempText = _originController.text;
      _originController.text = _destinationController.text;
      _destinationController.text = tempText;
    });
    
    // Recalculer la route si les deux champs sont remplis
    if (_isQueryComplete()) {
      _calculateRoute();
    }
  }

  bool _isQueryComplete() {
    return _query.pickupAddress.isNotEmpty &&
        _query.destinationAddress.isNotEmpty &&
        _query.pickupLat != null &&
        _query.pickupLng != null &&
        _query.destinationLat != null &&
        _query.destinationLng != null;
  }

  void _onDrag(LatLng position, bool isOrigin) {
    if (isOrigin) {
      setState(() {
        _query = _query.copyWith(
          pickupAddress: 'Position de départ',
          pickupLat: position.latitude,
          pickupLng: position.longitude,
        );
      });
    } else {
      // Mise à jour immédiate du champ Destination avec les coordonnées
      final coordsLabel = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      _destinationController.text = coordsLabel;
      setState(() {
        _query = _query.copyWith(
          destinationAddress: coordsLabel,
          destinationLat: position.latitude,
          destinationLng: position.longitude,
        );
      });
      // Reverse geocoding asynchrone pour remplacer par une adresse lisible si disponible
      Future(() async {
        final reverse = ref.read(reverseGeocodingServiceProvider);
        final addr = await reverse.reverse(position.latitude, position.longitude);
        if (!mounted) return;
        // Vérifier que la destination n'a pas changé entre-temps
        if (addr != null &&
            _query.destinationLat == position.latitude &&
            _query.destinationLng == position.longitude) {
          setState(() {
            _destinationController.text = addr;
            _query = _query.copyWith(destinationAddress: addr);
          });
        }
      });
    }
    if (_isQueryComplete()) {
      _calculateRoute();
    }
  }

  Future<void> _calculateRoute() async {
    if (!_isQueryComplete()) return;

    setState(() {
      _routing = true;
      _distance = 0;
      _duration = 0;
      _routePolyline = const [];
    });

    final oLat = _query.pickupLat!;
    final oLng = _query.pickupLng!;
    final dLat = _query.destinationLat!;
    final dLng = _query.destinationLng!;

    // Tente un calcul via Google Directions API
    try {
      final svc = ref.read(directionsServiceProvider);
      final res = await svc.route(originLat: oLat, originLng: oLng, destLat: dLat, destLng: dLng);
      if (!mounted) return;
      if (res != null && res.polyline.isNotEmpty) {
        setState(() {
          _routing = false;
          _distance = res.distanceMeters.toDouble();
          _duration = res.durationSeconds;
          _routePolyline = res.polyline.map((p) => LatLng(p[0], p[1])).toList();
        });
        return;
      }
    } catch (_) {
      // ignore et passe au fallback
    }

    // Fallback: estimation approx. par Haversine + ligne droite
  double deg2rad(double d) => d * 3.141592653589793 / 180.0;
    final R = 6371000.0; // rayon Terre en mètres
  final dLatR = deg2rad(dLat - oLat);
  final dLngR = deg2rad(dLng - oLng);
  final a =
  (math.sin(dLatR / 2) * math.sin(dLatR / 2)) +
  math.cos(deg2rad(oLat)) * math.cos(deg2rad(dLat)) *
      (math.sin(dLngR / 2) * math.sin(dLngR / 2));
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = R * c; // mètres
    // Vitesse moyenne urbaine approx. 45 km/h
    final durationSeconds = ((distance / 1000) / 45.0 * 3600).round();

    // Polyline simple: interpolation linéaire
    const steps = 60;
    final List<LatLng> line = List.generate(steps + 1, (i) {
      final t = i / steps;
      return LatLng(
        oLat + (dLat - oLat) * t,
        oLng + (dLng - oLng) * t,
      );
    });

    if (!mounted) return;
    setState(() {
      _routing = false;
      _distance = distance;
      _duration = durationSeconds;
      _routePolyline = line;
    });
  }

  Future<void> _openComparatorIfReady() async {
    if (!_isQueryComplete()) return;
    final oLat = _query.pickupLat!;
    final oLng = _query.pickupLng!;
    final dLat = _query.destinationLat!;
    final dLng = _query.destinationLng!;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComparatorPage(
          originLat: oLat,
          originLng: oLng,
          destLat: dLat,
          destLng: dLng,
          when: DateTime.now(),
          distanceMeters: _distance > 0 ? _distance : null,
          durationSeconds: _duration > 0 ? _duration : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Carte Google Maps
        SearchMap(
          origin: _query.pickupLat != null && _query.pickupLng != null 
            ? LatLng(_query.pickupLat!, _query.pickupLng!) 
            : null,
          destination: _query.destinationLat != null && _query.destinationLng != null 
            ? LatLng(_query.destinationLat!, _query.destinationLng!) 
            : null,
          onPickOrigin: (position) => _onDrag(position, true),
          onMoveDestination: (position) => _onDrag(position, false),
          routePolyline: _routePolyline,
        ),
        
        // Interface utilisateur - Menu en haut pour laisser la place aux suggestions comme Uber
        Positioned(
          top: 16,
          left: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Départ
                AddressAutocompleteField(
                  hintText: 'Départ',
                  label: 'Départ',
                  controller: _originController,
                  isOrigin: true,
                  showLocationButton: true,
                  onAddressSelected: (coordinates, address) {
                    setState(() {
                      _query = _query.copyWith(
                        pickupAddress: address,
                        pickupLat: coordinates['lat'],
                        pickupLng: coordinates['lng'],
                      );
                    });
                    if (_isQueryComplete()) {
                      _calculateRoute();
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Bouton d'échange
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.swap_vert, color: Colors.white),
                      onPressed: _swapLocations,
                      tooltip: 'Échanger départ et destination',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Destination
                AddressAutocompleteField(
                  hintText: 'Destination',
                  label: 'Destination',
                  controller: _destinationController,
                  isOrigin: false,
                  onAddressSelected: (coordinates, address) {
                    setState(() {
                      _query = _query.copyWith(
                        destinationAddress: address,
                        destinationLat: coordinates['lat'],
                        destinationLng: coordinates['lng'],
                      );
                    });
                    if (_isQueryComplete()) {
                      _calculateRoute();
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Bouton rechercher
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isQueryComplete() && !_searchingOffers
                        ? () async {
                            setState(() => _searchingOffers = true);
                            await _calculateRoute();
                            if (!mounted) return;
                            await _openComparatorIfReady();
                            if (!mounted) return;
                            setState(() => _searchingOffers = false);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: (_routing || _searchingOffers)
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Recherche…', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : const Text(
                            'Rechercher des offres',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Informations de route (si disponibles) - en bas à droite
        if (_routing || _distance > 0)
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Consumer(builder: (context, ref, child) {
                if (_routing) {
                  return const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                if (_distance > 0) {
                  final km = (_distance / 1000).toStringAsFixed(_distance >= 10000 ? 0 : 1);
                  final mins = (_duration / 60).round();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$km km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('~$mins min', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            ),
          ),
      ],
    );
  }
}
