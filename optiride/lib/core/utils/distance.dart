import 'dart:math';

/// Calcule la distance haversine en mètres entre deux points.
double haversine(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0; // m
  double toRad(double d) => d * pi / 180.0;
  final dLat = toRad(lat2 - lat1);
  final dLon = toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(toRad(lat1)) * cos(toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}
