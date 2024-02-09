import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

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
    return GestureDetector(onTap: (){onPressedFunct();},
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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: Colors.black, // Default text color
                              ),
                              children: [

                                TextSpan(text: "$dayMonth\n",style: const TextStyle(fontSize: 9,color:kLightNormalText )),
                                TextSpan(
                                  text: date,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,color: kLightBoldText), // Make "30th" bold
                                ),])),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0,bottom: 4.0),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(borderRadius),
                            child: Container(
                              height: 30,
                              width: 3,
                              color: Colors.greenAccent,
                            )),
                      ),RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: Colors.black, // Default text color
                              ),
                              children: [

                                TextSpan(text: "$endDayMonth\n",style: TextStyle(fontSize: 9,color:kLightNormalText )),
                                TextSpan(
                                  text: endDate,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,color: kLightBoldText), // Make "30th" bold
                                ),])),
                      verticalSpace(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.location_on_sharp),
                          Flexible(child: AutoSizeText(location,style: const TextStyle(fontSize: 12),minFontSize: 8,   maxLines: 1,overflow: TextOverflow.ellipsis,)),
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
