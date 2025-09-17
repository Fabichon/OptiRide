import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:optiride/core/models/place_suggestion.dart';
import 'package:optiride/core/models/place_details.dart';

class PlacesService {
  final String apiKey;
  PlacesService(this.apiKey);

  Future<List<PlaceSuggestion>> autocomplete(String input, {String language = 'fr'}) async {
    if (input.trim().isEmpty) return [];
    // Si pas de clé API configurée, retourner les suggestions de fallback
    if (apiKey.trim().isEmpty) {
      return _getFallbackSuggestions(input);
    }
    
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': input,
      'types': 'geocode',
      'language': language,
      'key': apiKey,
    });
    
    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        print('Places API Error: ${resp.statusCode} - ${resp.body}');
        return _getFallbackSuggestions(input);
      }
      final data = json.decode(resp.body) as Map<String, dynamic>;
      
      // Vérifier si l'API a retourné une erreur
      if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
        print('Places API Status Error: ${data['status']} - ${data['error_message'] ?? ''}');
        if (data['status'] == 'REQUEST_DENIED') {
          print('SOLUTION: Configurez les restrictions de votre API key dans Google Cloud Console');
        }
        return _getFallbackSuggestions(input);
      }
      
      final predictions = (data['predictions'] as List?) ?? [];
      return predictions.map((e) => PlaceSuggestion.fromApi(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Places API Exception: $e');
      return _getFallbackSuggestions(input);
    }
  }

  List<PlaceSuggestion> _getFallbackSuggestions(String input) {
    // Données de fallback étendues pour le développement
    final lowerInput = input.toLowerCase();
    final fallbackData = [
      // Grandes villes
      {'description': 'Paris, France', 'place_id': 'fallback_paris'},
      {'description': 'Lyon, France', 'place_id': 'fallback_lyon'},
      {'description': 'Marseille, France', 'place_id': 'fallback_marseille'},
      {'description': 'Toulouse, France', 'place_id': 'fallback_toulouse'},
      {'description': 'Nice, France', 'place_id': 'fallback_nice'},
      {'description': 'Bordeaux, France', 'place_id': 'fallback_bordeaux'},
      {'description': 'Lille, France', 'place_id': 'fallback_lille'},
      {'description': 'Strasbourg, France', 'place_id': 'fallback_strasbourg'},
      {'description': 'Nantes, France', 'place_id': 'fallback_nantes'},
      {'description': 'Montpellier, France', 'place_id': 'fallback_montpellier'},
      {'description': 'Rennes, France', 'place_id': 'fallback_rennes'},
      {'description': 'Reims, France', 'place_id': 'fallback_reims'},
      {'description': 'Le Havre, France', 'place_id': 'fallback_lehavre'},
      {'description': 'Toulon, France', 'place_id': 'fallback_toulon'},
      {'description': 'Grenoble, France', 'place_id': 'fallback_grenoble'},
      {'description': 'Dijon, France', 'place_id': 'fallback_dijon'},
      {'description': 'Angers, France', 'place_id': 'fallback_angers'},
      {'description': 'Villeurbanne, France', 'place_id': 'fallback_villeurbanne'},
      {'description': 'Le Mans, France', 'place_id': 'fallback_lemans'},
      {'description': 'Aix-en-Provence, France', 'place_id': 'fallback_aix'},
      {'description': 'Clermont-Ferrand, France', 'place_id': 'fallback_clermont'},
      {'description': 'Brest, France', 'place_id': 'fallback_brest'},
      {'description': 'Tours, France', 'place_id': 'fallback_tours'},
      {'description': 'Limoges, France', 'place_id': 'fallback_limoges'},
      {'description': 'Amiens, France', 'place_id': 'fallback_amiens'},
      {'description': 'Annecy, France', 'place_id': 'fallback_annecy'},
      {'description': 'Perpignan, France', 'place_id': 'fallback_perpignan'},
      {'description': 'Besançon, France', 'place_id': 'fallback_besancon'},
      {'description': 'Orléans, France', 'place_id': 'fallback_orleans'},
      {'description': 'Metz, France', 'place_id': 'fallback_metz'},
      {'description': 'Rouen, France', 'place_id': 'fallback_rouen'},
      {'description': 'Mulhouse, France', 'place_id': 'fallback_mulhouse'},
      {'description': 'Caen, France', 'place_id': 'fallback_caen'},
      {'description': 'Nancy, France', 'place_id': 'fallback_nancy'},
      
      // Quartiers de Paris populaires
      {'description': 'Champs-Élysées, Paris', 'place_id': 'fallback_champs'},
      {'description': 'Montmartre, Paris', 'place_id': 'fallback_montmartre'},
      {'description': 'Gare du Nord, Paris', 'place_id': 'fallback_gare_nord'},
      {'description': 'République, Paris', 'place_id': 'fallback_republique'},
      {'description': 'Bastille, Paris', 'place_id': 'fallback_bastille'},
      {'description': 'Opéra, Paris', 'place_id': 'fallback_opera'},
      {'description': 'Tour Eiffel, Paris', 'place_id': 'fallback_eiffel'},
      {'description': 'Notre-Dame, Paris', 'place_id': 'fallback_notredame'},
      {'description': 'Louvre, Paris', 'place_id': 'fallback_louvre'},
      {'description': 'Châtelet, Paris', 'place_id': 'fallback_chatelet'},
      
      // Lieux communs
      {'description': 'Aéroport Charles de Gaulle, Roissy', 'place_id': 'fallback_cdg'},
      {'description': 'Aéroport Orly, Orly', 'place_id': 'fallback_orly'},
      {'description': 'Disneyland Paris, Marne-la-Vallée', 'place_id': 'fallback_disney'},
      {'description': 'Versailles, France', 'place_id': 'fallback_versailles'},
    ];
    
    return fallbackData
        .where((item) => item['description']!.toLowerCase().contains(lowerInput))
        .take(8) // Augmenter de 5 à 8 suggestions
        .map((item) => PlaceSuggestion(
          placeId: item['place_id']!,
          mainText: item['description']!.split(',')[0],
          secondaryText: item['description']!.split(',').length > 1 
              ? item['description']!.split(',')[1].trim() 
              : '',
        ))
        .toList();
  }

  Future<PlaceDetails?> details(String placeId, {String language = 'fr'}) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'language': language,
      'key': apiKey,
    });
    final resp = await http.get(uri);
    if (resp.statusCode != 200) return null;
    final data = json.decode(resp.body) as Map<String, dynamic>;
    if ((data['status'] as String?) == 'OK') {
      return PlaceDetails.fromApi(data);
    }
    return null;
  }
}
