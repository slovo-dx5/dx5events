
import 'package:dx5veevents/splashScreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:shared_preferences/shared_preferences.dart';


///This screen uses shared pref to check if user had previously signed in then redirects them accordingly
class InitialScreen extends StatefulWidget {

  Widget followingScreen;
   InitialScreen({required this.followingScreen,super.key});

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
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: SplashScreen(),
          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.slideRight,
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
