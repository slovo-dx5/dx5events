
import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
class CircleGradientAvatar extends StatelessWidget {
  IconData actionIcon;
  String actionText;
  Function onPressedF;
   CircleGradientAvatar({required this.actionIcon,required this.actionText,required this.onPressedF,super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(onTap: (){onPressedF();},
          child: ClipOval(
            child: Container(
              width: 65.0, // Diameter of the circle
              height: 65.0, // Diameter of the circle
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kCIOPink,kCISOPurple, // First color
                    // Second color
                  ],
                ),
              ),child: Icon(actionIcon,color: kWhiteColor,),
            ),
          ),
        ),verticalSpace(height: 10),
        Text(actionText)
      ],
    );
  }
}
