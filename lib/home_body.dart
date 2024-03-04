import 'dart:io';

import 'package:dx5veevents/screens/cisoScreens/cisoAgendaScreen.dart';
import 'package:dx5veevents/screens/cisoScreens/cisoAttendeesScreen.dart';
import 'package:dx5veevents/screens/cisoScreens/cisoSpeakersScreen.dart';
import 'package:dx5veevents/screens/cisoScreens/ciso_sessions_screen.dart';
import 'package:dx5veevents/widgets/cio_widgets.dart';
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

    return UpgradeAlert(
      upgrader: Upgrader(
          dialogStyle: Platform.isAndroid
              ? UpgradeDialogStyle.material
              : UpgradeDialogStyle.cupertino,
          showIgnore: false,
          durationUntilAlertAgain: const Duration(hours: 1)),
      child: Scaffold(
          body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Image.asset(
                  "assets/images/themes/ciso.png",
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.3,
                  fit: BoxFit.cover,
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(15.0, 15, 15, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month),
                  horizontalSpace(width: 5),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Start",
                        style: TextStyle(fontSize: 10),
                      ),
                      Text(
                        "March 20",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    ],
                  ),
                  horizontalSpace(width: 10),
                  const SizedBox(
                    width: 40,
                    child: Divider(
                      thickness: 1.5,
                    ),
                  ),
                  horizontalSpace(width: 15),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("End",
                          style: TextStyle(
                            fontSize: 10,
                          )),
                      Text(
                        "March 21",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    ],
                  ),
                  horizontalSpace(width: 20),
                ],
              ),
            ),
            Divider(color: kCIOPink),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                CIOWidgets().gradientItemWidget(
                  firstColor: kCISOOrange,
                  secondColor: kCISOLightOrange,
                  context: context,
                  editIcon: Image.asset(
                    "assets/icons/speaker.png",
                    width: 10,
                    height: 10,
                  ),
                  screen: CisoSpeakersScreen(),
                  itemName: 'Speakers',
                ),
                CIOWidgets().gradientItemWidget(
                  firstColor: kCISOTeal.withOpacity(0.7),
                  secondColor: kCISOBlue.withOpacity(0.7),
                  context: context,
                  editIcon: Image.asset(
                    "assets/icons/sponsors.png",
                    width: 10,
                    height: 10,
                  ),
                  screen: CISOAgendaScreen(),
                  itemName: 'Sponsors',
                ),
                CIOWidgets().gradientItemWidget(
                  firstColor: kCISOYellow.withOpacity(0.7),
                  secondColor: kCISOGreenYellow.withOpacity(0.7),
                  context: context,
                  editIcon: Image.asset(
                    "assets/icons/agenda.png",
                    width: 10,
                    height: 10,
                  ),
                  screen: CISOAgendaScreen(),
                  itemName: 'Agenda',
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CIOWidgets().gradientItemWidget(
                  firstColor: kCISOTeal,
                  secondColor: kCISOPurple,
                  context: context,
                  editIcon: Image.asset(
                    "assets/icons/attendee.png",
                    width: 10,
                    height: 10,
                  ),
                  screen: AttendeesScreen(),
                  itemName: 'Attendees',
                ),
                CIOWidgets().gradientItemWidget(
                  firstColor: kCISOOrange,
                  secondColor: kCISOPurple,
                  context: context,
                  editIcon: Image.asset(
                    "assets/icons/exhibitors.png",
                    width: 10,
                    height: 10,
                  ),
                  screen: CISOAgendaScreen(),
                  itemName: 'Partners',
                ),
                CIOWidgets().gradientItemWidget(
                  firstColor: kCISOPink.withOpacity(0.9),
                  secondColor: kCISOPurple.withOpacity(0.9),
                  context: context,
                  editIcon: Image.asset(
                    "assets/icons/sessions.png",
                    width: 10,
                    height: 10,
                  ),
                  screen: UserSessionsScreen(userid: profileProvider.userID!,),
                  itemName: 'My Sessions',
                ),
              ],
            ),
            verticalSpace(height: 15),
            SizedBox(
                height: 100,
                width: MediaQuery.of(context).size.width,
                child: HorizontalCardScroll())
          ],
        ),
      )),
    );
  }
}
