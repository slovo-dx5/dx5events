import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../initialScreen.dart';
import '../providers/themeProvider.dart';
import '../widgets/cio_bottomsheets.dart';
import '../widgets/landingPageWidget.dart';
import 'authScreens/eventLogin.dart';

class LandingPage2 extends StatefulWidget {

  LandingPage2({



    Key? key}) : super(key: key);
  @override
  State<LandingPage2> createState() => _LandingPage2State();
}

class _LandingPage2State extends State<LandingPage2> {



List <String> items=["ACTIVE","FUTURE" ];
  int current=0;
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
            return GestureDetector(onTap: (){
              setState(() {
                current=index;
              });
            },
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(30),color:current==index? kCISOPurple:kTextColorGrey),
                margin: const EdgeInsets.all(5),
                width: MediaQuery.of(context).size.width*0.45,
                height: 45,
                child: Center(child: Text(items[index],style: TextStyle(color: themeProvider.themeMode==ThemeModeOptions.dark?kWhiteText:kTextColorBlack),),),
              ),
            );
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return  SafeArea(
      child: Scaffold(

        body: Column(children: [customAppbar(),
        //if (current==0) FutureEvents(),
        if(current==0)ActiveEvents(),if (current==1)FutureEvents()],)
      ),
    );
  }
}


class ActiveEvents extends StatefulWidget {

  ActiveEvents({




    Key? key}) : super(key: key);

  @override
  State<ActiveEvents> createState() => _ActiveEventsState();
}

class _ActiveEventsState extends State<ActiveEvents> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // UpcomingEventWidget2(imagePath: 'assets/images/themes/cloudsecurity.png', dayMonth: 'THUR, MAY', date: '2nd', endDate: '3rd', location: 'NIGERIA', endDayMonth: 'FRIDAY, MAY', onPressedFunct: (){
        //
        //   Navigator.of(context).pushReplacement(
        //     MaterialPageRoute(builder: (_) => InitialScreen(eventDay: 2, eventMonth: 5, eventYear: 2024,coverImagePath: 'assets/images/themes/cloudsecurity.png', eventName: "AFRICA CLOUD AND SECURITY SUMMIT",
        //         eventDate: 'THUR, MAY 2nd - FRIDAY MAY 3rd',
        //
        //         shortEventDescription: 'Digital Transformation Through Cloud Security.',
        //         eventLocation: 'Nigeria'
        //         ,followingScreen: CISOLogin(eventDay: 2, eventMonth: 5, eventYear: 2024,coverImagePath: 'assets/images/themes/cloudsecurity.png', eventName: "AFRICA CLOUD AND SECURITY SUMMIT",
        //             eventDate: 'THUR, MAY, 2nd - FRIDAY MAY 3rd',
        //
        //             shortEventDescription: 'Digital Transformation Through Cloud Security',
        //             eventLocation: 'Nigeria', eventID: '6',), eventID: '6',)),
        //   );
        // }, eventName: 'Cloud and Security\n'
        //     'Summit', containerColor: kCISOPurple,),
        UpcomingEventWidget2(imagePath: 'assets/images/themes/smartbanking.png', dayMonth: 'WED, MAY', date: '22nd', endDate: '23rd', location: 'KENYA', endDayMonth: 'THUR, MAY', onPressedFunct: (){
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => InitialScreen(coverImagePath: 'assets/images/themes/smartbanking.png', eventName: "SMART BANKING",
                eventHappeningDates: 'WED, MAY, 22nd - THUR MAY 23rd',

                shortEventDescription: "Navigating the Next: Africa's Leap into Smart, Secure, and Inclusive Banking",
                eventLocation: 'KENYA'
                ,followingScreen: EventLogin(coverImagePath: 'assets/images/themes/smartbanking.png', eventName: "SMART BANKING",
                    eventDate: 'WED, MAY, 22nd - THUR MAY 23rd',

                    shortEventDescription: "Navigating the Next: Africa's Leap into Smart, Secure, and Inclusive Banking",
                    eventLocation: 'KENYA', eventID: '8', eventDay: 22, eventMonth: 5, eventYear: 2024, eventDayOfWeek: 'WED',), eventID: '8', eventDay: 22, eventMonth: 5, eventYear: 2024, eventDayOfWeek: 'WED',)),
          );
        }, eventName: 'Smart Banking'
            , containerColor: kCISOPurple,),
      ],
    );
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
    return Column(children: [ CurvedImageContainer(imagePath: 'assets/images/themes/smarthealth.png',  dayMonth: 'THUR, APR', date: '25th', endDate: '26th', endDayMonth: 'FRI, APR', location: 'NIGERIA', onPressedFunct: (){
      defaultScrollableBottomSheet(context,"",PendingEventBottomSheet(imagePath: 'assets/images/themes/smarthealth.png', month: 6, date: 25, slug: 'events/africa-cloud-and-security-summit',
        eventNAme: 'Smart Health', endDate: '29th', endDay: 'Sat', endMonth: 'June', startDate: '28th', startDay: 'Fri', startMonth: 'June', eventDesc: 'The Africa SaccoTech Forum spearheads the vital SACCO movement, propelling these inclusive cooperatives into the future with cutting-edge technology and digital solutions as they continue', ));
    },),],);
  }
}


