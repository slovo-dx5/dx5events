import 'dart:io';

import 'package:dx5veevents/screens/cisoScreens/cisoAgendaScreen.dart';
import 'package:dx5veevents/screens/cisoScreens/cisoAttendeesScreen.dart';
import 'package:dx5veevents/screens/cisoScreens/cisoSpeakersScreen.dart';
import 'package:dx5veevents/screens/cisoScreens/ciso_partners_screen.dart';
import 'package:dx5veevents/screens/cisoScreens/ciso_sessions_screen.dart';
import 'package:dx5veevents/screens/cisoScreens/ciso_sponsors_screens.dart';
import 'package:dx5veevents/widgets/cio_widgets.dart';
import 'package:dx5veevents/widgets/homePageWidget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:upgrader/upgrader.dart';

import '../helpers/helper_widgets.dart';
import '../providers.dart';
import 'constants.dart';

class HomeBody extends StatefulWidget {

  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final GlobalKey _one = GlobalKey();
  GlobalKey _two = GlobalKey();
  GlobalKey _three = GlobalKey();
  GlobalKey _four = GlobalKey();
  bool isFirstTime = true;
  void checkFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isFirstTime = prefs.getBool('isFirstTimeHome') ?? true;

    if (isFirstTime) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ShowCaseWidget.of(context).startShowCase([
                _one,
                _two,
                _three,
                _four,
              ]));
      await prefs.setBool('isFirstTimeHome', false);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    checkFirstTime();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return HomePageWidget(coverImagepath: 'assets/images/themes/cloudsecurity.png', eventName: 'Cloud and Security Summit', eventDate: 'THUR, MAY, 2nd - FRIDAY MAY 3rd', shortEventDescription: 'The Africa Cloud and Cybersecurity Summit is a pivotal event, addressing the accelerating growth of cloud computing and the critical importance of cybersecurity in the African region.', eventLocation: 'Nigeria',);
  }
}
