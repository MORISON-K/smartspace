import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'listings_detail_screen.dart';

const LatLng currentLocation = LatLng(-0.33379, 31.73409); // Masaka

class SearchScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialMarkerTitle;

  const SearchScreen({
    super.key,
    this.initialLocation,
    this.initialMarkerTitle,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late GoogleMapController mapController;
  Map<String, Marker> markers = {};

  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    // Zoom to passed-in location
    if (widget.initialLocation != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(widget.initialLocation!, 15),
      );

      addMarker(
        widget.initialMarkerTitle ?? 'Property',
        widget.initialLocation!,
      );
    } else {
      addMarker('Kampala', currentLocation);
    }

    _loadPropertyMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Location"),
        backgroundColor: Color(0xFFFFE066),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.initialLocation ?? currentLocation,
          zoom: 13,
        ),
        onMapCreated: _onMapCreated,
        markers: markers.values.toSet(),
      ),
    );
  }

  void addMarker(String markerId, LatLng location) {
    final marker = Marker(
      markerId: MarkerId(markerId),
      position: location,
      infoWindow: InfoWindow(
        title: markerId,
        snippet: '${location.latitude}, ${location.longitude}',
      ),
    );
    markers[markerId] = marker;
    setState(() {});
  }

  Future<void> _loadPropertyMarkers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('listings').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lat = data['latitude'];
        final lng = data['longitude'];
        final title = data['title'] ?? 'Property';
        final price = data['price'] ?? 'N/A';

        if (lat != null && lng != null) {
          final marker = Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: 'UGX $price',
              snippet: title,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ListingDetailScreen(
                          listing: data,
                          listingId: doc.id,
                        ),
                  ),
                );
              },
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          );

          markers[doc.id] = marker;
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error loading property markers: $e');
    }
  }
}
