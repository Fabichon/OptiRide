import 'package:flutter_test/flutter_test.dart';
import 'package:optiride/core/models/search_query.dart';

void main() {
  test('copyWith coords', () {
    final q1 = const SearchQuery(pickupAddress: 'A', destinationAddress: 'B');
    final q2 = q1.copyWith(pickupLat: 1.2, pickupLng: 3.4);
    expect(q2.pickupLat, 1.2);
    expect(q2.pickupLng, 3.4);
    final q3 = q2.copyWith(clearPickupCoords: true);
    expect(q3.pickupLat, isNull);
    expect(q3.pickupLng, isNull);
  });

  test('isComplete requires addresses only', () {
    final q = const SearchQuery(pickupAddress: 'X', destinationAddress: 'Y', pickupLat: 1, pickupLng: 2);
    expect(q.isComplete, isTrue);
  });
}
