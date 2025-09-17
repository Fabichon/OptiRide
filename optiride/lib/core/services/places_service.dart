import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:optiride/core/models/place_suggestion.dart';
import 'package:optiride/core/models/place_details.dart';

class PlacesService {
  final String apiKey;
  PlacesService(this.apiKey);

  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    String language = 'fr',
    String? sessionToken,
    double? latitude,
    double? longitude,
    int? radius,
  }) async {
    if (input.trim().isEmpty) return [];
    // Si pas de clé API configurée, ne rien proposer (exige une vraie API)
    if (apiKey.trim().isEmpty) {
      return [];
    }
    
  final params = <String, String>{
      'input': input,
      'language': language,
      'key': apiKey,
    };
  // Restriction aux adresses pour éviter villes/POI génériques
  params['types'] = 'address';
    // Biais de localisation: privilégie des résultats autour de l’utilisateur
    if (latitude != null && longitude != null) {
      params['location'] = '$latitude,$longitude';
      if (radius != null && radius > 0) {
        params['radius'] = radius.toString();
      }
    }
    // Laisser Google retourner des adresses précises; si besoin, on peut ajouter 'types': 'address'
    // 'types' est obsolète pour certains cas; on s'en passe pour une meilleure compatibilité.
    if (sessionToken != null && sessionToken.isNotEmpty) {
      params['sessiontoken'] = sessionToken;
    }
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', params);
    
    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        print('Places API HTTP Error: ${resp.statusCode} - ${resp.body}');
        return [];
      }
      final data = json.decode(resp.body) as Map<String, dynamic>;
      
      // Vérifier si l'API a retourné une erreur
      if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
        print('Places API Status Error: ${data['status']} - ${data['error_message'] ?? ''}');
        if (data['status'] == 'REQUEST_DENIED') {
          print('SOLUTION: Configurez les restrictions de votre API key dans Google Cloud Console');
        }
        return [];
      }
      
      final predictions = (data['predictions'] as List?) ?? [];
      return predictions.map((e) => PlaceSuggestion.fromApi(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Places API Exception: $e');
      return [];
    }
  }
  

  Future<PlaceDetails?> details(String placeId, {String language = 'fr', String? sessionToken}) async {
    final params = <String, String>{
      'place_id': placeId,
      'language': language,
      'key': apiKey,
    };
    if (sessionToken != null && sessionToken.isNotEmpty) {
      params['sessiontoken'] = sessionToken;
    }
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', params);
    final resp = await http.get(uri);
    if (resp.statusCode != 200) return null;
    final data = json.decode(resp.body) as Map<String, dynamic>;
    if ((data['status'] as String?) == 'OK') {
      return PlaceDetails.fromApi(data);
    }
    return null;
  }
}
