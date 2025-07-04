import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smartspace/auth/login_screen.dart';

import 'package:smartspace/seller/my_listings_screen.dart';
import 'package:smartspace/seller/add_listing_screen.dart';
import 'package:smartspace/seller/ai-valuation/ai_valuation.dart';
import 'package:smartspace/seller/analytics_screen.dart';
import 'package:smartspace/seller/noticications_screen.dart';
import 'package:smartspace/seller/profile_screen.dart';
import 'package:smartspace/seller/seller_home_screen.dart';

// Global navigator key for navigation from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseApi().initNofications();
  runApp(const SmartSpace());
}

class SmartSpace extends StatelessWidget {
  const SmartSpace({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
      routes: {
        '/mylistings_screen': (context) => const MyListingsScreen(),
        '/analytics_screen': (context) => AnalyticsScreen(),
        '/ai_valuation': (context) => AiValuationScreen(),
        '/notifications_screen': (context) => NoticicationsScreen(),
        '/add_listing_screen': (context) => AddListingScreen(),
        '/seller_home_screen': (context) => SellerHomeScreen(),
        '/profile_screen': (context) => ProfileScreen(),

      },
    );
  }
}
