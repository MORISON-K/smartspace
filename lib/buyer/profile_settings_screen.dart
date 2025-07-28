import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  String? profileImageUrl;
  String? userName;
  String? email;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        profileImageUrl = data['profileImageUrl'];
        userName = data['name'];
        email = data['email'];
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedImage != null) {
      setState(() => isLoading = true);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      await storageRef.putFile(File(pickedImage.path));
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profileImageUrl': imageUrl,
      });

      setState(() {
        profileImageUrl = imageUrl;
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color golden = const Color(0xFFFFE066);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Settings"),
        backgroundColor: golden,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : null,
                  child:
                      profileImageUrl == null
                          ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.black),
                    onPressed: _pickAndUploadImage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (userName != null)
              Text(
                userName!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (email != null)
              Text(email!, style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
