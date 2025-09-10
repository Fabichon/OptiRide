import 'package:flutter_test/flutter_test.dart';
import 'package:optiride/core/models/place_suggestion.dart';

void main() {
  test('PlaceSuggestion parsing', () {
    final json = {
      'place_id': 'abc123',
      'structured_formatting': {
        'main_text': 'Paris',
        'secondary_text': 'France'
      }
    };
    final s = PlaceSuggestion.fromApi(json);
    expect(s.placeId, 'abc123');
    expect(s.mainText, 'Paris');
    expect(s.secondaryText, 'France');
  });
}
