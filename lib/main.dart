import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smartspace/auth/login_screen.dart';

import 'package:smartspace/seller/my_listings_screen.dart';
import 'package:smartspace/seller/add_listing_screen.dart';
import 'package:smartspace/seller/ai_valuation.dart';
import 'package:smartspace/seller/analytics_screen.dart';
import 'package:smartspace/seller/noticications_screen.dart';

//import 'package:smartspace/seller/mylistings_screen.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  );
  runApp(const SmartSpace());
}

class SmartSpace extends StatelessWidget {
  const SmartSpace({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
      routes: {

        '/mylistings_screen': (context) => const MyListingsScreen(),

       // '/mylistings_screen': (context) => MylistingsScreen(),
        '/analytics_screen': (context) => AnalyticsScreen(),
        '/ai_valuation': (context) => AiValuationScreen(),
        '/notifications_screen': (context) => NoticicationsScreen(),
        '/add_listing_screen': (context) => AddListingScreen(),

      },
    );
  }
}