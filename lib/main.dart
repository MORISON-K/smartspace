import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smartspace/auth/login_screen.dart';
import 'package:smartspace/seller/ai-valuation/land_value_predictor.dart';

import 'package:smartspace/seller/my_listings_screen.dart';
import 'package:smartspace/seller/add_listing_screen.dart';
import 'package:smartspace/seller/analytics_screen.dart';
import 'package:smartspace/notifications/notifications_screen.dart';
import 'package:smartspace/seller/profile_screen.dart';
import 'package:smartspace/seller/seller_home_screen.dart';
import 'package:smartspace/notifications/notifications_service.dart';

// Global navigator key for navigation from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notifications only, token will be updated when user logs in
  // or if user is already logged in, it will be updated by the auth state listener
  await FirebaseApi().initNofications();

  runApp(const SmartSpace());
}

class SmartSpace extends StatelessWidget {
  const SmartSpace({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.amber,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
      routes: {
        '/mylistings_screen': (context) => const MyListingsScreen(),
        '/analytics_screen': (context) => AnalyticsScreen(),
        '/notifications_screen': (context) => NotificationsScreen(),
        '/add_listing_screen': (context) => AddListingScreen(),
        '/seller_home_screen': (context) => SellerHomeScreen(),
        '/profile_screen': (context) => ProfileScreen(),
        '/land_valuation': (context) => LandValuePredictorWidget(),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}
