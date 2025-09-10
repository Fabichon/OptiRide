import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_suggestion.dart';
import '../models/place_details.dart';

class PlacesService {
  final String apiKey;
  PlacesService(this.apiKey);

  Future<List<PlaceSuggestion>> autocomplete(String input, {String language = 'fr'}) async {
    if (input.trim().isEmpty) return [];
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': input,
      'types': 'geocode',
      'language': language,
      'key': apiKey,
    });
    final resp = await http.get(uri);
    if (resp.statusCode != 200) return [];
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final predictions = (data['predictions'] as List?) ?? [];
    return predictions.map((e) => PlaceSuggestion.fromApi(e as Map<String, dynamic>)).toList();
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
