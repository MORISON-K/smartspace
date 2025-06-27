import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smartspace/auth/login_screen.dart';
import 'package:smartspace/seller/my_listings_screen.dart';






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
      },
    );
  }
}