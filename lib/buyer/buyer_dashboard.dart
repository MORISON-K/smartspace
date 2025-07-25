import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartspace/buyer/listings_detail_screen.dart';

class BuyerDashboardScreen extends StatefulWidget {
  final String userId;

  const BuyerDashboardScreen({super.key, required this.userId});

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  late Future<String?> _emailFuture;
  List<String> cartPropertyIds = [];
  List<String> likedPropertyIds = [];

  @override
  void initState() {
    super.initState();
    _emailFuture = fetchEmail();
    _loadCartFromPrefs();
    _fetchLikedProperties();
  }

  Future<String?> fetchEmail() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    return userDoc.data()?['email'];
  }

  Future<void> _loadCartFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cartPropertyIds = prefs.getStringList('chosenListings') ?? [];
    });
  }

  Future<void> _fetchLikedProperties() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    final likedList = userDoc.data()?['likedListings'] ?? [];
    setState(() {
      likedPropertyIds = List<String>.from(likedList);
    });
  }

  Future<List<DocumentSnapshot>> _fetchChosenListings() async {
    final List<DocumentSnapshot> docs = [];
    for (String id in cartPropertyIds) {
      final doc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(id)
          .get();
      if (doc.exists) {
        docs.add(doc);
      }
    }
    return docs;
  }

  Future<void> _addToCart(String listingId) async {
    if (!cartPropertyIds.contains(listingId)) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        cartPropertyIds.add(listingId);
      });
      await prefs.setStringList('chosenListings', cartPropertyIds);
    }
  }

  Widget buildCartSection() {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _fetchChosenListings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        final chosenDocs = snapshot.data!;
        if (chosenDocs.isEmpty) {
          return const Text("No chosen listings in cart.");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Chosen Listings (Cart)",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ...chosenDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? 'No title'),
                subtitle: Text(data['description'] ?? 'No description'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ListingDetailScreen(
                        listing: data,
                        listingId: doc.id,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget buildLikedListingsSection(String title, List<String> likedIds) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait(
        likedIds.map((id) => FirebaseFirestore.instance
            .collection('listings')
            .doc(id)
            .get()),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!
            .where((doc) => doc.exists)
            .toList();

        if (docs.isEmpty) {
          return const Text("No liked listings to show.");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? 'No title'),
                subtitle: Text(data['description'] ?? 'No description'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_shopping_cart),
                  onPressed: () => _addToCart(doc.id),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ListingDetailScreen(
                        listing: data,
                        listingId: doc.id,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLiked = likedPropertyIds
        .where((id) => !cartPropertyIds.contains(id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Buyer Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            FutureBuilder<String?>(
              future: _emailFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return Text("Email: ${snapshot.data}",
                    style: const TextStyle(fontSize: 18));
              },
            ),
            const SizedBox(height: 16),
            buildCartSection(),
            const SizedBox(height: 16),
            buildLikedListingsSection(
              'Liked Listings (Not in Cart)',
              filteredLiked,
            ),
          ],
        ),
      ),
    );
  }
}


