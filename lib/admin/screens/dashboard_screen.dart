import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Firestore references
  final CollectionReference listingsCollection =
      FirebaseFirestore.instance.collection('Listings');
      
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Helper to format currency
  String _formatPrice(String price) {
    final value = double.tryParse(price) ?? 0;
    return NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(value);
  }

  // Helper to format time difference
  String _formatTimeDifference(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Helper to format timestamp
  String _formatTime(Timestamp timestamp) {
    return DateFormat('h:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "👋 Welcome back, Admin!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Manage your platform",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text("A"),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: "Search listings, users or requests...",
                  prefixIcon: const Icon(Icons.search, size: 22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Real-time data sections
              Expanded(
                child: Column(
                  children: [
                    // Pending Listings Section
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: listingsCollection
                                .where('status', isEqualTo: 'pending')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const SectionHeader(
                                  title: "📝 Pending Listings", 
                                  count: 0,
                                  child: Center(child: Text("No pending listings")),
                                );
                              }
                              
                              final listings = snapshot.data!.docs;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHeader(
                                    title: "📝 Pending Listings", 
                                    count: listings.length
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: listings.length,
                                      itemBuilder: (context, index) {
                                        final listing = listings[index];
                                        final data = listing.data() as Map<String, dynamic>;
                                        return _PendingItem(
                                          id: listing.id,
                                          title: data['description'] ?? 'No Description',
                                          location: data['location'] ?? 'Unknown Location',
                                          price: data['price'] != null 
                                              ? _formatPrice(data['price']) 
                                              : 'Price not set',
                                          createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Responds to Requests Section
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: usersCollection
                                .where('requests', isGreaterThan: 0)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const SectionHeader(
                                  title: "📩 User Requests", 
                                  count: 0,
                                  child: Center(child: Text("No user requests")),
                                );
                              }
                              
                              final users = snapshot.data!.docs;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHeader(
                                    title: "📩 User Requests", 
                                    count: users.length
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: users.length,
                                      itemBuilder: (context, index) {
                                        final user = users[index];
                                        final data = user.data() as Map<String, dynamic>;
                                        return _RequestItem(
                                          id: user.id,
                                          user: data['name'] ?? 'Unknown User',
                                          message: data['lastRequest'] ?? 'No message',
                                          createdAt: data['lastRequestTime'] as Timestamp? ?? Timestamp.now(),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Custom Widgets ---

class SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Widget? child;
  
  const SectionHeader({
    super.key,
    required this.title,
    required this.count,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _PendingItem extends StatelessWidget {
  final String id;
  final String title;
  final String location;
  final String price;
  final Timestamp createdAt;

  const _PendingItem({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgo = (context.findAncestorStateOfType<_DashboardScreenState>()?._formatTimeDifference(createdAt) ?? '');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              location,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // View listing details
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("View Details"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      // Approve listing
                      await FirebaseFirestore.instance
                          .collection('Listings')
                          .doc(id)
                          .update({'status': 'approved'});
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Approve"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestItem extends StatelessWidget {
  final String id;
  final String user;
  final String message;
  final Timestamp createdAt;

  const _RequestItem({
    required this.id,
    required this.user,
    required this.message,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime = (context.findAncestorStateOfType<_DashboardScreenState>()?._formatTime(createdAt) ?? '');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(
          user,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          message,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Text(
          formattedTime,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
        onTap: () {
          // Handle request
        },
      ),
    );
  }
}