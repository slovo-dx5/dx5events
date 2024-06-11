import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

import '../constants.dart';

import '../screens/dx5veScreens/cisoIndividualAttendee.dart';
import '../widgets/profile_initials_widget.dart';

menuItem(
    {required String menuText,
    required IconData widgetIcon,
    required Color iconColor,
    required VoidCallback onPressedFunction}) {
  return Padding(
    padding: EdgeInsets.only(top: 12, bottom: 12),
    child: InkWell(
      splashColor: kPrimaryColor.withOpacity(0.4),
      borderRadius: BorderRadius.circular(8),
      onTap: onPressedFunction,
      child: Row(
        children: [
          Icon(
            widgetIcon,
            color: iconColor,
          ),
          horizontalSpace(width: 10),
          Text(
            menuText,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
          const Spacer(),
          const Icon(
            Icons.arrow_forward_ios,
            size: 15,
          )
        ],
      ),
    ),
  );
}

attendeeWidget({
  required String assetName,
  required BuildContext context,
  required String firstName,
  required String lastName,
  required String role,
  required String company,
  required String profileid,
  required int userID,
  required List<String> interests,
}) {
  return SizedBox(
    height: 85,
    width: MediaQuery.of(context).size.width,
    child: GestureDetector(
      onTap: () {
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: CisoIndividualAttendeeScreen(
            assetName: assetName,
            FirstName: firstName,
            LastName: lastName,
            Role: role,
            Company: company,
            Bio: "",
           profileid: profileid??'', id: userID,
          ),
          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.slideRight,
        );
      },
      child: Card(
        elevation: 0.2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Row(
            children: [
             if(profileid=="" || profileid==null) AttendeeProfileInitials(firstName: firstName??".", lastName: lastName,),
             if(profileid!="" && profileid!=null) AttendeeProfilePicWidget(profileID: profileid,),
              horizontalSpace(width: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$firstName $lastName",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "$role at $company",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: kTextColorGrey),
                    )
                  ],
                ),
              ),
              connectButton( assetName: assetName,
                firstName: firstName,
                lastName: lastName,
                role: role,
                company: company,

                profileid: profileid??'', userID: userID, context: context,)
            ],
          ),
        ),
      ),
    ),
  );
}

meWidget({
  required String assetName,
  required BuildContext context,
  required String firstName,
  required String lastName,
  required String role,
  required String company,
  required String profileid,
  required int userID,
  required List<String> interests,
}) {
  return SizedBox(
    height: 85,
    width: MediaQuery.of(context).size.width,
    child: GestureDetector(
      onTap: () {

      },
      child: Card(
        elevation: 0.2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Row(
            children: [
              if(profileid=="" || profileid==null) AttendeeProfileInitials(firstName: firstName, lastName: lastName,),
              if(profileid!="" && profileid!=null) AttendeeProfilePicWidget(profileID: profileid,),
              horizontalSpace(width: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$firstName $lastName",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "$role at $company",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: kTextColorGrey),
                    )
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    ),
  );
}

interestWidget({
  required String interest,
}) {
  return Stack(
    alignment: Alignment.center,
    children: [
      Container(
        height: 40,
        // width: 200,

        decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                "assets/images/interests/$interest.png",
              ),
              fit: BoxFit.cover,
            ),
            border: Border.all(color: kCIOPink, width: 1),
            borderRadius: BorderRadius.circular(30)),
      ),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.black.withOpacity(0.5),
        ),
        height: 40,
        // width: 200,
      ),
      Align(
          alignment: Alignment.center,
          child: Text(
            interest,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: kLightAppbar),
          ))
    ],
  );
}

class HorizontalCardScroll extends StatefulWidget {
  @override
  _HorizontalCardScrollState createState() => _HorizontalCardScrollState();
}

class _HorizontalCardScrollState extends State<HorizontalCardScroll> {
  // Data for your cards (you can replace this with your own data)
  final List<String> cardItems = [

    'assets/images/sponsors/master.png'
  ];

  // Index to track the currently displayed card
  int currentCardIndex = 0;

  // Timer to auto-scroll the cards
  late Timer timer;

  @override
  void initState() {
    super.initState();

    // Start the timer to scroll cards every 5 seconds
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      setState(() {
        currentCardIndex = (currentCardIndex + 1) % cardItems.length;
      });
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return    SizedBox(
      height: 100,
      width: MediaQuery.of(context).size.width,

      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Row(
              children: [
                Expanded(child: Container(decoration: BoxDecoration(border: Border.all(width: 0.5,color: kCIOPink.withOpacity(0.5)),),height: 1,)),
                horizontalSpace(width: 5),
                const Text("Powered by Mastercard"),
                horizontalSpace(width: 5),
                Expanded(child: Container(decoration: BoxDecoration(border: Border.all(width: 0.5,color: kCIOPink.withOpacity(0.5)),),height: 1,)),


              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Container(
                  height: 100,
                  child: Image.asset('assets/images/sponsors/master.png',

                    fit: BoxFit.fill,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

nameWidget(
    {required String name,
    required String phone,
    required String email,
    required String company,
    required String role,

    required BuildContext context}) {
  return SizedBox(
    width: MediaQuery.of(context).size.width,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 2, 8, 2),
      child: Card(

        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Name",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              verticalSpace(height: 5),
              Text(
                name,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              //verticalSpace(height: 9),
              Divider(),
              verticalSpace(height: 9),
              Text(
                "Phone",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              verticalSpace(height: 5),
              Text(
                phone,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Divider(),
              verticalSpace(height: 9),
              Text(
                "Email",
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              Text(
                email,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Divider(),verticalSpace(height: 9),
              Text(
                "Company",
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              Text(
                company,
                style: Theme.of(context).textTheme.bodyLarge,
              ),verticalSpace(height: 9),
              Divider(),
              verticalSpace(height: 9),Text(
                "Role",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              verticalSpace(height: 5),
              Text(
                role,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
//
// editableProfileWidgets(
//     {required String company,
//     required String role,
//     required BuildContext context}) {
//   return SizedBox(
//     width: MediaQuery.of(context).size.width,
//     child: Padding(
//       padding: const EdgeInsets.fromLTRB(8.0, 2, 8, 2),
//       child: Card(
//         color: kWhiteText.withOpacity(0.8),
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Company",
//                         style: Theme.of(context).textTheme.bodyMedium,
//                       ),
//                       verticalSpace(height: 5),
//                       Text(
//                         company,
//                         style: Theme.of(context).textTheme.bodyLarge,
//                       ),
//                     ],
//                   ),
//                   Spacer(),
//                   IconButton(
//                       onPressed: () {
//                         profileBottomSheet(
//                             context,
//                             "Edit Company",
//                             EditCompanyBottomSheet(
//                               userCompany: company,
//                             ));
//                       },
//                       icon: Icon(Icons.edit))
//                 ],
//               ),
//
//               //ListTile(title: Text(company,style: Theme.of(context).textTheme.bodyLarge,),trailing: IconButton(onPressed: (){}, icon: const Icon(Icons.edit)),),
//
//               const Divider(),
//               verticalSpace(height: 9),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Role",
//                         style: Theme.of(context).textTheme.bodyMedium,
//                       ),
//                       verticalSpace(height: 5),
//                       Text(
//                         role,
//                         style: Theme.of(context).textTheme.bodyLarge,
//                       ),
//                     ],
//                   ),
//                   Spacer(),
//                   IconButton(
//                       onPressed: () {
//                         profileBottomSheet(
//                             context,
//                             "Edit Role",
//                             EditRoleBottomSheet(
//                               userRole: role,
//                             ));
//                       },
//                       icon: Icon(Icons.edit))
//                 ],
//               ),
//
//               const Divider(),
//               verticalSpace(height: 9),
//
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }
