import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:smartspace/main.dart'; // Import to access navigatorKey

class NoticicationsScreen extends StatelessWidget {
  const NoticicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //get the notification message and display on screen
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
  //Create an instance of firebase messaging
  final _firebaseMessaging = FirebaseMessaging.instance;

  //function to initialize notifications
  Future<void> initNofications() async {
    //Request permission from user
    await _firebaseMessaging.requestPermission();

    //fetch the FCM token for this device
    final fCMToken = await _firebaseMessaging.getToken();

    // Print token
    print('Token: $fCMToken');

    //initialize further settings for push notifications
    initPushNotifications();
  }

  //function to handle received messages
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    // Navigate to notification screen when message is received
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
