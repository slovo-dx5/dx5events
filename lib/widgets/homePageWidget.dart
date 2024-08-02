import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';

import '../constants.dart';
import '../providers.dart';

import '../screens/dx5veScreens/eventSpeakersScreen.dart';
import '../screens/dx5veScreens/dx5ve_partners_screen.dart';
import '../screens/dx5veScreens/event_sessions_screen.dart';
import '../screens/dx5veScreens/dx5ve_sponsors_screen.dart';
import '../screens/dx5veScreens/dx5veAttendeesScreen.dart';
import '../screens/dx5veScreens/eventAgendaScreen.dart';
import 'cio_widgets.dart';

class HomePageWidget extends StatefulWidget {
  String coverImagepath;
  String eventName;
  String shortEventDescription;
  String eventDayOfWeek;
  String eventDate;
  String eventLocation;
  String eventID;int eventDay;
  int eventMonth;
  int eventYear;
  bool isCustomerEvent;
  HomePageWidget(
      {super.key,
        required this.isCustomerEvent,
      required this.coverImagepath,
      required this.eventName,required this.eventDate,
      required this.eventDayOfWeek,required this.eventLocation,required this.eventID,
      required this.shortEventDescription , required this.eventDay,
        required this.eventMonth,
        required this.eventYear});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return UpgradeAlert(
      upgrader: Upgrader(
          // dialogStyle: Platform.isAndroid
          //     ? UpgradeDialogStyle.material
          //     : UpgradeDialogStyle.cupertino,
          // showIgnore: false,
          durationUntilAlertAgain: const Duration(hours: 1)),
      child: Scaffold(
          body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Image.asset(
                  widget.coverImagepath,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.3,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15.0, 15, 15, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.75,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.eventName,style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.calendar_month),
                            horizontalSpace(width: 5),
                            Text(
                              widget.eventDate,
                              style: const TextStyle(fontSize: 10),
                            ),

                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(padding: EdgeInsets.all(5),
                    height: 50,
                    width: 60,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_on_sharp,
                          color: kCISOPurple,
                        ),Flexible(child: AutoSizeText(widget.eventLocation, maxFontSize: 10,minFontSize: 5,))
                      ],
                    ),
                  )
                ],
              ),
            ),verticalSpace(height: 10),
            //Text(widget.eventDescription),
            Padding(
              padding: const EdgeInsets.only(left:8.0, right: 8.0),
              child: Text( widget.shortEventDescription,),
            ),
            const Divider(color: kCIOPink),
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
                  // screen: EventSpeakersScreen(eventName: widget.eventName,eventID: widget.eventID),
                  screen: EventSpeakersScreen(eventID: widget.eventID,),
                  itemName: 'Speakers', analyticsActionName: 'speakers_page_opened',
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
                  screen: CISOSponsorsScreen(eventID: widget.eventID,),
                  itemName: 'Sponsors', analyticsActionName: 'sponsors_page_opened',
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
                  screen: EventAgendaScreen(eventID: widget.eventID, eventDay: widget.eventDay, eventMonth: widget.eventMonth, eventYear: widget.eventYear, eventLocation: widget.eventLocation, eventDayOfWeek: widget.eventDayOfWeek,),
                  itemName: 'Agenda', analyticsActionName: 'agenda_page_opened',
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
                  screen: AttendeesScreen(eventID: widget.eventID, isCustomerEvent: widget.isCustomerEvent,),
                  itemName: 'Attendees', analyticsActionName: 'attendees_page_opened',
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
                  screen: CISOPartnersScreen(eventID: widget.eventID,),
                  itemName: 'Partners', analyticsActionName: 'partners_page_opened',
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
                  screen: UserSessionsScreen(
                    userid: profileProvider.userID!,
                    eventID: widget.eventID,eventDay: widget.eventDay, eventLocation: widget.eventLocation, eventMonth: widget.eventMonth,eventYear: widget.eventYear, eventDayOfWeek: widget.eventDayOfWeek,                ),
                  itemName: 'My Sessions', analyticsActionName: 'sessions_page_opened',
                ),
              ],
            ),
            verticalSpace(height: 15),
            // SizedBox(
            //     height: 100,
            //     width: MediaQuery.of(context).size.width,
            //     child: HorizontalCardScroll())
          ],
        ),
      )),
    );
  }
}
