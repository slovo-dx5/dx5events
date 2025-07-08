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
  String email;
  String FirstName;
  String LastName;
  String Role;
  String Company;
  String requestedByphone;
  String meetingWithPhone;
  String Bio;
  String profileid;
  bool hasDownloadedApp;
  int id;

  IndividualAttendeeScreen(
      {super.key,
      required this.assetName,
      required this.email,
      required this.requestedByphone,
      required this.meetingWithPhone,
      required this.FirstName,
      required this.LastName,
      required this.hasDownloadedApp,
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
          backgroundColor: Colors.grey.shade50,

          appBar: AppBar(centerTitle: true,
              title: const Text(
                'ATTENDEE PROFILE',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            elevation: 0,
            backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(children: <Widget>[
          verticalSpace(height: 40),
          widget.profileid==""?IndividualAttendeeProfileInitials(
            firstName: widget.FirstName,
            lastName: widget.LastName,
          ):IndividualAttendeeProfilePicWidget(profileID: widget.profileid,),
          verticalSpace(height: 16),
          Text(
            "${widget.FirstName} ${widget.LastName}",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          verticalSpace(height: 4),
          Text(
            "${widget.Role} at ${widget.Company}",
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),

          ),verticalSpace(height: 24),

          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
            SizedBox(width: MediaQuery.of(context).size.width*0.35,child:   primaryButton2(
                context: context,
                onPressedFunction: () {},
                buttonText: "MEET",
                backgroundColor: kConnectedBlue) ,),


              SizedBox(width: MediaQuery.of(context).size.width*0.35,
                child:   primaryButton2(
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
    otherUSerID: widget.id, company: widget.Company, recipientEmail: widget.email,
      requestedByphone:widget.requestedByphone, meetingWithPhone: widget.meetingWithPhone, hasDownloadedApp: widget.hasDownloadedApp ,),


        ]),
      ),
    ));
  }
}
