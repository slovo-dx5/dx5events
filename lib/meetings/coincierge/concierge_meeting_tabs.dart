import 'package:dx5veevents/meetings/coincierge/concierge_accepted.dart';
import 'package:dx5veevents/meetings/coincierge/concierge_pending.dart';
import 'package:dx5veevents/meetings/pending_Meetings.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';


class ConciergeMeetingTabs extends StatefulWidget {

  ConciergeMeetingTabs({super.key});

  @override
  State<ConciergeMeetingTabs> createState() => _ConciergeMeetingTabsState();
}

class _ConciergeMeetingTabsState extends State<ConciergeMeetingTabs> {
  final List<Tab> tabs = <Tab>[
    const Tab(child: Text("Confirmed",style: TextStyle(color:kConnectedBlue ),)),
    const Tab(child: Text("Pending",style: TextStyle(color:kConnectedBlue ),),),
  ];


  List<Widget> pages = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      pages = <Widget>[
        ConciergeAcceptedMeetings(),
        ConciergePendingMeetings(),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: tabs.length, child: Scaffold(
      appBar: AppBar(title: TabBar(
        indicatorColor: kCIOPink,

        tabs: tabs,
        labelStyle: TextStyle(color: kTextColorBlackLighter),
      ),),
      body:  TabBarView(
        children: pages,
      ),

    ));
  }
}
