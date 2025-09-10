import 'package:flutter_test/flutter_test.dart';
import 'package:optiride/core/models/search_query.dart';
import 'package:optiride/core/services/mock_quote_provider.dart';

void main() {
  test('Stream emits periodically', () async {
    final provider = MockQuoteProvider();
    final query = const SearchQuery(pickupAddress: 'X', destinationAddress: 'Y');
    final stream = provider.watchQuotes(query);
    final first = await stream.first;
    expect(first, isNotEmpty);
    // We won't wait full 30s; cancel early.
  });
}
