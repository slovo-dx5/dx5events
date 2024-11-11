import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

import 'howToWidget.dart';

class GamificationSystem {
  userPointsWidget({required BuildContext context,required String actionDescription,required String urlString,
    required String actionName,
    required  screenName,
    required int pointsCarried, required int currentProgress, required int requiredProgress}) {

   double percent= currentProgress/requiredProgress;
    return SizedBox(
      height: 150,  // Set the height you need for the widget
      width: double.infinity,  // Set width to fill the grid cell
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: kPrimaryColor.withOpacity(0.5)),
        ),
        child: Row(
          //mainAxisAlignment: MainAxisAlignment.center,
          //crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(10),

                child: Image.network(urlString,height: 75,width: 75,)),

            horizontalSpace(width: 10),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        Flexible(
                          child: Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Text(actionName.toUpperCase(),
                                     style: const TextStyle(fontWeight: FontWeight.w900,fontSize: 16),),
                                //verticalSpace(height: 10),
                                Text(actionDescription),

                              ],),
                            ],
                          ),
                        ),


                        Flexible(
                          child: Column(children: [
                            RichText(
                            text: TextSpan(
                              // Default style for non-specified TextSpans
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                // First variable
                                TextSpan(
                                  text: currentProgress.toString(),
                                  style: const TextStyle(
                                    fontSize: 15, // Customize style for "0"

                                  ),
                                ),
                                const TextSpan(
                                  text: " | ",
                                  style: TextStyle(
                                    fontSize: 20, // Customize style for "one"

                                  ),
                                ),

                                // Second variable
                                TextSpan(
                                  text: requiredProgress.toString(),
                                  style: const TextStyle(
                                    fontSize: 15, // Customize style for "one"

                                  ),
                                ),
                              ],
                            ),
                          ),

                            verticalSpace(height: 10),
                            RichText(
                              text: TextSpan(
                                // Default style for non-specified TextSpans
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  // First variable
                                  const TextSpan(
                                    text: "Points: ",
                                    style: TextStyle(
                                      fontSize: 13, // Customize style for "0"

                                    ),
                                  ),


                                  // Second variable
                                  TextSpan(
                                    text: pointsCarried.toString(),
                                    style: const TextStyle(
                                      fontSize: 13, // Customize style for "one"

                                    ),
                                  ),
                                ],
                              ),
                            ),
    //                         howToWidget(onPress: () { PersistentNavBarNavigator.pushNewScreen(
    // context,
    // screen: screenName
    // ,
    // withNavBar: false,
    // pageTransitionAnimation: PageTransitionAnimation.slideRight,
    // ); })
                      ],),
                        )
                      ],
                    ),
                  ),
                  Flexible(
                    child: LinearPercentIndicator(
                      animation: true,
                      animationDuration: 2000,
                      alignment: MainAxisAlignment.start,
                      width: MediaQuery.of(context).size.width*0.65,
                      lineHeight: 6.0,

                      barRadius: const Radius.circular(10),
                      percent: percent,
                      backgroundColor: Colors.grey,
                      progressColor: kPrimaryColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
