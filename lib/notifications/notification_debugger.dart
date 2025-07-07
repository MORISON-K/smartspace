import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Utility class for testing and debugging notifications
class NotificationDebugger {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  /// Check current user's FCM token and role
  static Future<Map<String, dynamic>> getCurrentUserNotificationInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'error': 'No user logged in'};
    }

    try {
      // Get FCM token
      final token = await _firebaseMessaging.getToken();

      // Get user role from Firestore
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final userData = userDoc.data();

      return {
        'uid': user.uid,
        'email': user.email,
        'fcmToken': token,
        'role': userData?['role'],
        'name': userData?['name'],
        'tokenStoredInFirestore': userData?['fcmToken'] != null,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Manually create a test listing to trigger notifications
  static Future<void> createTestListing() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in - cannot create test listing');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('listings').add({
        'title': 'Test Property for Notifications',
        'description': 'This is a test property to verify notifications work',
        'location': 'Test Location, Kampala',
        'price': '500000',
        'category': 'Freehold',
        'user_id': user.uid,
        'status': 'pending',
        'sellerName': 'Test Seller',
        'createdAt': Timestamp.now(),
      });
      print('Test listing created successfully');
    } catch (e) {
      print('Error creating test listing: $e');
    }
  }

  /// Test topic subscription status
  static Future<void> testTopicSubscription(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Successfully subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Print comprehensive debug info
  static Future<void> printDebugInfo() async {
    print('\n=== NOTIFICATION DEBUG INFO ===');
    final info = await getCurrentUserNotificationInfo();
    info.forEach((key, value) {
      print('$key: $value');
    });
    print('===============================\n');
  }
}
