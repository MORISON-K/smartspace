import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Reference to the "lands" collection.
final CollectionReference<Map<String, dynamic>> landRef =
    FirebaseFirestore.instance.collection('listings');

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late Future<List<Map<String, dynamic>>> listingsFuture;

  @override
  void initState() {
    super.initState();
    listingsFuture = _getLandListings();
  }

  /// Fetch approved land listings from Firestore
  Future<List<Map<String, dynamic>>> _getLandListings() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await landRef.where('status', isEqualTo: 'approved').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e, stack) {
      debugPrint('Firestore read failed: $e');
      debugPrintStack(stackTrace: stack);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Land Listings")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: listingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Failed to load data"));
          }

          final listings = snapshot.data!;
          if (listings.isEmpty) {
            return const Center(child: Text("No approved listings found."));
          }

          return ListView.builder(
            itemCount: listings.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final item = listings[index];
              final images = item['images'] as List<dynamic>?;
              final imageUrl = (images != null && images.isNotEmpty) ? images[0] as String : null;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['location'] ?? 'Unknown location',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Category: ${item['category'] ?? '-'}'),
                          Text('Size: ${item['description'] ?? '-'}'),
                          Text('Price: UGX ${item['price'] ?? '0'}'),
                          Text('Contact: ${item['mobile_number'] ?? '-'}'),
                          const SizedBox(height: 10),
                        ],
                      ),
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
