import 'package:flutter/material.dart';
import 'package:smartspace/models/listings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  late Future<List<Listing>> _listings;

  @override
  void initState() {
    super.initState();
    _listings = _fetchListings();
  }

  Future<List<Listing>> _fetchListings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Listing.fromFirestore(
              doc.data(),
              doc.id,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Properties')),
      body: FutureBuilder<List<Listing>>(
        future: _listings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No listings found.'));
          }

          final listings = snapshot.data!;
          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 3,
                child: ListTile(
                  leading: listing.imageUrl.isNotEmpty
                      ? Image.network(
                          listing.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(listing.title),
                  subtitle:
                      Text('${listing.location} • UGX ${listing.price}'),
                  onTap: () {
                    // TODO: push a detail page
                    // Navigator.push(context, MaterialPageRoute(
                    //   builder: (_) => ListingDetailScreen(listing: listing)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
