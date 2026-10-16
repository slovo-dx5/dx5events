import 'package:dx5veevents/widgets/showMoreText.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../constants.dart';
import '../helpers/helper_functions.dart';
import '../models/agendaModel.dart';
import '../providers/themeProvider.dart';

speakerWidget({
  required BuildContext context,
  required String name,
  required String title,
  String? bio,
  required String linkedinurl,
  required String imageURL,
  List<SpeakerSession>? sessions,
  // required List<String> interests,
}) {
  final themeProvider = Provider.of<ThemeProvider>(context);

  return Padding(
      padding: const EdgeInsets.only(left: 1.0, right: 1.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                imageURL == ""
                    ? const CircularProgressIndicator()
                    : CircleAvatar(radius: 30,
                        backgroundImage: NetworkImage(
                          imageURL!,
                        ),
                      ),
                horizontalSpace(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54),
                      ),
                    )
                  ],
                ),linkedinCircularButton( linkedinURL: linkedinurl),


              ],
            ),verticalSpace(height: 10),
            bio==""?const Text(""):ShowMoreText(text: bio??"",),
            if (sessions != null && sessions.isNotEmpty) ...[
              verticalSpace(height: 12),
              Row(
                children: [
                  Icon(Icons.mic_rounded, size: 14, color: kCISOPink),
                  horizontalSpace(width: 4),
                  Text(
                    'SPEAKING ON',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kCISOPink,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              verticalSpace(height: 6),
              ...sessions.map((session) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kGradientLighterBlue.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: kCISOBlue.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: const TextStyle(fontSize: 12, color: kTextColorBlack),
                      ),
                      verticalSpace(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 10, color: kTextColorGrey),
                          horizontalSpace(width: 3),
                          Text(
                            DateFormat('EEE, MMM d').format(session.date),
                            style: const TextStyle(fontSize: 10, color: kTextColorGrey),
                          ),
                          if (session.startTime.isNotEmpty) ...[
                            horizontalSpace(width: 8),
                            Icon(Icons.access_time, size: 10, color: kTextColorGrey),
                            horizontalSpace(width: 3),
                            Text(
                              '${convertToAmPm(session.startTime)} - ${convertToAmPm(session.endTime)}',
                              style: const TextStyle(fontSize: 10, color: kTextColorGrey),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ],
        ),
      ));
}

speakerShimmerWidget({
  required BuildContext context,

  // required List<String> interests,
}) {
  return Padding(
      padding: const EdgeInsets.only(left: 1.0, right: 1.0),
      child: SizedBox(
        child: Shimmer.fromColors(
          period: Duration(milliseconds: 2500),
          baseColor: Colors.black12,
          highlightColor: kCIOPink.withOpacity(0.25),
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.45,
                height: MediaQuery.of(context).size.width * 0.5,
                child: Card(
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ));
}
