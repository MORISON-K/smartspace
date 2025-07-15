// Required imports for file operations, UI components, image/file picking,
// Firebase services, and geocoding functionality
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartspace/seller/recent-activity/activity_service.dart';

/// Screen that allows sellers to add new property listings
/// Users can input property details, upload images, attach documents, and submit for approval
class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers for form inputs
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _acreageController = TextEditingController();
  final _phoneController = TextEditingController();

  // Selected category for the property (Freehold, Leasehold, etc.)
  String? _selectedCategory;

  // List to store selected images for the property
  List<XFile> _images = [];

  // File to store the selected PDF document (land title)
  File? _pdfFile;

  // Image picker instance for selecting multiple images
  final ImagePicker _picker = ImagePicker();

  /// Allows users to select multiple images from their device gallery
  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _images = picked;
      });
    }
  }

  /// Allows users to pick a PDF file (specifically for land title documents)
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

        // Save all listing data to Firestore database
        final docRef = await FirebaseFirestore.instance
            .collection('listings')
            .add({
              'title': "land",
              'price': _priceController.text.trim(),
              'location': _locationController.text.trim(),
              'latitude': lat,
              'longitude': lng,
              'mobile_number': '256 ${_phoneController.text.trim()}',
              'category': _selectedCategory,
              'description': _descriptionController.text.trim(),
              'acreage': '${_acreageController.text.trim()} acres',
              'images': imageUrls,
              'pdf': pdfUrl,
              'createdAt': Timestamp.now(),
              'user_id': user.uid,
              'sellerName': sellerName,
              "status": "pending",
            });

        final ActivityService activityService = ActivityService();
        await activityService.createListingActivity(
          _locationController.text.trim(), // propertyTitle
          docRef.id, // propertyId
        );

        _showSnack("Listing submitted successfully!");
        Navigator.of(context).pop(); // Return to previous screen
      } catch (e) {
        _showSnack("Error: $e");
      }
    }
  }

  /// Creates consistent input decoration styling for all form fields
  InputDecoration _inputDecoration(String label) {
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

  /// Clean up text controllers when widget is disposed to prevent memory leaks
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
              // Price input field with number keyboard and validation
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Price (UGX)'),
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

              // Location input field
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Location'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Mobile Number').copyWith(
                  prefixText: '+256 ',
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

              // Category dropdown with predefined options
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Category'),
                value: _selectedCategory,
                items:
                    ['Freehold', 'Leasehold', 'Mailo', 'Customary']
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 12),

              // Acreage input field
              TextFormField(
                controller: _acreageController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Acreage (in acres)'),
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

              // Multi-line description input field
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration('Description (max 30 words)'),
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
                  backgroundColor: const Color.fromARGB(255, 149, 65, 23),
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
