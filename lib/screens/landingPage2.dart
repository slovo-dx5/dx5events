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
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(30),color:current==index? kGradientLightBlue:kTextColorGrey),
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


        UpcomingEventWidget2(imagePath: 'assets/images/themes/smartbanking.png', dayMonth: 'THUR, AUG', date: '22nd',
          endDate: '23rd', location: 'NIGERIA', endDayMonth: 'FRI, AUGUST', onPressedFunct: (){
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => InitialScreen(coverImagePath: 'assets/images/themes/smartbanking.png', eventName: 'SMART BANKING\nSUMMIT',
                eventHappeningDates: 'THUR, AUG, 22nd - THUR, AUG, 23rd',

                shortEventDescription: "Navigating the Next: Africa's Leap into Smart, Secure, and Inclusive Banking",
                eventLocation: 'NIGERIA'
                ,followingScreen: EventLogin(coverImagePath: 'assets/images/themes/smartbanking.png', eventName: 'SMART BANKING\nSUMMIT',
                    eventDate: 'THUR, AUG, 22nd - THUR, AUG, 23rd',

                    shortEventDescription: "Navigating the Next: Africa's Leap into Smart, Secure, and Inclusive Banking",
                    eventLocation: 'NIGERIA', eventID: '24', eventDay: 22, eventMonth: 8, eventYear: 2024, eventDayOfWeek: 'THUR',
                isCustomerEvent: false,), eventID: '24', eventDay: 22, eventMonth: 8, eventYear: 2024, eventDayOfWeek: 'THUR', isCustomerEvent: false,)),
          );
        }, eventName: 'SMART BANKING\nSUMMIT'
            , containerColor: kGradientLightBlue.withOpacity(0.7),),
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
    return Column(children: [




      CurvedImageContainer(imagePath: 'assets/images/themes/smartgov.png',
      dayMonth: 'WED, OCT', date: '2nd', endDate: '3rd',
      endDayMonth: 'THUR, OCT', location: 'KENYA', onPressedFunct: (){
      defaultScrollableBottomSheet(context,"",
          PendingEventBottomSheet(imagePath: 'assets/images/themes/smartgov.png', month: 7,
            date: 24, slug: 'events/smart-government-summit',
        eventNAme: 'Smart Government Summit',
            endDate: '3rd', endDay: 'THUR', endMonth: 'October',
            startDate: '2nd', startDay: 'WED', startMonth: 'October',
            eventDesc: 'The Smart Government Summit stands at the forefront of Africa’s digital transformation, bridging the gap between advanced digital technologies and government operations. This pivotal event comes at a time when Africa’s digital landscape is witnessing exponential growth, with increasing internet access and mobile connectivity shaping public sector innovation. The summit is a critical confluence for discussing the integration of digital solutions in government, offering a unique perspective on the future of digital government in Africa.', ));
    },),

      verticalSpace(height: 10),

      CurvedImageContainer(imagePath: 'assets/images/themes/cio100.png',
      dayMonth: 'WED, NOV', date: '20th', endDate: '22nd',
      endDayMonth: 'FRI, NOV', location: 'KENYA', onPressedFunct: (){
      defaultScrollableBottomSheet(context,"",
          PendingEventBottomSheet(imagePath: 'assets/images/themes/cio100.png', month: 11,
            date: 20, slug: 'events/smart-government-summit',
        eventNAme: 'CIO100 Symposium and Awards',
            endDate: '22nd', endDay: 'FRI', endMonth: 'Nov',
            startDate: '20th', startDay: 'WED', startMonth: 'Nov',
            eventDesc: 'The CIO100 Symposium & Awards is a celebration of excellence in IT leadership. This prestigious event will honor 100 award recipients, highlighting their achievements in leadership, innovation, and the adoption of advanced technologies such as generative AI and Edge Computing.', ));
    },),


    ],);
  }
}


