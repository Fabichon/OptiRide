import 'package:flutter_test/flutter_test.dart';
import 'package:optiride/core/utils/distance.dart';

void main() {
  test('Haversine Paris-Lyon approx', () {
    // Paris (48.8566, 2.3522) Lyon (45.7640, 4.8357)
    final d = haversine(48.8566, 2.3522, 45.7640, 4.8357) / 1000; // km
    expect(d, greaterThan(380));
    expect(d, lessThan(470));
  });
}
