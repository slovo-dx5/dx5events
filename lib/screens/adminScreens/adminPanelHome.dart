import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';

import '../../widgets/cio_widgets.dart';
import 'broadCastMessageToAll.dart';
class AdminPanelHome extends StatefulWidget {
  String adminName;
   AdminPanelHome({super.key, required this.adminName});

  @override
  State<AdminPanelHome> createState() => _AdminPanelHomeState();
}

class _AdminPanelHomeState extends State<AdminPanelHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ADMIN PANEL"),),
      body:  SingleChildScrollView(child: Column(children: [
        verticalSpace(height: 20),
        const Text("CAUTION!! Use responsibly.\nYour name and actions are being recorded"),
        CIOWidgets().adminWidget( actionTitle: 'New Broadcast',
          actionDescription: 'Send a notification to all users', context: context, assetPath: "assets/icons/broadcast.png", screen: BroadCastMessageToAll(),),
        CIOWidgets().adminWidget( actionTitle: 'Scan QR',
          actionDescription: 'Scan attendees badge to check them in', context: context, assetPath: "assets/icons/qr.png", screen: BroadCastMessageToAll(),)


    ],),),);
  }
}
