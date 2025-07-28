import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'buyer_home_screen.dart';
import 'favorite_screen.dart';
import 'package:smartspace/buyer/listings_detail_screen.dart';
import 'profile_settings_screen.dart';

class BuyerDashboardScreen extends StatefulWidget {
  final String userId;

  const BuyerDashboardScreen({super.key, required this.userId});

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  String? email;
  String? userName;
  List<String> savedPropertyIds = [];
  List<String> recentViewedIds = [];

  final Color goldenBackground = const Color(
    0xFFFFE066,
  ); // lighter gold background
  final Color textColor = Colors.black; // black text/icons

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _loadSavedListings();
    _loadRecentlyViewed();
  }

  Future<void> _fetchUserInfo() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
    setState(() {
      email = userDoc.data()?['email'];
      userName =
          userDoc.data()?['name'] ?? userDoc.data()?['fullName'] ?? 'User';
    });
  }

  Future<void> _loadSavedListings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedPropertyIds = prefs.getStringList('chosenListings') ?? [];
    });
  }

  Future<void> _loadRecentlyViewed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      recentViewedIds = prefs.getStringList('recentlyViewed') ?? [];
    });
  }

  Future<List<DocumentSnapshot>> _fetchListings(List<String> ids) async {
    final List<DocumentSnapshot> docs = [];
    for (String id in ids) {
      final doc =
          await FirebaseFirestore.instance.collection('listings').doc(id).get();
      if (doc.exists) docs.add(doc);
    }
    return docs;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: goldenBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/user_placeholder.png'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileSettingsScreen(),
                      ),
                    );
                  },
                  child: Text(
                    userName ?? 'User',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  email ?? '',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListingsSection(String title, List<DocumentSnapshot> listings) {
    if (listings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text("No $title available.", style: TextStyle(color: textColor)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        ...listings.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.2),
            child: ListTile(
              leading:
                  data['images'] != null && data['images'].isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['images'][0],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                      : Icon(Icons.image, size: 60, color: textColor),
              title: Text(
                data['title'] ?? 'Untitled',
                style: TextStyle(color: textColor),
              ),
              subtitle: Text(
                data['location'] ?? 'No location',
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: textColor),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ListingDetailScreen(
                          listing: data,
                          listingId: doc.id,
                        ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BuyerHomeScreen()),
                  );
                },
                icon: Icon(Icons.explore, color: textColor),
                label: Text(
                  "Explore More",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldenBackground,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  shadowColor: Colors.black.withOpacity(0.2),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoriteScreen()),
                  );
                },
                icon: Icon(Icons.favorite, color: textColor),
                label: Text(
                  "Liked Listings",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldenBackground,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  shadowColor: Colors.black.withOpacity(0.2),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder(
        future: Future.wait([
          _fetchListings(savedPropertyIds),
          _fetchListings(recentViewedIds),
        ]),
        builder: (context, AsyncSnapshot<List<List<DocumentSnapshot>>> snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final saved = snap.data![0];
          final recent = snap.data![1];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(),
                _buildListingsSection("Saved Listings", saved),
                _buildListingsSection("Recently Viewed", recent),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }
}
