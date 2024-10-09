import 'package:dx5veevents/constants.dart';
import 'package:dx5veevents/dioServices/dioPostService.dart';
import 'package:dx5veevents/providers.dart';
import 'package:dx5veevents/providers/themeProvider.dart';
import 'package:dx5veevents/screens/doLastMinuteShyet.dart';
import 'package:dx5veevents/screens/dx5veScreens/notificationsScreen.dart';
import 'package:dx5veevents/screens/dx5veScreens/videoSplash.dart';
import 'package:dx5veevents/screens/landingPage2.dart';
import 'package:dx5veevents/screens/rewardsPage.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'backendOps/sendBroadcast.dart';
import 'firebase_options.dart';
import 'helpers/CustomerAttendeeCSVHelper.dart';
import 'helpers/CustomerSpeakerCSVHelper.dart';
import 'helpers/themeData.dart';
import 'homeScreen.dart';
import 'notifications/pushNotifications.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message ) async {
  final NotificationSetup _notificationSetup=NotificationSetup();
  _notificationSetup.configurePushNotifications();
  // _notificationSetup.eventListenerCallback();
  print("Handling a background message: $message");
}
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  Get.put<MyDrawerController>(MyDrawerController());
  await Firebase.initializeApp(

    options: DefaultFirebaseOptions.currentPlatform,

  );
  if(Platform.isAndroid){
    await FirebaseMessaging.instance.subscribeToTopic("dx5veNewBroadcast");
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }else if(Platform.isIOS){
    try{ await NotificationSetup().getIOSPermission();
    await FirebaseMessaging.instance.getAPNSToken();

    await FirebaseMessaging.instance.getAPNSToken().then((value)async{
      await FirebaseMessaging.instance.subscribeToTopic("dx5veNewBroadcast");
    } );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);}catch(e){
      print(("firebase messaging error is? $e"));
    }
  }

  runApp(const MyApp());
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
    precacheImage(const AssetImage("assets/images/themes/ciso.png"), context);
    precacheImage(const AssetImage("assets/images/themes/cio100.png"), context);
    precacheImage(const AssetImage("assets/images/themes/cloudsecurity.png"), context);
    precacheImage(const AssetImage("assets/images/themes/smartbanking.png"), context);
    precacheImage(const AssetImage("assets/images/themes/smartenterprise.png"), context);
    precacheImage(const AssetImage("assets/images/themes/smartgov.png"), context);
    precacheImage(const AssetImage("assets/images/themes/smarthealth.png"), context);
    precacheImage(const AssetImage("assets/images/logos/cisologo.png"), context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        //// New provider
      ],
      builder: (context, _) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              navigatorKey: navigatorKey, // Assign the navigatorKey to the MaterialApp
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode == ThemeModeOptions.light
                  ? ThemeMode.light
                  : ThemeMode.dark,
              theme: lightTheme,
              darkTheme: darkTheme,
             //home: Platform.isAndroid?VideoSplashScreen():LandingPage2(),
             //home: VideoSplashScreen()
             //home: StructureLAstMinute()
           // home: LandingPage2(),
            home: RewardsPage(),

             //home: AdminPanelHome(adminName: 'Slovo Ulo',)
             //home: GetContact()
            //home: StructureLAstMinute()
            // home: CSVHelper()
             //home: CustomerSpeakerCSVHelper()
            //  home: CISOLogin(coverImagePath: '', eventName: '', shortEventDescription: '', eventDate: '', eventLocation: '',),
            );
          },
        );
      },
    );
  }
}

