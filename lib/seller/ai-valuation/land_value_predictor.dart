import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LandValuePredictorWidget extends StatefulWidget {
  const LandValuePredictorWidget({super.key});

  @override
  LandValuePredictorWidgetState createState() =>
      LandValuePredictorWidgetState();
}

class LandValuePredictorWidgetState extends State<LandValuePredictorWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _plotAcController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Dropdown values
  String? selectedTenure;
  String? selectedUse;

  // Dropdown options
  final List<String> tenureOptions = [
    'Freehold',
    'Customary',
    'Leasehold',
    'Mailo',
  ];

  final List<String> useOptions = [
    'Residential',
    'Commercial',
    'Agricultural',
    'Industrial',
    'Mixed',
  ];

  double? predictedValue;
  String? errorMessage;
  bool isLoading = false;

  String _getApiUrl() {
    if (Platform.isAndroid) {
      return "https://smartspace-e7e32524ddcb.herokuapp.com/api/predict/"; // Android emulator
    } else if (Platform.isIOS) {
      return "https://smartspace-e7e32524ddcb.herokuapp.com/api/predict/"; // iOS simulator
    } else {
      // For physical devices, replace with computer's IP
      return "http://192.168.1.100:8000/predict";
    }
  }

  Future<void> _predictLandValue() async {
    setState(() {
      isLoading = true;
      predictedValue = null;
      errorMessage = null;
    });

    final String apiUrl = _getApiUrl();

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "TENURE": selectedTenure!,
              "LOCATION": _locationController.text.trim(),
              "USE": selectedUse!,
              "PLOT_ac": double.parse(_plotAcController.text.trim()),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          predictedValue = data["predicted_value"].toDouble();
        });
      } else {
        setState(() {
          errorMessage = "Error: ${response.statusCode}\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Request failed: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _plotAcController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Land Valuation"),
        backgroundColor: const Color.fromARGB(255, 67, 160, 151),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Header Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.landscape,
                        size: 48,
                        color: const Color.fromARGB(255, 50, 55, 63),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter Land Details",
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 67, 160, 151),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Fill in the information below to predict land value",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tenure Dropdown
              DropdownButtonFormField<String>(
                value: selectedTenure,
                decoration: const InputDecoration(
                  labelText: "Land Tenure Type",
                  prefixIcon: Icon(Icons.gavel),
                  border: OutlineInputBorder(),
                  helperText: "Select the type of land ownership",
                ),
                items:
                    tenureOptions.map((String tenure) {
                      return DropdownMenuItem<String>(
                        value: tenure,
                        child: Text(tenure),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedTenure = newValue;
                  });
                },
                validator:
                    (value) =>
                        value == null ? "Please select a tenure type" : null,
              ),
              const SizedBox(height: 16),

              // Use Dropdown
              DropdownButtonFormField<String>(
                value: selectedUse,
                decoration: const InputDecoration(
                  labelText: "Land Use Type",
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                  helperText: "Select the intended use of the land",
                ),
                items:
                    useOptions.map((String use) {
                      return DropdownMenuItem<String>(
                        value: use,
                        child: Row(
                          children: [
                            Icon(_getUseIcon(use), size: 20),
                            const SizedBox(width: 8),
                            Text(use),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedUse = newValue;
                  });
                },
                validator:
                    (value) =>
                        value == null ? "Please select a land use type" : null,
              ),
              const SizedBox(height: 16),

              //Location Input Field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Location",
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                  helperText: "Enter the location",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter  the location";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Plot Size Input
              TextFormField(
                controller: _plotAcController,
                decoration: const InputDecoration(
                  labelText: "Plot Size (acres)",
                  prefixIcon: Icon(Icons.crop_free),
                  border: OutlineInputBorder(),
                  helperText:
                      "Enter the size of the plot in acres (e.g., 0.25)",
                  suffixText: "acres",
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter plot size";
                  }
                  final val = double.tryParse(value);
                  if (val == null || val <= 0) {
                    return "Enter a valid plot size greater than 0";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Predict Button
              ElevatedButton.icon(
                onPressed:
                    isLoading
                        ? null
                        : () {
                          if (_formKey.currentState!.validate()) {
                            _predictLandValue();
                          }
                        },
                icon:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.calculate),
                label: Text(
                  isLoading ? "Predicting..." : "Predict Land Value",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 149, 183, 62),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Results Section
              if (predictedValue != null) ...[
                Card(
                  elevation: 4,
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 48,
                          color: const Color.fromARGB(255, 56, 116, 142),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Predicted Land Value",
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 103, 28, 23),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "UGX ${predictedValue!.toStringAsFixed(0)}",
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Input Summary:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("• Tenure: $selectedTenure"),
                              Text("• Use: $selectedUse"),
                              Text("• Location: ${_locationController.text}"),
                              Text(
                                "• Plot Size: ${_plotAcController.text} acres",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Error Message
              if (errorMessage != null) ...[
                Card(
                  elevation: 4,
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[700],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Prediction Error",
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getUseIcon(String use) {
    switch (use) {
      case 'Residential':
        return Icons.home;
      case 'Commercial':
        return Icons.business_center;
      case 'Agricultural':
        return Icons.agriculture;
      case 'Industrial':
        return Icons.factory;
      default:
        return Icons.terrain;
    }
  }
}
