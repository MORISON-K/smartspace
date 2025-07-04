import 'package:flutter/material.dart';
import 'package:smartspace/admin/screens/manage_users_screen.dart';
import '../widgets/admin_sidebar.dart';
import 'dashboard_screen.dart';
// Import other screen widgets here
// import 'manage_users_screen.dart';
import 'manage_admins_screen.dart';

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
        return const ManageUsersScreen(); // Replace with ManageUsersScreen()
      case 2:
        return const ManageAdminsScreen(); // Replace with ManageAdminsScreen()
      case 3:
        return const Text("Property Listings Screen");
      case 4:
        return const Text("Reports Screen");
      case 5:
        return const Text("Settings Screen");
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Tablet/Desktop Layout
          return Row(
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
          );
        } else {
          // Mobile Layout with Drawer
          return Scaffold(
            appBar: AppBar(title: const Text("Admin Panel")),
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
