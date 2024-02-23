import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';

import '../models/speakersModel.dart';

class AgendaWidget extends StatefulWidget {
  String startTime;
  String endTime;
  String sessionType;
  String sessionTitle;
 List <IndividualSpeaker> speakers;
  AgendaWidget({required this.startTime,required this.endTime,required this.sessionTitle,required this.speakers,required this.sessionType, super.key});

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
            if(widget.speakers!=[])Text("SPEAKERS",style: TextStyle(fontWeight: FontWeight.w600),),
            if(widget.speakers!=[])
              Container(width: MediaQuery.of(context).size.width*0.8,height: 80,
                child: ListView.builder(scrollDirection:Axis.horizontal,itemCount: widget.speakers.length,itemBuilder: (BuildContext context, int index){
                  // bool speakerExists = doesSpeakerExist(widget.speakers[index]["field_62ac3eeb577b8"],widget.speakersCollection);


                 // IndividualSpeaker requiredPeaker=widget.speakersCollection.firstWhere((element) => element.name==widget.speakers[index]["first_name"]);

                  return Text("${widget.speakers[index].firstName}");


                },),
              ),

          ],)
        ],
      ),
    );
  }
}
