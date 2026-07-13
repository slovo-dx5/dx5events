import 'package:dx5veevents/constants.dart';

import 'package:dx5veevents/providers.dart';
import 'package:dx5veevents/providers/themeProvider.dart';
import 'package:dx5veevents/screens/dx5veScreens/notificationsScreen.dart';

import 'package:dx5veevents/screens/landingPage2.dart';
import 'package:dx5veevents/screens/test.dart';
import 'package:dx5veevents/scripts/doLastMinuteShyet.dart';
import 'package:dx5veevents/map_screen.dart';
import 'package:dx5veevents/testScreen.dart';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'package:timezone/data/latest.dart' as tzdata;

import 'helpers/themeData.dart';
import 'homeScreen.dart';
import 'mainNavigationPage.dart';
import 'meetings/meeting_tabs.dart';
import 'notifications/pushNotifications.dart';
import 'providers/cart_provider.dart';
import 'providers/social_provider.dart';
import 'providers/harry_controller.dart';
import 'services/activity_logger.dart';
import 'services/harry/harry_config.dart';
import 'services/harry/harry_reminders.dart';
import 'widgets/harry/harry_overlay.dart';
const AndroidNotificationChannel _meetingChannel = AndroidNotificationChannel(
  'meeting_notifications',
  'Meeting Notifications',
  description: 'Notifications for meeting requests and updates',
  importance: Importance.high,
);

// Channel for reminders the user asks Harry (the AI assistant) to set.
const AndroidNotificationChannel _harryReminderChannel =
    AndroidNotificationChannel(
  HarryReminders.channelId,
  HarryReminders.channelName,
  description: 'Reminders you asked Harry to set',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final NotificationSetup _notificationSetup=NotificationSetup();
  _notificationSetup.configurePushNotifications();
  // _notificationSetup.eventListenerCallback();
  print("Handling a background message: $message");
}
// Default event params for launching the full app shell (MainNavigationPage)
// from a notification cold-start. Mirrors the values defined in landingPage2.dart.
MainNavigationPage _buildMainNavShell({int initialTabIndex = 0}) {
  return MainNavigationPage(
    initialTabIndex: initialTabIndex,
    coverImagePath: 'assets/images/themes/smart_gov_landscape.jpg',
    eventName: 'BFSI WEEK',
    eventDate: 'WED, JUN, 17TH',
    shortEventDescription: "Powering Africa's Financial Transformation",
    eventLocation: 'KENYA',
    eventID: '104',
    eventDay: 14,
    eventMonth: 6,
    eventYear: 2026,
    eventDayOfWeek: 'WED',
    isCustomerEvent: false,
  );
}

// Renders the full app shell and pushes NotificationsScreen on top so the user
// retains the bottom nav bar and can navigate home from a notification cold-start.
class _NotificationsLauncher extends StatefulWidget {
  const _NotificationsLauncher();

  @override
  State<_NotificationsLauncher> createState() => _NotificationsLauncherState();
}

class _NotificationsLauncherState extends State<_NotificationsLauncher> {
  bool _pushed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pushed || !mounted) return;
      _pushed = true;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) => _buildMainNavShell();
}

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
     builder: (context, state) =>  LandingPage2(isFromLogout: false,),
    ),
    GoRoute(
      path: '/meetings',
      // Render the full app shell so the user keeps the bottom nav and can
      // leave the meetings tab when cold-started from a notification.
      builder: (context, state) => _buildMainNavShell(initialTabIndex: 2),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const _NotificationsLauncher(),
    ),
    GoRoute(
      path: '/test-contact',
      builder: (context, state) => ContactSaveTest(),
    ),
  ],
);
// Builds the Harry assistant controller with its reminder scheduler and an
// app-navigation handler (go_router lives here). Event context defaults to the
// active event surfaced on the landing page (Smart Government Summit, id 107)
// and can be refreshed later via HarryController.updateEvent.
HarryController _buildHarryController() {
  final controller = HarryController();
  controller.reminders = HarryReminders(_localNotifications);
  controller.updateEvent(
    eventId: '107',
    name: 'Smart Government Summit',
    location: 'Kenya',
  );
  controller.navigateHandler = (target) async {
    switch (target) {
      case 'meetings':
        router.go('/meetings');
        return 'Opened your Meetings.';
      case 'notifications':
        router.go('/notifications');
        return 'Opened Notifications.';
      case 'home':
        router.go('/');
        return 'Opened Home.';
      default:
        return 'I can only open Meetings, Notifications or Home directly — '
            'for anything else, tell the user which tab or tile to tap.';
    }
  };
  return controller;
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();


  // Initialize Firebase only if not already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: "dx5veevents",
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } else {
    debugPrint('Firebase already initialized');
  }

  // Initialise local notifications with both Android and iOS settings
  await _localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    ),
  );
  final androidNotifications = _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidNotifications?.createNotificationChannel(_meetingChannel);
  await androidNotifications?.createNotificationChannel(_harryReminderChannel);
  // Needed on Android 13+ for Harry's scheduled reminders to appear.
  await androidNotifications?.requestNotificationsPermission();

  // Timezone DB is required for scheduling Harry's reminders (zonedSchedule).
  tzdata.initializeTimeZones();

  // Load Harry's AI keys from assets/.env (falls back to --dart-define).
  await HarryConfig.load();

  Get.put<MyDrawerController>(MyDrawerController());

  ActivityLogger.instance.init();

  if(Platform.isAndroid){
    await FirebaseMessaging.instance.subscribeToTopic("SmartGovBroadCast");
    //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }else if(Platform.isIOS){
    try{ await NotificationSetup().getIOSPermission();
    await FirebaseMessaging.instance.getAPNSToken();

    await FirebaseMessaging.instance.getAPNSToken().then((value)async{
      await FirebaseMessaging.instance.subscribeToTopic("SmartGovBroadCast");
    } );

    //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
    catch(e){
      print(("firebase messaging error is? $e"));
    }
  }
  // await FlutterDownloader.initialize(
  //     debug: true, // optional: set to false to disable printing logs to console (default: true)
  //     ignoreSsl: true // option: set to false to disable working with http links (default: false)
  // );

  runApp( MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();
  List<Map<String, String>> notifications = [];

  @override
  void initState() {
    super.initState();
    initDeepLinks();

if(Platform.isIOS){
  try{
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data);
      _storeNotification(message.notification?.title, message.notification?.body);
    });

    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationClick(message.data);
        _storeNotification(message.notification?.title, message.notification?.body);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {
        _storeNotification(message.notification!.title, message.notification!.body);
        await _showForegroundNotification(message);
      }
    });
  } catch (e) {
    print("firebase messaging config error $e");
  }
} else {
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationClick(message.data);
    _storeNotification(message.notification?.title, message.notification?.body);
  });

  _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      _handleNotificationClick(message.data);
      _storeNotification(message.notification?.title, message.notification?.body);
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (message.notification != null) {
      _storeNotification(message.notification!.title, message.notification!.body);
      await _showForegroundNotification(message);
    }
  });
}
  }
  Future<void> initDeepLinks() async {
    // Handle deep links when app is started from terminated state
    final  response = await SystemChannels.platform.invokeMethod('initialRoute');
    final String? initialLink = response as String?;

    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }

    // Handle deep links when app is in background or foreground
    SystemChannels.platform.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'pushRoute') {
        final String? link = call.arguments as String?;
        if (link != null) {
          _handleDeepLink(link);
        }
      }
      return null;
    });
  }

  void _handleDeepLink(String link) {
    if (link.startsWith('https://')) {
      // Extract the path from the URI
      final uri = Uri.parse(link);
      final path = uri.path;

      // If it's a meetings link with an ID
      if (path.startsWith('/meetings') && uri.queryParameters.containsKey('id')) {
        final id = uri.queryParameters['id'];
        router.go('/meetings/$id');
      }
      // If it's just a meetings link without ID
      else if (path.startsWith('/meetings')) {
        router.go('/meetings');
      }
    }
  }

  void _handleNotificationClick(Map<String, dynamic> data) async {
    final bool isAuthenticated = await getBoolPref("isAuthenticated");
    if (!isAuthenticated) return;

    final String targetPage = data['targetPage'] ?? 'notifications';
    if (targetPage == 'meetings') {
      router.go('/meetings');
    } else {
      router.go('/notifications');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!Platform.isAndroid) return; // iOS shows foreground banners natively
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meeting_notifications',
          'Meeting Notifications',
          channelDescription: 'Notifications for meeting requests and updates',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> _storeNotification(String? title, String? body) async {
    // ignore: unnecessary_null_comparison
    if (title != null && body != null) {
      final String timestamp = DateTime.now().toString();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      notifications.add({"title": title, "body": body, "timestamp": timestamp,});
      prefs.setStringList('notifications', notifications.map((notification) => "${notification['title']}:${notification['body']}:${notification['timestamp']}").toList());
      setState(() {});
    }
  }
  @override
  Widget build(BuildContext context) {


    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => _buildHarryController()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
        //// New provider
      ],
      builder: (context, _) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp.router(
              routerConfig: router,
              //navigatorKey: navigatorKey, // Assign the navigatorKey to the MaterialApp
              debugShowCheckedModeBanner: false,
              // themeMode: themeProvider.themeMode == ThemeModeOptions.light
              //     ? ThemeMode.light
              //     : ThemeMode.dark,
              themeMode: ThemeMode.light,
              theme: lightTheme,
              //darkTheme: darkTheme,
              // Harry floats above every routed screen and survives
              // navigation. HarryRoot wraps it in its own Overlay so tooltips
              // and the chat TextField's selection toolbar work (the app's own
              // Overlay is inside `child`, not above this builder).
              builder: (context, child) => Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  const Positioned.fill(child: HarryRoot()),
                ],
              ),

         // home: LandingPage2(),
         // home: StructureLAstMinute(),
          //home: CookFigures(),

            //home: PastNavigationPage(eventName: 'CIO 100', eventID: 21,)

            );
          },
        );
      },
    );
  }
}

