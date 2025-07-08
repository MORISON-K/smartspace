import 'package:flutter/material.dart';
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
  double _distanceToTownKm = 1.0;

  double? _estimatedPrice;
  String? _explanation;

  final _valuationService = LandValuationService();

  void _calculateEstimate() {
    final input = PropertyInput(
      sizeInAcres: _sizeInAcres,
      locationDistrict: _district,
      isTitled: _isTitled,
      nearTarmac: _nearTarmac,
      powerNearby: _powerNearby,
      waterAvailable: _waterAvailable,
      landUse: _landUse,
      terrain: _terrain,
      distanceToTownKm: _distanceToTownKm,
    );

    setState(() {
      _estimatedPrice = _valuationService.estimateFinalPrice(input);
      _explanation = _valuationService.explainModifiers(input);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimate Land Value'),
        backgroundColor: const Color.fromARGB(255, 167, 184, 198),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Size
              TextFormField(
                decoration: _aiDecoration(
                   'Land Size (acres)',
                ),
                keyboardType: TextInputType.number,
                initialValue: _sizeInAcres.toString(),
                onChanged: (val) => _sizeInAcres = double.tryParse(val) ?? 0.5,
              ),
              const SizedBox(height: 10),

              // District dropdown
              DropdownButtonFormField(
                value: _district,
                items:
                    ['Kampala', 'Wakiso', 'Mukono', 'Mbarara', 'Gulu']
                        .map(
                          (loc) =>
                              DropdownMenuItem(value: loc, child: Text(loc)),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _district = val!),
                decoration: _aiDecoration('District'),
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
                items:
                    ['Residential', 'Commercial', 'Agricultural']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (val) => setState(() => _landUse = val!),
                decoration: _aiDecoration('Land Use'),
              ),

              SizedBox(height: 15,),

              //Terrain
              DropdownButtonFormField(
                value: _terrain,
                items:
                    ['Flat', 'Rocky', 'Swampy']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                onChanged: (val) => setState(() => _terrain = val!),
                decoration: _aiDecoration('Terrain'),
              ),

               SizedBox(height: 15,),

              // Distance to town
              TextFormField(
                decoration: _aiDecoration(
                   'Distance to Town (km)',
                ),
                keyboardType: TextInputType.number,
                initialValue: _distanceToTownKm.toString(),
                onChanged:
                    (val) => _distanceToTownKm = double.tryParse(val) ?? 1.0,
              ),

              const SizedBox(height: 15),

              OutlinedButton.icon(
                onPressed: _calculateEstimate,
                icon: const Icon(Icons.auto_awesome),
                label: const Text("Estimate Price"),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
              ),

              if (_estimatedPrice != null) ...[
                const SizedBox(height: 20),
                Text(
                  "Estimated Value: ${_estimatedPrice!.toStringAsFixed(2)} UGX",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text("Breakdown: $_explanation"),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

  InputDecoration _aiDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF007BFF), width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
