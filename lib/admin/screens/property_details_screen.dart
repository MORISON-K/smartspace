import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smartspace/admin/models/properties.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final Property property;

  const PropertyDetailsScreen({super.key, required this.property});

  void _openPdf(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch PDF';
    }
  }

  void _updateStatus(BuildContext context, String status) async {
    print('Trying to update doc ID: ${property.id}');

    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(property.id) // Assuming title is used as document ID
          .update({'status': status});

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Property $status successfully.')),
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context, true); // Return to refresh listings
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  void _confirmAction(BuildContext context, String status) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${status == 'approved' ? 'Approve' : 'Reject'} Property'),
        content: Text('Are you sure you want to ${status == 'approved' ? 'approve' : 'reject'} this property?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _updateStatus(context, status); // Call Firestore update
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(property.category)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Location: ${property.location}'),
            Text('Price: ${property.price}'),
            Text('Description: ${property.description}'),
            const SizedBox(height: 16),
            const Text('Images:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: property.images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.network(
                      property.images[index],
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text('Attached PDF:', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('View PDF Document'),
              onTap: () => _openPdf(property.pdfUrl),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  onPressed: () => _confirmAction(context, 'approved'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _confirmAction(context, 'rejected'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
