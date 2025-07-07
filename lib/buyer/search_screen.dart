import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


const LatLng  currentLocation = LatLng(0.3152, 32.5816); // Example coordinates for Kampala, Uganda

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late GoogleMapController mapController;
  Map<String, Marker> markers = {};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentLocation,
          zoom: 4.0, // Adjust the zoom level as needed
        ),
        onMapCreated: (controller){
          mapController =controller;
          addMarker('test',currentLocation);
          
          
          
        },
        markers: markers.values.toSet(),
      
      

    
      ),
    
      );
  }

  
  addMarker(String markerId,LatLng location){
    
          
    var marker = Marker(
      markerId: MarkerId(markerId),
      position: location,
      infoWindow: InfoWindow(
        title: 'Title of the place',
        snippet: 'This is a marker at $location',
      ),
      
      
    );
    markers[markerId] = marker;
    setState(() {});
  }
}

