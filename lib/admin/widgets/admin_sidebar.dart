import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSectionSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSectionSelected,
  });

  final List<Map<String, dynamic>> menuItems = const [
    {'icon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.people, 'label': 'Manage Users'},
    {'icon': Icons.admin_panel_settings, 'label': 'Manage Admins'},
    {'icon': Icons.home, 'label': 'Property Listings'},
    {'icon': Icons.report, 'label': 'Reports'},
    {'icon': Icons.settings, 'label': 'Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.blueGrey[900],
      child: Column(
        children: [
          const DrawerHeader(
            child: Text("Admin Panel", style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          ...menuItems.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;

            return ListTile(
              selected: selectedIndex == index,
              selectedTileColor: const Color.fromARGB(255, 7, 95, 135),
              leading: Icon(item['icon'], color: Colors.white),
              title: Text(item['label'], style: const TextStyle(color: Colors.white)),
              onTap: () => onSectionSelected(index),
            );
          }).toList(),
        ],
      ),
    );
  }
}
