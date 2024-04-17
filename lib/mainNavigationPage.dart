import 'dart:developer';

import 'package:dx5veevents/profile_screen.dart';
import 'package:dx5veevents/screens/chats/all_chats.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../constants.dart';

import 'gallery_screen.dart';
import 'homeScreen.dart';
import 'meetings/meeting_tabs.dart';
import 'meetings/meeting_tabs.dart';

_MainNavigationPageState mainNavigationPageState = _MainNavigationPageState();

class MainNavigationPage extends StatefulWidget {
  static String routeName = "/main_page";
  final String coverImagePath ;
  final String eventLocation ;
  final String eventDate ;
  final String eventName ;
  final String eventID ;
  final String shortEventDescription ; int eventDay;
  int eventMonth;
  int eventYear;

  MainNavigationPage({Key? key,  required this.eventDay,
    required this.eventMonth,
    required this.eventYear,required this.coverImagePath,required this.eventID, required this.eventName,required this.shortEventDescription,required this.eventDate, required this.eventLocation}) : super(key: key);

  @override
  _MainNavigationPageState createState() {
    mainNavigationPageState = _MainNavigationPageState();
    return mainNavigationPageState;
  }
}

class _MainNavigationPageState extends State<MainNavigationPage> {
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
    getFirebaseMessagingToken();
  }

  updateUserInFirestore({required String token}) async {
    await  getIntPref( kUserID).then((value) {
      setState(() {
        print("user id is $value");
        currentUID=value;
      });
    });
    try {

      await usersRef.doc(currentUID.toString()).update({
        "messaging_token": token,


      });
      ///create meetings collection


    } catch (e) {}
  }

  getFirebaseMessagingToken()async{
    await FirebaseMessaging.instance.requestPermission();
    print("getting tokennnnn");
    if (Platform.isIOS){
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      print("apns token is $apnsToken");
      if(apnsToken !=null){
        try{final String? token=await FirebaseMessaging.instance.getToken().then((receivedToken) {
          print("ios firebase token is: $receivedToken");
          updateUserInFirestore(token: receivedToken??"");
        });
        print("user token updated");
        print("ios firebase token is: $token");}catch(e){
          print("get token error is $e");
        }
      }
    }else{
      try{final String? token=await FirebaseMessaging.instance.getToken().then((receivedToken) {
        debugPrint("firebase token is: $receivedToken");
        updateUserInFirestore(token: receivedToken??"");
      });
      print("user token updated");
      debugPrint("firebase token is: $token");}catch(e){
        print("get token error is $e");
      }
    }


  }

  List<Widget> _buildScreens() {
    return [
      HomeScreen(  eventDay: widget.eventDay, eventMonth: widget.eventMonth, eventYear: widget.eventYear,coverImagePath: widget.coverImagePath, eventName: widget.eventName,
        //eventDate: 'THUR, MAY, 2nd - FRIDAY MAY 3rd',
        eventDate: widget.eventDate,
        //shortEventDescription: 'The Africa Cloud and Cybersecurity Summit is a pivotal event, addressing the accelerating growth of cloud computing and the critical importance of cybersecurity in the African region.',
        shortEventDescription: widget.shortEventDescription,
        //eventLocation: 'Nigeria',);
        eventLocation: widget.eventLocation, eventID: widget.eventID,),
      AllChatsScreen(),
      MeetingTabs(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<PersistentBottomNavBarItem> _navBarsItems() {
      return [
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.video_settings),
          title: "Home",
          //  textStyle: style,
          activeColorPrimary: kPrimaryColor,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.inbox),
          title: "Inbox",
          //  textStyle: style,
          activeColorPrimary: kPrimaryColor,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.meeting_room),
          title: "Meetings",
          //  textStyle: style,
          activeColorPrimary: kPrimaryColor,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.person),
          title: ("Profile"),
          //   textStyle: style,
          activeColorPrimary: kPrimaryColor,
          inactiveColorPrimary: Colors.grey,
          routeAndNavigatorSettings: RouteAndNavigatorSettings(
            initialRoute: '/',
            routes: {
              '/first': (context) => HomeScreen(eventDay: widget.eventDay, eventMonth: widget.eventMonth, eventYear: widget.eventYear,coverImagePath: widget.coverImagePath, eventName: widget.eventName,
                //eventDate: 'THUR, MAY, 2nd - FRIDAY MAY 3rd',
                eventDate: widget.eventDate,
                //shortEventDescription: 'The Africa Cloud and Cybersecurity Summit is a pivotal event, addressing the accelerating growth of cloud computing and the critical importance of cybersecurity in the African region.',
                shortEventDescription: widget.shortEventDescription,
                //eventLocation: 'Nigeria',);
                eventLocation: widget.eventLocation, eventID: widget.eventID,),
              '/second': (context) => MeetingTabs(),
              '/third': (context) => const GalleryScreen(),
              '/fourth': (context) => const ProfileScreen(),
            },
          ),
        ),
        // PersistentBottomNavBarItem(icon: Icon(Icons.add))
      ];
    }

    return Scaffold(
      body: ShowCaseWidget(
        onStart: (index, key) {},
        onComplete: (index, key){},
        blurValue: 1,
        builder: Builder(builder: (context)=> PersistentTabView(
          context,
          controller: controller,
          screens: _buildScreens(),
          items: _navBarsItems(),
          confineInSafeArea: true,
          backgroundColor: kLightAppbar, // Default is Colors.white.
          handleAndroidBackButtonPress: true, // Default is true.
          resizeToAvoidBottomInset:
          true, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
          stateManagement: true, // Default is true.
          hideNavigationBarWhenKeyboardShows:
          true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
          decoration: NavBarDecoration(
            borderRadius: BorderRadius.circular(10.0),
            //colorBehindNavBar: Colors.white,
          ),
          popAllScreensOnTapOfSelectedTab: true,
          popActionScreens: PopActionScreensType.all,
          itemAnimationProperties: const ItemAnimationProperties(
            // Navigation Bar's items animation properties.
            duration: Duration(milliseconds: 200),
            curve: Curves.ease,
          ),
          screenTransitionAnimation: const ScreenTransitionAnimation(
            // Screen transition animation on change of selected tab.
            animateTabTransition: true,
            curve: Curves.ease,
            duration: Duration(milliseconds: 200),
          ),
          navBarStyle:
          NavBarStyle.style6, // Choose the nav bar style with this property.
        ),),
      ),
    );

  }
}
