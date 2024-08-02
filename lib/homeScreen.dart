
import 'package:dx5veevents/providers.dart';
import 'package:dx5veevents/providers/themeProvider.dart';
import 'package:dx5veevents/screens/getContact.dart';
import 'package:dx5veevents/screens/landingPage2.dart';
import 'package:dx5veevents/widgets/checkin_widget.dart';
import 'package:dx5veevents/widgets/notifications_widget.dart';
import 'package:dx5veevents/widgets/qr_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';

import '../constants.dart';
import '../helpers/helper_functions.dart';
import '../helpers/helper_widgets.dart';

import '../widgets/profile_initials_widget.dart';
import 'home_body.dart';
import 'dart:io';



class HomeScreen extends GetView<MyDrawerController> {
  static String routeName = "/home";
  final String coverImagePath ;
  final String eventLocation ;
  final String eventDayOfWeek ;
  final String eventDate ;
  final String eventName ;
  final String shortEventDescription ;
  final String eventID ;final int eventDay;
  final int eventMonth;
  final int eventYear;
  final bool isCustomerEvent;


   const HomeScreen({Key? key,   required this.eventDay,
     required this.eventMonth,required this.isCustomerEvent,
     required this.eventYear,required this.coverImagePath,required this.eventDayOfWeek,required this.eventID, required this.eventLocation, required this.eventName, required this.eventDate,required this.shortEventDescription}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return GetBuilder<MyDrawerController>(
      builder: (_) => ZoomDrawer(
        controller: _.zoomDrawerController,
        menuScreen: MenuScreen(),
        mainScreen: MainScreen(controller: controller, coverImagePath: coverImagePath, eventLocation: eventLocation, eventName: eventName, eventDate: eventDate, 
          shortEventDescription: shortEventDescription, eventID: eventID, eventDay: eventDay, eventMonth: eventMonth, eventYear: eventYear, eventDayOfWeek: eventDayOfWeek, isCustomerEvent: isCustomerEvent,),
        androidCloseOnBackTap: true,
        borderRadius: 24.0,
        showShadow: true,
        mainScreenTapClose: true,
        angle: 0.0,
        slideWidth: MediaQuery.of(context).size.width * 0.65,
        moveMenuScreen: false,
        mainScreenScale: 0.2,
        style: DrawerStyle.defaultStyle,
        shadowLayer1Color: kCIOPurple.withOpacity(0.5),
        shadowLayer2Color: kPrimaryColor.withOpacity(0.8),
        menuBackgroundColor: kCIOPink.withOpacity(0.4),
      ),
    );
  }
}

class MainScreen extends GetView<MyDrawerController> {
  String coverImagePath;
  String eventName;
  String eventDate;
  String eventDayOfWeek;
  String shortEventDescription;
  String eventLocation;
  String eventID; int eventDay;
  int eventMonth;
  int eventYear;
  bool isCustomerEvent;
   MainScreen({
    Key? key,
    required this.controller,  required this.eventDay,
     required this.eventMonth,required this.isCustomerEvent,
     required this.eventYear,required this.coverImagePath, required this.eventID,required this.eventLocation, required this.eventName, required this.eventDate,required this.eventDayOfWeek,required this.shortEventDescription
  }) : super(key: key);

  final MyDrawerController controller;
 //pre relese



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: controller.toggleDrawer,
          child: const Icon(
            Icons.menu,size: 40,
          ),
        ) ,
        backgroundColor: kCIOPurple.withOpacity(0.5),centerTitle: true,
        title:  Text("DX5VE EVENTS",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600),),
        actions: [NotificationIconButton()],
        // actions:  [Icon(Icons.notification_important_rounded,color: kTextColorBlackLighter,)],
      ),
      body:  HomeBody(eventDay: eventDay, eventMonth: eventMonth, eventYear: eventYear,coverImagePath: coverImagePath, eventName: eventName, shortEventDescription: shortEventDescription, eventDate: eventDate, eventLocation: eventLocation, eventID: eventID, eventDayOfWeek: eventDayOfWeek, isCustomerEvent: isCustomerEvent,),
    );
  }
}


class MenuScreen extends GetView<MyDrawerController> {
  MenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildMenu(context);
  }

  Widget buildMenu(context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return UpgradeAlert(
      upgrader: Upgrader(
          // dialogStyle: Platform.isAndroid
          //     ? UpgradeDialogStyle.material
          //     : UpgradeDialogStyle.cupertino,
          // showIgnore: false,
          durationUntilAlertAgain: const Duration(hours: 1)),
      child: Scaffold(backgroundColor: themeProvider.themeMode==ThemeModeOptions.dark?kTextColorBlack:Colors.white54,
        body: SafeArea(
          child: SingleChildScrollView(

            child:  Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ProfileProvider().previewImage(
                      //     context: context,
                      //     radius: 22.0,
                      //     avatarRadius: 22.0,
                      //     fontSize: 12.0),
                      if(profileProvider.profileId==null||profileProvider.profileId=="")const ProfileInitials(),
                      if(profileProvider.profileId!=null&&profileProvider.profileId!="")const ProfilePicWidget(),
                      const SizedBox(height: 16.0),
                      greetingFunc(firstName: profileProvider.firstName),
                      const Divider(),
                      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children: [const Text("Dark mode",
                      //  style: settingsTextStyle(),
                      ),Switch(
                        inactiveTrackColor: kWhiteText,
                        value: themeProvider.themeMode == ThemeModeOptions.dark,
                        onChanged: (value) {
                          final newTheme = value ? ThemeModeOptions.dark : ThemeModeOptions.light;
                          themeProvider.setThemeMode(newTheme);
                        }
                      ),],),
                      menuItem(menuText: 'Scan QR',
                          widgetIcon: Icons.qr_code_2, iconColor: kCIOPink, onPressedFunction: () {

                              PersistentNavBarNavigator.pushNewScreen(
                                context,
                                screen: SponsorScanner(
                                  firstName: profileProvider.firstName,
                                  phone: profileProvider.phone,
                                  lastName: profileProvider.lastName,
                                  company: profileProvider.company,
                                  position: profileProvider.role,
                                  email: profileProvider.email,),
                                withNavBar: false,
                                pageTransitionAnimation: PageTransitionAnimation.slideRight,
                              );

                          }),


                      // menuItem(menuText: "Logout", widgetIcon: Icons.logout, iconColor: kKeyRedBG, onPressedFunction: (){
                      //   logOut(context);
                      // }),

                      const CheckInWidget(),

                      menuItem(menuText: 'Events Menu',
                          widgetIcon: Icons.qr_code_2, iconColor: kCIOPink, onPressedFunction: () {

                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen:  LandingPage2(
                            ),
                              withNavBar: false,
                              pageTransitionAnimation: PageTransitionAnimation.slideRight,
                            );

                          }),

                      menuItem(menuText: 'Get Contact',
                          widgetIcon: Icons.contacts, iconColor: kCIOPink, onPressedFunction: () {

                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: GetContact(
                               ),
                              withNavBar: false,
                              pageTransitionAnimation: PageTransitionAnimation.slideRight,
                            );

                          }),

                      verticalSpace(height: 30),

                      menuItem(menuText: 'Need an app?',
                          widgetIcon: Icons.touch_app, iconColor: kCIOPink, onPressedFunction: () {

                            launchMailClient(emailAddress: 'dev@dx5ve.com', subject: 'APP DEVELOPMENT PROPOSAL', body: '');

                          }),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyDrawerController extends GetxController {
  final zoomDrawerController = ZoomDrawerController();

  void toggleDrawer() {
    zoomDrawerController.toggle?.call();
  }
}
