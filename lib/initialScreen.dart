
import 'package:dx5veevents/splashScreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mainNavigationPage.dart';


///This screen uses shared pref to check if user had previously signed in then redirects them accordingly
class InitialScreen extends StatefulWidget {

  Widget followingScreen;final String coverImagePath ;
  final String eventLocation ;
  final String eventHappeningDates ;
  final String eventName ;
  final String eventDayOfWeek ;
  final String shortEventDescription ;
  final String eventID ; int eventDay;bool isCustomerEvent;
  int eventMonth;
  int eventYear;
   InitialScreen({  required this.eventDay,
     required this.eventMonth,required this.isCustomerEvent,
     required this.eventYear,required this.followingScreen,required this.eventDayOfWeek,required this.coverImagePath,required this.eventID, required this.eventName,required this.shortEventDescription,required this.eventHappeningDates, required this.eventLocation,super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {


  @override
  void initState() {
    // TODO: implement initState


   checkIfHasSignedIn();

    super.initState();
  }



  checkIfHasSignedIn()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    int initialValue=prefs.getInt("isFirstTime")??0;

    if(initialValue==1){
      if(mounted){
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainNavigationPage(eventDay: widget.eventDay, eventMonth: widget.eventMonth, eventYear: widget.eventYear,coverImagePath: widget.coverImagePath, eventName: widget.eventName,
            //eventDate: 'THUR, MAY, 2nd - FRIDAY MAY 3rd',
            eventDate: widget.eventHappeningDates,
            //shortEventDescription: 'The Africa Cloud and Cybersecurity Summit is a pivotal event, addressing the accelerating growth of cloud computing and the critical importance of cybersecurity in the African region.',
            shortEventDescription: widget.shortEventDescription,
            //eventLocation: 'Nigeria',);
            eventLocation: widget.eventLocation, eventID: widget.eventID, eventDayOfWeek: widget.eventDayOfWeek, isCustomerEvent: widget.isCustomerEvent,)),
        );

      }
    }else if(initialValue==0){
      if(mounted){
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen:widget.followingScreen,
          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.slideRight,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
