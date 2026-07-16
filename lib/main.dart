import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Screen Imports
import 'package:shiftsmart/screens/login.dart';

// Service & Provider Imports
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/services/notification_service.dart';

// Global navigator key for showing dialogs without context (e.g. from services)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// --- 1. Background Message Handler ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  debugPrint("Background Data: ${message.data}");

  // Initialize Local Notifications (Required for background isolate)
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
    macOS: DarwinInitializationSettings(),
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Manual Parsing Logic for Backend Data Messages
  String? title;
  String? body;

  if (message.notification != null) {
    title = message.notification?.title;
    body = message.notification?.body;
  } else if (message.data.containsKey('shiftDetails')) {
    title = "New Shift Assigned";
    body = message.data['shiftDetails'];
  } else if (message.data.containsKey('completionDetails')) {
    title = "Shift Completed";
    body = message.data['completionDetails'];
  } else if (message.data.containsKey('status') ||
      message.data.containsKey('Status')) {
    title = "Leave Update";
    body =
        "Your leave request is ${message.data['status'] ?? message.data['Status']}";
  } else if (message.data.containsKey('type')) {
    title = _titleForMessageType(message.data['type']);
    body = message.data['body'] ??
        message.data['message'] ??
        message.data['details'] ??
        message.data['shiftDetails'];
  }

  // Show the Notification
  if (body != null) {
    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher', // Ensure this icon exists
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}

// --- 2. Global Notification Channel Setup ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupLocalNotifications() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
    macOS: DarwinInitializationSettings(),
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

String _titleForMessageType(String? type) {
  switch (type) {
    case 'shift_assignment':
      return 'Shift Assigned';
    case 'shift_completed':
      return 'Shift Completed';
    case 'leave_request':
      return 'New Leave Request';
    case 'leave_status':
      return 'Leave Request Status';
    case 'shift_response':
      return 'Shift Response';
    case 'shift_updated':
      return 'Shift Updated';
    case 'shift_incomplete':
      return 'Incomplete Shift Alert';
    case 'onboarding_complete':
      return 'Onboarding Complete';
    default:
      return 'Notification';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Maps renderer (fixes blank/beige map tiles)
  // Wrapped in try-catch because hot restart throws "Renderer already initialized"
  try {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      await mapsImplementation
          .initializeWithRenderer(AndroidMapRenderer.latest);
    }
  } catch (_) {
    // Renderer already initialized (e.g. on hot restart) – safe to ignore
  }

  // Initialize Firebase & Environment
  await Firebase.initializeApp();
  await dotenv.load();

  // Set up Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Setup Local Notifications (For Foreground Pop-ups)
  await setupLocalNotifications();

  // Initialize FCM Service (Permission Request)
  // We pass employeeId: 0 to setup listeners, BUT skip registration to avoid 403 error.
  await NotificationService().initializeFCM(
    employeeId: 0,
    userTag: "guest",
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TenantProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Welcome'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // Replaced the simple timer with the Smart Session Check
    _checkLoginStatus();
  }

  //  LOGIC: Check Disk for Token -> Restore Session -> Navigate
  Future<void> _checkLoginStatus() async {
    // 1. Give the splash screen a visual delay (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = FlutterSecureStorage();
      final String? token = await storage.read(key: 'appToken');
      final String? email = prefs.getString('userEmail');

      if (token != null && token.isNotEmpty && email != null) {
        final bool biometricEnabled =
            prefs.getBool('biometric_enabled') ?? false;

        if (biometricEnabled) {
          debugPrint("Biometrics enabled. Redirecting to Biometric Login...");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const Login(promptBiometric: true),
            ),
          );
        } else {
          debugPrint("Biometrics disabled. Standard Login.");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const Login(promptBiometric: false),
            ),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint("Session check failed: $e");
    }

    // 4. Fallback: If no token or invalid token, go to Login (Standard)
    if (mounted) {
      debugPrint("No valid session found. Going to Standard Login.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const Login(promptBiometric: false)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            color: const Color(0xFF242C3B),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image(
                  image: AssetImage('assets/logo.png'),
                  width: 250,
                  height: 250,
                ),
                SizedBox(height: 20),
                // Optional loading spinner so user knows we are checking session
                CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
