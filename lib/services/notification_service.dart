import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'timezone_service.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  NotificationService() {
    _initializeNotifications();
    _initializeFCM();
    TimezoneService.initialize(); // Initialize timezone settings
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {
      // Handle your logic when a notification is selected
    });
  }

  void _initializeFCM() async {
    try {
      // Request permission for iOS
      await firebaseMessaging.requestPermission();

      // Get the token for the device
      String? token = await firebaseMessaging.getToken();
      print('FCM Token: $token');
      
      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received a message in the foreground!');
        _showNotification(message);
      });

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      print('FCM initialized successfully');
    } catch (e) {
      print('FCM initialization error: $e');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    NotificationService()._showNotification(message);
  }

  void _showNotification(RemoteMessage message) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      channelDescription: 'This channel is used for important notifications.', // description
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledDate) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id', // required String channelId
      'channel_name', // required String channelName
      channelDescription: 'channel_description', // optional String channelDescription
      importance: Importance.max, // optional Importance importance
      priority: Priority.high, // optional Priority priority
    );
    const IOSNotificationDetails iOSDetails = IOSNotificationDetails();
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);

    final tz.TZDateTime tzScheduledDate =
        TimezoneService.convertToTZDateTime(scheduledDate);

    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future<void> scheduleEventNotifications(
      String eventId, String title, String body, DateTime scheduledDate) async {
    DatabaseReference eventRef = FirebaseDatabase.instance.ref('events/$eventId/participants');
    eventRef.once().then((DatabaseEvent databaseEvent) {
      Map<dynamic, dynamic> participants = databaseEvent.snapshot.value as Map<dynamic, dynamic>;
      int id = 0; // Initializing the notification ID
      participants.forEach((key, value) {
        String userId = key; // User ID
        // Fetch user notification ID or token from the database
        DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$userId/notificationToken');
        userRef.once().then((DatabaseEvent userEvent) async {
          String notificationToken = userEvent.snapshot.value as String;
          await scheduleNotification(
              id++, title, body, scheduledDate); // Incrementing the notification ID for each user
          // Note: If you're using Firebase Cloud Messaging (FCM), you would use the token to send a push notification instead
        });
      });
    });
  }
}
