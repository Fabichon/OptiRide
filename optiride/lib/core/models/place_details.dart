class PlaceDetails {
  final String placeId;
  final String formattedAddress;
  final double lat;
  final double lng;
  const PlaceDetails({required this.placeId, required this.formattedAddress, required this.lat, required this.lng});

  factory PlaceDetails.fromApi(Map<String, dynamic> json) {
    final result = (json['result'] ?? json);
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    return PlaceDetails(
      placeId: result['place_id'] as String? ?? '',
      formattedAddress: result['formatted_address'] as String? ?? '',
      lat: (location?['lat'] as num?)?.toDouble() ?? 0,
      lng: (location?['lng'] as num?)?.toDouble() ?? 0,
    );
  }
}
