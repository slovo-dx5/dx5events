import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

import '../initialScreen.dart';
import '../widgets/cio_bottomsheets.dart';
import '../widgets/landingPageWidget.dart';
import 'authScreens/cisoLogin.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return  SafeArea(
      child:  Scaffold(
        backgroundColor: Colors.grey,
        body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            const Text("Welcome to dx5 EVENTS"),
            const Text("PICK AN EVENT"),

             CurvedImageContainer(imagePath: 'assets/images/themes/ciso.png',  dayMonth: 'WED, MARCH', date: '20th', endDate: '21st', endDayMonth: 'THUR, MARCH', location: 'KENYA', onPressedFunct: (){
               PersistentNavBarNavigator.pushNewScreen(
                 context,
                 screen: InitialScreen(followingScreen: CISOLogin(),),
                 withNavBar: false,
                 pageTransitionAnimation: PageTransitionAnimation.slideRight,
               );
             },),
            verticalSpace(height: 10),
             CurvedImageContainer(imagePath: 'assets/images/themes/cloudsecurity.png',  dayMonth: 'THUR, APR', date: '25th', endDate: '26th', endDayMonth: 'FRI, APR', location: 'NIGERIA', onPressedFunct: (){
                defaultScrollableBottomSheet(context,"Cloud and Security Summit",PendingEventBottomSheet(imagePath: 'assets/images/themes/cloudsecurity.png', month: 4, date: 25, onPressedFunction: () {  },));
             },),verticalSpace(height: 10),
              CurvedImageContainer(imagePath: 'assets/images/themes/smartbanking.png',  dayMonth: 'WED, MAY', date: '22nd', endDate: '23rd', endDayMonth: 'THUR, MAY', location: 'KENYA', onPressedFunct: (){
                defaultScrollableBottomSheet(context,"SMART BANKING",PendingEventBottomSheet(imagePath: 'assets/images/themes/smartbanking.png', month: 5, date: 22, onPressedFunction: () {  },));},),verticalSpace(height: 10),
             CurvedImageContainer(imagePath: 'assets/images/themes/smarthealth.png',  dayMonth: 'FRI, JUN', date: '28th', endDate: '29th', endDayMonth: 'SAT, JUN', location: 'SOUTH AFRICA', onPressedFunct: (){
               defaultScrollableBottomSheet(context,"SMART HEALTH",PendingEventBottomSheet(imagePath: 'assets/images/themes/smarthealth.png', month: 6, date: 28, onPressedFunction: () {  },));},),verticalSpace(height: 10),

            CurvedImageContainer(imagePath: 'assets/images/themes/smartgov.png',  dayMonth: 'WED, JUL', date: '24th', endDate: '25th', endDayMonth: 'THUR, JUL', location: 'KENYA', onPressedFunct: (){
    defaultScrollableBottomSheet(context,"SMART GOV",PendingEventBottomSheet(imagePath: 'assets/images/themes/smartgov.png', month: 7, date: 24, onPressedFunction: () {  },));},),verticalSpace(height: 10),


              CurvedImageContainer(imagePath: 'assets/images/themes/smartbanking.png',  dayMonth: 'THUR, AUG', date: '22nd', endDate: '23rd', endDayMonth: 'FRI, AUG', location: 'NIGERIA', onPressedFunct: (){
                defaultScrollableBottomSheet(context,"SMART BANKING",PendingEventBottomSheet(imagePath: 'assets/images/themes/smartbanking.png', month: 8, date: 22, onPressedFunction: () {  },));},),verticalSpace(height: 10),

              CurvedImageContainer(imagePath: 'assets/images/themes/smarthealth.png',  dayMonth: 'WES, SEP', date: '25th', endDate: '26th', endDayMonth: 'THUR, SEP', location: 'KENYA', onPressedFunct: (){
                defaultScrollableBottomSheet(context,"SMART HEALTH",PendingEventBottomSheet(imagePath: 'assets/images/themes/smarthealth.png', month: 9, date: 25, onPressedFunction: () {  },));},),verticalSpace(height: 10),

              CurvedImageContainer(imagePath: 'assets/images/themes/smartenterprise.png',  dayMonth: 'WED, SEP', date: '11TH', endDate: '13TH', endDayMonth: 'FRI, SEP', location: 'SOUTH AFRICA', onPressedFunct: (){

                defaultScrollableBottomSheet(context,"SMART ENTERPRISE",PendingEventBottomSheet(imagePath: 'assets/images/themes/smartenterprise.png', month: 9, date: 11, onPressedFunction: () {  },));},),verticalSpace(height: 10),

              CurvedImageContainer(imagePath: 'assets/images/themes/cio100.png',  dayMonth: 'WED, NOV', date: '20TH', endDate: '22ND', endDayMonth: 'FRI, NOV', location: 'KENYA', onPressedFunct: (){

                defaultScrollableBottomSheet(context,"CIO100",PendingEventBottomSheet(imagePath: 'assets/images/themes/cio100.png', month: 10, date: 20, onPressedFunction: () {  },));},),verticalSpace(height: 10),


          ],),
        ),
      ),),
    );
  }
}
