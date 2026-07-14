import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../initialScreen.dart';
import '../providers.dart';
import '../providers/harry_controller.dart';
import '../providers/themeProvider.dart';
import '../widgets/cio_bottomsheets.dart';
import '../widgets/landingPageWidget.dart';
import 'authScreens/eventLogin.dart';

class LandingPage2 extends StatefulWidget {
  bool isFromLogout;
  LandingPage2({Key? key, required this.isFromLogout}) : super(key: key);
  @override
  State<LandingPage2> createState() => _LandingPage2State();
}

class _LandingPage2State extends State<LandingPage2> {
//  List<String> items = ["PAST", "ACTIVE", "FUTURE"];
  int current = 1;
@override
  void initState() {
    // TODO: implement initState
    super.initState();
    // The event-selection landing is outside any event — hide Harry here.
    Provider.of<HarryController>(context, listen: false).setInEvent(false);
    if(widget.isFromLogout==true) {
      (
        clearAllPrefs().then((on){
          final provider = Provider.of<ProfileProvider>(context, listen: false);
          // Clear in-memory profile before navigating
          provider.clearProfile();
          // Hide Harry again and clear its chat on logout.
          Provider.of<HarryController>(context, listen: false)
              .setAuthenticated(false);
          debugPrint("Prefs cleared");
        })
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: ActiveEvents()),
    );
  }
}

class ActiveEvents extends StatefulWidget {
  ActiveEvents({Key? key}) : super(key: key);

  @override
  State<ActiveEvents> createState() => _ActiveEventsState();
}

///kdkk
class _ActiveEventsState extends State<ActiveEvents> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        //height: MediaQuery.of(context).size.height * 0.85,
        child: ActiveEventWidget(
          imagePath: 'assets/images/themes/smart_gov_portraitt.jpg',
          dayMonth: 'WED, JUL',
          date: '23rd',
          endDate: '23rd',
          location: 'KENYA',
          endDayMonth: 'WED, JUL',
          onPressedFunct: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => InitialScreen(
                        coverImagePath: 'assets/images/themes/smart_gov_landscape.jpg',
                        eventName: 'SMART GOVERNMENT SUMMIT',
                        //eventHappeningDates: 'WED, JULY, 16TH - THUR, MAY, 29TH',
                        eventHappeningDates: 'WED, JUL, 23RD',
                        shortEventDescription:
                            "Powering Africa's Financial Transformation",
                        eventLocation: 'KENYA',
                        followingScreen: EventLogin(
                          coverImagePath:
                              'WED, JUL, 23rd',
                          eventName: 'SMART GOVERNMENT SUMMIT',
                          eventDate: 'WED, JUl, 23rd',
                          shortEventDescription:
                              "Bridging the gap between advanced digital technologies and government operations",
                          eventLocation: 'KENYA',
                          eventID: '107',
                          eventDay: 23,
                          eventMonth: 07,
                          eventYear: 2026,
                          eventDayOfWeek: 'WED',
                          isCustomerEvent: false,
                        ),
                        eventID: '107',
                    eventDay: 23,
                    eventMonth: 07,
                    eventYear: 2026,
                        eventDayOfWeek: 'WED',
                        isCustomerEvent: false,
                      )),
            );
          },
          eventName: 'SMART GOVERNMENT SUMMIT',
          containerColor: kGradientLightBlue.withValues(alpha: 0.7),
          shortDescription: "Bridging the gap between advanced digital technologies and government operations",
        )
    );
  }
}

