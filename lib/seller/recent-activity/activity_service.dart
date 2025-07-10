import 'recent_activity_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new activity
  Future<void> createActivity({
    required String title,
    required String description,
    required String type,
    String? propertyId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final activity = Activity(
      id: '',
      title: title,
      description: description,
      timestamp: DateTime.now(),
      type: type,
      sellerId: user.uid,
      propertyId: propertyId,
    );

    await _firestore.collection('activities').add(activity.toFirestore());
  }

  // Get activities for current seller
  Stream<List<Activity>> getSellerActivities({int limit = 10}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // PERMANENT SOLUTION: Indexed query
    // REQUIRES: Firestore composite index on (sellerId, timestamp)
    // See: firestore_indexes_required.md for setup instructions
    return _firestore
        .collection('activities')
        .where('sellerId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList(),
        );
  }

  // Helper methods to create specific activity types
  Future<void> createListingActivity(
    String propertyTitle,
    String propertyId,
  ) async {
    await createActivity(
      title: 'New listing created',
      description: 'You successfully listed "$propertyTitle"',
      type: 'listing_created',
      propertyId: propertyId,
    );
  }

  Future<void> createInquiryActivity(
    String propertyTitle,
    String propertyId,
  ) async {
    await createActivity(
      title: 'New inquiry received',
      description: 'Someone is interested in "$propertyTitle"',
      type: 'inquiry_received',
      propertyId: propertyId,
    );
  }

  Future<void> createViewActivity(
    String propertyTitle,
    String propertyId,
    int viewCount,
  ) async {
    await createActivity(
      title: 'Property viewed',
      description: '"$propertyTitle" has been viewed $viewCount times today',
      type: 'view_count',
      propertyId: propertyId,
    );
  }

  Future<void> createPriceUpdateActivity(
    String propertyTitle,
    String propertyId,
  ) async {
    await createActivity(
      title: 'Price updated',
      description: 'Price for "$propertyTitle" has been updated',
      type: 'price_update',
      propertyId: propertyId,
    );
  }

  Future<void> createListingApprovalActivity(
    String propertyTitle,
    String propertyId,
  ) async {
    await createActivity(
      title: 'Listing approved',
      description:
          'Your listing "$propertyTitle" has been approved and is now live',
      type: 'listing_approved',
      propertyId: propertyId,
    );
  }

  Future<void> createListingRejectionActivity(
    String propertyTitle,
    String propertyId,
    String reason,
  ) async {
    await createActivity(
      title: 'Listing rejected',
      description:
          'Your listing "$propertyTitle" was rejected. Reason: $reason',
      type: 'listing_rejected',
      propertyId: propertyId,
    );
  }
}
