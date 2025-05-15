import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../initialScreen.dart';
import '../mainNavigationPage.dart';
import '../providers/themeProvider.dart';
import '../screens/authScreens/eventLogin.dart';
import '../screens/pastEvents/past_navigation.dart';

// Custom CurvedImageContainer widget
class CurvedImageContainer extends StatelessWidget {
  final String imagePath;
  final String dayMonth;
  final String endDayMonth;
  final String location;
  final String date;
  final String endDate;
  final double height;
  final double width;
  Function onPressedFunct;
  final double borderRadius;

  CurvedImageContainer({
    Key? key,
    required this.imagePath,
    required this.dayMonth,
    required this.date,
    required this.endDate,
    required this.location,
    required this.endDayMonth,
    required this.onPressedFunct,
    this.height = 170.0,
    this.width = 300.0,
    this.borderRadius = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPressedFunct();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          height: height,
          width: MediaQuery.of(context).size.width,
          child: Row(
            children: [
              // Text widget occupies a quarter of the container width
              Container(
                color: Colors.white70,
                width: MediaQuery.of(context).size.width * 0.25,
                height: 170,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: Colors.black, // Default text color
                              ),
                              children: [
                            TextSpan(
                                text: "$dayMonth\n",
                                style: const TextStyle(
                                    fontSize: 9, color: kLightNormalText)),
                            TextSpan(
                              text: date,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: kLightBoldText), // Make "30th" bold
                            ),
                          ])),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(borderRadius),
                            child: Container(
                              height: 30,
                              width: 3,
                              color: Colors.greenAccent,
                            )),
                      ),
                      RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: Colors.black, // Default text color
                              ),
                              children: [
                            TextSpan(
                                text: "$endDayMonth\n",
                                style: TextStyle(
                                    fontSize: 9, color: kLightNormalText)),
                            TextSpan(
                              text: endDate,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: kLightBoldText), // Make "30th" bold
                            ),
                          ])),
                      verticalSpace(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.location_on_sharp),
                          Flexible(
                              child: AutoSizeText(
                            location,
                            style: const TextStyle(fontSize: 12),
                            minFontSize: 8,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              // Image occupies the remaining three-quarters of the width
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(borderRadius),
                    bottomRight: Radius.circular(borderRadius),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class UpcomingEventWidget2 extends StatelessWidget {
  final String imagePath;
  final String dayMonth;
  final String endDayMonth;
  final String location;
  final String date;
  final String eventName;
  final String shortDescription;
  final String endDate;
  final double height;
  final double width;
  final Color containerColor;
  Function onPressedFunct;
  final double borderRadius;

  UpcomingEventWidget2({
    Key? key,
    required this.imagePath,
    required this.shortDescription,
    required this.dayMonth,
    required this.date,
    required this.endDate,
    required this.location,
    required this.endDayMonth,
    required this.onPressedFunct,
    required this.containerColor,
    required this.eventName,
    this.height = 170.0,
    this.width = 300.0,
    this.borderRadius = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: const EdgeInsets.only(left: 8.0,right: 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            imagePath, // Replace with your image path
            fit: BoxFit.cover,
          ),
          // Semi-transparent overlay
          Container(
            //color: Colors.black.withOpacity(0.5), // Adjust opacity as needed
          ),
          // Centered text
          Column(
            children: [
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Row(
              //       children: [
              //         Icon(
              //           Icons.location_on,
              //           color: Colors.white.withOpacity(0.75),
              //         ),
              //         Text(
              //           location,
              //           style: TextStyle(
              //               color: Colors.white.withOpacity(0.75),
              //               fontWeight: FontWeight.w700,
              //               fontSize: 15),
              //         ),
              //       ],
              //     ),
              //     Column(
              //       children: [
              //         verticalSpace(height: 10),
              //         Text(
              //           "Starting: $dayMonth $date",
              //           style: TextStyle(
              //               color: Colors.white.withOpacity(0.75),
              //               fontWeight: FontWeight.w700,
              //               fontSize: 15),
              //         ),
              //         verticalSpace(height: 10),
              //         Text(
              //           "Ending: $endDayMonth $endDate",
              //           style: TextStyle(
              //               color: Colors.white.withOpacity(0.75),
              //               fontWeight: FontWeight.w700,
              //               fontSize: 15),
              //         ),
              //       ],
              //     )
              //   ],
              // ),
              const Spacer(),
              // Text(
              //   eventName,
              //   textAlign: TextAlign.center,
              //   style: TextStyle(
              //     fontSize: 55,
              //     fontWeight: FontWeight.w700,
              //     color: Colors.white.withOpacity(0.8),
              //   ),
              // ),
              verticalSpace(height: 15),
              // Text(
              //   shortDescription,
              //   textAlign: TextAlign.center,
              //   style: const TextStyle(
              //     fontSize: 15,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.white70,
              //   ),
              // ),
              verticalSpace(height: 35),
              primaryButton(
                  context: context,
                  onPressedFunction: () {onPressedFunct();},
                  buttonText: "Explore More"),
              verticalSpace(height: 40)
            ],
          ),
        ],
      ),
    );
  }
}

class PastEventWidget extends StatefulWidget {
  String eventName;
  String eventAssetPath;
  String year;
  int eventID;
  PastEventWidget({super.key,required this.eventName,
    required this.year,required this.eventAssetPath, required this.eventID});

  @override
  State<PastEventWidget> createState() => _PastEventWidgetState();
}

class _PastEventWidgetState extends State<PastEventWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(onTap: (){
        PersistentNavBarNavigator.pushNewScreen(context, screen:
        PastNavigationPage(eventName: widget.eventName, eventID: widget.eventID,));
      },
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
              border: Border.all(color: kPastEventBorder),
              borderRadius: BorderRadius.circular(10),
              color: kPastEventColor),
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.25,
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image:  DecorationImage(
                      image: AssetImage(widget.eventAssetPath),
                      fit: BoxFit.fill,
                    )),
              ),
              verticalSpace(height: 20),
               Text(
                widget.eventName+widget.year,
                style: TextStyle(fontSize: 20),
              ),
              verticalSpace(height: 30),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column( crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.black54,
                          ),
                          Text(
                            "Naivasha",
                            style: TextStyle(fontSize: 14),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: Colors.black54,
                          ),
                          Text("22nd Nov- 24th Nov")
                        ],
                      ),
                    ],
                  ),
                  Container(
                      height: 40,
                      width: 100,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(60),border: Border.all(
                        color: kPrimaryColor
                      )),
                      child: Center(child: Text("Explore")))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
