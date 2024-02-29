import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:shimmer/shimmer.dart';

import '../constants.dart';
import '../screens/cisoScreens/cisoIndividualSpeaker.dart';

speakerWidget({
  required BuildContext context,
  required String name,

  required String title,
   String? bio,
  required String linkedinurl,
  required String imageURL,
  // required List<String> interests,
}) {
  return Padding(
      padding: const EdgeInsets.only(left: 1.0, right: 1.0),
      child: GestureDetector(
        onTap: () {
          PersistentNavBarNavigator.pushNewScreen(
            context,
            screen: IndividualSpeakerScreen(imageUrl: imageURL!, speakerName: name, title: title, Bio: bio?? "", linkedinurl: linkedinurl,),
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.slideRight,
          );
        },
        child: SizedBox(
          child: Column(
            children: [
              imageURL==""?CircularProgressIndicator():Image.network(
                width: MediaQuery.of(context).size.width * 0.45,
                height: MediaQuery.of(context).size.width * 0.4,
                imageURL!,
                fit: BoxFit.cover,
              ),
              Container(  decoration: const BoxDecoration(color: kLightCardColor,borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10),bottomRight: Radius.circular(10))),

                height: MediaQuery.of(context).size.width * 0.15,
                width: MediaQuery.of(context).size.width * 0.45,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: kTextColorBlack,
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: kTextColorGrey),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
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
                child: Card(elevation: 2,),


              ),

            ],
          ),
        ),
      ));
}