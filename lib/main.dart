import 'package:dx5veevents/providers.dart';
import 'package:dx5veevents/providers/themeProvider.dart';
import 'package:dx5veevents/screens/authScreens/eventLogin.dart';
import 'package:dx5veevents/screens/doLastMinuteShyet.dart';
import 'package:dx5veevents/screens/landingPage2.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:provider/provider.dart';

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
  await NotificationSetup().getIOSPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode == ThemeModeOptions.light
                  ? ThemeMode.light
                  : ThemeMode.dark,
              theme: lightTheme,
              darkTheme: darkTheme,
             home: LandingPage2()
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

