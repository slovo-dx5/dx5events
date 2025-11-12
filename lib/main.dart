import 'package:dx5veevents/constants.dart';

import 'package:dx5veevents/providers.dart';
import 'package:dx5veevents/providers/themeProvider.dart';
import 'package:dx5veevents/screens/dx5veScreens/notificationsScreen.dart';

import 'package:dx5veevents/screens/landingPage2.dart';
import 'package:dx5veevents/screens/test.dart';
import 'package:dx5veevents/test.dart';
import 'package:dx5veevents/testScreen.dart';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'helpers/themeData.dart';
import 'homeScreen.dart';
import 'meetings/meeting_tabs.dart';
import 'notifications/pushNotifications.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message ) async {
  final NotificationSetup _notificationSetup=NotificationSetup();
  _notificationSetup.configurePushNotifications();
  // _notificationSetup.eventListenerCallback();
  print("Handling a background message: $message");
}
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
     builder: (context, state) =>  LandingPage2(),
     //builder: (context, state) =>  MapScreenTest(),
    //builder: (context, state) =>  ContactSaveTest(),
     //builder: (context, state) =>  StructureLAstMinute(),
     //builder: (context, state) =>  ExamplePage(),
  //  builder: (context, state) =>  MapScreen(),
      //builder: (context, state) =>  ProfileScreen(),
    ),
    GoRoute(
      path: '/meetings',
      //builder: (context, state) => MainNavigationPage(initialTabIndex: 2),
      builder: (context, state) => MeetingTabs(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => NotificationsScreen(),
    ),
    GoRoute(
      path: '/test-contact',
      builder: (context, state) => ContactSaveTest(),
    ),
    // GoRoute(
    //   path: '/meetings/:id',
    //   builder: (context, state) {
    //     final meetingId = state.pathParameters['id'];
    //     return MeetingsDetailScreen(meetingId: meetingId);
    //   },
    // ),
  ],
);
void main() async{
  WidgetsFlutterBinding.ensureInitialized();


  try {
    await Firebase.initializeApp(
      // name: "dx5ve_events",
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  Get.put<MyDrawerController>(MyDrawerController());

  if(Platform.isAndroid){
    await FirebaseMessaging.instance.subscribeToTopic("CIO1002025Broadcast");
    //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }else if(Platform.isIOS){
    try{ await NotificationSetup().getIOSPermission();
    await FirebaseMessaging.instance.getAPNSToken();

    await FirebaseMessaging.instance.getAPNSToken().then((value)async{
      await FirebaseMessaging.instance.subscribeToTopic("connectedAfricaBroadcast");
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
      _storeNotification(message.notification!.title, message.notification!.body);
    });

    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationClick(message.data);
        _storeNotification(message.notification!.title, message.notification!.body);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _storeNotification(message.notification!.title, message.notification!.body);
      }
    });
  }catch(e){
    print("firebase messaging config error $e");
  }
}else{
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationClick(message.data);
    _storeNotification(message.notification!.title, message.notification!.body);
  });

  _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      _handleNotificationClick(message.data);
      _storeNotification(message.notification!.title, message.notification!.body);
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      _storeNotification(message.notification!.title, message.notification!.body);
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

  void _handleNotificationClick(Map<String, dynamic> data)async {
    String? targetPage = data['targetPage'];
    bool isAuthenticated=false;
    await getBoolPref("isAuthenticated").then((value) {
      setState(() {
        isAuthenticated=value;
        print("auth status is $value");
      });
    });
    if (targetPage == 'notifications' && isAuthenticated==true) {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => LandingPage2()));
    }else{
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => LandingPage2()));
    }
  }

  Future<void> _storeNotification(String? title, String? body) async {
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

