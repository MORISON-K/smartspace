import 'package:flutter/material.dart';
import 'package:smartspace/admin/screens/property_listings_screen.dart';
import 'package:smartspace/notifications/notifications_screen.dart';

import '../screens/dashboard_screen.dart';
import '../screens/manage_users_screen.dart';

class SectionRouter extends StatelessWidget {
  final int index;
  const SectionRouter({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ManageUsersScreen();
      case 2:
        return const PropertyListingsScreen();
      case 3:
        return const NotificationsScreen();
      case 4:
        return const Center(child: Text("Settings"));
      default:
        return const Center(child: Text("Select a section"));
    }
  }
}
