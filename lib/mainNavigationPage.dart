import 'dart:developer';

import 'package:dx5veevents/screens/dx5veScreens/profile_screen.dart';
import 'package:dx5veevents/screens/chats/all_chats.dart';
import 'package:dx5veevents/screens/dx5ve_social/social_feed.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'dart:io';


import '../../constants.dart';
import 'dioServices/dioFetchService.dart';
import 'models/sponsor_contact_model.dart';

import 'gallery_screen.dart';
import 'homeScreen.dart';
import 'meetings/meeting_tabs.dart';

_MainNavigationPageState mainNavigationPageState = _MainNavigationPageState();

class MainNavigationPage extends StatefulWidget {
  static String routeName = "/main_page";
  final String? coverImagePath ;
  final String? eventLocation ;
  final String? eventDate ;
  final String? eventDayOfWeek ;
  final String? eventName ;
  final String? eventID ;
  final String? shortEventDescription ; int ?eventDay;
  int? eventMonth;
  final int initialTabIndex;
  int? eventYear;bool? isCustomerEvent;


  MainNavigationPage({Key? key,   this.eventDay,
     this.eventMonth, this.isCustomerEvent,this.initialTabIndex=0,
     this.eventYear, this.coverImagePath, this.eventID, this.eventDayOfWeek,  this.eventName, this.shortEventDescription, this.eventDate,  this.eventLocation}) : super(key: key);

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
  String sponsorPhoneNumber = "";

  PersistentTabController? controller;
  TextStyle style = const TextStyle(fontSize: 12, fontWeight: FontWeight.bold);

  @override
  void initState() {
    super.initState();
    currentBackPressTime = DateTime.now();

    getFirebaseMessagingToken();
    fetchAndStoreSponsorPhone();
  }

  fetchAndStoreSponsorPhone() async {
    try {
      DioFetchService dioFetchService = DioFetchService();
      final response = await dioFetchService.fetchAppSponsor();

      if (response.data != null && response.data['data'] != null && response.data['data'].isNotEmpty) {
        final sponsorData = AppSponsorData.fromJson(response.data['data'][0]);
        await setStringPref(key: kSponsorPhone, value: sponsorData.phone_number);
        setState(() {
          sponsorPhoneNumber = sponsorData.phone_number;
        });
        print("Sponsor phone number stored: ${sponsorData.phone_number}");
      }
    } catch (e) {
      print("Error fetching sponsor data: $e");
    }
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
      HomeScreen(  eventDay: widget.eventDay!, eventMonth: widget.eventMonth!, eventYear: widget.eventYear!,coverImagePath: widget.coverImagePath!, eventName: widget.eventName!,
        //eventDate: 'THUR, MAY, 2nd - FRIDAY MAY 3rd',
        eventDate: widget.eventDate!,
        //shortEventDescription: 'The Africa Cloud and Cybersecurity Summit is a pivotal event, addressing the accelerating growth of cloud computing and the critical importance of cybersecurity in the African region.',
        shortEventDescription: widget.shortEventDescription!,
        //eventLocation: 'Nigeria',);
        eventLocation: widget.eventLocation!, eventID: widget.eventID!, eventDayOfWeek:widget.eventDayOfWeek!, isCustomerEvent: widget.isCustomerEvent! ,),
      AllChatsScreen(),
      MeetingTabs(),
      //SocialFeed(),
       ProfileScreen(eventId: int.parse(widget.eventID!), ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final controller = PersistentTabController(initialIndex: widget.initialTabIndex);
    List<PersistentBottomNavBarItem> _navBarsItems() {
      return [
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.home),
          title: "Home",
          //  textStyle: style,
          activeColorPrimary: kConnectedBlue,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.inbox),
          title: "Inbox",
          //  textStyle: style,
          activeColorPrimary: kConnectedBlue,
          inactiveColorPrimary: Colors.grey,
        ),
        PersistentBottomNavBarItem(
          icon: const Icon(Icons.meeting_room),
          title: "Meetings",
          //  textStyle: style,
          activeColorPrimary: kConnectedBlue,
          inactiveColorPrimary: Colors.grey,
        ),


        PersistentBottomNavBarItem(
          icon: const Icon(Icons.person),
          title: ("Profile"),
          //   textStyle: style,
          activeColorPrimary: kConnectedBlue,
          inactiveColorPrimary: Colors.grey,
          routeAndNavigatorSettings: RouteAndNavigatorSettings(
            initialRoute: '/',
            routes: {
              '/first': (context) => HomeScreen(eventDay: widget.eventDay!, eventMonth: widget.eventMonth!, eventYear: widget.eventYear!,
                coverImagePath: widget.coverImagePath!, eventName: widget.eventName!,
                //eventDate: 'THUR, MAY, 2nd - FRIDAY MAY 3rd',
                eventDate: widget.eventDate!,
                //shortEventDescription: 'The Africa Cloud and Cybersecurity Summit is a pivotal event, addressing the accelerating growth of cloud computing and the critical importance of cybersecurity in the African region.',
                shortEventDescription: widget.shortEventDescription!,
                //eventLocation: 'Nigeria',);
                eventLocation: widget.eventLocation!, eventID: widget.eventID!, eventDayOfWeek: widget.eventDayOfWeek!, isCustomerEvent: widget.isCustomerEvent!,),
              '/second': (context) => MeetingTabs(),
              '/third': (context) => const GalleryScreen(),
              '/fourth': (context) =>  ProfileScreen(eventId: int.parse(widget.eventID!),),
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

        popBehaviorOnSelectedNavBarItemPress: PopBehavior.all,

        navBarStyle:
        NavBarStyle.style8, // Choose the nav bar style with this property.
      )
    );

  }
}
