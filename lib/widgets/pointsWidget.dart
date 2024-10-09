import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class GamificationSystem {
  userPointsWidget() {
    return SizedBox(
      height: 400,  // Set the height you need for the widget
      width: double.infinity,  // Set width to fill the grid cell
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: kPrimaryColor.withOpacity(0.5)),
        ),
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          //crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
                height: 75,
                width: 75,
                child: Image.asset("assets/images/sponsors/master.png")),
            Text("INFLUENCER",style: TextStyle(fontWeight: FontWeight.w900,fontSize: 18),),
            verticalSpace(height: 5),
            SizedBox(height:35,child: Text("Update your profile picture")),
            Text("0/1"),
            Center(
              child: LinearPercentIndicator(
                animation: true,
                animationDuration: 2000,
                alignment: MainAxisAlignment.center,
                width: 140.0,
                lineHeight: 6.0,

                barRadius: Radius.circular(10),
                percent: 0.5,
                backgroundColor: Colors.grey,
                progressColor: kPrimaryColor,
              ),
            ),
            verticalSpace(height: 10),
            Text("Points: 200")
          ],
        ),
      ),
    );
  }
}
