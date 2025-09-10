import 'package:flutter/material.dart';

enum ServiceTag { womenPreferred, petsAllowed, van, eco, luxury }

extension ServiceTagX on ServiceTag {
  String get label => switch (this) {
        ServiceTag.womenPreferred => 'Women',
        ServiceTag.petsAllowed => 'Pets',
        ServiceTag.van => 'Van',
        ServiceTag.eco => 'Eco',
        ServiceTag.luxury => 'Luxury',
      };

  IconData get icon => switch (this) {
        ServiceTag.womenPreferred => Icons.female,
        ServiceTag.petsAllowed => Icons.pets,
        ServiceTag.van => Icons.airport_shuttle,
        ServiceTag.eco => Icons.eco,
        ServiceTag.luxury => Icons.diamond,
      };
}
