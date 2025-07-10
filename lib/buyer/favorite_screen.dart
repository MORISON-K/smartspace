import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final user = FirebaseAuth.instance.currentUser;
  List<DocumentSnapshot<Map<String, dynamic>>> favoriteListings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFavoriteListings();
  }

  Future<void> fetchFavoriteListings() async {
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final likedListingIds =
          List<String>.from(userDoc.data()?['likedListings'] ?? []);

      if (likedListingIds.isEmpty) {
        setState(() {
          favoriteListings = [];
          isLoading = false;
        });
        return;
      }

      final List<DocumentSnapshot<Map<String, dynamic>>> listings = [];

      for (String id in likedListingIds) {
        final doc = await FirebaseFirestore.instance
            .collection('listings')
            .doc(id)
            .get();
        if (doc.exists) {
          listings.add(doc);
        }
      }

      setState(() {
        favoriteListings = listings;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorites")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteListings.isEmpty
              ? const Center(child: Text("No favorites yet."))
              : ListView.builder(
                  itemCount: favoriteListings.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final doc = favoriteListings[index];
                    final item = doc.data()!;
                    final images = item['images'] as List<dynamic>?;
                    final imageUrl = (images != null && images.isNotEmpty)
                        ? images[0] as String
                        : null;

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
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text('Category: ${item['category'] ?? '-'}'),
                                Text('Size: ${item['description'] ?? '-'}'),
                                Text('Price: UGX ${item['price'] ?? '0'}'),
                                Text('Contact: ${item['mobile_number'] ?? '-'}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
