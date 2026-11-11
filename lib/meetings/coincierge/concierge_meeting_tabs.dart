import 'package:flutter/material.dart';

import '../../../constants.dart';
import 'concierge_meeting_list.dart';

class ConciergeMeetingTabs extends StatelessWidget {
  const ConciergeMeetingTabs({super.key, this.adminName = ''});

  /// Who is working the desk — recorded on shared status + reminders.
  final String adminName;

  @override
  Widget build(BuildContext context) {
    final tabs = <Tab>[
      const Tab(child: Text('Confirmed', style: TextStyle(color: kConnectedBlue))),
      const Tab(child: Text('Pending', style: TextStyle(color: kConnectedBlue))),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: TabBar(
            indicatorColor: kCIOPink,
            tabs: tabs,
            labelStyle: TextStyle(color: kTextColorBlackLighter),
          ),
        ),
        body: TabBarView(
          children: [
            ConciergeMeetingList(confirmed: true, adminName: adminName),
            ConciergeMeetingList(confirmed: false, adminName: adminName),
          ],
        ),
      ),
    );
  }
}
