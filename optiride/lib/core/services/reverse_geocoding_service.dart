import 'dart:convert';
import 'package:http/http.dart' as http;

class ReverseGeocodingService {
  final String apiKey; // réutilise clé Maps
  ReverseGeocodingService(this.apiKey);

  Future<String?> reverse(double lat, double lng, {String language = 'fr'}) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$lat,$lng',
      'language': language,
      'key': apiKey,
    });
    final resp = await http.get(uri);
    if (resp.statusCode != 200) return null;
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) return null;
    return results.first['formatted_address'] as String?;
  }
}
