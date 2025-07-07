import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String _debugInfo = "Loading...";

  @override
  void initState() {
    super.initState();
    _checkNotificationSetup();
  }

  Future<void> _checkNotificationSetup() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _debugInfo = "❌ No user logged in";
        });
        return;
      }

      // Get FCM token
      final token = await FirebaseMessaging.instance.getToken();

      // Get user data from Firestore
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final userData = userDoc.data();

      setState(() {
        _debugInfo = """
✅ User logged in: ${user.email}
✅ User ID: ${user.uid}
✅ FCM Token: ${token != null ? 'Generated' : '❌ Not found'}
✅ Role: ${userData?['role'] ?? '❌ Not found'}
${userData?['fcmToken'] != null ? '✅' : '❌'} FCM Token stored in Firestore: ${userData?['fcmToken'] != null}
📅 Token last updated: ${userData?['tokenUpdatedAt']?.toDate() ?? 'Unknown'}

🔑 Current FCM Token: $token
💾 Stored FCM Token: ${userData?['fcmToken']}
🔄 Tokens match: ${token == userData?['fcmToken'] ? '✅ Yes' : '❌ No - Token should be updated'}

Debug Steps:
1. ✅ Check if FCM token is stored
2. ✅ Check if user role is correct  
3. ❓ Check Firebase Console Cloud Messaging settings
4. ✅ Check if Cloud Functions are deployed
5. ❓ Test by creating a listing
6. ✅ Check token freshness

Best Practice: FCM Token should be updated on:
- Signup ✅
- Login ✅  
- Token refresh (automatic) ✅
- App start with existing user ✅
        """;
      });
    } catch (e) {
      setState(() {
        _debugInfo = "❌ Error: $e";
      });
    }
  }

  Future<void> _createTestListing() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Create a test listing to trigger notification
      await FirebaseFirestore.instance.collection('listings').add({
        'title': 'Test Listing - ${DateTime.now().millisecondsSinceEpoch}',
        'description': 'Test listing to trigger notification',
        'price': 100000,
        'user_id': user.uid,
        'sellerName': 'Test Seller',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test listing created! Check admin notifications.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Setup Debug',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkNotificationSetup,
                    child: const Text('Refresh Debug Info'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createTestListing,
                    child: const Text('Create Test Listing'),
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
