import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  _MyListingsScreenState createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final List<Map<String, dynamic>> _listings = [];
  final _formKey = GlobalKey<FormState>();

  String _location = '';
  String _price = '';
  String _size = '';
  File? _image;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _addListing() {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select an image')));
        return;
      }

      _formKey.currentState!.save();

      setState(() {
        _listings.add({
          'location': _location,
          'price': _price,
          'size': _size,
          'image': _image,
        });
        _image = null; // reset image
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Listing added')));
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Add Listing'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Location'),
                      validator:
                          (value) => value!.isEmpty ? 'Enter location' : null,
                      onSaved: (value) => _location = value!,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator:
                          (value) => value!.isEmpty ? 'Enter price' : null,
                      onSaved: (value) => _price = value!,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Size'),
                      validator:
                          (value) => value!.isEmpty ? 'Enter size' : null,
                      onSaved: (value) => _size = value!,
                    ),
                    const SizedBox(height: 10),
                    _image != null
                        ? Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_image!, fit: BoxFit.cover),
                          ),
                        )
                        : const Text('No image selected'),
                    TextButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Image'),
                      onPressed: _pickImage,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(onPressed: _addListing, child: const Text('Add')),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
        ],
      ),
      body:
          _listings.isEmpty
              ? const Center(child: Text('No listings yet. Tap "ADD+" to add.'))
              : ListView.builder(
                itemCount: _listings.length,
                itemBuilder: (ctx, index) {
                  final item = _listings[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading:
                          item['image'] != null
                              ? Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    item['image'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                              : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.home,
                                  color: Colors.grey,
                                ),
                              ),
                      title: Text(item['location']),
                      subtitle: Text(
                        'Price: \$${item['price']}, Size: ${item['size']}',
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
