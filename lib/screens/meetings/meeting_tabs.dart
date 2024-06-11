import 'package:flutter/material.dart';

import '../../constants.dart';
import '../chats/all_chats.dart';
import '../chats/chat_screen.dart';
import 'pending_Meetings.dart';
import 'accepted_meetings_screen.dart';

class MeetingTabs extends StatefulWidget {

   MeetingTabs({super.key});

  @override
  State<MeetingTabs> createState() => _MeetingTabsState();
}

class _MeetingTabsState extends State<MeetingTabs> {
  final List<Tab> tabs = <Tab>[
    Tab(child: Text("Confirmed",style: TextStyle(color: kCIOPink),),),
    Tab(child: Text("Pending",),),
  ];


   List<Widget> pages = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      pages = <Widget>[
        AcceptedMeetingsScreen(),
        PendingMeetingsScreen(),
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
