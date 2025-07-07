import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartspace/notifications/notifications_service.dart';

class AuthService {
  // Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Firebase API instance for notifications
  final FirebaseApi _firebaseApi = FirebaseApi();

  // Function to handle user signup
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Create user in Firebase Authentication with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // Save additional user data (name, role) in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': role, // Role determines if user is Admin or User
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Initialize notifications for new user (includes FCM token storage)
      await _firebaseApi.initNofications();

      return null; // Success: no error message
    } catch (e) {
      return e.toString(); // Error: return the exception message
    }
  }

  // Function to handle user login
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in the user using Firebase Authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Fetch the user's role from Firestore to determine access level
      DocumentSnapshot userDoc =
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

      // Update FCM token and subscribe to notifications on login
      await _firebaseApi.updateFCMToken(); // Update token (might have changed)
      await _firebaseApi.subscribeToRoleTopic(); // Ensure topic subscription

      return userDoc['role']; // Return the user's role (Admin/User)
    } catch (e) {
      return e.toString(); // Error: return the exception message
    }
  }

  // for user log out
  signOut() async {
    // Unsubscribe from role-based topics before logout
    await _firebaseApi.unsubscribeFromRoleTopic();
    await _auth.signOut();
  }
}
