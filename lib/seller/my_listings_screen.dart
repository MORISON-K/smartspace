import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
        const SnackBar(content: Text("Listing deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete listing")),
      );
    }
  }

  void confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this listing?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              deleteListing(docId);
            },
            child: const Text("Delete"),
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
            title: const Text("Edit Listing"),
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
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: newImageFile != null
                          ? Image.file(newImageFile!, fit: BoxFit.cover)
                          : (imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.cover)
                              : const Icon(Icons.add_a_photo)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty ||
                      priceController.text.isEmpty ||
                      locationController.text.isEmpty ||
                      descriptionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill in all fields")),
                    );
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Listing updated")),
                  );
                },
                child: const Text("Save"),
              ),
            ],
          );
        });
      },
    );
  }

  void _showReplyDialog(String listingId, String requestId, String currentReply) {
    final TextEditingController replyController = TextEditingController(text: currentReply);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reply to Admin Request'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(
            hintText: 'Type your reply here',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final replyText = replyController.text.trim();
              if (replyText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reply cannot be empty')),
                );
                return;
              }

              // Update Firestore with seller's reply and change status to 'responded'
              await FirebaseFirestore.instance
                  .collection('listings')
                  .doc(listingId)
                  .collection('documentRequests')
                  .doc(requestId)
                  .update({
                'sellerReply': replyText,
                'status': 'responded',
                'responseTimestamp': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reply sent successfully')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Listings"),
        backgroundColor: const Color.fromARGB(255, 164, 192, 221),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('user_id', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No listings found'));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final images = data['images'] as List<dynamic>? ?? [];
              final imageUrl = images.isNotEmpty ? images[0] : '';
              final description = data['description'] ?? 'No description';
              final title = data['title'] ?? 'Property Listing';
              final price = data['price'] ?? 'N/A';
              final location = data['location'] ?? 'No location';

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Optional: open listing details screen here
                        },
                        child: ListTile(
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(imageUrl, fit: BoxFit.cover)
                                  : const Icon(Icons.home, color: Colors.grey),
                            ),
                          ),
                          title: Text(title),
                          subtitle: Text(
                            '$description\n📍 $location',
                            style: const TextStyle(height: 1.3),
                          ),
                          isThreeLine: true,
                          trailing: Text('\$$price'),
                        ),
                      ),

                      // Admin requests for this listing
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('listings')
                            .doc(doc.id)
                            .collection('documentRequests')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, reqSnapshot) {
                          if (reqSnapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (reqSnapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Error: ${reqSnapshot.error}'),
                            );
                          }

                          if (!reqSnapshot.hasData || reqSnapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('No admin requests'),
                            );
                          }

                          final requests = reqSnapshot.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: requests.length,
                            itemBuilder: (context, i) {
                              final reqDoc = requests[i];
                              final reqData = reqDoc.data() as Map<String, dynamic>;
                              final message = reqData['message'] ?? '';
                              final status = reqData['status'] ?? 'pending';
                              final sellerReply = reqData['sellerReply'] ?? '';

                              return Card(
                                color: status == 'pending'
                                    ? Colors.orange.shade50
                                    : Colors.green.shade50,
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                child: ListTile(
                                  title: Text(message),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Status: $status'),
                                      if (sellerReply.isNotEmpty) Text('Your reply: $sellerReply'),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.reply),
                                    onPressed: () {
                                      _showReplyDialog(doc.id, reqDoc.id, sellerReply);
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // Action buttons for listing
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => showEditDialog(doc.id, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => confirmDelete(doc.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
