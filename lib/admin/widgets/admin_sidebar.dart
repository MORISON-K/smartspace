import 'package:flutter/material.dart';
import 'package:smartspace/auth/auth_service.dart';
import 'package:smartspace/auth/login_screen.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSectionSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSectionSelected,
  });

  final List<Map<String, dynamic>> menuItems = const [
    {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
    {'icon': Icons.people_rounded, 'label': 'Manage Users'},
    {'icon': Icons.home_work_rounded, 'label': 'Property Listings'},
    {'icon': Icons.notifications_rounded, 'label': 'Notifications'},
    {'icon': Icons.settings_rounded, 'label': 'Settings'},
  ];

  // Logout method
  void _handleLogout(BuildContext context) {
    final AuthService _authService = AuthService();
    _authService.signOut();
    print("Logout successful");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // Profile navigation method
  void _navigateToProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 181, 183, 74),
                      Color.fromARGB(255, 181, 183, 74),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Admin Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileItem('Name', 'Administrator'),
              _buildProfileItem('Email', 'admin@smartspace.com'),
              _buildProfileItem('Role', 'System Administrator'),
              _buildProfileItem('Last Login', 'Today, 10:30 AM'),
              _buildProfileItem('Status', 'Active', isStatus: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Color.fromARGB(255, 250, 250, 249)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileItem(
    String label,
    String value, {
    bool isStatus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child:
                isStatus
                    ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    )
                    : Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 45, 48, 48),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "SmartSpace",
                      style: TextStyle(
                        color: Color.fromARGB(255, 208, 180, 20),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Admin Panel",
                      style: TextStyle(
                        color: Color.fromARGB(255, 208, 180, 20).withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Menu Items wrapped in SizedBox with height
              SizedBox(
                height: 300,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    final isSelected = selectedIndex == index;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onSectionSelected(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.transparent,
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item['icon'],
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item['label'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Profile and Logout Section remains unchanged
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Profile Button
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _navigateToProfile(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Administrator",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "View Profile",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Logout Button
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _handleLogout(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Logout",
                              style: TextStyle(
                                color: Color.fromARGB(255, 248, 247, 247),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.exit_to_app_rounded,
                            color: const Color.fromARGB(
                              255,
                              243,
                              241,
                              240,
                            ).withOpacity(0.7),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
