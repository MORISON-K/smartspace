import 'package:flutter/material.dart';
import '../screens/manage_admins_screen.dart';
import '../screens/dashboard_screen.dart';

//

class SectionRouter extends StatelessWidget {
  final int index;
  const SectionRouter({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const Center(child: Text("Manage Users"));
      case 2:
        return const  ManageAdminsScreen();
      case 3:
        return const Center(child: Text("Property Listings"));
      case 4:
        return const Center(child: Text("Reports"));
      case 5:
        return const Center(child: Text("Settings"));
      default:
        return const Center(child: Text("Select a section"));
    }
  }
}
