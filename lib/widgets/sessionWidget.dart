import 'dart:math';

import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../helpers/helper_functions.dart';

import '../models/sessionModel.dart';
import '../providers.dart';
import '../screens/dx5veScreens/cisoFullAgenda.dart';
class SessionWidget extends StatefulWidget {
  String sessionTitle;
  String startTime;
  String endTime;
  String description;
  String sessionType;
  String eventDate;
  String eventLocation;
  int sessionId;
  int date;
  var futures;
  var speakers;int eventDay;
  int eventMonth;
  int eventYear;
  // List <Speaker>speakersCollection;
   List <SessionModel>sessions;



  SessionWidget({super.key, required this.speakers,

  //  required this.speakersCollection,
    required this.sessionType,required this.sessions, required this.eventDay,required this.eventDate,
    required this.eventMonth,
    required this.eventYear,required this.date,required this.eventLocation,this.futures,required this.sessionId,required this.sessionTitle, required this.startTime, required this.endTime, required this.description});

  @override
  State<SessionWidget> createState() => _SessionWidgetState();
}

class _SessionWidgetState extends State<SessionWidget> {



  Random random = Random();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }
  bool isDeleting=false;
  bool isDeleted=false;
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return  Padding(
      padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 4,bottom: 4),
      child: GestureDetector(onTap: (){
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: FullAgendaScreen(
            title: widget.sessionTitle,
            day: 20,
            startTime: widget.startTime,
            endTime: widget.endTime,
            isFromSession: false,
            type:widget.sessionType,
            userID: profileProvider.userID!,
            description: "Cybersecurity threats are constantly changing – think of new viruses, more advanced hacking techniques, and unexpected targets. There is a need for individuals and organisations to stay informed about these shifts in the threat landscape.The goal is to continuously adapt security strategies to maintain protection in this ever-evolving digital world.",
            speakers: false, eventLocation: widget.eventLocation, eventDay: widget.eventDay, eventMonth: widget.eventMonth, eventYear: widget.eventYear, futures: widget.futures, date: widget.eventDate,
          ),
          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.slideRight,
        );
      },
        child: Visibility(visible: !isDeleted,
          child:widget.speakers!=[]?

          Column(
            children: [
              Container(
                height: 180,
                color: kRightBubble.withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          height: 180,
                          color: kRightBubble,
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Text(convertToAmPm(widget.startTime),
                                  style: kGreyTextStyle(fontsiZe: 12)),
                              verticalSpace(height: 10),
                              Text(convertToAmPm(widget.endTime),
                                  style: kGreyTextStyle(fontsiZe: 12)),
                            ],
                          ),
                        ),
                        horizontalSpace(width: 15),
                        Expanded(
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.start,
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              verticalSpace(height: 10),
                              Text(
                                "${widget.sessionTitle}",
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                              verticalSpace(height: 10),


                            ],
                          ),
                        ),

                        Padding(
                          padding:  EdgeInsets.fromLTRB(10,70,5,70),
                          child: GestureDetector(
                              onTap:()async{


                                setState(() {
                                  isDeleting = true;
                                });

                                await  deleteSession(sessionID: widget.sessionId);
                                widget.sessions.removeWhere((event) => event.id == widget.sessionId);
                                setState(() {
                                  isDeleted=true;

                                  isDeleting = false;
                                });
                              },
                              child: const Icon(Icons.delete,color: kIconDeepBlue,)),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              verticalSpace(height: 10)
            ],
          ):
          Column(
            children: [
              Container(
                height: 100,
                color: kRightBubble.withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          height: 100,
                          color: kRightBubble,
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Text(convertToAmPm(widget.startTime),
                                  style: kGreyTextStyle(fontsiZe: 12)),
                              verticalSpace(height: 10),
                              Text(convertToAmPm(widget.endTime),
                                  style: kGreyTextStyle(fontsiZe: 12)),
                            ],
                          ),
                        ),
                        horizontalSpace(width: 15),
                        Expanded(
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.start,
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              verticalSpace(height: 10),
                              Text(
                                "${widget.sessionTitle}",
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                              verticalSpace(height: 10),


                            ],
                          ),
                        ),

                        Padding(
                          padding:  EdgeInsets.fromLTRB(10,30,5,30),
                          child: GestureDetector(onTap:()async{

                            setState(() {
                              isDeleted=true;

                              isDeleting = true;
                            });

                            await  deleteSession(sessionID: widget.sessionId);
                            widget.sessions.removeWhere((event) => event.id == widget.sessionId);
                            setState(() {
                              isDeleting = false;
                            });
                          } ,child: const Icon(Icons.delete,color: kIconDeepBlue,)),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              verticalSpace(height: 10)
            ],
          ),













































          // Stack(
          //   alignment: Alignment.bottomRight,
          //   children: [
          //     Container(
          //       decoration: BoxDecoration(
          //           borderRadius: BorderRadius.circular(10),
          //           color: widget.type == "Panel Discussion"
          //               ? kPanelColor.withOpacity(0.3)
          //               : widget.type == "Lunch"
          //               ? kLunchColor.withOpacity(0.3)
          //               : widget.type == "Normal"
          //               ? kTextColorNavy.withOpacity(0.3)
          //               : widget.type == "Breakout"
          //               ? kSuccessGreen.withOpacity(0.3)
          //               : kNashPurple.withOpacity(0.3)),
          //       padding: EdgeInsets.all(20),
          //       height: widget.speakers==false?180 :220 ,
          //       width: MediaQuery.of(context).size.width,
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Text(
          //             widget.agendaTitle,
          //             maxLines: 1,
          //             overflow: TextOverflow.ellipsis,
          //             style: TextStyle(
          //                 fontSize: 16,
          //                 fontWeight: FontWeight.w500,
          //                 color: kTextColorBlackLighter),
          //           ),
          //
          //           verticalSpace(height: 10),
          //           if(widget.description!=null || widget.description!="")Text(widget.description,maxLines: 2,overflow: TextOverflow.ellipsis,style: TextStyle(color: kTextColorBlack),),
          //           verticalSpace(height: 10),
          //           if(widget.date==22)const Text(
          //             "Wednesday",
          //             style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500),
          //           ),
          //           if(widget.date==23)const Text(
          //             "Thursday",
          //             style: TextStyle(fontSize: 13),
          //           ),
          //           if(widget.date==24)const Text(
          //             "Friday",
          //             style: TextStyle(fontSize: 13),
          //           ),
          //
          //
          //           Text(
          //             "${widget.startTime} - ${widget.endTime}",
          //             style: const TextStyle(fontSize: 13),
          //           ),
          //           if(widget.speakers!=false) verticalSpace(height: 5),
          //           if(widget.speakers!=false)Text("SPEAKERS",style: TextStyle(fontSize: 10),),
          //
          //           // widget.imageurl==""?CircularProgressIndicator():Image.network(
          //           //   width: MediaQuery.of(context).size.width * 0.2,
          //           //   height: MediaQuery.of(context).size.width * 0.4,
          //           //   widget.imageurl!,
          //           //   fit: BoxFit.cover,
          //           // ),
          //
          //           if(widget.speakers!=false)
          //             Container(width: MediaQuery.of(context).size.width*0.8,height: 80,
          //               child: ListView.builder(scrollDirection:Axis.horizontal,itemCount: widget.speakers.length,itemBuilder: (BuildContext context, int index){
          //                 // bool speakerExists = doesSpeakerExist(widget.speakers[index]["field_62ac3eeb577b8"],widget.speakersCollection);
          //
          //
          //                 Speaker requiredPeaker=widget.speakersCollection.firstWhere((element) => element.name==widget.speakers[index]["field_62ac3eeb577b8"]);
          //                 print("jdjdjdj speaker ius $requiredPeaker");
          //                 return FutureBuilder(future: getSpeakerImage(id:requiredPeaker.imageid), builder: (context, snapshot){
          //                   if(snapshot.connectionState!=ConnectionState.done){
          //                     return  SpinKitCircle(color: kCIOPink,);
          //                   }else{
          //                     return
          //
          //                       Padding(
          //                         padding: const EdgeInsets.all(8.0),
          //                         child: CachedNetworkImage(
          //                           fit: BoxFit.cover,
          //                           imageUrl: snapshot.data.toString(),
          //                           // placeholder: (context, url) => CircularProgressIndicator(), // Optional
          //                           // errorWidget: (context, url, error) =>  ProfileInitials(),
          //                           progressIndicatorBuilder: (context, url, downloadProgress) =>
          //                               SizedBox(height:20, width:20,child: CircularProgressIndicator(value: downloadProgress.progress)),// Optional
          //                           imageBuilder: (context, imageProvider) => CircleAvatar(
          //                             radius: 30,
          //                             backgroundImage: imageProvider,
          //                           ),
          //                         ),
          //                       );
          //
          //
          //
          //                   }
          //                 });
          //
          //
          //                 Text(widget.speakers[index]["field_62ac3eeb577b8"]);
          //               },),
          //             ),
          //
          //
          //
          //         ],
          //       ),
          //     ),
          //     Align(alignment: Alignment.centerLeft,
          //       child: Container(
          //         decoration: BoxDecoration(
          //             borderRadius: BorderRadius.circular(10),
          //             color: widget.type == "Panel Discussion"
          //                 ? kPanelColor
          //                 : widget.type == "Lunch"
          //                 ? kLunchColor
          //                 : widget.type == "Normal"
          //                 ? kTextColorNavy
          //                 : widget.type == "Breakout"
          //                 ? kSuccessGreen
          //                 : kNashPurple),
          //         height: widget.speakers==false?180 :220 ,
          //         width: 4,
          //       ),
          //     ),
          //     Padding(
          //       padding: const EdgeInsets.all(8.0),
          //       child: Visibility(
          //         visible: !isDeleting,
          //         replacement: const SpinKitCircle(
          //           color: Colors.black,
          //         ),
          //         child: IconButton(
          //           onPressed: () async {
          //             setState(() {
          //               isDeleting=true;
          //             });
          //
          //             await  deleteSession(sessionID: widget.sessionId);
          //             widget.sessions.removeWhere((event) => event.id == widget.sessionId);
          //
          //
          //
          //             setState(() {
          //               isDeleted=true;
          //               isDeleting=false;
          //             });
          //           },
          //           icon: const Icon(
          //             Icons.delete,
          //             size: 30,
          //             color: kScreenDark,
          //           ),
          //         ),
          //       ),
          //     )
          //   ],
          // ),



        ),
      ),
    );
  }
}










