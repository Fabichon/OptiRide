import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import 'package:optiride/comparator/models.dart';
import 'package:optiride/comparator/mock_repository.dart';

/// Contrôleur de l'état du comparateur VTC.
class ComparatorController extends ChangeNotifier {
  ComparatorController({required this.repo});

  /// Critère de tri courant.
  ComparatorSort sort = ComparatorSort.cheapest;

  /// Filtre de catégorie courant.
  RideCategory category = RideCategory.all;

  /// Dépôt de données (mock pour l’instant).
  final RideOffersRepository repo;

  /// Source complète récupérée depuis le dépôt.
  List<RideOffer> _source = const [];

  /// Liste visible après filtre + tri.
  List<RideOffer> visible = const [];

  /// Timer d’auto-raffraîchissement.
  Timer? _timer;

  /// Indique si un raffraîchissement est en cours.
  bool refreshing = false;

  /// Initialise le contrôleur en chargeant les offres.
  Future<void> init({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required DateTime when,
  }) async {
    _source = await repo.fetchOffers(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      when: when,
    );
    _applySortAndFilter();
  }

  /// Met à jour le tri et notifie si nécessaire.
  void setSort(ComparatorSort s) {
    if (s == sort) return;
    sort = s;
    _applySortAndFilter();
  }

  /// Met à jour la catégorie et notifie si nécessaire.
  void setCategory(RideCategory c) {
    if (c == category) return;
    category = c;
    _applySortAndFilter();
  }

  /// Applique le filtre catégorie et le tri courant.
  void _applySortAndFilter() {
    Iterable<RideOffer> it = _source;

    if (category != RideCategory.all) {
      it = it.where((o) => o.category == category);
    }

    final list = it.toList();
    switch (sort) {
      case ComparatorSort.cheapest:
        list.sort((a, b) => a.priceMinCents.compareTo(b.priceMinCents));
        break;
      case ComparatorSort.fastest:
        list.sort((a, b) => a.etaMin.compareTo(b.etaMin));
        break;
    }

    visible = List.unmodifiable(list);
    notifyListeners();
  }

  /// Démarre un auto-refresh périodique (par ex. toutes les 3 secondes).
  void startAutoRefresh(Duration every) {
    stopAutoRefresh();
    _timer = Timer.periodic(every, (timer) async {
      refreshing = true;
      notifyListeners();

      // Simuler de légères variations de prix (±1–2%) et ETA (±1 minute)
      _source = _source.map((o) => _jitter(o)).toList(growable: false);

      _applySortAndFilter();

      // Fin de refresh après ~800 ms
      await Future<void>.delayed(const Duration(milliseconds: 800));
      refreshing = false;
      notifyListeners();
    });
  }

  /// Arrête l’auto-refresh si actif.
  void stopAutoRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}

// --- Helpers internes ---
final _rand = math.Random();

RideOffer _jitter(RideOffer o) {
  // Variation ±1–2% pour les prix
  double mult() {
    final sign = _rand.nextBool() ? 1 : -1;
    final pct = 0.01 + _rand.nextInt(2) * 0.01; // 0.01 ou 0.02
    return 1 + sign * pct;
  }

  int clampPos(int v) => v < 0 ? 0 : v;

  final minC = clampPos((o.priceMinCents * mult()).round());
  final maxC = math.max(minC, clampPos((o.priceMaxCents * mult()).round()));

  // Variation ETA ±1 minute
  final dEta = _rand.nextBool() ? 1 : -1;
  final etaMin = math.max(0, o.etaMin + dEta);
  final etaMax = math.max(etaMin, o.etaMax + dEta);

  return RideOffer(
    id: o.id,
    platform: o.platform,
    category: o.category,
    capacityMin: o.capacityMin,
    capacityMax: o.capacityMax,
    etaMin: etaMin,
    etaMax: etaMax,
    priceMinCents: minC,
    priceMaxCents: maxC,
    deeplinkApp: o.deeplinkApp,
    deeplinkWeb: o.deeplinkWeb,
  );
}
