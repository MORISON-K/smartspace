import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map?;
    final RemoteMessage? message = arguments?['message'];
    final String? role = arguments?['role'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 97, 113, 147),
        title: Text("Notifications"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Role: $role"),
            Text("Title: ${message?.notification?.title ?? 'No Title'}"),
            Text("Body: ${message?.notification?.body ?? 'No Body'}"),
          ],
        ),
      ),
    );
  }
}
