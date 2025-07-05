import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final message = arguments is RemoteMessage ? arguments : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 97, 113, 147),
        title: Text("Notifications"),
      ),
      body:
          message != null
              ? Column(
                children: [
                  Text(message.notification?.title?.toString() ?? 'No title'),
                  Text(message.notification?.body?.toString() ?? 'No body'),
                  Text(message.data.toString()),
                ],
              )
              : const Center(child: Text('No notification data available')),
    );
  }
}
