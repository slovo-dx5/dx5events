import 'dart:developer';

import 'package:dx5veevents/profile_screen.dart';
import 'package:dx5veevents/screens/chats/all_chats.dart';
import 'package:dx5veevents/screens/dx5ve_social/social_feed.dart';
import 'package:dx5veevents/screens/pastEvents/pastPresentationsScreen.dart';
import 'package:dx5veevents/screens/pastEvents/pastSponsorsScreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../constants.dart';

import '../../gallery_screen.dart';



class PastNavigationPage extends StatefulWidget {
  String eventName;
  int eventID;



  PastNavigationPage({Key? key,required this.eventName, required this.eventID}) : super(key: key);


  @override
  _PastNavigationPageState createState() => _PastNavigationPageState();
}


class _PastNavigationPageState extends State<PastNavigationPage> {
  late DateTime currentBackPressTime;
  bool hasReviewedApp = false;
  int ?currentUID;

  PersistentTabController? controller;
  TextStyle style = const TextStyle(fontSize: 12, fontWeight: FontWeight.bold);

  @override
  void initState() {
    super.initState();
    currentBackPressTime = DateTime.now();
    controller = PersistentTabController(initialIndex: 0);
  }



  List<Widget> _buildScreens() {
    return [
     // PastPresentationsScreen(eventName: widget.eventName, eventID: widget.eventID,),
      SocialFeed(),
      PastSponsorsScreen(),
      GalleryScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<PersistentBottomNavBarItem> _navBarsItems() {
      return [
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.present_to_all),
          title: "Presentations",
          //  textStyle: style,
          activeColorPrimary: kPrimaryColor,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.inbox),
          title: "Gallery",
          //  textStyle: style,
          activeColorPrimary: kPrimaryColor,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.meeting_room),
          title: "Sponsors",
          //  textStyle: style,
          activeColorPrimary: kPrimaryColor,
          inactiveColorPrimary: Colors.grey,
        ),

        // PersistentBottomNavBarItem(
        //   icon: const Icon(Icons.perm_media),
        //   title: "Social",
        //   //  textStyle: style,
        //   activeColorPrimary: kPrimaryColor,
        //   inactiveColorPrimary: Colors.grey,
        // ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.mediation_outlined),
          title: ("Social"),
          //   textStyle: style,
          activeColorPrimary: kPrimaryColor,
          inactiveColorPrimary: Colors.grey,
          routeAndNavigatorSettings: RouteAndNavigatorSettings(
            initialRoute: '/',
            routes: {
            //  '/first': (context) => PastPresentationsScreen(eventName: widget.eventName,
            //    eventID: widget.eventID,),
              '/second': (context) => SocialFeed(),
              '/third': (context) => const PastSponsorsScreen(),
              '/fourth': (context) =>  GalleryScreen(),
            },
          ),
        ),
        // PersistentBottomNavBarItem(icon: Icon(Icons.add))
      ];
    }

    return Scaffold(
      body: PersistentTabView(
        context,
        controller: controller,
        screens: _buildScreens(),
        items: _navBarsItems(),
        confineToSafeArea: true,
        backgroundColor: kLightAppbar, // Default is Colors.white.
        handleAndroidBackButtonPress: true, // Default is true.
        resizeToAvoidBottomInset:
        true, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
        stateManagement: true, // Default is true.
        hideNavigationBarWhenKeyboardAppears:
        true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
        decoration: NavBarDecoration(
          borderRadius: BorderRadius.circular(10.0),
          //colorBehindNavBar: Colors.white,
        ),
        popBehaviorOnSelectedNavBarItemPress: PopBehavior.all,

        navBarStyle:
        NavBarStyle.style6, // Choose the nav bar style with this property.
      )
    );

  }
}
