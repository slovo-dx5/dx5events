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



class ActiveEventWidget extends StatelessWidget {
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
  final String? presenterText;
  final String? presenterLogo;
  Function onPressedFunct;
  final double borderRadius;

  ActiveEventWidget({
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
    this.presenterText,
    this.presenterLogo,
    this.height = 650.0,
    this.width = 300.0,
    this.borderRadius = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      //margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
     // height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        //borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image with parallax effect
            Positioned.fill(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),

            // Content layout - positioned to fill entire space
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium presenter badge
                    if (presenterText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00D4FF),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              presenterText!.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: 1.5,
                              ),
                            ),
                            if (presenterLogo != null) ...[
                              const SizedBox(width: 12),
                              Container(
                                height: 22,
                                width: 45,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Center(
                                  child: Text(
                                    'dx⁵',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Flexible spacer to push content to bottom
                    const Expanded(child: SizedBox()),

                    // Event details section - positioned at bottom
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Event title with better typography


                          // Enhanced date and location section


                          // Premium CTA button
                          GestureDetector(
                            onTap: () => onPressedFunct(),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient:  LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    kCISOPink.withValues(alpha: 0.9),
                                    kCISOBlue.withValues(alpha: 0.9),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    spreadRadius: 0,
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 0,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Explore Event',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: kWhiteText,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00D4FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class PastEventWidget extends StatefulWidget {
//   String eventName;
//   String eventAssetPath;
//   String year;
//   int eventID;
//   PastEventWidget({super.key,required this.eventName,
//     required this.year,required this.eventAssetPath, required this.eventID});
//
//   @override
//   State<PastEventWidget> createState() => _PastEventWidgetState();
// }
//
// class _PastEventWidgetState extends State<PastEventWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: GestureDetector(onTap: (){
//         PersistentNavBarNavigator.pushNewScreen(context, screen:
//         PastNavigationPage(eventName: widget.eventName, eventID: widget.eventID,));
//       },
//         child: Container(
//           width: MediaQuery.of(context).size.width,
//           decoration: BoxDecoration(
//               border: Border.all(color: kPastEventBorder),
//               borderRadius: BorderRadius.circular(10),
//               color: kPastEventColor),
//           padding: EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 height: MediaQuery.of(context).size.height * 0.25,
//                 width: MediaQuery.of(context).size.width * 0.9,
//                 decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     image:  DecorationImage(
//                       image: AssetImage(widget.eventAssetPath),
//                       fit: BoxFit.fill,
//                     )),
//               ),
//               verticalSpace(height: 20),
//                Text(
//                 widget.eventName+widget.year,
//                 style: TextStyle(fontSize: 20),
//               ),
//               verticalSpace(height: 30),
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Column( crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.location_on,
//                             color: Colors.black54,
//                           ),
//                           Text(
//                             "Naivasha",
//                             style: TextStyle(fontSize: 14),
//                           )
//                         ],
//                       ),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.calendar_month,
//                             color: Colors.black54,
//                           ),
//                           Text("22nd Nov- 24th Nov")
//                         ],
//                       ),
//                     ],
//                   ),
//                   Container(
//                       height: 40,
//                       width: 100,
//                       decoration: BoxDecoration(borderRadius: BorderRadius.circular(60),border: Border.all(
//                         color: kPrimaryColor
//                       )),
//                       child: Center(child: Text("Explore")))
//                 ],
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
