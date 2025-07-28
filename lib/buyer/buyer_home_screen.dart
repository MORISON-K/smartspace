import 'package:flutter/material.dart';
import 'package:smartspace/buyer/favorite_screen.dart';
import 'package:smartspace/buyer/home_screen_content.dart';
import 'package:smartspace/buyer/search_screen.dart';
import 'package:smartspace/notifications/notifications_screen.dart';
import 'package:smartspace/buyer/buyer_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _selectedPage = 0;

  void _navigationBottomBar(int index) {
    setState(() {
      _selectedPage = index;
    });
  }

  List<Widget> get _pages => [
    const HomeScreenContent(),
    const SearchScreen(),
    const FavoriteScreen(),
    const NotificationsScreen(),
    BuyerDashboardScreen(userId: FirebaseAuth.instance.currentUser!.uid),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedPage],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomNavigationBar(
              backgroundColor: Colors.black,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              currentIndex: _selectedPage,
              onTap: _navigationBottomBar,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false, // hides text labels when selected
              showUnselectedLabels: false, // hides text labels when unselected
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home, size: 30), // bigger icon size
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search, size: 30),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite, size: 30),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications, size: 30),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person, size: 30),
                  label: '',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
