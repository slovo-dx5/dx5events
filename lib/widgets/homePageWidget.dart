import 'package:auto_size_text/auto_size_text.dart';
import 'package:dx5veevents/widgets/showMoreText.dart';
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
  String eventDate;
  String eventLocation;
  String eventID;int eventDay;
  int eventMonth;
  int eventYear;
  HomePageWidget(
      {super.key,
      required this.coverImagepath,
      required this.eventName,
      required this.eventDate,required this.eventLocation,required this.eventID,
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
                  fit: BoxFit.cover,
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
                    width: 50,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),color: kScreenDark),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_on_sharp,
                          color: kCISOPurple,
                        ),AutoSizeText(widget.eventLocation, maxFontSize: 10,minFontSize: 5,)
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
                  // screen: EventSpeakersScreen(eventName: widget.eventName,eventID: widget.eventID),
                  screen: EventSpeakersScreen(eventID: widget.eventID,),
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
                  screen: CISOSponsorsScreen(eventID: widget.eventID,),
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
                  screen: EventAgendaScreen(eventID: widget.eventID, eventDay: widget.eventDay, eventMonth: widget.eventMonth, eventYear: widget.eventYear, eventLocation: widget.eventLocation,),
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
                  screen: AttendeesScreen(eventID: widget.eventID,),
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
                  screen: CISOPartnersScreen(eventID: widget.eventID,),
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
                  screen: UserSessionsScreen(
                    userid: profileProvider.userID!,
                    eventID: widget.eventID,eventDay: widget.eventDay, eventLocation: widget.eventLocation, eventMonth: widget.eventMonth,eventYear: widget.eventYear,                ),
                  itemName: 'My Sessions',
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
