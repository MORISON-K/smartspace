import 'package:flutter/material.dart';
import 'package:smartspace/auth/auth_service.dart';
import 'package:smartspace/auth/login_screen.dart';

class SellerHomeScreen extends StatelessWidget {
  SellerHomeScreen({super.key});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      body: Center(child: Text("seller home screen")),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("Seller Name"),
              accountEmail: Text("seller@example.com"),
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage("assets/logo.png"),
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
