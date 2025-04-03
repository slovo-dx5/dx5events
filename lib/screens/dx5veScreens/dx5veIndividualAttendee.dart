import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../helpers/helper_widgets.dart';
import '../../providers.dart';
import '../../widgets/appbarWidget.dart';
import '../../widgets/cio_bottomsheets.dart';
import '../../widgets/circleGradientAvatar.dart';
import '../../widgets/profile_initials_widget.dart';
import '../chats/chat_screen.dart';

class IndividualAttendeeScreen extends StatefulWidget {
  String assetName;
  String FirstName;
  String LastName;
  String Role;
  String Company;
  String Bio;
  String profileid;
  int id;

  IndividualAttendeeScreen(
      {super.key,
      required this.assetName,
      required this.FirstName,
      required this.LastName,
      required this.Role,
      required this.Company,
      required this.profileid,
      required this.Bio,
      required this.id
      });

  @override
  State<IndividualAttendeeScreen> createState() =>
      _IndividualAttendeeScreenState();
}

class _IndividualAttendeeScreenState
    extends State<IndividualAttendeeScreen> {
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return SafeArea(
        child: Scaffold(
      appBar: AppBar(centerTitle: true,
        title: const Text("ATTENDEE"),
      ),
      body: SingleChildScrollView(
        child: Column(children: <Widget>[
          verticalSpace(height: 40),
          IndividualAttendeeProfileInitials(
            firstName: widget.FirstName,
            lastName: widget.LastName,
          ),verticalSpace(height: 8),
          Text(
            "${widget.FirstName} ${widget.LastName}",
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 34.0, ),
          ),
          Text(
            "${widget.Role} at ${widget.Company}",
            // " ${widget.Company}",

          ),verticalSpace(height: 10),

          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
            SizedBox(width: MediaQuery.of(context).size.width*0.35,child:   primaryButton2(
                context: context,
                onPressedFunction: () {},
                buttonText: "MEET",
                backgroundColor: kCISOPurple) ,),


              SizedBox(width: MediaQuery.of(context).size.width*0.35,child:   primaryButton2(
                context: context,
                onPressedFunction: () {     if(mounted){
                  PersistentNavBarNavigator.pushNewScreen(
                    context,
                    screen:  CioChatScreen(chattingWithName: widget.FirstName, chattingWithID: widget.id, currentUserID: profileProvider.userID!, currentUserName: profileProvider.firstName,),
                    withNavBar: false,
                    pageTransitionAnimation: PageTransitionAnimation.slideRight,
                  );
                }},
                buttonText: "CHAT",
                backgroundColor: kLightCardColor) ,),

            ],
          ),verticalSpace(height: 10),
    MeetingRequestBottomSheet(userName: widget.FirstName,
    meetingWith: "${widget.FirstName} ${widget.LastName}",
    otherUSerID: widget.id,),


        ]),
      ),
    ));
  }
}
