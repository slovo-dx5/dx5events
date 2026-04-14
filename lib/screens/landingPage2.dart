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
          imagePath: 'assets/images/themes/CONNECTED-PORTRAIT.jpg',
          dayMonth: 'WED, NOV',
          date: '19th',
          endDate: '21ST',
          location: 'KENYA',
          endDayMonth: 'FRI, NOV',
          onPressedFunct: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => InitialScreen(
                        coverImagePath: 'assets/images/themes/CONNECTED AFRICA 2026 THEME FA2.jpg',
                        eventName: 'CONNECTED AFRICA SUMMIT 2026',
                        //eventHappeningDates: 'WED, JULY, 16TH - THUR, MAY, 29TH',
                        eventHappeningDates: 'WED, NOV, 19TH',
                        shortEventDescription:
                            "The Future of Tech",
                        eventLocation: 'KENYA',
                        followingScreen: EventLogin(
                          coverImagePath:
                              'assets/images/themes/smart-landscape.jpg',
                          eventName: 'CONNECTED AFRICA SUMMIT 2026',
                          eventDate: 'MON, APR, 27TH',
                          shortEventDescription:
                              "The Future of Tech",
                          eventLocation: 'KENYA',
                          eventID: '63',
                          eventDay: 27,
                          eventMonth: 04,
                          eventYear: 2026,
                          eventDayOfWeek: 'MON',
                          isCustomerEvent: false,
                        ),
                        eventID: '63',
                    eventDay: 27,
                    eventMonth: 04,
                    eventYear: 2026,
                        eventDayOfWeek: 'MON',
                        isCustomerEvent: false,
                      )),
            );
          },
          eventName: 'CONNECTED AFRICA SUMMIT 2026',
          containerColor: kGradientLightBlue.withValues(alpha: 0.7),
          shortDescription: "The Future of Tech",
        )
    );
  }
}

