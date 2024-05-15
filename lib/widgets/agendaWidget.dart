import 'package:cached_network_image/cached_network_image.dart';
import 'package:dx5veevents/constants.dart';
import 'package:dx5veevents/models/agendaModel.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';

import '../models/speakersModel.dart';
import '../providers/themeProvider.dart';
import '../screens/dx5veScreens/eventFullAgenda.dart';


agendaItemWithSpeakers({required BuildContext context,
  required String eventLocation,
  required int eventYear,
  required int eventMonth,
  required int eventDay,
  required String title,
  required String eventDayOfWeek,
  required String startTime,
  required DateTime sessionDate,
  required int sessionID,
  required var futures, required String endTime,
  required String sessionType,required String summary,
   List <BreakoutSession>?breakoutSessions,
  required List speakers,required VoidCallback onPressedFunction,
  required int userID}){
  final themeProvider = Provider.of<ThemeProvider>(context);

  return Column(
    children: [
      GestureDetector( onTap:(){
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: FullAgendaScreen(
              title: title,
              day: eventDay,
              startTime: startTime,
             endTime: endTime,
              isFromSession: false,
              type:sessionType,
             userID: userID,
              description: summary,
              speakers: speakers,
              breakOuts: breakoutSessions, eventLocation: eventLocation, eventDay: eventDay, eventMonth: eventMonth, eventYear: eventYear, futures: futures, date: eventDayOfWeek, sessionId: sessionID, sessionDate: sessionDate,
          ),
          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.slideRight,
        );
      },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(padding: const EdgeInsets.only(top: 20,bottom: 20),
            height: speakers.length>=2?280:190,decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),color: themeProvider.themeMode==ThemeModeOptions.dark?kGreyAgenda:kGradientLighterBlue.withOpacity(0.4),),

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
                      ),horizontalSpace(width: 5),const Text("-"),
                      horizontalSpace(width: 5),
                      Text(convertToAmPm(endTime),
                      ),

                      const Spacer(),


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
                          title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                        verticalSpace(height: 10),
                        FutureBuilder<
                            List<IndividualSpeaker?>>(
                          future: Future.wait(futures),
                          builder: (context, snapshot) {
                           // print("snapshot is ${snapshot.data!.first!.firstName!}");
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
                                      "https://subscriptions.cioafrica.co/assets/${speaker!.photo}",
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
                                            '${speaker.firstName} ${speaker.lastName}',style:kGreyTextStyle(fontsiZe: 12) ,),
                                          Text(
                                            '${speaker.role} at ${speaker.company}',style: kNameTextStyle( fontsiZe: 10),overflow: TextOverflow.ellipsis,maxLines: 2,),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )

                              )
                                  .toList();
                              print("speker widgets are ${speakerWidgets.length}");
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
  required String eventDayOfWeek,
   required String endTime,required String eventLocation,
  required int eventYear,
  required int eventMonth,
  required int eventDay,
  required DateTime sessionDate,
  required int sessionID,
  required String type,required String summary,
   List <BreakoutSession>?breakoutSessions,
  required List speakers,required VoidCallback onPressedFunction,
  required int userID}){
  final themeProvider = Provider.of<ThemeProvider>(context);

  return Column(
    children: [
      GestureDetector( onTap:(){
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: FullAgendaScreen(eventLocation: eventLocation, 
            eventDay: eventDay, eventMonth: eventMonth, eventYear: eventYear,
              title: title,
              day: eventDay,
              startTime:startTime,
              endTime: endTime,
              isFromSession: false,
              type:type,
              userID: userID,
              description: summary,
              //  speakersCollection: widget.speakersCollection,
              speakers: false,
              breakOuts: breakoutSessions, futures: null, date: eventDayOfWeek, sessionId: sessionID, sessionDate: sessionDate,
          ),
          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.slideRight,
        );
      },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: 100,decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),color: themeProvider.themeMode==ThemeModeOptions.dark?kGreyAgenda:kGradientLighterBlue.withOpacity(0.5),),

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
                      ),horizontalSpace(width: 5),const Text("-"),
                      horizontalSpace(width: 5),
                      Text(convertToAmPm(endTime),
                      ),

                   const Spacer(),


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
                        title,maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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