import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place with ClusterItem {
  final String id;
  final String name;
  final LatLng latLng;

  Place({
    required this.id,
    required this.name,
    required double lat,
    required double lng,
  }) : latLng = LatLng(lat, lng);

  @override
  LatLng get location => latLng;
}
