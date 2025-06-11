import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_v2/firebase_options.dart';
import 'package:mobile_v2/services/log_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  /// Handles messages when the app is in the background or terminated
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await _initializeLocalNotifications();
    await _showFlutterNotification(message);
  }

  /// Static callback for background notification responses
  @pragma('vm:entry-point')
  static void onDidReceiveBackgroundNotificationResponse(
    NotificationResponse response,
  ) {
    LogService.info("Notification tapped: ${response.payload}");
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );
  }

  /// Initializes Firebase Messaging and local notifications
  static Future<void> initializeNotification() async {
    await _firebaseMessaging.requestPermission();
    // Called when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      LogService.info("Received message while in foreground: ${message.data}");
      _showFlutterNotification(message);
    });

    // Called when app is brought to foreground from background by tapping a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      LogService.info(
        "App opened from background Notification tapped: ${message.data}",
      );
    });

    // Get and print FCM token (for sending targeted messages)
    await _getFcmToken();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Check if the app was opened from a terminated state by tapping a notification
    await _getInitialNotification();
    LogService.info("Firebase Messaging initialized");
  }

  static Future<void> _getFcmToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      LogService.info("FCM Token: $token");

      // Save token to Firestore with a fixed document ID
      try {
        await FirebaseFirestore.instance
            .collection('fcm_tokens')
            .doc('user_token') // Fixed document ID since there's only one user
            .set({
              'token': token,
              'updated_at': FieldValue.serverTimestamp(),
              'device_info': 'mobile_app',
            });
        LogService.info("FCM Token saved to Firestore");
      } catch (e) {
        LogService.error("Failed to save FCM token to Firestore: $e");
      }
    } else {
      LogService.error("Failed to get FCM token");
    }
  }

  /// Shows a notification when a message is received
  static Future<void> _showFlutterNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    Map<String, dynamic> data = message.data;

    String title = notification?.title ?? data['title'] ?? 'No Title';
    String body = notification?.body ?? data['body'] ?? 'No Body';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          channelDescription: 'your_channel_description',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
    );
  }

  static Future<void> _getInitialNotification() async {
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      LogService.info(
        "App opened from terminated state with notification: ${initialMessage.data}",
      );
    }
  }
}
