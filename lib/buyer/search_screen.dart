import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // For locationFromAddress

const LatLng currentLocation = LatLng(0.3152, 32.5816); // Kampala

class SearchScreen extends StatefulWidget {
  final LatLng? targetLocation;
  final String? label;

  const SearchScreen({
    super.key,
    this.targetLocation,
    this.label,
  });

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
      appBar: AppBar(
        title: const Text("Search Location"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.targetLocation ?? currentLocation,
              zoom: 12.0,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              if (widget.targetLocation != null) {
                // Listing location provided
                mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(widget.targetLocation!, 15),
                );
                addMarker(
                  widget.label ?? "Listing Location",
                  widget.targetLocation!,
                );
              } else {
                // Default location
                addMarker("Kampala", currentLocation);
              }
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                  ),
                ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding location: $e')),
      );
    }
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
}
