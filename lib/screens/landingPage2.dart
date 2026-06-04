import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../initialScreen.dart';
import '../providers.dart';
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
    if(widget.isFromLogout==true) {
      (
        clearAllPrefs().then((on){
          final provider = Provider.of<ProfileProvider>(context, listen: false);
          // Clear in-memory profile before navigating
          provider.clearProfile();
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
          imagePath: 'assets/images/themes/bfsi_portrait.jpg',
          dayMonth: 'WED, JUN',
          date: '17th',
          endDate: '18th',
          location: 'KENYA',
          endDayMonth: 'THUR, JUN',
          onPressedFunct: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => InitialScreen(
                        coverImagePath: 'assets/images/themes/bfsi_landscape.png',
                        eventName: 'BFSI WEEK',
                        //eventHappeningDates: 'WED, JULY, 16TH - THUR, MAY, 29TH',
                        eventHappeningDates: 'WED, JUN, 17TH',
                        shortEventDescription:
                            "Powering Africa's Financial Transformation",
                        eventLocation: 'KENYA',
                        followingScreen: EventLogin(
                          coverImagePath:
                              'WED, JUN, 17TH',
                          eventName: 'BFSI WEEK',
                          eventDate: 'WED, JUN, 17TH',
                          shortEventDescription:
                              "Powering Africa's Financial Transformation",
                          eventLocation: 'KENYA',
                          eventID: '104',
                          eventDay: 17,
                          eventMonth: 06,
                          eventYear: 2026,
                          eventDayOfWeek: 'WED',
                          isCustomerEvent: false,
                        ),
                        eventID: '104',
                    eventDay: 17,
                    eventMonth: 06,
                    eventYear: 2026,
                        eventDayOfWeek: 'WED',
                        isCustomerEvent: false,
                      )),
            );
          },
          eventName: 'BFSI WEEK',
          containerColor: kGradientLightBlue.withValues(alpha: 0.7),
          shortDescription: "Powering Africa's Financial Transformation",
        )
    );
  }
}

