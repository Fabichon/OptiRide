import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectionsRoute {
  final List<List<double>> polyline; // list of [lat,lng]
  final int distanceMeters;
  final int durationSeconds;
  DirectionsRoute({required this.polyline, required this.distanceMeters, required this.durationSeconds});
}

List<List<double>> decodePolyline(String encoded) {
  List<List<double>> points = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;
  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;
    points.add([lat / 1e5, lng / 1e5]);
  }
  return points;
}

class DirectionsService {
  final String apiKey;
  DirectionsService(this.apiKey);

  Future<DirectionsRoute?> route({required double originLat, required double originLng, required double destLat, required double destLng, String mode = 'driving'}) async {
    final params = {
      'origin': '$originLat,$originLng',
      'destination': '$destLat,$destLng',
      'mode': mode,
      'key': apiKey,
    };
    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', params);
    final resp = await http.get(uri);
    if (resp.statusCode != 200) return null;
    final data = json.decode(resp.body) as Map<String, dynamic>;
    if ((data['status'] as String?) != 'OK') return null;
    final routes = (data['routes'] as List?) ?? [];
    if (routes.isEmpty) return null;
    final first = routes.first as Map<String, dynamic>;
    final legs = (first['legs'] as List?) ?? [];
    final leg = legs.isNotEmpty ? legs.first as Map<String, dynamic> : {};
    final dist = ((leg['distance']?['value']) as num?)?.toInt() ?? 0;
    final dur = ((leg['duration']?['value']) as num?)?.toInt() ?? 0;
    final polyline = (first['overview_polyline']?['points']) as String?;
    final decoded = polyline != null ? decodePolyline(polyline) : <List<double>>[];
    return DirectionsRoute(polyline: decoded, distanceMeters: dist, durationSeconds: dur);
  }
}
