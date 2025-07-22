import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'listings_detail_screen.dart';

const LatLng currentLocation = LatLng(0.3152, 32.5816); // Kampala

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late GoogleMapController mapController;
  Map<String, Marker> markers = {};
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Location"), centerTitle: true),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: currentLocation,
              zoom: 12.0,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              addMarker('Kampala', currentLocation);
              _loadPropertyMarkers(); // Load property listings from Firestore
            },
            markers: markers.values.toSet(),
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search place...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _searchPlace(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchPlace,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 Search using geocoding
  Future<void> _searchPlace() async {
    final query = searchController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a place name')),
      );
      return;
    }

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final target = LatLng(location.latitude, location.longitude);

        mapController.animateCamera(CameraUpdate.newLatLngZoom(target, 14));
        addMarker(query, target);
      } else {
        throw Exception("No locations found");
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error finding location: $e')));
    }
  }

  // 📍 Add a custom marker
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

  // 🔥 Load property markers from Firestore
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
                        (context) => ListingDetailScreen(
                          listing: data,
                          listingId: doc.id,
                        ),
                  ),
                );
              },
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
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
