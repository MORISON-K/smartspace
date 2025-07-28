import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class DocumentRequestsScreen extends StatefulWidget {
  final String propertyId;
  final String userId;
  final String userName;

  const DocumentRequestsScreen({
    super.key,
    required this.propertyId,
    required this.userId,
    required this.userName,
  });

  @override
  State<DocumentRequestsScreen> createState() => _DocumentRequestsScreenState();
}

class _DocumentRequestsScreenState extends State<DocumentRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isUploading = false;

  Future<void> _uploadDocument(String requestId, String documentType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      allowMultiple: true,
    );

    if (result == null) {
      // User canceled the picker
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      List<String> uploadedUrls = [];

      for (final file in result.files) {
        final fileName = file.name;
        final fileBytes = file.bytes;
        if (fileBytes == null) continue;

        final storageRef = _storage.ref().child(
            'listings/${widget.propertyId}/documentRequests/$requestId/uploads/$fileName');

        final uploadTask = storageRef.putData(fileBytes);

        final snapshot = await uploadTask.whenComplete(() {});

        final downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      }

      // Update user document with uploaded document info for admin dashboard
      final userDocRef = _firestore.collection('users').doc(widget.userId);

      await userDocRef.set({
        'hasNewDocuments': true,
        'newDocumentUrls': FieldValue.arrayUnion(uploadedUrls),
        'documentUploadTime': FieldValue.serverTimestamp(),
        'lastDocumentMessage': 'Uploaded additional documents',
        'pendingDocumentType': documentType,
      }, SetOptions(merge: true));

      // Update the document request status to 'uploaded'
      final docRequestRef = _firestore
          .collection('listings')
          .doc(widget.propertyId)
          .collection('documentRequests')
          .doc(requestId);

      await docRequestRef.update({
        'status': 'uploaded',
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documents uploaded successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload documents: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat.yMMMd().add_jm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final docRequestsQuery = _firestore
        .collection('listings')
        .doc(widget.propertyId)
        .collection('documentRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: docRequestsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text('No pending document requests'),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;
              final message = data['message'] ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              final status = data['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(message),
                  subtitle: Text('Requested on: ${_formatTimestamp(timestamp)}'),
                  trailing: _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : ElevatedButton(
                          onPressed: status == 'pending'
                              ? () => _uploadDocument(doc.id, message)
                              : null,
                          child: const Text('Upload Document'),
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
