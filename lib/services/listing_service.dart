import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartspace/models/listings.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Listing>> fetchListings() async {
    final snapshot = await _firestore
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

  Future<void> addListing(Listing listing) async {
    await _firestore.collection('listings').add(listing.toMap());
  }
}
