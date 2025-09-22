// Modèles et énumérations pour le comparateur VTC.
//
// Ce fichier ne contient aucune logique métier; uniquement des
// définitions de données avec null-safety activée.

/// Critères de tri pour les offres.
enum ComparatorSort { cheapest, fastest }

/// Types de catégories de course supportées par les plateformes VTC.
enum RideCategory { all, standard, premium, xl, pet, woman }

/// Représente une offre de course VTC (Uber, Bolt, Heetch, FreeNow, ...).
class RideOffer {
  /// Identifiant unique de l'offre (côté app/comparateur).
  final String id;

  /// Nom de la plateforme (ex: "uber", "bolt", "heetch", "freenow").
  final String platform;

  /// Catégorie de véhicule associée à l'offre.
  final RideCategory category;

  /// Capacité minimale de passagers acceptés.
  final int capacityMin;

  /// Capacité maximale de passagers acceptés.
  final int capacityMax;

  /// Estimation du temps d'arrivée du véhicule minimal (en minutes).
  final int etaMin;

  /// Estimation du temps d'arrivée du véhicule maximal (en minutes).
  final int etaMax;

  /// Prix minimum estimé (en centimes).
  final int priceMinCents;

  /// Prix maximum estimé (en centimes).
  final int priceMaxCents;

  /// Lien profond (deeplink) vers l'application native de la plateforme.
  final String deeplinkApp;

  /// Lien profond (deeplink) vers l'interface web de la plateforme.
  final String deeplinkWeb;

  /// Crée une nouvelle offre de course.
  const RideOffer({
    required this.id,
    required this.platform,
    required this.category,
    required this.capacityMin,
    required this.capacityMax,
    required this.etaMin,
    required this.etaMax,
    required this.priceMinCents,
    required this.priceMaxCents,
    required this.deeplinkApp,
    required this.deeplinkWeb,
  });
}
