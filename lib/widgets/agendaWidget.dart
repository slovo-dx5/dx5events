import 'package:cached_network_image/cached_network_image.dart';
import 'package:dx5veevents/constants.dart';
import 'package:dx5veevents/models/agendaModel.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

import '../helpers/helper_functions.dart';
import '../models/speakersModel.dart';
import '../screens/cisoScreens/cisoFullAgenda.dart';

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





agendaItemWithSpeakers({required BuildContext context,
  required String title,
  required String startTime,
  required var futures, required String endTime,
  required String sessionType,required String summary,
   List <BreakoutSession>?breakoutSessions,
  required List speakers,required VoidCallback onPressedFunction,
  required int userID}){
  return Column(
    children: [
      GestureDetector( onTap:(){
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: FullAgendaScreen(
             // title: firstDaySession.title,
              title: title,
              day: 20,
            //  startTime: firstDaySession.startTime,
              startTime: startTime,
             // endTime: firstDaySession.endTime,
             endTime: endTime,
              isFromSession: false,
             // type:firstDaySession.sessionType,
              type:sessionType,
            //  userID: profileProvider.userID!,
             userID: userID!,
              //description: firstDaySession.summary,
              description: summary,
              //  speakersCollection: widget.speakersCollection,
              speakers: futures,
              breakOuts: breakoutSessions
          ),
          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.slideRight,
        );
      },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(padding: const EdgeInsets.only(top: 20,bottom: 20),
            height: speakers!.length>=2?280:190,

            color: kGreyAgenda,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(convertToAmPm(startTime),
                        //style: kGreyTextStyle(fontsiZe: 12)
                      ),horizontalSpace(width: 5),Text("-"),
                      horizontalSpace(width: 5),
                      Text(convertToAmPm(endTime),
                        //  style: kGreyTextStyle(fontsiZe: 12)
                      ),

                      Spacer(),


                      Padding(
                        padding:  const EdgeInsets.only(right:10,),
                        child: GestureDetector(onTap:

                        onPressedFunction
                            ,child: const Icon(Icons.bookmark,color: kIconDeepBlue,)),
                      )
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.start,
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        verticalSpace(height: 10),
                        Text(
                          "${title}",
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                        verticalSpace(height: 10),
                        FutureBuilder<
                            List<IndividualSpeaker?>>(
                          future: Future.wait(futures),
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

                                    Expanded(
                                      child: Column(mainAxisAlignment: MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${speaker!.firstName} ${speaker.lastName}',style:kGreyTextStyle(fontsiZe: 12) ,),
                                          Text(
                                            '${speaker!.role} at ${speaker.company}',style: kNameTextStyle( fontsiZe: 10),overflow: TextOverflow.ellipsis,maxLines: 2,),
                                        ],
                                      ),
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
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      verticalSpace(height: 10)
    ],
  );
}

agendaItemWithoutSpeakers({required BuildContext context,
  required String title,
  required String startTime,
   required String endTime,
  required String sessionType,required String summary,
   List <BreakoutSession>?breakoutSessions,
  required List speakers,required VoidCallback onPressedFunction,
  required int userID}){
  return Column(
    children: [
      GestureDetector( onTap:(){
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: FullAgendaScreen(
              title: title,
              day: 20,
              startTime:startTime,
              endTime: endTime,
              isFromSession: false,
              type:sessionType,
              userID: userID!,
              description: summary,
              //  speakersCollection: widget.speakersCollection,
              speakers: false,
              breakOuts: breakoutSessions
          ),
          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.slideRight,
        );
      },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: 100,
            color: kGreyAgenda,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(convertToAmPm(startTime),
                          //style: kGreyTextStyle(fontsiZe: 12)
                      ),horizontalSpace(width: 5),Text("-"),
                      horizontalSpace(width: 5),
                      Text(convertToAmPm(endTime),
                        //  style: kGreyTextStyle(fontsiZe: 12)
                      ),

                   Spacer(),


                      Padding(
                        padding:  const EdgeInsets.only(right:10,),
                        child: GestureDetector(onTap:

                        onPressedFunction
                        ,child: const Icon(Icons.bookmark,color: kIconDeepBlue,)),
                      )
                    ],
                  ),Column(
                    mainAxisAlignment:
                    MainAxisAlignment.start,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      verticalSpace(height: 10),
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      verticalSpace(height: 10),


                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      verticalSpace(height: 10)
    ],
  );
}