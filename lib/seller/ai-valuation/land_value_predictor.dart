import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smartspace/seller/ai-valuation/land_prediction_data.dart';
import 'package:smartspace/seller/add_listing_screen.dart';

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
    if (!mounted) return;

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

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          predictedValue = data["predicted_value"].toDouble();
        });

        _showPredictionResultModal();
      } else {
        setState(() {
          errorMessage = "Error: ${response.statusCode}\n${response.body}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Request failed: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _plotAcController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  List<String> allowedLocations = [];
  bool isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _fetchAllowedLocations();
  }

  Future<void> _fetchAllowedLocations() async {
    final url = "https://smartspace-e7e32524ddcb.herokuapp.com/api/locations/";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle different possible response structures
        List<String> locations = [];

        if (data is Map) {
          // If response is a map, try different possible keys
          if (data['locations'] != null) {
            locations = List<String>.from(data['locations']);
          } else if (data['LOCATION'] != null) {
            locations = List<String>.from(data['LOCATION']);
          } else if (data['data'] != null) {
            locations = List<String>.from(data['data']);
          } else {
            //  list all keys for debugging
            throw Exception(
              "Expected location data not found in response. Available keys: ${data.keys.toList()}",
            );
          }
        } else if (data is List) {
          // If response is directly a list
          locations = List<String>.from(data);
        } else {
          throw Exception("Unexpected response format: ${data.runtimeType}");
        }

        if (mounted) {
          setState(() {
            allowedLocations = locations;
            isLoadingLocations = false;
          });
        }
      } else {
        throw Exception(
          "Failed to load locations. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Could not fetch locations: $e";
          isLoadingLocations = false;
        });
      }
    }
    return;
  }

  void _showPredictionResultModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 103, 28, 23),
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
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
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
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryRow(
                              Icons.gavel,
                              "Tenure",
                              selectedTenure!,
                            ),
                            _buildSummaryRow(
                              Icons.business,
                              "Use",
                              selectedUse!,
                            ),
                            _buildSummaryRow(
                              Icons.location_city,
                              "Location",
                              _locationController.text,
                            ),
                            _buildSummaryRow(
                              Icons.crop_free,
                              "Plot Size",
                              "${_plotAcController.text} acres",
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: const Text('Close'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context); // Close modal first
                                final predictionData = LandPredictionData(
                                  tenure: selectedTenure!,
                                  location: _locationController.text,
                                  use: selectedUse!,
                                  plotSize: double.parse(
                                    _plotAcController.text,
                                  ),
                                  predictedValue: predictedValue,
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AddListingScreen(
                                          predictionData: predictionData,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_business),
                              label: const Text('Create Listing'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  45,
                                  48,
                                  48,
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green[700]),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Land Valuation"),
        backgroundColor: Color.fromARGB(255, 45, 48, 48),
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
                          color: const Color.fromARGB(255, 45, 48, 48),
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
                  prefixIcon: Icon(
                    Icons.gavel,
                    color: Color.fromARGB(255, 188, 162, 16),
                  ),
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
                  prefixIcon: Icon(
                    Icons.business,
                    color: Color.fromARGB(255, 188, 162, 16),
                  ),
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

              //Location Autocomplete Field
              if (isLoadingLocations)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text("Loading locations..."),
                      ],
                    ),
                  ),
                )
              else if (allowedLocations.isNotEmpty)
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return allowedLocations.where((String option) {
                      return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  fieldViewBuilder: (
                    context,
                    controller,
                    focusNode,
                    onEditingComplete,
                  ) {
                    _locationController.text = controller.text;
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: "Location",
                        prefixIcon: Icon(
                          Icons.location_city,
                          color: Color.fromARGB(255, 188, 162, 16),
                        ),
                        border: OutlineInputBorder(),
                        helperText: "Start typing to choose a valid location",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter the location";
                        }
                        if (!allowedLocations.contains(value)) {
                          return "Invalid location. Please select from the suggestions.";
                        }
                        return null;
                      },
                    );
                  },
                  onSelected: (String selection) {
                    _locationController.text = selection;
                  },
                )
              else
                // Fallback: Regular text field if locations couldn't be loaded
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: "Location",
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                    helperText:
                        "Enter the location (auto-suggestions unavailable)",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter the location";
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
                  prefixIcon: Icon(
                    Icons.crop_free,
                    color: Color.fromARGB(255, 188, 162, 16),
                  ),
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
                    isLoading || isLoadingLocations
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
                  backgroundColor: const Color.fromARGB(164, 5, 32, 34),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
