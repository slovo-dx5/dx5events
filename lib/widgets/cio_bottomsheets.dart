import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../dioServices/dioPostService.dart';
import '../helpers/helper_functions.dart';
import '../helpers/time_dropdown.dart';
import '../providers.dart';

class SponsorBottomSheet extends StatefulWidget {
  String SponsorName;
  String SponsorImage;
  String SponsorAbout;
  String SponsorURL;
  SponsorBottomSheet(
      {Key? key,
      required this.SponsorImage,
      required this.SponsorURL,
      required this.SponsorAbout,
      required this.SponsorName})
      : super(key: key);

  @override
  _SponsorBottomSheetState createState() => _SponsorBottomSheetState();
}

class _SponsorBottomSheetState extends State<SponsorBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final List<String> errors = [];
  int current = 0;

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 20, 20, 100),
        child: Column(
          children: [
            GestureDetector(
                onTap: () {
                  visitSponsor(url: widget.SponsorURL);
                },
                child: SizedBox(
                    height: 150, child: Image.network(widget.SponsorImage))),
            verticalSpace(height: 30),
            HtmlWidget(
              widget.SponsorAbout,
             // style: TextStyle(color: kTextColorBlack, fontSize: 14),
            )
          ],
        ),
      ),
    ));
  }
}

class EditCompanyBottomSheet extends StatefulWidget {
  String userCompany;

  EditCompanyBottomSheet({
    Key? key,
    required this.userCompany,
  }) : super(key: key);

  @override
  _EditCompanyBottomSheetState createState() => _EditCompanyBottomSheetState();
}

class _EditCompanyBottomSheetState extends State<EditCompanyBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final List<String> errors = [];
  int current = 0;
  TextEditingController textEditingController = TextEditingController();
  bool isEditing = false;
  String? companyName;

  @override
  void initState() {
    // TODO: implement initState
    setState(() {
      companyName = widget.userCompany;
      textEditingController.text = companyName!;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: textEditingController,
            decoration: InputDecoration(
              hintText: companyName,
            ),
          ),
          verticalSpace(height: 25),
          SizedBox(
              height: 40,
              width: 135,
              child: ElevatedButton(
                  onPressed: () async {
                    await profileProvider.editCompany(
                        newcompany: textEditingController.text);
                    Fluttertoast.showToast(
                        backgroundColor: kSuccessGreen,
                        msg: "Company edited successfully");
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 14),
                  )))
        ],
      ),
    );
  }
}

class EditRoleBottomSheet extends StatefulWidget {
  String userRole;
  EditRoleBottomSheet({required this.userRole, super.key});

  @override
  State<EditRoleBottomSheet> createState() => _EditRoleBottomSheetState();
}

class _EditRoleBottomSheetState extends State<EditRoleBottomSheet> {
  TextEditingController textEditingController = TextEditingController();
  bool isEditing = false;
  String? roleName;

  @override
  void initState() {
    // TODO: implement initState
    setState(() {
      roleName = widget.userRole;
      textEditingController.text = roleName!;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: textEditingController,
            decoration: InputDecoration(
              hintText: roleName,
            ),
          ),
          verticalSpace(height: 25),
          SizedBox(
              height: 40,
              width: 135,
              child: ElevatedButton(
                  onPressed: () async {
                    await profileProvider.editRole(
                        newRole: textEditingController.text);
                    Fluttertoast.showToast(
                        backgroundColor: kSuccessGreen,
                        msg: "Role edited successfully");
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 14),
                  )))
        ],
      ),
    );
  }
}

class MeetingRequestBottomSheet extends StatefulWidget {
  String userName;
  String meetingWith;
  int otherUSerID;

  MeetingRequestBottomSheet(
      {required this.userName,
      required this.meetingWith,
      required this.otherUSerID,
      super.key});

  @override
  State<MeetingRequestBottomSheet> createState() =>
      _MeetingRequestBottomSheetState();
}

class _MeetingRequestBottomSheetState extends State<MeetingRequestBottomSheet> {
  TextEditingController textEditingController = TextEditingController();
  bool isEditing = false;
  bool isSending = false;
  String startTime = "";

  String placeholderText = "";

  @override
  void initState() {
    // TODO: implement initState
    setState(() {
      placeholderText =
          "Hello ${widget.userName}. I'd like to have a meeting with you.";

      textEditingController.text = placeholderText;
    });

    super.initState();
  }

  sendMeetingNotification() async {
   // get receiver token
    String ?receiverToken;
    try{
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection("users").doc(widget.otherUSerID.toString()).get();
      //.collection("users").doc("158").get();

      if (documentSnapshot.exists) {
        // Replace 'field_name' with the name of the field you want to fetch
        setState(() {
          receiverToken=documentSnapshot.get('messaging_token').toString();
          print("receiver token is $receiverToken");
        });
        await DioPostService().sendNotification({"to": receiverToken,
          "notification":{
            //"title": sentFromname,
            "body": "New Meeting request"
          }
        });
        return documentSnapshot.get('messaging_token').toString();
      } else {
        return 'Document does not exist';
      }
    }catch(e){
      print("Coul not get user id");
    }
    //
  }
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text("You can request a 30 minute meeting with ${widget.userName}"),
          TextFormField(
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
            controller: textEditingController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Message",
              contentPadding:
                  new EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0),
              hintText: placeholderText,
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return "You must provide a message";
              }
              return null;
            },
          ),
          verticalSpace(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Starting time: ", style: TextStyle(fontSize: 15)),
              TimeDropdown(
                onTimePicked: (String? value) {
                  setState(() {
                    startTime = value!;
                  });
                },
              ),
            ],
          ),
          verticalSpace(height: 50),
          SizedBox(
              height: 40,
              width: 135,
              child: ElevatedButton(
                  onPressed: () async {
                    if (startTime == "") {
                      Fluttertoast.showToast(
                          msg: "You must select starting time",
                          backgroundColor: kLogoutRed);
                    } else {
                      setState(() {
                        isSending = true;
                      });
                      await requestMeeting(
                          currentUserID: profileProvider.userID!,
                          requestedBy:
                              "${profileProvider.firstName} ${profileProvider.lastName}",
                          meetingWith: widget.meetingWith,
                          message: textEditingController.text,
                          company: profileProvider.company,
                          otherUserID: widget.otherUSerID,
                          startTime: startTime,
                          requestedByID: profileProvider.userID.toString(),
                          meetingWithI: widget.otherUSerID.toString());
                      await sendMeetingNotification();
                      //sendMeetingRequest();
                      setState(() {
                        isSending = false;
                      });
                      Fluttertoast.showToast(
                          backgroundColor: kSuccessGreen,
                          msg: "Meeting request sent");
                      Navigator.of(context).pop();
                    }
                  },
                  child: isSending
                      ? const SpinKitCircle(
                          color: kWhiteColor,
                        )
                      : const Text(
                          "Send",
                          style: TextStyle(fontSize: 14),
                        )))
        ],
      ),
    );
  }
}

profileBottomSheet(
  BuildContext context,
  String title,
  Widget myExpandedWidget,
) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.2,
        maxChildSize: 0.6,
        expand: false,
        builder: (_, controller) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                SizedBox(width: 30),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w900),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: new BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                        color: Color(0xFFEEEEEE),
                      ),
                      child: Icon(Icons.close_rounded)),
                ),
                SizedBox(width: 5)
              ],
            ),
            myExpandedWidget
          ],
        ),
      ),
    );

defaultScrollableBottomSheet(
  BuildContext context,
  String title,
  Widget myExpandedWidget,
) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.6,
        expand: false,
        builder: (_, controller) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                SizedBox(width: 30),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w900),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: new BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                        color: Color(0xFFEEEEEE),
                      ),
                      child: Icon(Icons.close_rounded)),
                ),
                SizedBox(width: 5)
              ],
            ),
            myExpandedWidget
          ],
        ),
      ),
    );

class PendingEventBottomSheet extends StatefulWidget {
  String imagePath;
  int month;
  int date;
  String slug;


  PendingEventBottomSheet(
      {required this.imagePath,
      required this.month,
      required this.date,
        required this.slug,
      super.key});

  @override
  State<PendingEventBottomSheet> createState() =>
      _PendingEventBottomSheetState();
}

class _PendingEventBottomSheetState extends State<PendingEventBottomSheet> {
  Timer? _timer;
  Duration _duration = Duration();
// Format: Year, Month, Date

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateTime());
    _updateTime();
  }

  void _updateTime() {
    final DateTime _targetDate = DateTime(2024, widget.month, widget.date);
    final now = DateTime.now();
    final difference = _targetDate.difference(now);
    setState(() {
      _duration = difference;
    });

    if (difference.inSeconds < 0) {
      _timer?.cancel();
      // Handle countdown finished
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format the duration to include leading zeros
    final days=_duration.inDays.toString().padLeft(2,'0');
    final hours = _duration.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes =
        _duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, right: 15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: kGrayishBlueText,
        ),
        height: MediaQuery.of(context).size.height * 0.5,
        width: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 140,
                width: MediaQuery.of(context).size.width,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(widget.imagePath),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ),
            verticalSpace(height: 15),
            const Text(
              "Happening in:",
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: kLighterGreenAccent),
            ),
            Center(
              child: Text('$days Days,$hours Hours,\n$minutes Minutes,\n$seconds Seconds',
                  style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: kLightDisabledColor),textAlign: TextAlign.center,),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20.0,10,20,30),
              child: Divider(thickness: 7,color:kLighterGreenAccent ,),
            ),
            SizedBox(height: 50,    width: MediaQuery.of(context).size.width * 0.6,

              child: ElevatedButton(
                  onPressed:(){openTicketURL(slug: widget.slug);},
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: kPrimaryLightGrey, // Text color
                  ),
                  child: const Text(
                    "Buy Ticket",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,color: kTextColorBlack),
                  )),
            ),

          ],
        ),
      ),
    );
  }
}
