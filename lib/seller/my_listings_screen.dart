// 🔹 main_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'responded_requests_screen.dart';


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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Listing deleted")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete listing")));
    }
  }

  void confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this listing?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
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

    Future<void> pickFiles() async {
      final picked = await ImagePicker().pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() {
          selectedFiles.addAll(picked.map((p) => File(p.path)));
        });
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Upload Documents'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Select Files'),
                onPressed: pickFiles,
              ),
              const SizedBox(height: 10),
              if (selectedFiles.isNotEmpty)
                ...selectedFiles.map((file) => Text(file.path.split('/').last)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
                  final ref = FirebaseStorage.instance.ref().child('request_documents').child(listingId).child(fileName);
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documents sent successfully')));
              },
              child: const Text('Send'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Listings"),
        backgroundColor: const Color.fromARGB(255, 164, 192, 221),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RespondedRequestsScreen()),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('listings').where('user_id', isEqualTo: user?.uid).snapshots(),
        builder: (context, snapshot) {
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
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl.isNotEmpty
                                ? Image.network(imageUrl, height: 80, width: 80, fit: BoxFit.cover)
                                : Container(
                                    height: 80,
                                    width: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.home, size: 30, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text("📍 $location", style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text("💵 \$${price.toString()}", style: const TextStyle(color: Colors.green)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(description, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('listings')
                            .doc(doc.id)
                            .collection('documentRequests')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, reqSnapshot) {
                          if (!reqSnapshot.hasData || reqSnapshot.data!.docs.isEmpty) {
                            return const Text('No admin requests');
                          }
                          final requests = reqSnapshot.data!.docs
                              .where((r) => (r.data() as Map<String, dynamic>)['status'] == 'pending')
                              .toList();
                          if (requests.isEmpty) return const Text('No pending admin requests');

                          return Column(
                            children: requests.map((reqDoc) {
                              final reqData = reqDoc.data() as Map<String, dynamic>;
                              final message = reqData['message'] ?? '';
                              final sellerDocs = reqData['sellerDocuments'] ?? [];
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: ListTile(
                                  title: Text(message),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      const Text("Status: pending"),
                                      if (sellerDocs.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        const Text('Uploaded Documents:'),
                                        ...sellerDocs.map<Widget>((url) => Text(url)).toList(),
                                      ]
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.upload_file),
                                    onPressed: () => _showReplyDialog(doc.id, reqDoc.id, sellerDocs),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => confirmDelete(doc.id)),
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
