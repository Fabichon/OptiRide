class SearchQuery {
  final String pickupAddress;
  final String destinationAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  const SearchQuery({
    required this.pickupAddress,
    required this.destinationAddress,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
  });

  SearchQuery copyWith({
    String? pickupAddress,
    String? destinationAddress,
    double? pickupLat,
    double? pickupLng,
    double? destinationLat,
    double? destinationLng,
    bool clearPickupCoords = false,
    bool clearDestinationCoords = false,
  }) => SearchQuery(
        pickupAddress: pickupAddress ?? this.pickupAddress,
        destinationAddress: destinationAddress ?? this.destinationAddress,
        pickupLat: clearPickupCoords ? null : (pickupLat ?? this.pickupLat),
        pickupLng: clearPickupCoords ? null : (pickupLng ?? this.pickupLng),
        destinationLat: clearDestinationCoords ? null : (destinationLat ?? this.destinationLat),
        destinationLng: clearDestinationCoords ? null : (destinationLng ?? this.destinationLng),
      );

  bool get isComplete => pickupAddress.isNotEmpty && destinationAddress.isNotEmpty;
}
