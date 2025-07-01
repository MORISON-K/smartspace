import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geocoding/geocoding.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  List<XFile> _images = [];
  File? _pdfFile;

  final ImagePicker _picker = ImagePicker();

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
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
      });
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
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
        // Convert location to coordinates
        final placemarks = await locationFromAddress(_locationController.text.trim());
        final lat = placemarks.first.latitude;
        final lng = placemarks.first.longitude;

        // Upload images
        List<String> imageUrls = [];
        for (var img in _images) {
          final file = File(img.path);
          final ref = FirebaseStorage.instance
              .ref('images/${DateTime.now().millisecondsSinceEpoch}_${img.name}');
          await ref.putFile(file);
          imageUrls.add(await ref.getDownloadURL());
        }

        // Upload PDF
        final pdfRef = FirebaseStorage.instance
            .ref('pdfs/${DateTime.now().millisecondsSinceEpoch}_${_pdfFile!.path.split('/').last}');
        await pdfRef.putFile(_pdfFile!);
        final pdfUrl = await pdfRef.getDownloadURL();

        // Save to Firestore
        await FirebaseFirestore.instance.collection('listings').add({
          'price': _priceController.text.trim(),
          'location': _locationController.text.trim(),
          'latitude': lat,
          'longitude': lng,
          'category': _selectedCategory,
          'description': _descriptionController.text.trim(),
          'images': imageUrls,
          'pdf': pdfUrl,
          'createdAt': Timestamp.now(),
        });

        _showSnack("Listing submitted successfully!");
        Navigator.of(context).pop();
      } catch (e) {
        _showSnack("Error: $e");
      }
    }
  }

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

  @override
  void dispose() {
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: const Color.fromARGB(255, 164, 192, 221),),
          onPressed: () => Navigator.of(context).pop(),),
        title: const Text(
  "Add New Property",
  style: TextStyle(
    color: Color.fromARGB(255, 0, 153, 255), 
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
          key: _formKey,
          child: ListView(
            children: [
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
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Category'),
                value: _selectedCategory,
                items: ['Freehold', 'Leasehold', 'Mailo', 'Customary']
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration('Description'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text("Upload Images"),
                style: _buttonStyle(),
              ),
              if (_images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _images
                        .map((img) => Image.file(
                              File(img.path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Attach Land Title (PDF)"),
                style: _buttonStyle(),
              ),
              if (_pdfFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Attached: ${_pdfFile!.path.split('/').last}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('SUBMIT FOR APPROVAL'),
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF),
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

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0.5,
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      textStyle: const TextStyle(fontSize: 14),
    );
  }
}
