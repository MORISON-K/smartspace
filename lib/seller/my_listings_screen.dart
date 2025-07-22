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

  void _showReplyDialog(String listingId, String requestId, List<dynamic> existingFiles) {
    List<File> selectedFiles = [];

    Future<void> _pickFiles() async {
      final picked = await ImagePicker().pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() {
          selectedFiles.addAll(picked.map((p) => File(p.path)));
        });
      }
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Upload Documents'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select Files'),
                  onPressed: _pickFiles,
                ),
                const SizedBox(height: 10),
                if (selectedFiles.isNotEmpty)
                  ...selectedFiles.map((file) => Text(file.path.split('/').last)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedFiles.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one document')),
                    );
                    return;
                  }

                  List<String> uploadedUrls = [];

                  for (File file in selectedFiles) {
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
                    final ref = FirebaseStorage.instance
                        .ref()
                        .child('request_documents')
                        .child(listingId)
                        .child(fileName);
                    await ref.putFile(file);
                    final url = await ref.getDownloadURL();
                    uploadedUrls.add(url);
                  }

                  await FirebaseFirestore.instance
                      .collection('listings')
                      .doc(listingId)
                      .collection('documentRequests')
                      .doc(requestId)
                      .update({
                    'status': 'responded',
                    'sellerDocuments': FieldValue.arrayUnion(uploadedUrls),
                    'responseTimestamp': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Documents sent successfully')),
                  );
                },
                child: const Text('Send'),
              ),
            ],
          );
        });
      },
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
                      ListTile(
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
                        trailing: Text('\$$price'),
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
                              final sellerDocs = reqData['sellerDocuments'] ?? [];

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
                                      if (sellerDocs.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        const Text('Uploaded Documents:'),
                                        ...sellerDocs.map<Widget>((url) => Text(url)).toList(),
                                      ]
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.upload_file),
                                    onPressed: () {
                                      _showReplyDialog(doc.id, reqDoc.id, sellerDocs);
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => {}, // add your showEditDialog
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
