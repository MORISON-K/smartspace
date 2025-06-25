import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({Key? key}) : super(key: key);

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

  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Property"),
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
              // Price
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

              // Location
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Location'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField(
                decoration: _inputDecoration('Category'),
                items: ['Freehold', 'Leasehold', 'Mailo', 'Customary']
                    .map((cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) =>
                    value == null ? "Please select a category" : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Description'),
                maxLines: 3,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Image Upload
              Text("Upload Property Images", style: _sectionTitleStyle()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  ..._images.map((img) => Image.file(
                        File(img.path),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),

              // PDF Upload
              Text("Attach Land Title (PDF)", style: _sectionTitleStyle()),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _pdfFile != null
                        ? Text(
                            _pdfFile!.path.split('/').last,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const Text("No file selected"),
                  ),
                  TextButton.icon(
                    onPressed: _pickPdf,
                    icon: const Icon(Icons.attach_file),
                    label: const Text("Attach PDF"),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
void _handleSubmit() async {
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
      // Upload images to Firebase Storage
      List<String> imageUrls = [];
      for (var img in _images) {
        final file = File(img.path);
        final fileName = 'images/${DateTime.now().millisecondsSinceEpoch}_${img.name}';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Upload PDF to Firebase Storage
      final pdfName = 'pdfs/${DateTime.now().millisecondsSinceEpoch}_${_pdfFile!.path.split('/').last}';
      final pdfRef = FirebaseStorage.instance.ref().child(pdfName);
      await pdfRef.putFile(_pdfFile!);
      final pdfUrl = await pdfRef.getDownloadURL();

      // Save all data to Firestore
      await FirebaseFirestore.instance.collection('listings').add({
        'price': _priceController.text.trim(),
        'location': _locationController.text.trim(),
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'images': imageUrls,
        'pdf': pdfUrl,
        'createdAt': Timestamp.now(),
      });

      _showSnack("Listing submitted successfully!");
      Navigator.of(context).pop(); // Optional: go back to previous screen
    } catch (e) {
      _showSnack("Upload failed: $e");
    }
  }
}

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 75);
    if (picked.isNotEmpty) {
      setState(() => _images = picked);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final size = result.files.single.size;
      if (size > 5 * 1024 * 1024) {
        _showSnack("File too large (max 5MB)");
        return;
      }
      setState(() => _pdfFile = File(result.files.single.path!));
    } else {
      _showSnack("No file selected or invalid file.");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

  TextStyle _sectionTitleStyle() {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
