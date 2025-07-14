import 'package:flutter/material.dart';
import 'package:smartspace/admin/screens/manage_users_screen.dart';

import 'package:smartspace/admin/screens/dashboard_screen.dart';
import 'package:smartspace/admin/screens/property_listings_screen.dart';
import 'package:smartspace/notifications/notifications_screen.dart';
import '../widgets/admin_sidebar.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int selectedIndex = 0;

  void _onSectionSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Widget _getSelectedScreen() {
    switch (selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ManageUsersScreen();
      
      case 2:
        return const PropertyListingsScreen();
      case 3:
        return const NotificationsScreen();
      case 4:
        return const Text("Settings Screen");
      
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final appBar = AppBar(
          title: const Text("Admin Panel"),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: 'Notifications',
              onPressed: () {
                setState(() {
                  selectedIndex = 6; // Navigate to Notifications
                });
              },
            ),
          ],
        );

        if (constraints.maxWidth > 600) {
          // Tablet/Desktop Layout
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: AdminSidebar(
                    selectedIndex: selectedIndex,
                    onSectionSelected: _onSectionSelected,
                  ),
                ),
                Expanded(child: _getSelectedScreen()),
              ],
            ),
          );
        } else {
          // Mobile Layout with Drawer
          return Scaffold(
            appBar: appBar,
            drawer: Drawer(
              child: AdminSidebar(
                selectedIndex: selectedIndex,
                onSectionSelected: (index) {
                  _onSectionSelected(index);
                  Navigator.pop(context); // Close drawer after tap
                },
              ),
            ),
            body: _getSelectedScreen(),
          );
        }
      },
    );
  }
}
