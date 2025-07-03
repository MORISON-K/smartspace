import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartspace/auth/auth_service.dart';
import 'package:smartspace/auth/login_screen.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  final AuthService _authService = AuthService();

  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    String? name;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      name = doc.data()?['name'] ?? user.displayName;
    }
    setState(() {
      _userName = name ?? "Seller Name";
      _userEmail = user?.email ?? "seller@example.com";
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "?";
final parts = name.trim().split(" ");
if (parts.length == 1) return parts[0][0].toUpperCase();
return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      body: Center(child: Text("seller home screen")),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_userName ?? "Seller Name"),
              accountEmail: Text(_userEmail ?? "seller@example.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: const Color.fromARGB(255, 247, 240, 240),
                child: Text(
                  _getInitials(_userName),
                  style: TextStyle(fontSize: 24, color: Colors.black),
                ),
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 167, 184, 198),
              ),
            ),

            ListTile(leading: Icon(Icons.dashboard), title: Text("Dashboard")),

            ListTile(
              leading: Icon(Icons.apartment),
              title: Text("My Listings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/mylistings_screen');
              },
            ),

            ListTile(
              leading: Icon(Icons.show_chart),
              title: Text("AI Valuation"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/ai_valuation');
              },
            ),

            ListTile(
              leading: Icon(Icons.analytics),
              title: Text("View Analytics"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/analytics_screen');
              },
            ),

            ListTile(
              leading: Icon(Icons.addchart),
              title: Text("Add New Listing"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/add_listing_screen");
              },
            ),

            ListTile(
              leading: Icon(Icons.notification_important),
              title: Text("Notifications"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notifications_screen');
              },
            ),

            ListTile(
              leading: Icon(Icons.person_3),
              title: Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile_screen');
              },
            ),

            ListTile(
              leading: Icon(Icons.logout_outlined),
              title: Text("Logout"),
              onTap: () {
                _authService.signOut();
                print("Logout successfull");
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


