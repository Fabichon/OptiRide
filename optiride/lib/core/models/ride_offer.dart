import 'provider_id.dart';
import 'vehicle_class.dart';
import 'service_tag.dart';

class RideOffer {
  final ProviderId provider;
  final VehicleClass vehicleClass;
  final double estimatedPrice; // EUR
  final Duration etaDriver;
  final DateTime timestamp;
  final List<ServiceTag> tags;

  const RideOffer({
    required this.provider,
    required this.vehicleClass,
    required this.estimatedPrice,
    required this.etaDriver,
    required this.timestamp,
    this.tags = const [],
  });

  factory RideOffer.fromApi(Map<String, dynamic> json) {
    return RideOffer(
      provider: ProviderId.values.firstWhere((p) => p.name == json['provider']),
      vehicleClass: VehicleClass.values.firstWhere((v) => v.name == json['vehicleClass']),
      estimatedPrice: (json['estimatedPrice'] as num).toDouble(),
      etaDriver: Duration(seconds: json['etaDriverSec'] as int),
      timestamp: DateTime.parse(json['generatedAt'] as String),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => ServiceTag.values.firstWhere(
                (t) => t.name == e,
                orElse: () => ServiceTag.eco,
              ))
          .toList(),
    );
  }
}
