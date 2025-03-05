import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import '../helpers/helper_functions.dart';
import '../models/contactModel.dart';
import '../widgets/cool_background.dart';
import 'package:flutter_contacts_service/flutter_contacts_service.dart'as fc;

import '../widgets/textStyles.dart';

class SaveContact extends StatefulWidget {
  String firstName;
  String lastName;
  String phone;
  String email;
  String company;
  String role;
  int ownerID;



   //
   SaveContact({required this.email,required this.ownerID, required this.firstName, required this.company,
    required this.role, required this.phone,required this.lastName,super.key});

  @override
  State<SaveContact> createState() => _SaveContactState();
}
Future<void> saveContactToDevice({required UserContact userContact}) async {
  // Request permissions
  if (await Permission.contacts.request().isGranted) {
    // Create a new contact
    fc.ContactInfo newContact = fc.ContactInfo(
      givenName: userContact.firstName,
      familyName: userContact.lastName,
      emails: [fc.ValueItem(label: 'work', value: userContact.email)],
      company: userContact.company,
      jobTitle: userContact.role,
      phones: [fc.ValueItem(label: 'mobile', value: userContact.phoneNumber)],
    );

    // Save the contact
    await fc.FlutterContactsService. addContact(newContact);
  } else {
    // Handle permission denial
    print('Permission to access contacts was denied');
  }
}
class _SaveContactState extends State<SaveContact> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(body:
      // body: Stack(
      //   children: [
      //     CoolBackground(),
      //     Column(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: [
      //         const Text(
      //           "New contact Details",
      //           style: TextStyle(fontSize: 17),
      //         ),
      //         verticalSpace(height: 40),
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.start,
      //           children: [
      //             Icon(Icons.person),
      //             horizontalSpace(width: 25),
      //             Text(widget.firstName, style: contactItemStyle()),
      //           ],
      //         ),
      //         verticalSpace(height: 25),
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.start,
      //           children: [
      //             Icon(Icons.person),
      //             horizontalSpace(width: 25),
      //             Text(widget.lastName, style: contactItemStyle()),
      //           ],
      //         ),
      //         verticalSpace(height: 25),
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.start,
      //           children: [
      //             Icon(Icons.email),
      //             horizontalSpace(width: 25),
      //             Flexible(
      //               child: Text(widget.email, style: contactItemStyle()),
      //             ),
      //           ],
      //         ),
      //         verticalSpace(height: 25),
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.start,
      //           children: [
      //             Icon(Icons.phone),
      //             horizontalSpace(width: 25),
      //             Text(widget.phone, style: contactItemStyle()),
      //           ],
      //         ),
      //         verticalSpace(height: 25),
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.start,
      //           children: [
      //             Icon(Icons.factory),
      //             horizontalSpace(width: 25),
      //             Flexible(
      //               child: Text(widget.company, style: contactItemStyle()),
      //             ),
      //           ],
      //         ),
      //         verticalSpace(height: 25),
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.start,
      //           children: [
      //             Icon(Icons.grid_4x4_outlined),
      //             horizontalSpace(width: 25),
      //             Flexible(
      //               child: Text(widget.role, style: contactItemStyle()),
      //             ),
      //           ],
      //         ),
      //         verticalSpace(height: 25),
      //         ElevatedButton(
      //           onPressed: () {
      //             print("saving");
      //           },
      //           child: Text("Save"),
      //         ),
      //         primaryButton2(
      //           context: context,
      //           onPressedFunction: () {
      //             print("saving");
      //             saveContactToDevice(
      //               userContact: UserContact(
      //                 firstName: widget.firstName,
      //                 lastName: widget.lastName,
      //                 email: widget.email,
      //                 company: widget.company,
      //                 role: widget.role,
      //                 phoneNumber: widget.phone,
      //               ),
      //             );
      //             Fluttertoast.showToast(msg: "Contact Saved");
      //           },
      //           buttonText: "Save Contact",
      //           backgroundColor: Colors.grey,
      //         ),
      //       ],
      //     ),
      //   ],
      // )








      Stack(
        children: [
          CoolBackground(),
          Center(
            child: GlossyContainer(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "New contact Details",
                      style: TextStyle(fontSize: 17),
                    ),
                    verticalSpace(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.person),
                        horizontalSpace(width: 25),
                        Text(widget.firstName, style: contactItemStyle()),
                      ],
                    ),
                    verticalSpace(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.person),
                        horizontalSpace(width: 25),
                        Text(widget.lastName, style: contactItemStyle()),
                      ],
                    ),
                    verticalSpace(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.email),
                        horizontalSpace(width: 25),
                        Flexible(
                          child: Text(widget.email, style: contactItemStyle()),
                        ),
                      ],
                    ),
                    verticalSpace(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.phone),
                        horizontalSpace(width: 25),
                        Text(widget.phone, style: contactItemStyle()),
                      ],
                    ),
                    verticalSpace(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.factory),
                        horizontalSpace(width: 25),
                        Flexible(
                          child: Text(widget.company, style: contactItemStyle()),
                        ),
                      ],
                    ),
                    verticalSpace(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.grid_4x4_outlined),
                        horizontalSpace(width: 25),
                        Flexible(
                          child: Text(widget.role, style: contactItemStyle()),
                        ),
                      ],
                    ),
                    verticalSpace(height: 25),

                    primaryButton2(
                      context: context,
                      onPressedFunction: ()async {
                        await saveContactToDevice(
                          userContact: UserContact(
                            firstName: widget.firstName,
                            lastName: widget.lastName,
                            email: widget.email,
                            company: widget.company,
                            role: widget.role,
                            phoneNumber: widget.phone,
                          ),
                        );
                        await UserPointsService().createOrUpdateUserPoints(userId: widget.ownerID,actionId: 3);
                        Fluttertoast.showToast(msg: "Contact Saved");
                        Navigator.of(context).pop();
                      },
                      buttonText: "Save Contact",
                      backgroundColor: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );




  }
}


class GlossyContainer extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  GlossyContainer({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.purple.shade300.withOpacity(0.3), Colors.green.shade700.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          child,
          // Positioned.fill(
          //   child: Container(
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(20),
          //       gradient: LinearGradient(
          //         colors: [
          //           Colors.white.withOpacity(0.2),
          //           Colors.white.withOpacity(0.1)
          //         ],
          //         begin: Alignment.topLeft,
          //         end: Alignment.bottomRight,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}