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
  List<String> items = ["PAST","ACTIVE", "FUTURE"];
  int current = 1;
  customAppbar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return SizedBox(
      height: 60,
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  current = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color:
                        current == index ? kGradientLightBlue : kTextColorGrey),
                margin: const EdgeInsets.all(5),
                width: MediaQuery.of(context).size.width * 0.3,
                height: 45,
                child: Center(
                  child: Text(
                    items[index],
                    style: TextStyle(
                        color: themeProvider.themeMode == ThemeModeOptions.dark
                            ? kWhiteText
                            : kTextColorBlack),
                  ),
                ),
              ),
            );
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Column(
        children: [
          customAppbar(),
          //if (current==0) FutureEvents(),
          if (current == 0) PastEvents(),
          if (current == 1) ActiveEvents(),
          if (current == 2) FutureEvents()
        ],
      )),
    );
  }
}

class ActiveEvents extends StatefulWidget {
  ActiveEvents({Key? key}) : super(key: key);

  @override
  State<ActiveEvents> createState() => _ActiveEventsState();
}

class _ActiveEventsState extends State<ActiveEvents> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height *0.9,
      child:

      UpcomingEventWidget2(imagePath: 'assets/images/themes/connected_portrait.jpg', dayMonth: 'THUR, MAY', date: '26th',
        endDate: '29th', location: 'KENYA', endDayMonth: 'SUN, MAY', onPressedFunct: (){
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => InitialScreen(coverImagePath: 'assets/images/themes/connected_bg.jpg', eventName: 'CONNECTED AFRICA SUMMIT',
              eventHappeningDates: 'THUR, MAY, 26TH - THUR, MAY, 29TH',

              shortEventDescription: "A summit for digital transformation in Africa",
              eventLocation: 'KENYA'
              ,followingScreen: EventLogin(coverImagePath: 'assets/images/themes/connected_bg.jpg',
              eventName: 'CONNECTED AFRICA SUMMIT',
                  eventDate: 'WED, MAR, 19TH - THUR, MAR, 20TH',

                  shortEventDescription: "A summit for digital transformation in Africa",
                  eventLocation: 'KENYA', eventID: '46', eventDay: 19, eventMonth: 3, eventYear: 2025, eventDayOfWeek: 'WED',
              isCustomerEvent: false,), eventID: '46', eventDay: 19, eventMonth: 3, eventYear: 2025, eventDayOfWeek: 'WED', isCustomerEvent: false,)),
        );
      }, eventName: 'CONNECTED AFRICA SUMMIT'
          , containerColor: kGradientLightBlue.withOpacity(0.7), shortDescription: 'A summit for digital transformation in Africa',));
  }
}

class FutureEvents extends StatefulWidget {
  const FutureEvents({super.key});

  @override
  State<FutureEvents> createState() => _FutureEventsState();
}

class _FutureEventsState extends State<FutureEvents> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [],
    );
  }
}

class PastEvents extends StatefulWidget {
  const PastEvents({super.key});

  @override
  State<PastEvents> createState() => _PastEventsState();
}

class _PastEventsState extends State<PastEvents> {
  @override
  Widget build(BuildContext context) {
    return  Align(alignment: Alignment.bottomCenter,
      // child: Center(
      //   child: Padding(
      //     padding: EdgeInsets.fromLTRB(8.0,300,8,150),
      //     child: Text("Information on Past Events Will Appear Here",style: TextStyle(fontSize: 25,fontWeight: FontWeight.w700),textAlign: TextAlign.center,),
      //   ),
      // ),
      child:  PastEventWidget(eventName: 'CIO 100 SYMPOSIUM AND AWARDS', year: ' 2024',
        eventAssetPath: 'assets/images/themes/cio100.jpg', eventID: 21,),
    );
      PastEventWidget(eventName: 'CIO 100 SYMPOSIUM AND AWARDS', year: ' 2024',
      eventAssetPath: 'assets/images/themes/cio100.jpg', eventID: 21,);
  }
}

