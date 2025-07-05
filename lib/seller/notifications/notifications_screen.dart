import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:smartspace/main.dart'; 

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

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNofications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    print('Token: $fCMToken');
    initPushNotifications();
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    navigatorKey.currentState?.pushNamed(
      '/notifications_screen',
      arguments: message,
    );
  }

  //function to initialize foreground and background settings
  Future initPushNotifications() async {
    //handle notifications if the app was terminated
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    //attach event listeners for when a notification opens
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}
