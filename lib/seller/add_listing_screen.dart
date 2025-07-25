import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartspace/seller/recent-activity/activity_service.dart';
import 'package:smartspace/seller/ai-valuation/land_prediction_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddListingScreen extends StatefulWidget {
  final LandPredictionData? predictionData;

  const AddListingScreen({super.key, this.predictionData});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers for form inputs
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _acreageController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedLandUse;
  String? _selectedTenure;
  List<XFile> _images = [];
  File? _pdfFile;
  final ImagePicker _picker = ImagePicker();

  // Add these new variables for price handling
  bool _useCustomPrice = false;
  double? _predictedPrice;

  // Location autocomplete variables
  List<String> allowedLocations = [];
  bool isLoadingLocations = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _populateFieldsFromPrediction();
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

        setState(() {
          allowedLocations = locations;
          isLoadingLocations = false;
        });
      } else {
        throw Exception(
          "Failed to load locations. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = "Could not fetch locations: $e";
        isLoadingLocations = false;
      });
    }
    return;
  }

  void _populateFieldsFromPrediction() {
    if (widget.predictionData != null) {
      final data = widget.predictionData!;

      // Populate form fields with prediction data
      _locationController.text = data.location;
      _selectedTenure = data.tenure;
      _acreageController.text = data.plotSize.toString();
      _selectedLandUse = data.use;

      // Store predicted value and set as default price
      if (data.predictedValue != null) {
        _predictedPrice = data.predictedValue!;
        _priceController.text = data.predictedValue!.toStringAsFixed(0);
      }

      setState(() {});
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _images = picked;
      });
    }
  }

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Only PDF files are allowed
    );

    if (result != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
      });
    }
  }

  /// Helper method to show snackbar messages to the user
  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Handles the form submission process:
  /// 1. Validates form inputs
  /// 2. Converts location text to coordinates
  /// 3. Uploads images and PDF to Firebase Storage
  /// 4. Saves listing data to Firestore database
  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      // Check if required files are selected
      if (_images.isEmpty) {
        _showSnack("Please upload at least one image.");
        return;
      }
      if (_pdfFile == null) {
        _showSnack("Please attach a land title PDF.");
        return;
      }

      _showSnack("Uploading...");

      try {
        // Get the current logged-in user
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          _showSnack("You must be logged in to submit a listing");
          return;
        }

        // Get seller name from users collection
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        final sellerName = userDoc.data()?['name'] ?? 'Unknown Seller';
        // Convert location string to latitude and longitude coordinates
        final placemarks = await locationFromAddress(
          _locationController.text.trim(),
        );
        final lat = placemarks.first.latitude;
        final lng = placemarks.first.longitude;

        // Upload all selected images to Firebase Storage
        List<String> imageUrls = [];
        for (var img in _images) {
          final file = File(img.path);
          final ref = FirebaseStorage.instance.ref(
            'images/${DateTime.now().millisecondsSinceEpoch}_${img.name}',
          );
          await ref.putFile(file);
          imageUrls.add(await ref.getDownloadURL());
        }

        // Upload PDF document to Firebase Storage
        final pdfRef = FirebaseStorage.instance.ref(
          'pdfs/${DateTime.now().millisecondsSinceEpoch}_${_pdfFile!.path.split('/').last}',
        );
        await pdfRef.putFile(_pdfFile!);
        final pdfUrl = await pdfRef.getDownloadURL();

        // Prepare listing data with both actual and predicted prices
        Map<String, dynamic> listingData = {
          'title': "land",
          'price': _priceController.text.trim(),
          'location': _locationController.text.trim(),
          'latitude': lat,
          'longitude': lng,
          'mobile_number':
              '256 ${_phoneController.text.trim().replaceAll(RegExp(r'[^\d]'), '')}',
          'land_use': _selectedLandUse,
          'tenure': _selectedTenure,
          'description': _descriptionController.text.trim(),
          'acreage': '${_acreageController.text.trim()} acres',
          'images': imageUrls,
          'pdf': pdfUrl,
          'createdAt': Timestamp.now(),
          'user_id': user.uid,
          'sellerName': sellerName,
          "status": "pending",
        };

        // Add prediction data if available
        if (widget.predictionData != null) {
          listingData['prediction_data'] = {
            'predicted_value': _predictedPrice,
            'used_predicted_price': !_useCustomPrice,
            'tenure': widget.predictionData!.tenure,
            'original_location': widget.predictionData!.location,
            'original_use': widget.predictionData!.use,
            'original_plot_size': widget.predictionData!.plotSize,
            'prediction_timestamp': Timestamp.now(),
          };
        }

        // Save all listing data to Firestore database
        final docRef = await FirebaseFirestore.instance
            .collection('listings')
            .add(listingData);

        final ActivityService activityService = ActivityService();
        await activityService.createListingActivity(
          _locationController.text.trim(), // propertyTitle
          docRef.id, // propertyId
        );

        _showSnack("Listing submitted successfully!");
        if (mounted) {
          Navigator.of(context).pop(); // Return to previous screen
        }
      } catch (e) {
        _showSnack("Error: $e");
      }
    }
  }

  /// Creates consistent input decoration styling for all form fields
  InputDecoration _inputDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _acreageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with back button and title
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color.fromARGB(255, 164, 192, 221),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Add New Property",
          style: TextStyle(
            color: Color.fromARGB(255, 22, 24, 25),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
            fontFamily: 'Roboto',
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Form key for validation
          child: ListView(
            children: [
              // Enhanced prediction info card with price options
              if (widget.predictionData != null &&
                  widget.predictionData!.predictedValue != null) ...[
                Card(
                  elevation: 2,
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'AI Predicted Value',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color.fromARGB(255, 233, 249, 144),
                            ),
                          ),
                          child: Text(
                            'UGX ${widget.predictionData!.predictedValue!.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Choose your pricing option:',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            RadioListTile<bool>(
                              title: Text(
                                'Use AI predicted price',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'UGX ${widget.predictionData!.predictedValue!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: false,
                              groupValue: _useCustomPrice,
                              onChanged: (value) {
                                setState(() {
                                  _useCustomPrice = value!;
                                  if (!_useCustomPrice) {
                                    _priceController.text = widget
                                        .predictionData!
                                        .predictedValue!
                                        .toStringAsFixed(0);
                                  }
                                });
                              },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            RadioListTile<bool>(
                              title: Text(
                                'Set my own price',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Enter your preferred price below',
                                style: TextStyle(
                                  color: Colors.orange[600],
                                  fontSize: 12,
                                ),
                              ),
                              value: true,
                              groupValue: _useCustomPrice,
                              onChanged: (value) {
                                setState(() {
                                  _useCustomPrice = value!;
                                  if (_useCustomPrice) {
                                    _priceController.clear();
                                  }
                                });
                              },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Modified price input field
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                enabled:
                    widget.predictionData?.predictedValue == null ||
                    _useCustomPrice,
                decoration: _inputDecoration(
                  'Price (UGX)',
                  prefixIcon: Icons.attach_money,
                ).copyWith(
                  filled:
                      widget.predictionData?.predictedValue != null &&
                      !_useCustomPrice,
                  fillColor:
                      widget.predictionData?.predictedValue != null &&
                              !_useCustomPrice
                          ? Colors.grey[100]
                          : null,
                  helperText:
                      widget.predictionData?.predictedValue != null &&
                              !_useCustomPrice
                          ? 'Using AI predicted price'
                          : 'Enter your desired price',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Location input field with autocomplete
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
                    // Sync the autocomplete controller with our location controller
                    if (_locationController.text.isNotEmpty &&
                        controller.text.isEmpty) {
                      controller.text = _locationController.text;
                    }
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: _inputDecoration(
                        'Location',
                        prefixIcon: Icons.location_city,
                      ).copyWith(
                        helperText: "Start typing to choose a valid location",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Location is required';
                        }
                        if (!allowedLocations.contains(value)) {
                          return "Invalid location. Please select from the suggestions.";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _locationController.text = value;
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
                  decoration: _inputDecoration(
                    'Location',
                    prefixIcon: Icons.location_city,
                  ).copyWith(
                    helperText:
                        "Enter the location (auto-suggestions unavailable)",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Location is required';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 12),

              // Show error message if location loading failed
              if (errorMessage != null && !isLoadingLocations) ...[
                Card(
                  elevation: 2,
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location suggestions unavailable. You can still enter location manually.',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  'Mobile Number',
                  prefixIcon: Icons.phone,
                ).copyWith(
                  prefixText: '256 ',
                  prefixStyle: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: '700123456',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Mobile Number is required';
                  }
                  // Remove any spaces and check if it's a valid phone number
                  String cleanedValue = value.replaceAll(' ', '');
                  if (cleanedValue.length < 9 || cleanedValue.length > 10) {
                    return 'Enter a valid mobile number (9-10 digits)';
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(cleanedValue)) {
                    return 'Enter only numbers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Acreage input field
              TextFormField(
                controller: _acreageController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  'Acreage (in acres)',
                  prefixIcon: Icons.crop_free,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Acreage is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Land Use dropdown
              DropdownButtonFormField<String>(
                decoration: _inputDecoration(
                  'Land Use',
                  prefixIcon: Icons.business,
                ),
                value: _selectedLandUse,
                items:
                    [
                          'Residential',
                          'Commercial',
                          'Agricultural',
                          'Industrial',
                          'Mixed',
                        ]
                        .map(
                          (use) =>
                              DropdownMenuItem(value: use, child: Text(use)),
                        )
                        .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedLandUse = val;
                  });
                },
                validator:
                    (value) => value == null ? 'Please select land use' : null,
              ),
              const SizedBox(height: 12),

              // Tenure dropdown
              DropdownButtonFormField<String>(
                decoration: _inputDecoration(
                  'Tenure',
                  prefixIcon: Icons.assignment,
                ),
                value: _selectedTenure,
                items:
                    ['Freehold', 'Customary', 'Leasehold', 'Mailo']
                        .map(
                          (tenure) => DropdownMenuItem(
                            value: tenure,
                            child: Text(tenure),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedTenure = val;
                  });
                },
                validator:
                    (value) => value == null ? 'Please select tenure' : null,
              ),
              const SizedBox(height: 12),

              // Multi-line description input field
              TextFormField(
                controller: _descriptionController,
                //maxLines: 3,
                decoration: _inputDecoration(
                  'Description (max 30 words)',
                  prefixIcon: Icons.description,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  // Count words by splitting on whitespace and filtering empty strings
                  final words =
                      value
                          .trim()
                          .split(RegExp(r'\s+'))
                          .where((word) => word.isNotEmpty)
                          .toList();
                  if (words.length > 30) {
                    return 'Description must be 30 words or less (currently ${words.length} words)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Button to select multiple images
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text("Upload Images"),
                style: _buttonStyle(),
              ),

              // Display selected images as thumbnails
              if (_images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _images
                            .map(
                              (img) => Image.file(
                                File(img.path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                            .toList(),
                  ),
                ),
              const SizedBox(height: 12),

              // Button to select PDF document
              ElevatedButton.icon(
                onPressed: _pickPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Attach Land Title (PDF)"),
                style: _buttonStyle(),
              ),

              // Display selected PDF file name
              if (_pdfFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Attached: ${_pdfFile!.path.split('/').last}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              const SizedBox(height: 20),

              // Submit button that triggers the form submission process
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('SUBMIT FOR APPROVAL'),
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 23, 149, 99),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Creates consistent button styling for image and PDF picker buttons
  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0.5,
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      textStyle: const TextStyle(fontSize: 14),
    );
  }
}
