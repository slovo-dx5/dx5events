import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models/contactModel.dart';
import '../widgets/cool_background.dart';

import '../widgets/textStyles.dart';
import '../database/scanned_contacts_db.dart';
import '../services/activity_logger.dart';

class SaveContact extends StatefulWidget {
  String firstName;
  String lastName;
  String phone;
  String email;
  String company;
  String role;
  int ownerID;
  /// The scanned delegate. Used as the target of the `contact_scanned` log so
  /// the Networker challenge counts distinct people, not repeat scans.
  int? attendeeID;

   SaveContact({required this.email,required this.ownerID, required this.firstName, required this.company,
    required this.role, required this.phone,required this.lastName,this.attendeeID,super.key});

  @override
  State<SaveContact> createState() => _SaveContactState();
}
const _contactsChannel = MethodChannel('dx5ve/contacts');

/// Opens the phone's own "new contact" screen pre-filled with this delegate;
/// the user confirms with Save (Android) or Done (iOS). Returns whether the
/// screen opened. Never waits on the user, and needs no contacts permission
/// to open.
///
/// Both platforms used to insert through flutter_contacts, which does its work
/// on a native background thread and replies from there: on Android 16+ that
/// crashed or never returned (fixed in 8f819f2), and on iOS it left the Save
/// button stuck with no message. Native code is in MainActivity.kt and
/// AppDelegate.swift.
Future<bool> saveContactToDevice({
  required String firstName,
  required String lastName,
  required String role,
  required String company,
  required String phoneNumber,
  required String email,
}) async {
  try {
    final opened = await _contactsChannel.invokeMethod<bool>(
      'insertViaContactsApp',
      {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phoneNumber,
        'email': email,
        'company': company,
        'role': role,
      },
    ).timeout(const Duration(seconds: 5));
    return opened ?? false;
  } catch (e) {
    debugPrint("Error opening the phone's Contacts screen: $e");
    return false;
  }
}

/// Opens the phone's Contacts screen for a contact from scan history and tells
/// the user if that failed. Used for contacts that never reached the phone.
Future<void> addScannedContactToPhone(ScannedContact c) async {
  final opened = await saveContactToDevice(
    firstName: c.firstName,
    lastName: c.lastName,
    role: c.role,
    company: c.company,
    phoneNumber: c.phone,
    email: c.email,
  );
  if (!opened) {
    Fluttertoast.showToast(
      msg: "Couldn't open your phone's Contacts. The contact is still in your scan history.",
      toastLength: Toast.LENGTH_LONG,
    );
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

  String get _contactName =>
      [widget.firstName, widget.lastName].where((s) => s.trim().isNotEmpty).join(' ');

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
          msg: "Note updated for $_contactName",
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

    // Scan history and the Networker log come first and never depend on the
    // phone's address book: on Android 16+ that save crashed the app or never
    // returned, and gating on it silently dropped the scan (and its points).
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

      if (widget.attendeeID != null && widget.attendeeID != widget.ownerID) {
        ActivityLogger.instance.log(
          action: ActivityAction.contactScanned,
          userId: widget.ownerID,
          targetType: 'attendee',
          targetId: widget.attendeeID.toString(),
        );
      }

    } catch (e) {
      print("Error saving to database: $e");
      Fluttertoast.showToast(
        msg: "Couldn't save $_contactName. Please try again.",
        toastLength: Toast.LENGTH_LONG,
      );
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    // Best effort: also add them to the phone's address book.
    final onDevice = await saveContactToDevice(
      firstName: widget.firstName,
      lastName: widget.lastName,
      email: widget.email,
      company: widget.company,
      role: widget.role,
      phoneNumber: widget.phone,
    );
    Fluttertoast.showToast(
      msg: onDevice
          ? "$_contactName saved to your scan history. Tap Save on the next screen to add them to your phone too."
          : "$_contactName saved to your scan history",
      toastLength: Toast.LENGTH_LONG,
    );
    if (mounted) Navigator.of(context).pop();
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
                      if (_existingContact != null) ...[
                        verticalSpace(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: () =>
                                addScannedContactToPhone(_existingContact!),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text("Add to phone contacts"),
                          ),
                        ),
                      ],
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