import 'package:flutter/material.dart';

void main() {
  runApp(const SmartSpace());
}

class SmartSpace extends StatelessWidget {
  const SmartSpace({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
     
    );
  }
}