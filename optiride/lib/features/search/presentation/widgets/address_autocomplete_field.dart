import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/models/place_suggestion.dart';

class AddressAutocompleteField extends ConsumerStatefulWidget {
  final String hintText;
  final String label;
  final bool showLocationButton;
  final TextEditingController? controller;
  final Widget? prefixIcon;
  final bool isOrigin; // Pour distinguer origine/destination
  final Function(Map<String, double>, String)? onAddressSelected;

  const AddressAutocompleteField({
    super.key,
    required this.hintText,
    required this.label,
    this.showLocationButton = false,
    this.controller,
    this.prefixIcon,
    this.isOrigin = false,
    this.onAddressSelected,
  });

  @override
  ConsumerState<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends ConsumerState<AddressAutocompleteField> {
  late final TextEditingController _controller;
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onQueryChanged(String query) {
    // Rechercher automatiquement les suggestions uniquement si plus de 2 caractères
    if (query.length >= 2) {
      setState(() {
        _showSuggestions = true;
      });
    } else {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _selectSuggestion(PlaceSuggestion suggestion) {
    _controller.text = suggestion.mainText;
    
    // Utiliser un callback pour informer le parent de la sélection
    if (widget.onAddressSelected != null) {
      // Coordonnées par défaut pour les villes françaises
      final coordinates = _getCityCoordinates(suggestion.placeId);
      widget.onAddressSelected!(coordinates, suggestion.mainText);
    }
  }

  // Méthode pour obtenir les coordonnées des villes
  Map<String, double> _getCityCoordinates(String placeId) {
    final coordinates = {
      'paris': {'lat': 48.8566, 'lng': 2.3522},
      'marseille': {'lat': 43.2965, 'lng': 5.3698},
      'lyon': {'lat': 45.7640, 'lng': 4.8357},
      'toulouse': {'lat': 43.6047, 'lng': 1.4442},
      'nice': {'lat': 43.7102, 'lng': 7.2620},
      'nantes': {'lat': 47.2184, 'lng': -1.5536},
      'strasbourg': {'lat': 48.5734, 'lng': 7.7521},
      'montpellier': {'lat': 43.6110, 'lng': 3.8767},
      'bordeaux': {'lat': 44.8378, 'lng': -0.5792},
      'lille': {'lat': 50.6292, 'lng': 3.0573},
      'current_location': {'lat': 48.8566, 'lng': 2.3522}, // Par défaut Paris
    };
    
    return coordinates[placeId] ?? {'lat': 48.8566, 'lng': 2.3522};
  }

  void _useCurrentLocation() async {
    try {
      // Afficher "Position actuelle" immédiatement
      _controller.text = "Position actuelle";
      
      // Demander les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement');
      }

      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Services de localisation désactivés');
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Enregistrer les coordonnées et informer le parent
      if (widget.onAddressSelected != null) {
        final coordinates = {'lat': position.latitude, 'lng': position.longitude};
        widget.onAddressSelected!(coordinates, "Position actuelle");
      }
      
      // Afficher confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position actuelle utilisée'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      // Remettre le champ vide en cas d'erreur
      _controller.text = "";
      
      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de géolocalisation: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _getFrenchCitySuggestions(_controller.text);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _controller,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: const TextStyle(fontSize: 12),
            hintText: widget.hintText,
            hintStyle: const TextStyle(fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.showLocationButton 
              ? IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.blue),
                  onPressed: _useCurrentLocation,
                  tooltip: 'Utiliser ma position',
                )
              : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: _onQueryChanged,
        ),
        // Suggestions intelligentes - seulement si on tape et qu'il y a des résultats
        if (_showSuggestions && suggestions.isNotEmpty && _controller.text.length >= 2)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length.clamp(0, 3), // Max 3 suggestions comme Uber
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: const Icon(Icons.location_on, color: Colors.grey, size: 20),
                  title: Text(
                    suggestion.mainText,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  subtitle: suggestion.secondaryText.isNotEmpty 
                    ? Text(
                        suggestion.secondaryText,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    : null,
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }

  List<PlaceSuggestion> _getFrenchCitySuggestions(String query) {
    final cities = [
      const PlaceSuggestion(
        placeId: 'paris',
        mainText: 'Paris',
        secondaryText: 'Île-de-France, France',
      ),
      const PlaceSuggestion(
        placeId: 'marseille',
        mainText: 'Marseille',
        secondaryText: 'Provence-Alpes-Côte d\'Azur, France',
      ),
      const PlaceSuggestion(
        placeId: 'lyon',
        mainText: 'Lyon',
        secondaryText: 'Auvergne-Rhône-Alpes, France',
      ),
      const PlaceSuggestion(
        placeId: 'toulouse',
        mainText: 'Toulouse',
        secondaryText: 'Occitanie, France',
      ),
      const PlaceSuggestion(
        placeId: 'nice',
        mainText: 'Nice',
        secondaryText: 'Provence-Alpes-Côte d\'Azur, France',
      ),
      const PlaceSuggestion(
        placeId: 'nantes',
        mainText: 'Nantes',
        secondaryText: 'Pays de la Loire, France',
      ),
      const PlaceSuggestion(
        placeId: 'strasbourg',
        mainText: 'Strasbourg',
        secondaryText: 'Grand Est, France',
      ),
      const PlaceSuggestion(
        placeId: 'montpellier',
        mainText: 'Montpellier',
        secondaryText: 'Occitanie, France',
      ),
      const PlaceSuggestion(
        placeId: 'bordeaux',
        mainText: 'Bordeaux',
        secondaryText: 'Nouvelle-Aquitaine, France',
      ),
      const PlaceSuggestion(
        placeId: 'lille',
        mainText: 'Lille',
        secondaryText: 'Hauts-de-France, France',
      ),
    ];

    return cities
        .where((city) => city.mainText.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
