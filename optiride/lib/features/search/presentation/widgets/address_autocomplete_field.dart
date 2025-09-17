import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:optiride/core/models/place_suggestion.dart';
import 'package:optiride/providers.dart'; // import des providers de requête et suggestions

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
  String? _sessionToken; // Token de session pour lier autocomplete et details

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
    if (query.length >= 2) {
      setState(() => _showSuggestions = true);
      // Met à jour la requête dans Riverpod
      if (widget.isOrigin) {
        ref.read(originQueryProvider.notifier).state = query;
      } else {
        ref.read(destinationQueryProvider.notifier).state = query;
      }
  // Rafraîchir un token de session pour une nouvelle séquence de saisie
  _sessionToken ??= UniqueKey().toString();
    } else {
      setState(() => _showSuggestions = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      // Demande la permission si nécessaire
      await Geolocator.requestPermission();
      // Obtient la position actuelle
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      // Tente un reverse geocoding pour une adresse formatée
      final reverse = ref.read(reverseGeocodingServiceProvider);
      final addr = await reverse.reverse(position.latitude, position.longitude) ?? 'Position actuelle';
      // Met à jour le champ de texte avec l'adresse
      _controller.text = addr;
      // Appelle le callback si défini
      widget.onAddressSelected?.call({'lat': position.latitude, 'lng': position.longitude}, addr);
    } catch (e) {
      // Gère les erreurs (ex: permission refusée)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la récupération de la position actuelle')),
      );
    }
  }

  // Gère la sélection d'une suggestion
  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    final places = ref.read(placesServiceProvider);
  final details = await places.details(suggestion.placeId, sessionToken: _sessionToken);
    final addr = details?.formattedAddress.isNotEmpty == true
        ? details!.formattedAddress
        : '${suggestion.mainText}${suggestion.secondaryText.isNotEmpty ? ', ${suggestion.secondaryText}' : ''}';
    _controller.text = addr;
    setState(() => _showSuggestions = false);
    if (details != null) {
      widget.onAddressSelected?.call({'lat': details.lat, 'lng': details.lng}, addr);
    } else {
      widget.onAddressSelected?.call({'lat': 0.0, 'lng': 0.0}, addr);
    }
  // Fin de session après sélection
  _sessionToken = null;
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = widget.isOrigin
        ? ref.watch(originSuggestionsProvider)
        : ref.watch(destinationSuggestionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _controller,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.showLocationButton
        ? IconButton(
          icon: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                  onPressed: _useCurrentLocation,
                  tooltip: 'Utiliser ma position',
                )
              : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: _onQueryChanged,
        ),
        if (_showSuggestions)
          suggestionsAsync.when(
             data: (suggestions) {
               final visible = suggestions.take(5).toList();
               return Container(
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
                   itemCount: visible.length,
                   itemBuilder: (context, index) {
                     final suggestion = visible[index];
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
               );
             },
             loading: () => const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator())),
             error: (e, _) => const Padding(padding: EdgeInsets.all(8.0), child: Center(child: Text('Erreur suggestions'))),
           ),
       ],
     );
   }
 }
