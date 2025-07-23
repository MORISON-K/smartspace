import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RespondedRequestsScreen extends StatelessWidget {
  const RespondedRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Responded Requests"),
        backgroundColor: Colors.green.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('user_id', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, listingSnapshot) {
          if (!listingSnapshot.hasData || listingSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No listings found."));
          }

          final listings = listingSnapshot.data!.docs;

          return ListView(
            children: listings.map((listing) {
              final listingId = listing.id;
              final title = listing['title'] ?? 'No Title';

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('listings')
                    .doc(listingId)
                    .collection('documentRequests')
                    .where('status', isEqualTo: 'responded')
                    .orderBy('responseTimestamp', descending: true)
                    .snapshots(),
                builder: (context, requestSnapshot) {
                  if (!requestSnapshot.hasData || requestSnapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink(); // Skip if no responded requests
                  }

                  final requests = requestSnapshot.data!.docs;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Listing: $title",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...requests.map((req) {
                            final data = req.data() as Map<String, dynamic>;
                            final message = data['message'] ?? '';
                            final sellerDocs = data['sellerDocuments'] ?? [];
                            final responseTimestamp = data['responseTimestamp'] != null
                                ? (data['responseTimestamp'] as Timestamp).toDate()
                                : null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "📩 Admin Request: $message",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  if (responseTimestamp != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        "🕒 Responded on: ${responseTimestamp.toLocal()}",
                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  if (sellerDocs.isNotEmpty) ...[
                                    const Text(
                                      "📎 Uploaded Documents:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...sellerDocs.map<Widget>((url) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Text(
                                            url,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.blue,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        )),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
