import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartspace/seller/ai-valuation/land_valuation_service.dart';
import 'package:smartspace/seller/ai-valuation/property_input.dart';


class AiValuationScreen extends StatefulWidget {
  const AiValuationScreen({super.key});

  @override
  State<AiValuationScreen> createState() => _AiValuationScreenState();
}

class _AiValuationScreenState extends State<AiValuationScreen> {
   final _formKey = GlobalKey<FormState>();

  // Form fields
  double _sizeInAcres = 0.5;
  String _district = 'Wakiso';
  bool _isTitled = true;
  bool _nearTarmac = true;
  bool _powerNearby = true;
  bool _waterAvailable = false;
  String _landUse = 'Residential';
  String _terrain = 'Flat';
  String _shape = 'Regular';
  double _distanceToTownKm = 1.0;
  LatLng? _coordinates;

  double? _estimatedPrice;
  String? _explanation;

  final _valuationService = LandValuationService();

  void _calculateEstimate() {
    if (_coordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a location on map.")));
      return;
    }

    final input = PropertyInput(
      sizeInAcres: _sizeInAcres,
      locationDistrict: _district,
      isTitled: _isTitled,
      nearTarmac: _nearTarmac,
      powerNearby: _powerNearby,
      waterAvailable: _waterAvailable,
      landUse: _landUse,
      terrain: _terrain,
      shape: _shape,
      distanceToTownKm: _distanceToTownKm,
      coordinates: _coordinates!,
    );

    setState(() {
      _estimatedPrice = _valuationService.estimateFinalPrice(input);
      _explanation = _valuationService.explainModifiers(input);
    });
  }

  void _selectLocation(LatLng position) {
    setState(() => _coordinates = position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estimate Land Value')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Size
              TextFormField(
                decoration: const InputDecoration(labelText: 'Land Size (acres)'),
                keyboardType: TextInputType.number,
                initialValue: _sizeInAcres.toString(),
                onChanged: (val) => _sizeInAcres = double.tryParse(val) ?? 0.5,
              ),
              const SizedBox(height: 10),

              // District dropdown
              DropdownButtonFormField(
                value: _district,
                items: ['Kampala', 'Wakiso', 'Mukono', 'Mbarara', 'Gulu']
                    .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                    .toList(),
                onChanged: (val) => setState(() => _district = val!),
                decoration: const InputDecoration(labelText: 'District'),
              ),

              // Toggle switches
              SwitchListTile(
                title: const Text('Is the land titled?'),
                value: _isTitled,
                onChanged: (val) => setState(() => _isTitled = val),
              ),
              SwitchListTile(
                title: const Text('Near tarmac road?'),
                value: _nearTarmac,
                onChanged: (val) => setState(() => _nearTarmac = val),
              ),
              SwitchListTile(
                title: const Text('Electricity nearby?'),
                value: _powerNearby,
                onChanged: (val) => setState(() => _powerNearby = val),
              ),
              SwitchListTile(
                title: const Text('Water available?'),
                value: _waterAvailable,
                onChanged: (val) => setState(() => _waterAvailable = val),
              ),

              // Land use
              DropdownButtonFormField(
                value: _landUse,
                items: ['Residential', 'Commercial', 'Agricultural']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => _landUse = val!),
                decoration: const InputDecoration(labelText: 'Land Use'),
              ),

              // Terrain
              DropdownButtonFormField(
                value: _terrain,
                items: ['Flat', 'Rocky', 'Swampy']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _terrain = val!),
                decoration: const InputDecoration(labelText: 'Terrain'),
              ),

              // Shape
              DropdownButtonFormField(
                value: _shape,
                items: ['Regular', 'Irregular']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _shape = val!),
                decoration: const InputDecoration(labelText: 'Land Shape'),
              ),

              // Distance to town
              TextFormField(
                decoration: const InputDecoration(labelText: 'Distance to Town (km)'),
                keyboardType: TextInputType.number,
                initialValue: _distanceToTownKm.toString(),
                onChanged: (val) => _distanceToTownKm = double.tryParse(val) ?? 1.0,
              ),

              const SizedBox(height: 20),

              // Google Map Pin
              SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(0.3476, 32.5825), // Kampala default
                    zoom: 10,
                  ),
                  onTap: _selectLocation,
                  markers: _coordinates != null
                      ? {
                          Marker(markerId: const MarkerId('picked'), position: _coordinates!)
                        }
                      : {},
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _calculateEstimate,
                child: const Text("Estimate Price"),
              ),

              if (_estimatedPrice != null) ...[
                const SizedBox(height: 20),
                Text("Estimated Value: ${_estimatedPrice!.toStringAsFixed(2)} UGX",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Breakdown: $_explanation"),
              ]
            ],
          ),
        ),
      ),
    );
  }
}