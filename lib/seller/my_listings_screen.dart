import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
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

  void showEditDialog(String docId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title']);
    final priceController = TextEditingController(text: data['price']);
    final locationController = TextEditingController(text: data['location']);
    final descriptionController = TextEditingController(text: data['description']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Listing"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price")),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: "Location")),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('listings').doc(docId).update({
                'title': titleController.text,
                'price': priceController.text,
                'location': locationController.text,
                'description': descriptionController.text,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Listing updated")));
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(String listingId, String requestId, List<dynamic> existingFiles) {
    List<File> selectedFiles = [];

    Future<void> pickFiles() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null) {
        setState(() {
          selectedFiles.addAll(result.paths.map((path) => File(path!)));
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
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text('Select PDF Files'),
                onPressed: pickFiles,
              ),
              const SizedBox(height: 10),
              if (selectedFiles.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView(
                    children: selectedFiles.map((file) => Text(file.path.split('/').last)).toList(),
                  ),
                ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Documents sent successfully')),
                );
              },
              child: const Text('Send'),
            ),
          ],
        );
      }),
    );
  }

  void _showUploadedDocs(List<dynamic> urls) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Uploaded Documents'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: urls.length,
            itemBuilder: (context, index) {
              final url = urls[index];
              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(url.split('/').last),
                onTap: () {
                  // TODO: implement open document url (e.g. url_launcher)
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Listings", style: TextStyle(color: Colors.amber)),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('listings').where('user_id', isEqualTo: user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No listings found'));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
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

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Material(
                  borderRadius: BorderRadius.circular(20),
                  elevation: 8,
                  color: const Color(0xFFFFF8DC),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('More details for "$title" coming soon!')),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, fit: BoxFit.cover)
                                    : const Icon(Icons.home, color: Colors.grey, size: 40),
                              ),
                            ),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                            subtitle: Text(
                              '$description\n📍 $location',
                              style: const TextStyle(height: 1.4),
                            ),
                            trailing: Text('\$$price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('listings')
                                .doc(doc.id)
                                .collection('documentRequests')
                                .snapshots(),
                            builder: (context, reqSnapshot) {
                              if (!reqSnapshot.hasData || reqSnapshot.data!.docs.isEmpty) {
                                return const SizedBox();
                              }

                              final requests = reqSnapshot.data!.docs;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Admin Requests:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.amber[800])),
                                  const SizedBox(height: 8),
                                  ...requests.map((reqDoc) {
                                    final reqData = reqDoc.data() as Map<String, dynamic>;
                                    final message = reqData['message'] ?? '';
                                    final status = reqData['status'] ?? 'pending';
                                    final sellerDocs = reqData['sellerDocuments'] ?? [];

                                    Color badgeColor;
                                    Icon badgeIcon;

                                    switch (status) {
                                      case 'responded':
                                        badgeColor = Colors.green.shade100;
                                        badgeIcon = const Icon(Icons.check_circle, color: Colors.green, size: 20);
                                        break;
                                      case 'denied':
                                        badgeColor = Colors.red.shade100;
                                        badgeIcon = const Icon(Icons.cancel, color: Colors.red, size: 20);
                                        break;
                                      case 'pending':
                                      default:
                                        badgeColor = Colors.orange.shade100;
                                        badgeIcon = const Icon(Icons.hourglass_top, color: Colors.orange, size: 20);
                                        break;
                                    }

                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: badgeColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: badgeColor.withOpacity(0.7)),
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
                                        leading: badgeIcon,
                                        trailing: status == 'pending'
                                            ? ElevatedButton.icon(
                                                icon: const Icon(Icons.upload_file, color: Colors.white),
                                                label: const Text('Respond'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.amber.shade700,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: () => _showReplyDialog(doc.id, reqDoc.id, sellerDocs),
                                              )
                                            : sellerDocs.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                                                    tooltip: 'View uploaded documents',
                                                    onPressed: () => _showUploadedDocs(sellerDocs),
                                                  )
                                                : null,
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.amber),
                                onPressed: () => showEditDialog(doc.id, data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => confirmDelete(doc.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
