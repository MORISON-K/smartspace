import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartspace/main.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNofications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    print('Token: $fCMToken');
    initPushNotifications();
  }

  Future<String?> getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return snapshot.data()?['role'];
  }

  void handleMessage(RemoteMessage? message) async {
    if (message == null) return;

    final role = await getUserRole();

    // Pass different arguments or route based on role
    switch (role) {
      case 'admin':
        navigatorKey.currentState?.pushNamed(
          '/notifications_screen',
          arguments: {'message': message, 'role': 'admin'},
        );
        break;
      case 'seller':
        navigatorKey.currentState?.pushNamed(
          '/notifications_screen',
          arguments: {'message': message, 'role': 'seller'},
        );
        break;
      case 'buyer':
        navigatorKey.currentState?.pushNamed(
          '/notifications_screen',
          arguments: {'message': message, 'role': 'buyer'},
        );
        break;
      default:
         navigatorKey.currentState?.pushNamed(
        '/notifications_screen',
         arguments: {'message': message},
    );
    }
  }

  //function to initialize foreground and background settings
  Future initPushNotifications() async {
    //handle notifications if the app was terminated
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    //attach event listeners for when a notification opens
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}
