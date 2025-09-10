class PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  const PlaceSuggestion({required this.placeId, required this.mainText, required this.secondaryText});

  factory PlaceSuggestion.fromApi(Map<String, dynamic> json) => PlaceSuggestion(
        placeId: json['place_id'] as String,
        mainText: ((json['structured_formatting'] ?? {})['main_text'] ?? '') as String,
        secondaryText: ((json['structured_formatting'] ?? {})['secondary_text'] ?? '') as String,
      );
}
