import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth_service.dart';
import 'pages/main_page.dart';
import 'package:logging/logging.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  _setupLogging();
  await _initializeLocalNotifications();
  await _initializeFCM();
  runApp(MyApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialization successful');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
}

Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  try {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print('Local notifications initialized successfully');
  } catch (e) {
    print('Local notifications initialization error: $e');
  }
}

Future<void> _initializeFCM() async {
  try {
    await firebaseMessaging.requestPermission();
    String? token = await firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message in the foreground!');
      _showNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    print('FCM initialized successfully');
  } catch (e) {
    print('FCM initialization error: $e');
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _showNotification(message);
}

void _showNotification(RemoteMessage message) {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title,
    message.notification?.body,
    platformChannelSpecifics,
    payload: 'item x',
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Event Calendar',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: AuthWrapper(),
        routes: {
          '/login': (context) => SignInScreen(),
          '/main': (context) => AuthWrapper(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final Logger _logger = Logger('AuthWrapper');

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      _logger.info('User is not authenticated');
      return SignInScreen();
    }

    _logger.info('User is authenticated');
    return MainPage(user: user);
  }
}

class SignInScreen extends StatelessWidget {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger('SignInScreen');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Firebase Google Sign-In'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              _logger.info('Attempting to sign in with Google');
              await _authService.signInWithGoogle();
              _logger.info('Successfully signed in with Google');
            } catch (e) {
              _logger.severe('Error during sign in: $e');
              _showErrorDialog(context, 'Error during sign in: $e');
            }
          },
          child: Text('Sign in with Google'),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sign-In Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
