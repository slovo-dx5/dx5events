import 'package:dx5veevents/providers.dart';
import 'package:dx5veevents/screens/landingPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'homeScreen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  Get.put<MyDrawerController>(MyDrawerController());
  await Firebase.initializeApp(

    options: DefaultFirebaseOptions.currentPlatform,

  );
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
        //// New provider
      ],
      builder: (context, _) {
        return const MaterialApp(
          debugShowCheckedModeBanner: false,

          home: LandingPage(),
          // home: ProfilePicScreen(),
          //home: InterestsScreen(),
        );
      },
    );
  }
}

