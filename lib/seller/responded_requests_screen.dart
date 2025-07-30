import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RespondedRequestsScreen extends StatelessWidget {
  const RespondedRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Responded Requests"),
        backgroundColor: const Color.fromARGB(255, 148, 203, 241),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('listings')
                .where('user_id', isEqualTo: user?.uid)
                .snapshots(),
        builder: (context, listingsSnapshot) {
          if (!listingsSnapshot.hasData ||
              listingsSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No listings available"));
          }

          final listings = listingsSnapshot.data!.docs;

          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              final listingId = listing.id;

              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('listings')
                        .doc(listingId)
                        .collection('documentRequests')
                        .where('status', isEqualTo: 'responded')
                        .orderBy('responseTimestamp', descending: true)
                        .snapshots(),
                builder: (context, requestSnapshot) {
                  if (!requestSnapshot.hasData ||
                      requestSnapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink(); // Hide empty
                  }

                  final requests = requestSnapshot.data!.docs;

                  return Column(
                    children:
                        requests.map((reqDoc) {
                          final reqData = reqDoc.data() as Map<String, dynamic>;
                          final message = reqData['message'] ?? '';
                          final status =
                              reqData['adminStatus'] ??
                              'pending';  // default to pending
                          final sellerDocs =
                              reqData['sellerDocuments'] as List<dynamic>? ??
                              [];

                          Color statusColor;
                          String statusText;
                          IconData statusIcon;
 


                          switch (status) {
                            case 'approved':
                              statusColor = Colors.green;
                              statusText = 'Approved';
                              statusIcon = Icons.check_circle;
                              break;
                            case 'rejected':
                              statusColor = Colors.red;
                              statusText = 'Rejected';
                              statusIcon = Icons.cancel;
                              break;
                            default:
                              statusColor = Colors.orange;
                              statusText = 'Pending';
                              statusIcon = Icons.hourglass_empty;
                              break;
                          }
 

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ), 

                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(statusIcon, color: statusColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Status: $statusText",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (sellerDocs.isNotEmpty) ...[
                                    const Text(
                                      'Uploaded Documents:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children:
                                            sellerDocs.map<Widget>((url) {
                                              final fileName =
                                                  url
                                                      .toString()
                                                      .split('/')
                                                      .last;
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.picture_as_pdf,
                                                      color:
                                                          Colors.red.shade600,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        fileName.length > 30
                                                            ? '${fileName.substring(0, 30)}...'
                                                            : fileName,
                                                        style: const TextStyle(
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    
                                                    Icon(
                                                      Icons.check_circle,
                                                      color:
                                                          Colors.green.shade600,
                                                      size: 16,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
