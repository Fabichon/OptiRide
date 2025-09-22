// Source de données mock pour les offres VTC.

import 'dart:async';
import 'dart:math';

import 'package:optiride/comparator/models.dart';

/// Dépôt des offres de course VTC.
class RideOffersRepository {
  /// Récupère une liste d'offres mock en fonction d'un trajet.
  Future<List<RideOffer>> fetchOffers({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required DateTime when,
  }) async {
    // Petit délai simulé 50–100 ms
    final delay = 50 + Random().nextInt(51);
    await Future.delayed(Duration(milliseconds: delay));

    final rnd = Random(_seedFromInputs(originLat, originLng, destLat, destLng, when));

    // Prix Standard base (4700–5600 cents)
    final basePriceMin = 4700 + rnd.nextInt(900); // 4700..5599
    final basePriceMax = basePriceMin + 200 + rnd.nextInt(300); // ~ +200..+499

    // ETA base Standard (2–7 min)
    final baseEtaMin = 2 + rnd.nextInt(3); // 2..4
    final baseEtaMax = baseEtaMin + 2 + rnd.nextInt(3); // +2..+4 => 4..8

    // Génère des offres pour 4 plateformes et catégories
    const platforms = ['uber', 'bolt', 'heetch', 'freenow'];
    const categories = <RideCategory>[
      RideCategory.standard,
      RideCategory.premium,
      RideCategory.xl,
      RideCategory.pet,
      RideCategory.woman,
    ];

    final offers = <RideOffer>[];

    for (final p in platforms) {
      for (final c in categories) {
        final priceMult = _priceMultiplier(c);
        final etaOffset = _etaOffset(c, rnd);

        final minCents = (basePriceMin * priceMult).round();
        final maxCents = (basePriceMax * priceMult).round();

        final etaMin = (baseEtaMin + etaOffset.min).clamp(1, 60);
        final etaMax = max(etaMin, (baseEtaMax + etaOffset.max).clamp(1, 90));

        final capacity = _capacityForCategory(c);

        offers.add(
          RideOffer(
            id: '${p}_${c.name}_${offers.length}',
            platform: p,
            category: c,
            capacityMin: capacity.min,
            capacityMax: capacity.max,
            etaMin: etaMin,
            etaMax: etaMax,
            priceMinCents: minCents,
            priceMaxCents: maxCents,
            deeplinkApp: '$p://',
            deeplinkWeb: _webLinkFor(p),
          ),
        );
      }
    }

    // On retourne 12 à 16 offres en échantillonnant selon le seed
    final count = 12 + rnd.nextInt(5); // 12..16
    offers.shuffle(rnd);
    return offers.take(count).toList(growable: false);
  }
}

class _EtaOffset {
  const _EtaOffset(this.min, this.max);
  final int min;
  final int max;
}

class _Capacity {
  const _Capacity(this.min, this.max);
  final int min;
  final int max;
}

int _seedFromInputs(double oLat, double oLng, double dLat, double dLng, DateTime when) {
  // Génère un seed stable basé sur l'entrée pour des résultats pseudo-déterministes.
  final s = (oLat * 1000).round() ^ (oLng * 1000).round() ^ (dLat * 1000).round() ^ (dLng * 1000).round();
  return s ^ when.millisecondsSinceEpoch;
}

double _priceMultiplier(RideCategory c) {
  switch (c) {
    case RideCategory.standard:
    case RideCategory.pet:
    case RideCategory.woman:
      return 1.0; // même prix que Standard
    case RideCategory.premium:
      return 1.4; // +40%
    case RideCategory.xl:
      return 1.6; // +60%
    case RideCategory.all:
      return 1.0; // non utilisée pour des offres spécifiques
  }
}

_EtaOffset _etaOffset(RideCategory c, Random rnd) {
  switch (c) {
    case RideCategory.standard:
    case RideCategory.pet:
    case RideCategory.woman:
      return const _EtaOffset(0, 0); // base
    case RideCategory.premium:
  return const _EtaOffset(1, 2); // +1–2 min
    case RideCategory.xl:
  return const _EtaOffset(2, 3); // +2–3 min
    case RideCategory.all:
      return const _EtaOffset(0, 0);
  }
}

_Capacity _capacityForCategory(RideCategory c) {
  switch (c) {
    case RideCategory.standard:
    case RideCategory.pet:
    case RideCategory.woman:
      return const _Capacity(1, 4);
    case RideCategory.premium:
      return const _Capacity(1, 4);
    case RideCategory.xl:
      return const _Capacity(4, 6);
    case RideCategory.all:
      return const _Capacity(1, 6);
  }
}

String _webLinkFor(String platform) {
  switch (platform) {
    case 'uber':
      return 'https://m.uber.com/';
    case 'bolt':
      return 'https://m.bolt.eu/';
    case 'heetch':
      return 'https://www.heetch.com/';
    case 'freenow':
      return 'https://web.freenow.com/';
    default:
      return 'https://example.com/';
  }
}
