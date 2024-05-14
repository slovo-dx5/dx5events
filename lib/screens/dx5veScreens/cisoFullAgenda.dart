import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../constants.dart';
import '../../helpers/helper_functions.dart';
import '../../models/image_model.dart';
import '../../models/speakersModel.dart';
import '../../widgets/appbarWidget.dart';
import '../../widgets/breakoutWidget.dart';

class FullAgendaScreen extends StatefulWidget {
  String title;
  String startTime;
  String endTime;
  String description;
  String type;
  String eventLocation;
  String date;
  int day;
  int userID;
  bool isFromSession;
  int? sessionId;
  var speakers;
  var futures;
  var breakOuts;
  int eventDay;
  int eventMonth;
  int eventYear;
  //var sigs;
 // List <Speaker>speakersCollection;
  FullAgendaScreen(
      {super.key,
        required this.title,
        required this.day,
        required this.date,
        required this.startTime,
        required this.endTime,
      //  required this.speakersCollection,
        this.sessionId,required this.eventLocation,
        required this.speakers,
        required this.futures,
        this.breakOuts,
        required this.eventDay,required this.eventMonth, required this.eventYear,
        required this.type,
        required this.userID,
       // required this.sigs,
        required this.description,
        required this.isFromSession

      });

  @override
  State<FullAgendaScreen> createState() => _FullAgendaScreenState();
}

class _FullAgendaScreenState extends State<FullAgendaScreen> {
  final currentDate = DateTime.now();
   DateTime? targetDate;
  bool isBookmarking=false;
  int? expandedIndex;
  // getSpeakerImage({required String id})async{
  //
  //   final response = await DioFetchService().fetchImage(id: id);
  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic> imageData = json.decode(json.encode(response.data));
  //
  //     return ImageModel.fromJson(imageData).sourceUrl;
  //   } else {
  //     throw Exception('Failed to load events');
  //   }
  //
  //
  //
  // }

  String replaceUnderscoresWithSpaces(String text) {
    return text.replaceAll('_', ' ');
  }

  @override
  void initState() {

    setState(() {
      targetDate = DateTime(widget.eventYear, widget.eventMonth, widget.eventDay);
    });

    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () async{
        if(widget.isFromSession){
          setState(() {
            isBookmarking=true;
          });
          await  deleteSession(sessionID: widget.sessionId!);
          Navigator.of(context).pop();

          setState(() {
            isBookmarking=false;
          });

        }else{
          setState(() {
            isBookmarking=true;
          });
          await createSession(currentUserId: widget.userID!,
            startTime: widget.startTime, endTime: widget.endTime,
            sessionTitle: widget.title, sessionDescription: widget.description, speakers: [], sessionType: widget.type, date: widget.day,

          );
          setState(() {
            isBookmarking=false;
          });
        }

      },
        child:

        Visibility(
          replacement: SpinKitCircle(color: Colors.black54,),
          visible: isBookmarking==false,
          child: widget.isFromSession? const Icon(Icons.delete):const Icon(Icons.bookmark),),),
      appBar:  const PreferredSize(
    preferredSize: Size.fromHeight(75.0), // Default AppBar height
    child: AppBarWithGradient(
    title: 'DETAILED AGENDA',
    gradientBegin: kCIOPurple,
    gradientEnd: kCIOPink,
    ),
    ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verticalSpace(height: 20),

              Container(
                  padding: const EdgeInsets.all(5),
                  decoration:BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: kCISOPurple
              ),child: Text(replaceUnderscoresWithSpaces(widget.type.toUpperCase()),
                style: const TextStyle(fontSize: 12,color: kGradientLighterBlue),)),
              verticalSpace(height: 10),

              Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(children: [

                    Text(widget.date,style: kFullAgendaDayTextStyle(fontsiZe: 15),),
                    Text(widget.day.toString(),style: kFullAgendaDateTextStyle(fontsiZe: 30),),






                  ],),horizontalSpace(width: 10),
                  Flexible(
                    child: Column(mainAxisAlignment: MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
                        ),
                        verticalSpace(height: 5),
                        Text("${convertToAmPm(widget.startTime)} - ${convertToAmPm(widget.endTime)} ",
                          style: kFullAgendaDayTextStyle(fontsiZe: 14),),
                        verticalSpace(height: 3),
                         Text(widget.eventLocation,style: kFullAgendaDayTextStyle(fontsiZe: 14),),
                        if(widget.speakers!=[false])verticalSpace(height:10),
                        if(widget.speakers!=[false])verticalSpace(height: 5),
                        if(widget.speakers!=false)SizedBox(width: MediaQuery.of(context).size.width,height: 230,
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const AlwaysScrollableScrollPhysics(), // new
                            scrollDirection:Axis.horizontal,itemCount: 1,itemBuilder: (BuildContext context, int index){
                            // bool speakerExists = doesSpeakerExist(widget.speakers[index]["field_62ac3eeb577b8"],widget.speakersCollection);


                            //     Speaker requiredPeaker=widget.speakersCollection.firstWhere((element) => element.name==widget.speakers[index]["field_62ac3eeb577b8"]);
                            return
                              FutureBuilder<
                                  List<IndividualSpeaker?>>(
                                future: Future.wait(widget.futures),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                      snapshot.data != null) {
                                    // Join the first names of all speakers
                                    final speakerWidgets =
                                    snapshot.data!
                                        .where((speaker) =>
                                    speaker != null)
                                        .map((speaker) => Padding(
                                      padding: const EdgeInsets.only(top:8.0,bottom: 8.0),
                                      child: Row(
                                        children: [
                                          CachedNetworkImage(
                                            fit:
                                            BoxFit.cover,
                                            imageUrl:
                                            "https://subscriptions.cioafrica.co/assets/${speaker!.photo!}",
                                            // placeholder: (context, url) => CircularProgressIndicator(), // Optional
                                            // errorWidget: (context, url, error) =>  ProfileInitials(),
                                            progressIndicatorBuilder: (context, url, downloadProgress) => SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(value: downloadProgress.progress)), // Optional
                                            imageBuilder: (context, imageProvider) =>
                                                CircleAvatar(
                                                  radius: 15,
                                                  backgroundImage: imageProvider,
                                                ),
                                          ),horizontalSpace(width: 10),

                                          Column(mainAxisAlignment: MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${speaker.firstName} ${speaker.lastName}',style:kGreyTextStyle(fontsiZe: 12) ,),
                                              Text(
                                                '${speaker.role} at ${speaker.company}',style: kNameTextStyle( fontsiZe: 10),overflow: TextOverflow.ellipsis,maxLines: 2,),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ))
                                        .toList();
                                    return Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        ...speakerWidgets,
                                      ],
                                    );
                                  } else if (snapshot
                                      .connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text(
                                        'Loading speakers...');
                                  } else {
                                    return const Text(
                                        'Speakers details not available');
                                  }
                                },
                              );


                          },),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (currentDate.isAfter(targetDate!))
                Text("Session is over",style: TextStyle(fontSize: 15,color: kKeyRedBG),),




              Divider(),
              verticalSpace(height: 10),
              if(widget.description.length>0 || widget.description!="")
                const Text("About",style: TextStyle(fontSize: 17,fontWeight: FontWeight.w700),),
              verticalSpace(height: 10),

              if(widget.description!=null || widget.description!="")Text(widget.description,style: const TextStyle(fontSize: 16,color: kTextColorGrey),),
              const Divider(),verticalSpace(height: 10),
              if(widget.breakOuts!=null) const Text("Breakout Sessions",style: TextStyle(fontSize: 17,fontWeight: FontWeight.w700),),
              if(widget.breakOuts!=null) BreakOutWidget(breakOutSessions: widget.breakOuts,),


              verticalSpace(height: 60)
            ],
          ),
        ),
      ),
    );
  }
}


agendaDate({required String date}) {
  return Row(
    children: [
      const Icon(Icons.calendar_month),
      horizontalSpace(width: 5),
      Text(
        date,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
    ],
  );
}
