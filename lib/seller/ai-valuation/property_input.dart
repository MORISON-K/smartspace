// models/property_input.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';

class PropertyInput {
  final double sizeInAcres;
  final String locationDistrict;
  final bool isTitled;
  final bool nearTarmac;
  final bool powerNearby;
  final bool waterAvailable;
  final String landUse; // e.g., "Residential", "Commercial"
  final String terrain; // e.g., "Flat", "Swampy"
  final String shape;   // e.g., "Regular", "Irregular"
  final double distanceToTownKm;
  final LatLng coordinates;

  PropertyInput({
    required this.sizeInAcres,
    required this.locationDistrict,
    required this.isTitled,
    required this.nearTarmac,
    required this.powerNearby,
    required this.waterAvailable,
    required this.landUse,
    required this.terrain,
    required this.shape,
    required this.distanceToTownKm,
    required this.coordinates,
  });
}
