import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';

import '../widgets/cio_bottomsheets.dart';
import '../widgets/landingPageWidget.dart';

class LandingPage2 extends StatefulWidget {
  @override
  State<LandingPage2> createState() => _LandingPage2State();
}

class _LandingPage2State extends State<LandingPage2> {

  List <String> items=["PAST","ACTIVE","FUTURE" ];
  int current=1;
  customAppbar() {
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
                width: MediaQuery.of(context).size.width*0.3,
                height: 45,
                child: Center(child: Text(items[index],),),
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
        if (current==0) ActiveEvents(),
        if(current==1)ActiveEvents(),if (current==2)FutureEvents()],)
      ),
    );
  }
}


class ActiveEvents extends StatefulWidget {
  const ActiveEvents({super.key});

  @override
  State<ActiveEvents> createState() => _ActiveEventsState();
}

class _ActiveEventsState extends State<ActiveEvents> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UpcomingEventWidget2(imagePath: 'assets/images/themes/cloudsecurity.png', dayMonth: 'THUR, MAY', date: '2nd', endDate: '3rd', location: 'NIGERIA', endDayMonth: 'FRIDAY, MAY', onPressedFunct: (){}, eventName: 'Cloud and Security\n'
            'Summit', containerColor: kCISOPurple,),
        UpcomingEventWidget2(imagePath: 'assets/images/themes/smartbanking.png', dayMonth: 'WED, MAY', date: '22nd', endDate: '23rd', location: 'KENYA', endDayMonth: 'THUR, MAY', onPressedFunct: (){}, eventName: 'Smart Banking'
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
      defaultScrollableBottomSheet(context,"",PendingEventBottomSheet(imagePath: 'assets/images/themes/smarthealth.png', month: 4, date: 25, slug: 'events/africa-cloud-and-security-summit',
        eventNAme: 'Smart Health', endDate: '29th', endDay: 'Sat', endMonth: 'June', startDate: '28th', startDay: 'Fri', startMonth: 'June', ));
    },),],);
  }
}


