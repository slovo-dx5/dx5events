import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';

class AgendaWidget extends StatefulWidget {
  String startTime;
  String endTime;
  String sessionType;
  String sessionTitle;
  AgendaWidget({required this.startTime,required this.endTime,required this.sessionTitle,required this.sessionType, super.key});

  @override
  State<AgendaWidget> createState() => _AgendaWidgetState();
}

class _AgendaWidgetState extends State<AgendaWidget> {

  bool doesSpeakerExist(String nameToCheck,List speakerstoCheck) {
    return speakerstoCheck.any((speakerr) => speakerr.name == nameToCheck);
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  Text(widget.startTime),
                  Container(
                    height: 80,
                    width: 3,
                    color: kCIOPink,
                  ),Text(widget.startTime),
                ],
              )
            ],
          ),horizontalSpace(width: 5),Column(children: [
            Text(widget.sessionType),
            Text(widget.sessionTitle),

          ],)
        ],
      ),
    );
  }
}
