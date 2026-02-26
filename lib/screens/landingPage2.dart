import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../initialScreen.dart';
import '../providers/themeProvider.dart';
import '../widgets/cio_bottomsheets.dart';
import '../widgets/landingPageWidget.dart';
import 'authScreens/eventLogin.dart';

class LandingPage2 extends StatefulWidget {
  LandingPage2({Key? key}) : super(key: key);
  @override
  State<LandingPage2> createState() => _LandingPage2State();
}

class _LandingPage2State extends State<LandingPage2> {
//  List<String> items = ["PAST", "ACTIVE", "FUTURE"];
  int current = 1;


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
          imagePath: 'assets/images/themes/ciso_portrait.jpg',
          dayMonth: 'WED, NOV',
          date: '19th',
          endDate: '21ST',
          location: 'KENYA',
          endDayMonth: 'FRI, NOV',
          onPressedFunct: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => InitialScreen(
                        coverImagePath: 'assets/images/themes/ciso_landscape.jpg',
                        eventName: 'AFRICA CISO SUMMIT 2026',
                        //eventHappeningDates: 'WED, JULY, 16TH - THUR, MAY, 29TH',
                        eventHappeningDates: 'WED, MAR, 11TH',
                        shortEventDescription:
                            "Protect, Innovate or Die",
                        eventLocation: 'KENYA',
                        followingScreen: EventLogin(
                          coverImagePath:
                              'assets/images/themes/ciso_landscape.jpg',
                          eventName: 'AFRICA CISO SUMMIT 2026',
                          eventDate: 'WED, MAR, 11TH',
                          shortEventDescription:
                              "Protect, Innovate or Die",
                          eventLocation: 'KENYA',
                          eventID: '101',
                          eventDay: 11,
                          eventMonth: 03,
                          eventYear: 2026,
                          eventDayOfWeek: 'WED',
                          isCustomerEvent: false,
                        ),
                        eventID: '101',
                    eventDay: 11,
                    eventMonth: 03,
                    eventYear: 2026,
                        eventDayOfWeek: 'WED',
                        isCustomerEvent: false,
                      )),
            );
          },
          eventName: 'AFRICA CISO SUMMIT 2026',
          containerColor: kGradientLightBlue.withValues(alpha: 0.7),
          shortDescription: "Protect, Innovate or Die",
        )
    );
  }
}

