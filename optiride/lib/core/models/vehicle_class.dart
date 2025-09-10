enum VehicleClass { economy, comfort, premium, van }

extension VehicleClassX on VehicleClass {
  String get label => switch (this) {
        VehicleClass.economy => 'Economy',
        VehicleClass.comfort => 'Comfort',
  VehicleClass.premium => 'Premium',
  VehicleClass.van => 'Van',
      };
}
