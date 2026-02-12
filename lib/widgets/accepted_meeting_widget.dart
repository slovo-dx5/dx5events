import 'package:flutter/material.dart';

import '../constants.dart';
import '../helpers/helper_functions.dart';

class AcceptedMeetingWidget extends StatefulWidget {
  String startTime;
  String message;

  String requesterName;
  VoidCallback cancelMeetingFunc;

  AcceptedMeetingWidget(
      {super.key,

        required this.startTime,
        required this.cancelMeetingFunc,


        required this.message,
        required this.requesterName});

  @override
  State<AcceptedMeetingWidget> createState() => _MeetingWidgetState();
}

class _MeetingWidgetState extends State<AcceptedMeetingWidget> {
  @override
  Widget build(BuildContext context) {
    return  Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: EdgeInsets.all(8),
                decoration: BoxDecoration(border: Border.all(color:kLightGrayishOrange,width: 1 ),
                    borderRadius: BorderRadius.circular(25),color:kLightGrayishOrange ),

                child: Text("Meeting with ${widget.requesterName}",style: TextStyle(color: kCIOPink),)),
            verticalSpace(height: 25),
            Text(widget.message,style: const TextStyle(fontSize: 15,color: kToggleDark),),
            verticalSpace(height: 10),


            Align(alignment: Alignment.bottomCenter,
              child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: ElevatedButton(
                      style: const ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(kKeyRedBG),),
                      onPressed: widget.cancelMeetingFunc, child: const Text("Cancel",style: TextStyle(fontSize: 13),))),
            )
          ],
        ),
      ),
    );

  }
}