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
import 'package:smartspace/seller/widgets/price_input_widget.dart';
import 'package:smartspace/seller/widgets/location_input_widget.dart';
import 'package:smartspace/seller/widgets/media_upload_widget.dart';
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
  bool _isAutoPredicating = false;
  bool _hasAutoPredicted = false;
  bool _isSubmitting = false;

  // Add tenure options
  final List<String> tenureOptions = [
    'Freehold',
    'Customary',
    'Leasehold',
    'Mailo',
  ];

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
        _hasAutoPredicted = true;
      }

      setState(() {});
    }
  }

  // Add automatic prediction method
  Future<void> _autoPredicteValue() async {
    // Check if all required fields are filled for prediction
    if (_selectedTenure == null ||
        _locationController.text.trim().isEmpty ||
        _selectedLandUse == null ||
        _acreageController.text.trim().isEmpty) {
      return; // Not enough data for prediction
    }

    // Don't predict if we already have a prediction or user is using custom price
    if (_hasAutoPredicted || _useCustomPrice) {
      return;
    }

    // Validate acreage is a valid number
    if (double.tryParse(_acreageController.text.trim()) == null) {
      return;
    }

    setState(() {
      _isAutoPredicating = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse(
              "https://smartspace-e7e32524ddcb.herokuapp.com/api/predict/",
            ),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "TENURE": _selectedTenure!,
              "LOCATION": _locationController.text.trim(),
              "USE": _selectedLandUse!,
              "PLOT_ac": double.parse(_acreageController.text.trim()),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _predictedPrice = data["predicted_value"].toDouble();
          _priceController.text = _predictedPrice!.toStringAsFixed(0);
          _hasAutoPredicted = true;
        });
      }
    } catch (e) {
      // Silent failure for auto-prediction
      print("Auto-prediction failed: $e");
    } finally {
      setState(() {
        _isAutoPredicating = false;
      });
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

      setState(() {
        _isSubmitting = true;
      });

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
        if (_predictedPrice != null) {
          listingData['prediction_data'] = {
            'predicted_value': _predictedPrice,
            'used_predicted_price': !_useCustomPrice,
            'tenure': _selectedTenure,
            'original_location': _locationController.text.trim(),
            'original_use': _selectedLandUse,
            'original_plot_size':
                double.tryParse(_acreageController.text.trim()) ?? 0.0,
            'prediction_timestamp': Timestamp.now(),
            'auto_generated':
                widget.predictionData ==
                null, // Track if this was auto-generated
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
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
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
              // Phone number field (now first)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  'Mobile Number',
                  prefixIcon: Icons.phone,
                ).copyWith(
                  prefixText: '256 ',
                  prefixStyle: const TextStyle(
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

              // Location input widget
              LocationInputWidget(
                locationController: _locationController,
                allowedLocations: allowedLocations,
                isLoadingLocations: isLoadingLocations,
                errorMessage: errorMessage,
                onLocationChanged: (value) {
                  _locationController.text = value;
                  _autoPredicteValue();
                },
                onLocationSelected: (selection) {
                  _locationController.text = selection;
                  _autoPredicteValue();
                },
                inputDecoration: _inputDecoration,
              ),

              // Tenure dropdown
              DropdownButtonFormField<String>(
                decoration: _inputDecoration(
                  'Land Tenure Type',
                  prefixIcon: Icons.gavel,
                ).copyWith(helperText: "Select the type of land ownership"),
                value: _selectedTenure,
                items:
                    tenureOptions.map((String tenure) {
                      return DropdownMenuItem<String>(
                        value: tenure,
                        child: Text(tenure),
                      );
                    }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedTenure = val;
                  });
                  _autoPredicteValue();
                },
                validator:
                    (value) =>
                        value == null ? 'Please select land tenure type' : null,
              ),
              const SizedBox(height: 12),

              // Acreage field
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
                onChanged: (value) {
                  // Trigger auto-prediction after user stops typing for 1 second
                  Future.delayed(const Duration(seconds: 1), () {
                    if (_acreageController.text == value &&
                        double.tryParse(value) != null) {
                      _autoPredicteValue();
                    }
                  });
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
                  _autoPredicteValue();
                },
                validator:
                    (value) => value == null ? 'Please select land use' : null,
              ),
              const SizedBox(height: 12),

              // Price input and prediction widget (now after land use)
              PriceInputWidget(
                priceController: _priceController,
                predictedPrice: _predictedPrice,
                useCustomPrice: _useCustomPrice,
                isAutoPredicating: _isAutoPredicating,
                hasAutoPredicted: _hasAutoPredicted,
                onUseCustomPriceChanged: (value) {
                  setState(() {
                    _useCustomPrice = value;
                    if (!_useCustomPrice && _predictedPrice != null) {
                      _priceController.text = _predictedPrice!.toStringAsFixed(
                        0,
                      );
                    } else if (_useCustomPrice) {
                      _priceController.clear();
                    }
                  });
                },
                inputDecoration: _inputDecoration,
                predictionData: widget.predictionData,
              ),

              // Description field
              TextFormField(
                controller: _descriptionController,
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

              // Media upload widget
              MediaUploadWidget(
                images: _images,
                pdfFile: _pdfFile,
                onPickImages: _pickImages,
                onPickPDF: _pickPDF,
                buttonStyle: _buttonStyle,
              ),

              // Submit button
              ElevatedButton.icon(
                icon:
                    _isSubmitting
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.cloud_upload_outlined, size: 18),
                label: Text(
                  _isSubmitting ? 'SUBMITTING...' : 'SUBMIT FOR APPROVAL',
                ),
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSubmitting
                          ? Colors.grey
                          : const Color.fromARGB(255, 23, 149, 99),
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
