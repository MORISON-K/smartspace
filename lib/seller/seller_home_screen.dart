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
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
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

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 234, 236, 240),
      appBar: AppBar(
        backgroundColor:  const Color.fromARGB(255, 167, 184, 198),
        title: Text(
          "Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              "Welcome back, ${_userName ?? 'Seller'}!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Here's what's happening with your properties",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),

            // Quick Actions
            Text(
              "Quick Actions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    "Add Listing",
                    Icons.add_home,
                    const Color.fromARGB(255, 45, 72, 94),
                    () => Navigator.pushNamed(context, "/add_listing_screen"),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    "Manage Listings ",
                    Icons.manage_history,
                    const Color.fromARGB(255, 76, 87, 115),
                    () => Navigator.pushNamed(context, '/mylistings_screen'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),

            // Recent Activity
            Text(
              "Recent Activity",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildActivityCard(
              "New inquiry for Busabaala Property",
              "2 hours ago",
              Icons.message,
              Colors.blue,
            ),
            _buildActivityCard(
              "Property viewed 5 times today",
              "4 hours ago",
              Icons.visibility,
              Colors.green,
            ),
            _buildActivityCard(
              "Price update completed",
              "1 day ago",
              Icons.update,
              Colors.orange,
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
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

            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text("Dashboard"),
              onTap: () {
                Navigator.pop(context);
               
              },
            ),

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
              leading: Icon(Icons.phone),
              title: Text("Test notifications"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notification_test');
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


