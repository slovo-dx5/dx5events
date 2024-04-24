import 'package:dx5veevents/widgets/showMoreText.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../constants.dart';
import '../helpers/helper_functions.dart';
import '../providers/themeProvider.dart';

speakerWidget({
  required BuildContext context,
  required String name,
  required String title,
  String? bio,
  required String linkedinurl,
  required String imageURL,
  // required List<String> interests,
}) {
  final themeProvider = Provider.of<ThemeProvider>(context);

  return Padding(
      padding: const EdgeInsets.only(left: 1.0, right: 1.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), color: themeProvider.themeMode==ThemeModeOptions.dark?kGrayishBlueText:kGradientLighterBlue),
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
                            color: kLightDisabledColor),
                      ),
                    )
                  ],
                ),linkedinCircularButton( linkedinURL: linkedinurl),


              ],
            ),verticalSpace(height: 10),
            bio==""?const Text(""):ShowMoreText(text: bio??"",)
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
