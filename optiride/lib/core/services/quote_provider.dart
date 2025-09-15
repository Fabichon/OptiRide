import 'package:optiride/core/models/ride_offer.dart';
import 'package:optiride/core/models/search_query.dart';

abstract class QuoteProvider {
  Stream<List<RideOffer>> watchQuotes(SearchQuery query);
  Future<List<RideOffer>> fetchOnce(SearchQuery query);
}
