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
        return _buildSettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  Widget _buildSettingsScreen() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Settings",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Manage your application settings and preferences",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      size: 60,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Settings Coming Soon",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This section is under development",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final appBar = AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E3A8A),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  "SmartSpace Admin",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            // Notifications Button
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_rounded, size: 24),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            "3",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                tooltip: 'Notifications',
                onPressed: () {
                  setState(() {
                    selectedIndex = 3;
                  });
                },
              ),
            ),

            // Quick Actions Menu (Simplified)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                tooltip: 'Quick Actions',
                onSelected: (value) {
                  switch (value) {
                    case 'help':
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Row(
                                children: [
                                  Icon(
                                    Icons.help_rounded,
                                    color: Color(0xFF3B82F6),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Help & Support'),
                                ],
                              ),
                              content: const Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SmartSpace Admin Panel'),
                                  SizedBox(height: 8),
                                  Text(
                                    '• Dashboard: Overview of system metrics',
                                  ),
                                  Text('• Users: Manage user accounts'),
                                  Text(
                                    '• Properties: Handle property listings',
                                  ),
                                  Text('• Notifications: View system alerts'),
                                  SizedBox(height: 12),
                                  Text(
                                    'For technical support, contact the system administrator.',
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                      );
                      break;
                    case 'about':
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Row(
                                children: [
                                  Icon(
                                    Icons.info_rounded,
                                    color: Color(0xFF3B82F6),
                                  ),
                                  SizedBox(width: 8),
                                  Text('About SmartSpace'),
                                ],
                              ),
                              content: const Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SmartSpace Admin Panel'),
                                  SizedBox(height: 8),
                                  Text('Version: 1.0.0'),
                                  Text('Build: 2024.1'),
                                  SizedBox(height: 12),
                                  Text(
                                    'A modern property management system built with Flutter.',
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                      );
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'help',
                        child: Row(
                          children: [
                            Icon(
                              Icons.help_rounded,
                              size: 20,
                              color: Color(0xFF3B82F6),
                            ),
                            SizedBox(width: 12),
                            Text('Help & Support'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'about',
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_rounded,
                              size: 20,
                              color: Color(0xFF3B82F6),
                            ),
                            SizedBox(width: 12),
                            Text('About'),
                          ],
                        ),
                      ),
                    ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        );

        if (constraints.maxWidth > 800) {
          // Tablet/Desktop Layout
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: appBar,
            body: Row(
              children: [
                AdminSidebar(
                  selectedIndex: selectedIndex,
                  onSectionSelected: _onSectionSelected,
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _getSelectedScreen(),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile Layout with Drawer
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: appBar,
            drawer: Drawer(
              child: AdminSidebar(
                selectedIndex: selectedIndex,
                onSectionSelected: (index) {
                  _onSectionSelected(index);
                  Navigator.pop(context);
                },
              ),
            ),
            body: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _getSelectedScreen(),
              ),
            ),
          );
        }
      },
    );
  }
}
