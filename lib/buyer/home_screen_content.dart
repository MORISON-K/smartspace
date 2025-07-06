import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Reference to the “users” collection.
/// Always use `FirebaseFirestore` (new API), not the old `Firestore`.
final CollectionReference<Map<String, dynamic>> usersRef =
    FirebaseFirestore.instance.collection('users');

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  @override
  void initState() {
    super.initState();
    _getUsers();
  }

  /// Reads the whole `users` collection once and prints every document.
  Future<void> _getUsers() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await usersRef.get();
      for (final doc in snapshot.docs) {
        debugPrint('data → ${doc.data()}');
        debugPrint('id   → ${doc.id}');
        debugPrint('exists → ${doc.exists}');
      }
    } catch (e, stack) {
      debugPrint(' Firestore read failed: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'This is the home screen content',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
