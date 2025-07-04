import 'package:flutter/material.dart';
import '../widgets/activity_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "👋 Welcome back, Admin!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search users or admins...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "🕒 Recent Activities",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // List of activities
            Expanded(
              child: ListView(
                children: const [
                  ActivityTile(user: "John Doe", action: "added a new property", time: "2 mins ago"),
                  ActivityTile(user: "Admin Jane", action: "removed a user", time: "10 mins ago"),
                  ActivityTile(user: "Sarah", action: "reported a listing", time: "30 mins ago"),
                  ActivityTile(user: "Mike", action: "signed up", time: "1 hour ago"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
