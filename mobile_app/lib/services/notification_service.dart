import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    // 1. Request Permission (FCM)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Local Notifications Setup (Skip on Web to avoid compilation issues)
    if (!kIsWeb) {
      try {
        const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
        
        const InitializationSettings initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        // Use dynamic to bypass static signature checks during web compilation
        await (_localNotifications as dynamic).initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            print('Notification clicked: ${response.payload}');
          },
        );
      } catch (e) {
        print('Local notifications initialization failed: $e');
      }
    }

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
      if (!kIsWeb) {
        _showLocalNotification(message);
      }
    });

    // 4. Handle Background/Terminated Click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked: ${message.data}');
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return; 

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'wise_wallet_alerts',
      'Wise Wallet Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    try {
      // Use dynamic to bypass static signature checks during web compilation
      await (_localNotifications as dynamic).show(
        message.hashCode,
        message.notification?.title ?? 'Wise Wallet Alert',
        message.notification?.body ?? '',
        details,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  static Future<void> uploadToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await ApiService.updateFcmToken(token);
      }
    } catch (e) {
      print('Error uploading token: $e');
    }
  }
}
