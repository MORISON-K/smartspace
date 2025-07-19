import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'listing_detail_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> deleteListing(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('listings').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Listing deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete listing")),
      );
    }
  }

  void confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to delete this listing?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteListing(docId);
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> showEditDialog(String docId, Map<String, dynamic> data) async {
    final titleController = TextEditingController(text: data['title']);
    final priceController = TextEditingController(text: data['price'].toString());
    final locationController = TextEditingController(text: data['location']);
    final descriptionController = TextEditingController(text: data['description']);
    String imageUrl = (data['images'] as List<dynamic>).isNotEmpty ? data['images'][0] : '';
    File? newImageFile;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("Edit Listing"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          newImageFile = File(pickedFile.path);
                        });
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                      child: newImageFile != null
                          ? Image.file(newImageFile!, fit: BoxFit.cover)
                          : (imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.cover)
                              : Icon(Icons.add_a_photo)),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(controller: locationController, decoration: InputDecoration(labelText: 'Location')),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty ||
                      priceController.text.isEmpty ||
                      locationController.text.isEmpty ||
                      descriptionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill in all fields")));
                    return;
                  }

                  String updatedImageUrl = imageUrl;

                  if (newImageFile != null) {
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final ref = FirebaseStorage.instance.ref().child('listing_images').child(fileName);
                    await ref.putFile(newImageFile!);
                    updatedImageUrl = await ref.getDownloadURL();
                  }

                  await FirebaseFirestore.instance.collection('listings').doc(docId).update({
                    'title': titleController.text,
                    'price': priceController.text,
                    'location': locationController.text,
                    'description': descriptionController.text,
                    'images': [updatedImageUrl],
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Listing updated")));
                },
                child: Text("Save"),
              ),
            ],
          );
        });
      },
    );
  }

  void respondToAdmin(String docId, String adminRequest) {
    final responseController = TextEditingController();
    final extraDescriptionController = TextEditingController();
    List<File> selectedImages = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Respond to Admin"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (adminRequest.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Admin Request:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(adminRequest),
                      SizedBox(height: 10),
                    ],
                  ),
                TextField(
                  controller: responseController,
                  decoration: InputDecoration(
                    labelText: "Your Response",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: extraDescriptionController,
                  decoration: InputDecoration(
                    labelText: "Additional Description",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var img in selectedImages)
                      Image.file(img, width: 70, height: 70, fit: BoxFit.cover),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFiles = await picker.pickMultiImage();
                        if (pickedFiles.isNotEmpty) {
                          setState(() {
                            selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
                          });
                        }
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade300,
                        child: Icon(Icons.add_a_photo),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final response = responseController.text.trim();
                final extraDesc = extraDescriptionController.text.trim();
                List<String> uploadedUrls = [];

                for (var imageFile in selectedImages) {
                  final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
                  final ref = FirebaseStorage.instance.ref().child('listing_responses/$fileName');
                  await ref.putFile(imageFile);
                  final downloadUrl = await ref.getDownloadURL();
                  uploadedUrls.add(downloadUrl);
                }

                await FirebaseFirestore.instance.collection('listings').doc(docId).update({
                  if (response.isNotEmpty) 'user_response': response,
                  if (extraDesc.isNotEmpty) 'extra_description': extraDesc,
                  if (uploadedUrls.isNotEmpty) 'extra_images': uploadedUrls,
                  'request_status': 'open',
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Response sent to admin")));
              },
              child: Text("Send"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Listings"),
        backgroundColor: Color.fromARGB(255, 164, 192, 221),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('user_id', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(child: Text('No listings found'));

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final imageUrl = (data['images'] as List<dynamic>?)?.first ?? '';
              final title = data['title'] ?? 'Untitled';
              final price = data['price'] ?? 'N/A';
              final location = data['location'] ?? 'Unknown';
              final description = data['description'] ?? '';
              final adminRequest = data['admin_request'] ?? '';
              final userResponse = data['user_response'] ?? '';
              final extraDesc = data['extra_description'] ?? '';
              final extraImages = data['extra_images'] as List<dynamic>? ?? [];
              final requestStatus = data['request_status'] ?? 'open';

              return Card(
                margin: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                            : Icon(Icons.home, size: 60),
                      ),
                      title: Text(title),
                      subtitle: Text("$description\n📍 $location"),
                      isThreeLine: true,
                      trailing: Text('\$$price'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ListingDetailScreen(
                              imageUrl: imageUrl,
                              title: title,
                              price: price.toString(),
                              location: location,
                              description: description,
                            ),
                          ),
                        );
                      },
                    ),
                    if (adminRequest.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("🛑 Admin Request: $adminRequest", style: TextStyle(color: Colors.red)),
                            if (userResponse.isNotEmpty)
                              Text("✅ Your Response: $userResponse", style: TextStyle(color: Colors.green)),
                            if (extraDesc.isNotEmpty)
                              Text("📄 Extra Description: $extraDesc"),
                            if (extraImages.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: extraImages.map((url) {
                                  return Image.network(url, width: 70, height: 70);
                                }).toList(),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Status: ${requestStatus == 'closed' ? "✅ Resolved" : "⏳ Open"}",
                                  style: TextStyle(
                                    color: requestStatus == 'closed' ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (requestStatus != 'closed')
                                  TextButton.icon(
                                    onPressed: () => respondToAdmin(doc.id, adminRequest),
                                    icon: Icon(Icons.reply, color: Colors.green),
                                    label: Text("Respond"),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    OverflowBar(
                      alignment: MainAxisAlignment.end,
                      children: [
                        IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => showEditDialog(doc.id, data)),
                        IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => confirmDelete(doc.id)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
