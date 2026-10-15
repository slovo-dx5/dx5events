import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../initialScreen.dart';
import '../providers.dart';
import '../providers/harry_controller.dart';
import '../providers/themeProvider.dart';
import '../services/active_event/active_event.dart';
import '../services/active_event/active_event_service.dart';
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
    // The event comes from Directus (app_config.active_event) via
    // ActiveEventService, so switching events needs no new build.
    final event = context.watch<ActiveEventService>().current;
    return SizedBox(
        //height: MediaQuery.of(context).size.height * 0.85,
        child: ActiveEventWidget(
          imagePath: ActiveEvent.bundledCardImage,
          imageUrl: event.cardImageUrl,
          dayMonth: ActiveEvent.dayLabel(event.dateFrom),
          date: '${event.dateFrom.day}',
          endDate: '${event.dateTo.day}',
          location: event.displayLocation,
          endDayMonth: ActiveEvent.dayLabel(event.dateTo),
          onPressedFunct: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => InitialScreen(
                        coverImagePath: ActiveEvent.bundledCoverImage,
                        eventName: event.displayName,
                        eventHappeningDates: event.dateLabel,
                        shortEventDescription: event.tagline,
                        eventLocation: event.displayLocation,
                        followingScreen: EventLogin(
                          coverImagePath: ActiveEvent.bundledCoverImage,
                          eventName: event.displayName,
                          eventDate: event.dateLabel,
                          shortEventDescription: event.tagline,
                          eventLocation: event.displayLocation,
                          eventID: event.id,
                          eventDay: event.dateFrom.day,
                          eventMonth: event.dateFrom.month,
                          eventYear: event.dateFrom.year,
                          eventDayOfWeek: event.dayOfWeek,
                          isCustomerEvent: false,
                        ),
                        eventID: event.id,
                        eventDay: event.dateFrom.day,
                        eventMonth: event.dateFrom.month,
                        eventYear: event.dateFrom.year,
                        eventDayOfWeek: event.dayOfWeek,
                        isCustomerEvent: false,
                      )),
            );
          },
          eventName: event.displayName,
          containerColor: kGradientLightBlue.withValues(alpha: 0.7),
          shortDescription: event.tagline,
        )
    );
  }
}
