import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../helpers/helper_functions.dart';
import '../models/contactModel.dart';
import '../widgets/cool_background.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../widgets/textStyles.dart';
import '../database/scanned_contacts_db.dart';

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
Future<bool> saveContactToDevice({
  required String firstName,
  required String lastName,
  required String role,
  required String company,
  required String phoneNumber,
  required String email,
}) async {
  try {
    // Request permission using flutter_contacts
    final permission = await FlutterContacts.requestPermission();

    if (!permission) {
      print('Contacts permission denied');
      Fluttertoast.showToast(
        msg: "Please enable contacts permission in Settings",
        toastLength: Toast.LENGTH_LONG,
      );
      return false;
    }

    // Create contact with all fields properly set
    final newContact = Contact(
      name: Name(first: firstName, last: lastName),
      phones: phoneNumber.isNotEmpty ? [Phone(phoneNumber)] : [],
      emails: email.isNotEmpty ? [Email(email)] : [],
      organizations: company.isNotEmpty || role.isNotEmpty
        ? [Organization(company: company, title: role)]
        : [],
    );

    // Insert the contact
    await newContact.insert();
    print("Contact saved successfully: $firstName $lastName");
    return true;
  } catch (e) {
    print("Error saving contact: $e");
    Fluttertoast.showToast(
      msg: "Failed to save contact: ${e.toString()}",
      toastLength: Toast.LENGTH_LONG,
    );
    return false;
  }
}
class _SaveContactState extends State<SaveContact> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;
  ScannedContact? _existingContact;

  @override
  void initState() {
    super.initState();
    _checkForExisting();
  }

  Future<void> _checkForExisting() async {
    final existing = await ScannedContactsDatabase.instance.findExistingContact(
      ownerID: widget.ownerID,
      email: widget.email,
      phone: widget.phone,
    );
    if (!mounted) return;
    setState(() {
      _existingContact = existing;
      if (existing != null) {
        _noteController.text = existing.note;
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _onSavePressed() async {
    setState(() => _isSaving = true);

    final note = _noteController.text.trim();

    // If this contact was already saved, just update the note in our DB
    // (no second device-contact insert, no second points award).
    if (_existingContact != null) {
      try {
        await ScannedContactsDatabase.instance
            .updateNote(id: _existingContact!.id!, note: note);
        Fluttertoast.showToast(
          msg: "Note updated",
          toastLength: Toast.LENGTH_SHORT,
        );
        if (context.mounted) Navigator.of(context).pop();
      } catch (e) {
        print("Error updating note: $e");
        Fluttertoast.showToast(
          msg: "Failed to update note",
          toastLength: Toast.LENGTH_LONG,
        );
        if (mounted) setState(() => _isSaving = false);
      }
      return;
    }

    final contactSaved = await saveContactToDevice(
      firstName: widget.firstName,
      lastName: widget.lastName,
      email: widget.email,
      company: widget.company,
      role: widget.role,
      phoneNumber: widget.phone,
    );

    if (!contactSaved) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    try {
      final scannedContact = ScannedContact(
        firstName: widget.firstName,
        lastName: widget.lastName,
        phone: widget.phone,
        email: widget.email,
        company: widget.company,
        role: widget.role,
        ownerID: widget.ownerID,
        scannedAt: DateTime.now(),
        note: note,
      );
      await ScannedContactsDatabase.instance.create(scannedContact);

      await UserPointsService().createOrUpdateUserPoints(
        userId: widget.ownerID,
        actionId: 3,
      );

      Fluttertoast.showToast(
        msg: "Contact saved successfully!",
        toastLength: Toast.LENGTH_SHORT,
      );

      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      print("Error saving to database: $e");
      Fluttertoast.showToast(
        msg: "Contact saved to device but database error occurred",
        toastLength: Toast.LENGTH_LONG,
      );
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.85,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          "New Contact Details",
                          style: TextStyle(fontSize: 17),
                        ),
                      ),
                      verticalSpace(height: 24),
                      if (_existingContact != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade700),
                          ),
                          child: const Text(
                            "You've already saved this contact. You can update the note below.",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.person),
                          horizontalSpace(width: 25),
                          Text(widget.firstName, style: contactItemStyle()),
                        ],
                      ),
                      verticalSpace(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.person),
                          horizontalSpace(width: 25),
                          Text(widget.lastName, style: contactItemStyle()),
                        ],
                      ),
                      verticalSpace(height: 18),
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
                      verticalSpace(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.phone),
                          horizontalSpace(width: 25),
                          Text(widget.phone, style: contactItemStyle()),
                        ],
                      ),
                      verticalSpace(height: 18),
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
                      verticalSpace(height: 18),
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
                      verticalSpace(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.sticky_note_2_outlined),
                          horizontalSpace(width: 25),
                          Expanded(
                            child: TextField(
                              controller: _noteController,
                              maxLines: 3,
                              maxLength: 280,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText:
                                    "Add a note (e.g. \"Met at lunch, talks AI\")",
                                hintStyle: const TextStyle(fontSize: 13),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      verticalSpace(height: 16),
                      primaryButton2(
                        context: context,
                        onPressedFunction: () {
                          if (_isSaving) return;
                          _onSavePressed();
                        },
                        buttonText: _existingContact == null
                            ? "Save Contact"
                            : "Update Note",
                        backgroundColor: Colors.grey,
                      ),
                    ],
                  ),
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