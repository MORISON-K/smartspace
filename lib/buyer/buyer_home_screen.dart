import 'package:flutter/material.dart';
import 'package:smartspace/buyer/favorite_screen.dart';
import 'package:smartspace/buyer/home_screen_content.dart';
import 'package:smartspace/buyer/search_screen.dart';
import 'package:smartspace/notifications/notifications_screen.dart';

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

  final List _pages = [HomeScreenContent(), SearchScreen(), FavoriteScreen(), NotificationsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: _pages[_selectedPage],

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color.fromARGB(203, 243, 89, 33),
        unselectedItemColor: Colors.grey,

        currentIndex: _selectedPage,
        onTap: _navigationBottomBar,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
        ],
      ),
    );
  }
}
