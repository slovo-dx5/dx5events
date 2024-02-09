import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../constants.dart';
import '../helpers/helper_functions.dart';

class IncomingMeetingWidget extends StatefulWidget {
  String startTime;
  String message;

  String requesterName;
  bool isAccepting;
  VoidCallback acceptMeetingFunc;
  VoidCallback declineMeetingFunc;
  IncomingMeetingWidget(
      {super.key,

      required this.startTime,
        required this.isAccepting,
        required this.acceptMeetingFunc,
        required this.declineMeetingFunc,


      required this.message,
      required this.requesterName});

  @override
  State<IncomingMeetingWidget> createState() => _IncomingMeetingWidgetState();
}

class _IncomingMeetingWidgetState extends State<IncomingMeetingWidget> {
  @override
  Widget build(BuildContext context) {
    return  Container(

        child: Container(
          width:  MediaQuery.of(context).size.width ,
          height: MediaQuery.of(context).size.height * 0.3,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),border: Border.all(color: kToggleLight),color: kSuccessGreen.withOpacity(0.2)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(border: Border.all(color:kLightGrayishOrange,width: 1 ),
                    borderRadius: BorderRadius.circular(25),color:kLightGrayishOrange ),

                    child: Text("Meeting request from ${widget.requesterName}",style: TextStyle(color: kCIOPink),)),
                verticalSpace(height: 25),
                Text(widget.message,style: const TextStyle(fontSize: 15,color: kToggleDark),),
                verticalSpace(height: 10),

                Text("Proposed time: ${widget.startTime} to ${addThirtyMinutes(time: widget.startTime)}"),
                verticalSpace(height: 15),
                Align(alignment: Alignment.bottomCenter,
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                         child: ElevatedButton(
                          style: const ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(kSuccessGreen),),
                          onPressed: widget.acceptMeetingFunc, child: widget.isAccepting?SpinKitCircle(color: Colors.white,): Text("Accept",style: TextStyle(fontSize: 13),))),
                      SizedBox(

                          child: ElevatedButton(
                              style: const ButtonStyle(backgroundColor: MaterialStatePropertyAll<Color>(kKeyRedBG),),
                              onPressed: widget.declineMeetingFunc, child: const Text("Decline",style: TextStyle(fontSize: 13),)))
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );

  }
}
