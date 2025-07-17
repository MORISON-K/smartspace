import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'listings_detail_screen.dart';

final CollectionReference<Map<String, dynamic>> landRef = FirebaseFirestore
    .instance
    .collection('listings');

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> listingsFuture;
  List<String> likedListings = [];

  final user = FirebaseAuth.instance.currentUser;

  String _sortOrder = 'none';

  @override
  void initState() {
    super.initState();
    listingsFuture = _getLandListings();
    _getUserLikedListings();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _getLandListings() async {
    try {
      final snapshot =
          await landRef.where('status', isEqualTo: 'approved').get();
      final docs = snapshot.docs;

      int getPrice(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        final price = doc.data()['price'];
        return int.tryParse(price.toString().replaceAll(',', '')) ?? 0;
      }

      if (_sortOrder == 'lowest') {
        docs.sort((a, b) => getPrice(a).compareTo(getPrice(b)));
      } else if (_sortOrder == 'highest') {
        docs.sort((a, b) => getPrice(b).compareTo(getPrice(a)));
      }

      return docs;
    } catch (e) {
      debugPrint('Error fetching listings: $e');
      return [];
    }
  }

  Future<void> _getUserLikedListings() async {
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
    final data = userDoc.data();
    setState(() {
      likedListings = List<String>.from(data?['likedListings'] ?? []);
    });
  }

  Future<void> _toggleLike(String listingId) async {
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid);
    final isLiked = likedListings.contains(listingId);

    if (isLiked) {
      await userDoc.update({
        'likedListings': FieldValue.arrayRemove([listingId]),
      });
    } else {
      await userDoc.set({
        'likedListings': FieldValue.arrayUnion([listingId]),
      }, SetOptions(merge: true));
    }

    setState(() {
      isLiked ? likedListings.remove(listingId) : likedListings.add(listingId);
    });
  }

  void _onSortChanged(String? value) {
    if (value == null) return;

    setState(() {
      _sortOrder = value;
      listingsFuture = _getLandListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // light background for contrast
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 3,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          title: const Text(
            "Land Listings",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Column(
        children: [
          // Filter button below the AppBar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            alignment: Alignment.centerRight,
            child: PopupMenuButton<String>(
              onSelected: _onSortChanged,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(value: 'none', child: Text('Default')),
                    const PopupMenuItem(
                      value: 'lowest',
                      child: Text('Lowest Price'),
                    ),
                    const PopupMenuItem(
                      value: 'highest',
                      child: Text('Highest Price'),
                    ),
                  ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.tune, color: Colors.black),
                  SizedBox(width: 6),
                  Text(
                    "Filter",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Listings list
          Expanded(
            child: FutureBuilder<
              List<QueryDocumentSnapshot<Map<String, dynamic>>>
            >(
              future: listingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No approved listings found."),
                  );
                }

                final listings = snapshot.data!;

                return ListView.builder(
                  itemCount: listings.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemBuilder: (context, index) {
                    final doc = listings[index];
                    final item = doc.data();
                    final listingId = doc.id;
                    final images = item['images'] as List<dynamic>?;
                    final imageUrl =
                        (images != null && images.isNotEmpty)
                            ? images[0] as String
                            : null;
                    final isLiked = likedListings.contains(listingId);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ListingDetailScreen(
                                  listing: item,
                                  listingId: listingId,
                                ),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.white,
                        elevation: 6,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        clipBehavior:
                            Clip.antiAlias, // round image corners properly
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image with rounded corners
                            if (imageUrl != null)
                              SizedBox(
                                height: 200,
                                width: double.infinity,
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (_, child, progress) =>
                                          progress == null
                                              ? child
                                              : const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                  errorBuilder:
                                      (_, __, ___) => const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 50,
                                        ),
                                      ),
                                ),
                              )
                            else
                              Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title + Like button row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item['location'] ??
                                              'Unknown location',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        iconSize: 28,
                                        splashRadius: 24,
                                        icon: Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color:
                                              isLiked
                                                  ? Colors.redAccent
                                                  : Colors.grey,
                                        ),
                                        onPressed: () => _toggleLike(listingId),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Details
                                  Text(
                                    'Category: ${item['category'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  Text(
                                    'Size: ${item['description'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Price - standout style
                                  Text(
                                    'Price: UGX ${item['price'] ?? '0'}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Contact info subtle
                                  Text(
                                    'Contact: ${item['mobile_number'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
