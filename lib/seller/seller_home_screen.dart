import 'package:flutter/material.dart';

class SellerHomeScreen extends StatelessWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      body: Center(child: Text("seller home screen")),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/logo.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Text("Hello seller"),
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
          ],
        ),
      ),
    );
  }
}
