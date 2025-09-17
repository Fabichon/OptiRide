import 'package:flutter/material.dart';
import 'package:optiride/core/models/search_query.dart';
import 'package:optiride/features/search/presentation/widgets/address_autocomplete_field.dart';
import 'package:optiride/features/search/presentation/widgets/search_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

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
  double _distance = 0;
  int _duration = 0;

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
           _query.destinationAddress.isNotEmpty;
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
      setState(() {
        _query = _query.copyWith(
          destinationAddress: 'Destination',
          destinationLat: position.latitude,
          destinationLng: position.longitude,
        );
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
    });

    // Simulation d'un calcul d'itinéraire
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _routing = false;
        _distance = 15000; // 15 km en mètres
        _duration = 1200;  // 20 minutes en secondes
      });
    }
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
        ),
        
        // Interface utilisateur - Menu en haut pour laisser la place aux suggestions comme Uber
        Positioned(
          top: 16,
          left: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                    onPressed: _isQueryComplete() ? _calculateRoute : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
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
