import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartspace/auth/auth_service.dart';
import 'package:smartspace/auth/login_screen.dart';
import 'package:smartspace/notifications/notifications_screen.dart';
import 'recent-activity/recent_activity_model.dart';
import 'recent-activity/activity_service.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  final AuthService _authService = AuthService();
  final ActivityService _activityService = ActivityService();

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

  Widget _buildActivityCard(Activity activity) {
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
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(activity.icon, color: AppColors.primaryBlue, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2),
                Text(
                  activity.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  activity.timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Activity",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        StreamBuilder<List<Activity>>(
          stream: _activityService.getSellerActivities(limit: 5),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading activities',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            final activities = snapshot.data ?? [];

            if (activities.isEmpty) {
              return Container(
                padding: EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                    SizedBox(height: 8),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Create your first listing to see activity here',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children:
                  activities
                      .map((activity) => _buildActivityCard(activity))
                      .toList(),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          "Dashboard",
          style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 25),
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
                     Color.fromARGB(255, 208, 180, 20),
                    () => Navigator.pushNamed(context, "/add_listing_screen"),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    "Manage Listings ",
                    Icons.manage_history,
                    Color.fromARGB(255, 208, 180, 20),
                    () => Navigator.pushNamed(context, '/mylistings_screen'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),

            _buildActivitiesSection(),

            // // Recent Activity
            // Text(
            //   "Recent Activity",
            //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            // ),
            // SizedBox(height: 16),
            // // Example usage of _buildActivityCard with a dummy Activity instance:
            // _buildActivityCard(
            //   Activity(
            //     title: "Sample Activity",
            //     description: "This is a sample recent activity.",
            //     timeAgo: "2 hours ago",
            //     icon: Icons.notifications,
            //     color: Colors.blue,
            //   ),
            // ),
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
                color: const Color.fromARGB(206, 46, 43, 13),
              ),
            ),

            ListTile(
              leading: Icon(Icons.dashboard, color: Color.fromARGB(255, 188, 162, 16),),
              title: Text("Dashboard"),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: Icon(Icons.apartment, color: Color.fromARGB(255, 188, 162, 16),),
              title: Text("My Listings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/mylistings_screen');
              },
            ),

            ListTile(
              leading: Icon(Icons.show_chart, color: Color.fromARGB(255, 188, 162, 16),),
              title: Text("AI Valuation"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/land_valuation');
              },
            ),

            ListTile(
              leading: Icon(Icons.analytics, color: Color.fromARGB(255, 188, 162, 16),),
              title: Text("View Analytics"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/analytics_screen');
              },
            ),

            ListTile(
              leading: Icon(Icons.addchart, color: Color.fromARGB(255, 188, 162, 16),),
              title: Text("Add New Listing"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/add_listing_screen");
              },
            ),

            ListTile(
              leading: Icon(Icons.notification_important, color: Color.fromARGB(255, 188, 162, 16),),
              title: Text("Notifications"),
              onTap: () {
                Navigator.pop(context);
                // Navigate directly to notifications screen without arguments to show history
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),

            // ListTile(
            //   leading: Icon(Icons.person_3),
            //   title: Text("Profile"),
            //   onTap: () {
            //     Navigator.pop(context);
            //     Navigator.pushNamed(context, '/profile_screen');
            //   },
            // ),

            ListTile(
              leading: Icon(Icons.logout_outlined, color: Color.fromARGB(255, 188, 162, 16),),
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

class AppColors {
  // Primary palette
  static const Color primaryBlue = Color.fromARGB(255, 188, 162, 16);
  static const Color lightBlue = Color(0xFF4A90C2);
  static const Color cream = Color(0xFFF8F6F3);
  static const Color gold = Color(0xFFD4A574);
  static const Color darkGray = Color(0xFF2C2C2C);
  
  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53E3E);
  static const Color info = Color(0xFF2196F3);
  
  // Background & surface
  static const Color background = cream;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F0);
  
  // Text colors
  static const Color textPrimary = darkGray;
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
}