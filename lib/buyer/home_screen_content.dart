import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'listings_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<String> savedListings = [];

  final user = FirebaseAuth.instance.currentUser;

  String _sortOrder = 'none';
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    listingsFuture = _getLandListings();
    _getUserLikedListings();
    _getUserSavedListings();
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

      List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs = docs;

      if (_searchText.isNotEmpty) {
        filteredDocs =
            filteredDocs.where((doc) {
              final data = doc.data();
              final location =
                  (data['location'] ?? '').toString().toLowerCase();
              final category =
                  (data['category'] ?? '').toString().toLowerCase();
              final searchLower = _searchText.toLowerCase();
              return location.contains(searchLower) ||
                  category.contains(searchLower);
            }).toList();
      }

      if (_sortOrder == 'lowest') {
        filteredDocs.sort((a, b) => getPrice(a).compareTo(getPrice(b)));
      } else if (_sortOrder == 'highest') {
        filteredDocs.sort((a, b) => getPrice(b).compareTo(getPrice(a)));
      }

      return filteredDocs;
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

  Future<void> _getUserSavedListings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final storedSaved = prefs.getStringList('savedListings') ?? [];
    setState(() {
      savedListings = storedSaved;
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

  Future<void> _toggleSave(String listingId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final isSaved = savedListings.contains(listingId);

    setState(() {
      if (isSaved) {
        savedListings.remove(listingId);
      } else {
        savedListings.add(listingId);
      }
    });

    await prefs.setStringList('savedListings', savedListings);
  }

  void _onSortChanged(String? value) {
    if (value == null) return;

    setState(() {
      _sortOrder = value;
      listingsFuture = _getLandListings();
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
      listingsFuture = _getLandListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 5,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.landscape, size: 32, color: Colors.black87),
              const SizedBox(width: 12),
              const Text(
                'Land Listings',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      blurRadius: 3,
                      color: Colors.black26,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search listings...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: PopupMenuButton<String>(
                    onSelected: _onSortChanged,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    itemBuilder:
                        (context) => const [
                          PopupMenuItem(value: 'none', child: Text('Default')),
                          PopupMenuItem(
                            value: 'lowest',
                            child: Text('Lowest Price'),
                          ),
                          PopupMenuItem(
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
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                    final isSaved = savedListings.contains(listingId);

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
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                  Text(
                                    'Category: ${item['category'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Size: ${item['acreage'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Price: UGX ${item['price'] ?? '0'}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Contact: ${item['mobile_number'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _toggleSave(listingId),
                                    icon: Icon(
                                      isSaved
                                          ? Icons.check_box
                                          : Icons.add_box_outlined,
                                      color:
                                          isSaved
                                              ? Colors.green
                                              : Colors.blueGrey,
                                    ),
                                    label: Text(isSaved ? 'Saved' : 'Save'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isSaved
                                              ? Colors.green[100]
                                              : Colors.blueGrey[100],
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
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
