import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartspace/buyer/listings_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class BuyerDashboardScreen extends StatefulWidget {
  final String userId;
  const BuyerDashboardScreen({super.key, required this.userId});

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  late final String uid;
  String? email;
  String? profilePicPath; // local file path for profile pic
  List<String> likedPropertyIds = [];
  List<String> cartPropertyIds = []; // local cart persisted
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    email = FirebaseAuth.instance.currentUser!.email;

    _loadLocalData().then((_) => fetchUserData());
  }

  // Load cart and profile pic path from SharedPreferences
  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cartPropertyIds = prefs.getStringList('cartPropertyIds') ?? [];
      profilePicPath = prefs.getString('profilePicPath');
    });
  }

  // Save cart list to SharedPreferences
  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cartPropertyIds', cartPropertyIds);
  }

  // Save profile pic path to SharedPreferences
  Future<void> _saveProfilePicPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profilePicPath', path);
  }

  Future<void> fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final liked = List<String>.from(data['likedListings'] ?? []);
        final notifs = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
        final filteredCart = cartPropertyIds.where((id) => liked.contains(id)).toList();

        setState(() {
          likedPropertyIds = liked;
          notifications = notifs;
          cartPropertyIds = filteredCart;
          isLoading = false;
        });

        await _saveCartToPrefs();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() => isLoading = false);
    }
  }

  void toggleCartItem(String listingId) {
    setState(() {
      if (cartPropertyIds.contains(listingId)) {
        cartPropertyIds.remove(listingId);
      } else if (likedPropertyIds.contains(listingId)) {
        cartPropertyIds.add(listingId);
      }
    });
    _saveCartToPrefs();
  }

  Future<void> navigateToDetail(String listingId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId)
          .get();

      if (doc.exists) {
        final listingData = doc.data()!;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailScreen(
              listingId: listingId,
              listing: listingData,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing not found")),
        );
      }
    } catch (e) {
      print("Error loading listing: $e");
    }
  }

  // Pick image from gallery or camera
  Future<void> _pickProfileImage(ImageSource source) async {
    final pickedImage = await _picker.pickImage(source: source);
    if (pickedImage == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = pickedImage.name;
    final savedImage = await File(pickedImage.path).copy('${appDir.path}/$fileName');

    setState(() {
      profilePicPath = savedImage.path;  // use profilePicPath here
    });

    await _saveProfilePicPath(savedImage.path);
  }

  // Show dialog to select image source
  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickProfileImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickProfileImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfileSection() {
    ImageProvider? imageProvider;

    if (profilePicPath != null) {
      imageProvider = FileImage(File(profilePicPath!));
    } else {
      imageProvider = const AssetImage('assets/default_profile.png');
    }

    return Row(
      children: [
        GestureDetector(
          onTap: _showImageSourceActionSheet,
          child: CircleAvatar(
            radius: 40,
            backgroundImage: imageProvider,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            email ?? 'No email found',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _showImageSourceActionSheet,
          tooltip: 'Change Profile Picture',
        ),
      ],
    );
  }

  Widget buildLikedListingsSection(String title, List<String> listingIds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        listingIds.isEmpty
            ? const Text('No liked listings yet.')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listingIds.length,
                itemBuilder: (context, index) {
                  final id = listingIds[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('listings')
                        .doc(id)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox();
                      }
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      if (data['status'] != 'approved') return const SizedBox();

                      return GestureDetector(
                        onTap: () => navigateToDetail(id),
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              if (data['imageUrl'] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    data['imageUrl'],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['title'] ?? 'No title',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(data['location'] ?? ''),
                                    Text("UGX ${data['price'] ?? 'N/A'}",
                                        style:
                                            const TextStyle(color: Colors.green)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  cartPropertyIds.contains(id)
                                      ? Icons.shopping_cart
                                      : Icons.add_shopping_cart_outlined,
                                  color: cartPropertyIds.contains(id)
                                      ? Colors.green
                                      : null,
                                ),
                                onPressed: () => toggleCartItem(id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ],
    );
  }

  Widget buildCartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('Cart',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        cartPropertyIds.isEmpty
            ? const Text('Your cart is empty.')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cartPropertyIds.length,
                itemBuilder: (context, index) {
                  final id = cartPropertyIds[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('listings')
                        .doc(id)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox();
                      }
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      if (data['status'] != 'approved') return const SizedBox();

                      return GestureDetector(
                        onTap: () => navigateToDetail(id),
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              if (data['imageUrl'] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    data['imageUrl'],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['title'] ?? 'No title',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(data['location'] ?? ''),
                                    Text("UGX ${data['price'] ?? 'N/A'}",
                                        style:
                                            const TextStyle(color: Colors.green)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_shopping_cart),
                                color: Colors.red,
                                onPressed: () => toggleCartItem(id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ],
    );
  }

  Widget buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        notifications.isEmpty
            ? const Text('No notifications yet.')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final listingId = notification['listingId'];
                  final message = notification['message'] ?? 'Update on property';

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('listings')
                        .doc(listingId)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox();
                      }
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      if (data['status'] != 'approved') return const SizedBox();

                      return GestureDetector(
                        onTap: () => navigateToDetail(listingId),
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: data['imageUrl'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      data['imageUrl'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.notifications),
                            title: Text(data['title'] ?? 'Listing'),
                            subtitle: Text(message),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Dashboard'),
        backgroundColor: Colors.green.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchUserData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildProfileSection(),
                    buildLikedListingsSection('Liked Listings', likedPropertyIds),
                    buildCartSection(),
                    buildNotificationsSection(),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Log out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
