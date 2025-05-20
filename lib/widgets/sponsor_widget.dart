import 'package:flutter/material.dart';

import '../constants.dart';
import 'cio_bottomsheets.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

Widget sponsorWidget({
  required BuildContext context,
  required String sponsorName,
  required String sponsorAsset,
  required String sponsorBio,
  required String degree,
  required String sponsorURL,
}) {
  // Define gradient colors based on sponsor degree
  List<Color> gradientColors = [];
  Color badgeColor;

  switch (degree) {
    case "360°":
      gradientColors = [Colors.orange.shade100, Colors.orange.shade50];
      badgeColor = Colors.orange;
      break;
    case "180°":
      gradientColors = [Color(0xFFE3F2FD), Color(0xFFF5F9FF)];
      badgeColor = Color(0xFF0D47A1); // Deep blue
      break;
    case "90°":
      gradientColors = [Color(0xFFE1BEE7), Color(0xFFF3E5F5)];
      badgeColor = Color(0xFF6A1B9A); // Purple
      break;
    default:
      gradientColors = [kConnectedBlue, kConnectedBlue.withOpacity(0.05)];
      badgeColor = kConnectedGreen; // Pink
  }

  return GestureDetector(
    onTap: () {
      defaultScrollableBottomSheet(
        context,
        sponsorName,
        SponsorBottomSheet(
          SponsorImage: sponsorAsset,
          SponsorAbout: sponsorBio,
          SponsorName: sponsorName,
          SponsorURL: sponsorURL,
        ),
      );
    },
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sponsor degree badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              degree,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          // Main card container
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: Stack(
              children: [
                // Decorative elements
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Opacity(
                    opacity: 0.1,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: badgeColor,
                    ),
                  ),
                ),
                Positioned(
                  left: -15,
                  top: -15,
                  child: Opacity(
                    opacity: 0.05,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: badgeColor,
                    ),
                  ),
                ),

                // Logo container with glassmorphism effect
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: 120,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Image.network(
                          sponsorAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // Interactive hint
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Tap for details",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
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
  );
}
exhibitorWidget({required BuildContext context ,required String sponsorName,required String sponsorAsset,required String sponsorBio,required String sponsorURL}) {
  return
    GestureDetector(onTap: (){
      defaultScrollableBottomSheet(context, sponsorName, SponsorBottomSheet(SponsorImage: sponsorAsset, SponsorAbout: sponsorBio, SponsorName: sponsorName, SponsorURL: sponsorURL,));
    },child: Container(padding: EdgeInsets.all(8),
      decoration: BoxDecoration(color:Colors.white,borderRadius: BorderRadius.circular(10)),
      height: 75,
      width: MediaQuery.of(context).size.width*0.4,
      child: Column(mainAxisSize: MainAxisSize.min,mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(
            child: Image.asset(
              sponsorAsset,
              // fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    ),);
}
vmsybWidget({required BuildContext context ,required String sponsorName,required String sponsorAsset,required String sponsorBio,required String degree, required String sponsorURL}) {
  return
    GestureDetector(onTap: (){
      defaultScrollableBottomSheet(context, sponsorName, SponsorBottomSheet(SponsorImage: sponsorAsset, SponsorAbout: sponsorBio, SponsorName: sponsorName, SponsorURL: sponsorURL,));
    },child: Container(padding: EdgeInsets.all(8),
      decoration: BoxDecoration(color:Colors.white,borderRadius: BorderRadius.circular(10)),
      height: 100,
      width: MediaQuery.of(context).size.width*0.906,
      child: Column(mainAxisSize: MainAxisSize.min,mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(degree,style: TextStyle(color: Colors.black54,fontWeight: FontWeight.w600),),
          Flexible(
            child: Image.asset(
              sponsorAsset,
              // fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    ),);
}
