import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../constants.dart';
import '../helpers/helper_functions.dart';

class OutgoingMeetingWidget extends StatefulWidget {
  String startTime;
  String message;

  String wantsToMeetWithName;
  bool isAccepting;
  VoidCallback acceptMeetingFunc;
  VoidCallback declineMeetingFunc;
  OutgoingMeetingWidget(
      {super.key,

        required this.startTime,
        required this.isAccepting,
        required this.acceptMeetingFunc,
        required this.declineMeetingFunc,


        required this.message,
        required this.wantsToMeetWithName});

  @override
  State<OutgoingMeetingWidget> createState() => _OutgoingMeetingWidgetState();
}

class _OutgoingMeetingWidgetState extends State<OutgoingMeetingWidget> {
  @override
  Widget build(BuildContext context) {
    return  Container(

      child: Container(
        width:  MediaQuery.of(context).size.width ,
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kToggleLight),),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(border: Border.all(color:kLightGrayishOrange,width: 1 ),
                      borderRadius: BorderRadius.circular(25),color:kLightGrayishOrange ),

                  child: Text("Sent request to ${widget.wantsToMeetWithName}",style: TextStyle(color: kCIOPink),)),
              verticalSpace(height: 25),
              Text("Your message:\n${widget.message}",style: const TextStyle(fontSize: 15,),),
              verticalSpace(height: 10),

              Text("Proposed time: Today ${widget.startTime} to ${addThirtyMinutes(time: widget.startTime)}"),
              verticalSpace(height: 15),
              Align(alignment: Alignment.bottomCenter,
                child: SizedBox(

                    child: ElevatedButton(
                        style: const ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(kKeyRedBG),),
                        onPressed: widget.declineMeetingFunc, child: const Text("Cancel",style: TextStyle(fontSize: 13),))),

              )
            ],
          ),
        ),
      ),
    );

  }
}
