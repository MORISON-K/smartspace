import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartspace/main.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  FirebaseApi() {
    // Listen to auth state changes to update FCM token
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User is signed in, update FCM token
        updateFCMToken();
      }
    });
  }

  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    print('Attempting to save notification. User: ${user?.uid}'); // Debug log

    if (user == null) {
      print('No user logged in - cannot save notification'); // Debug log
      return;
    }

    try {
      print(
        'Saving notification to Firestore for user: ${user.uid}',
      ); // Debug log
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
            'title': message.notification?.title,
            'body': message.notification?.body,
            'data': message.data,
            'receivedAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
      print("Notification saved to firestore successfully"); // Updated log
    } catch (e) {
      print("Error saving notification: $e"); // Updated log
    }
  }

  Future<void> initNofications() async {
    await _firebaseMessaging.requestPermission();
    await updateFCMToken(); // Always update token
    await subscribeToRoleTopic(); // Subscribe to role topics
    initPushNotifications();

    // Listen for token refresh and update it
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      _updateTokenInFirestore(newToken);
    });
  }

  /// Update FCM token in Firestore
  Future<void> updateFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final fCMToken = await _firebaseMessaging.getToken();
      print('Current FCM Token: $fCMToken');

      if (fCMToken != null) {
        await _updateTokenInFirestore(fCMToken);
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  /// Helper method to update token in Firestore
  Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': token, 'tokenUpdatedAt': FieldValue.serverTimestamp()},
      );
      print('FCM Token updated in Firestore for user: ${user.uid}');
    } catch (e) {
      print('Error updating FCM token in Firestore: $e');
    }
  }

  /// Subscribe user to appropriate topic based on their role
  Future<void> subscribeToRoleTopic() async {
    final role = await getUserRole();
    if (role != null) {
      String topic = _mapRoleToTopic(role);
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    }
  }

  /// Unsubscribe from role-based topic (useful when user changes role or logs out)
  Future<void> unsubscribeFromRoleTopic() async {
    final role = await getUserRole();
    if (role != null) {
      String topic = _mapRoleToTopic(role);
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    }
  }

  /// Map user role to corresponding topic name
  String _mapRoleToTopic(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'admin';
      case 'seller':
        return 'seller';
      case 'user':
      case 'buyer':
        return 'buyer';
      default:
        return 'general'; // fallback topic
    }
  }

  Future<String?> getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return snapshot.data()?['role'];
  }

  void handleMessage(RemoteMessage? message) async {
    if (message == null) return;

    await _saveNotificationToFirestore(message);

    final role = await getUserRole();

    // Pass different arguments or route based on role
    switch (role) {
      case 'admin':
        navigatorKey.currentState?.pushNamed(
          '/notifications_screen',
          arguments: {'message': message, 'role': 'admin'},
        );
        break;
      case 'seller':
        navigatorKey.currentState?.pushNamed(
          '/notifications_screen',
          arguments: {'message': message, 'role': 'seller'},
        );
        break;
      case 'buyer':
        navigatorKey.currentState?.pushNamed(
          '/notifications_screen',
          arguments: {'message': message, 'role': 'buyer'},
        );
        break;
      default:
        navigatorKey.currentState?.pushNamed(
          '/notifications_screen',
          arguments: {'message': message},
        );
    }
  }

  //function to initialize foreground and background settings
  Future initPushNotifications() async {
    //handle notifications if the app was terminated
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    //attach event listeners for when a notification opens
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    //handle foreground notifications (when app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      // Save notification to Firestore
      await _saveNotificationToFirestore(message);

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // You can show a local notification here or update UI
        // For now, let's just show a snackbar if possible
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text(message.notification?.body ?? 'New notification'),
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'View',
                onPressed: () async {
                  final role = await getUserRole();
                  navigatorKey.currentState?.pushNamed(
                    '/notifications_screen',
                    arguments: {'message': message, 'role': role},
                  );
                },
              ),
            ),
          );
        }
      }
    });
  }
}
