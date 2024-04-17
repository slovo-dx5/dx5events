import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../helpers/helper_widgets.dart';
import '../../providers.dart';
import '../../widgets/appbarWidget.dart';
import '../../widgets/cio_bottomsheets.dart';
import '../../widgets/circleGradientAvatar.dart';
import '../../widgets/profile_initials_widget.dart';
import '../chats/chat_screen.dart';

class CisoIndividualAttendeeScreen extends StatefulWidget {
  String assetName;
  String FirstName;
  String LastName;
  String Role;
  String Company;
  String Bio;
  String profileid;
  int id;

  CisoIndividualAttendeeScreen(
      {super.key,
      required this.assetName,
      required this.FirstName,
      required this.LastName,
      required this.Role,
      required this.Company,
      required this.profileid,
      required this.Bio,
      required this.id});

  @override
  State<CisoIndividualAttendeeScreen> createState() =>
      _CisoIndividualAttendeeScreenState();
}

class _CisoIndividualAttendeeScreenState
    extends State<CisoIndividualAttendeeScreen> {
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return SafeArea(
        child: Scaffold(
      appBar: AppBar(centerTitle: true,
        title: const Text("ATTENDEE"),
      ),
      body: Column(children: <Widget>[
        verticalSpace(height: 40),
        IndividualAttendeeProfileInitials(
          firstName: widget.FirstName,
          lastName: widget.LastName,
        ),verticalSpace(height: 8),
        Text(
          "${widget.FirstName} ${widget.LastName}",
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 34.0, color: kLightAppbar),
        ),
        Text(
          "${widget.Role} at ${widget.Company}",
          style: const TextStyle(color: kLighterGreenAccent),
        ),verticalSpace(height: 10),

        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
          SizedBox(width: MediaQuery.of(context).size.width*0.35,child:   primaryButton2(
              context: context,
              onPressedFunction: () {},
              buttonText: "MEET",
              backgroundColor: kCISOPurple) ,), SizedBox(width: MediaQuery.of(context).size.width*0.35,child:   primaryButton2(
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

        // Stack(
        //   alignment:
        //   Alignment.topCenter,
        //   children: <Widget>[
        //     Padding(
        //       padding: const EdgeInsets.only(
        //         top: 120 / 2.0,
        //       ),
        //
        //       ///here we create space for the circle avatar to get ut of the box
        //       child: Container(
        //         height: 690.0,
        //         decoration:
        //         BoxDecoration(
        //           borderRadius:
        //           BorderRadius
        //               .circular(
        //               15.0),
        //           // color: Colors.white,
        //           color:
        //           kLightAppbar,
        //
        //           boxShadow: const [
        //             BoxShadow(
        //               color: kCISOPurple,
        //               blurRadius: 12.0,
        //               offset: Offset(
        //                   0.0, 5.0),
        //             ),
        //           ],
        //         ),
        //         width: double.infinity,
        //         child: Padding(
        //             padding:
        //             const EdgeInsets
        //                 .only(
        //                 top: 15.0,
        //                 bottom:
        //                 15.0),
        //             child:
        //             Column(
        //               children: <
        //                   Widget>[
        //                 verticalSpace(height: 45),
        //
        //
        //                 verticalSpace(height: 50),
        //                  Padding(
        //                   padding: const EdgeInsets
        //                       .symmetric(
        //                       horizontal:
        //                       80),
        //                   child:Row(
        //                     children: [
        //                       CircleGradientAvatar(actionIcon: Icons.meeting_room, actionText: 'Meet', onPressedF: (){
        //                         defaultScrollableBottomSheet(context, "Meeting request",
        //                             MeetingRequestBottomSheet(userName: widget.FirstName,
        //                               meetingWith: "${widget.FirstName} ${widget.LastName}",
        //                               otherUSerID: widget.id,));
        //                       },),
        //                       Spacer(),
        //                       CircleGradientAvatar(actionIcon: Icons.message, actionText: 'Chat', onPressedF: (){
        //                         if(mounted){
        //                           PersistentNavBarNavigator.pushNewScreen(
        //                             context,
        //                             screen:  CioChatScreen(chattingWithName: widget.FirstName, chattingWithID: widget.id, currentUserID: profileProvider.userID!, currentUserName: profileProvider.firstName,),
        //                             withNavBar: false,
        //                             pageTransitionAnimation: PageTransitionAnimation.slideRight,
        //                           );
        //                         }
        //                       },),
        //                     ],
        //                   )
        //                   ,
        //                 )
        //               ],
        //             )),
        //       ),
        //     ),
        //
        //   ],
        // ),
      ]),
    ));
  }
}
