import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

import '../constants.dart';
import '../models/agendaModel.dart';
class BreakOutWidget extends StatefulWidget {
  List<BreakoutSession> breakOutSessions;
   BreakOutWidget({required this.breakOutSessions,super.key});

  @override
  State<BreakOutWidget> createState() => _BreakOutWidgetState();
}

class _BreakOutWidgetState extends State<BreakOutWidget> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(height: 400,
        child: ListView.builder(
            itemCount: widget.breakOutSessions.length,
            itemBuilder: (context,index){
              final breakOut=widget.breakOutSessions[index];

              return Expanded(
                child: Column(
                  children: [
                    Container(padding: const EdgeInsets.only(top: 20,bottom: 20),
                     // height: firstDaySession.speakers!.length>=2?250:160,
                      color: kRightBubble.withOpacity(0.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Expanded(
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.start,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    verticalSpace(height: 10),
                                    Container(padding:const EdgeInsets.all(5),decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),color: kCISOOrange.withOpacity(0.5)
                                    ),child: Text(breakOut.type,),),
                                    verticalSpace(height: 15),
                                    Text(
                                      breakOut.title,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    verticalSpace(height: 10),
                                    Text(
                                      breakOut.summary,
                                      style: const TextStyle(color: kTextColorGrey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),


                                  ],
                                ),
                              ),


                            ],
                          ),
                        ],
                      ),
                    ),
                    verticalSpace(height: 10)
                  ],
                ),
              );
            }),
      ),
    );
  }
}
