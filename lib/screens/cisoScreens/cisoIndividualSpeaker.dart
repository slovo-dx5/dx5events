import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../helpers/helper_functions.dart';
import '../../helpers/helper_widgets.dart';

class IndividualSpeakerScreen extends StatefulWidget {
  String imageUrl;
  String speakerName;

  String title;
  String linkedinurl;
  String Bio;


  IndividualSpeakerScreen(
      {super.key,
        required this.imageUrl,
        required this.speakerName,
        required this.title,
        required this.linkedinurl,

        required this.Bio,


      });

  @override
  State<IndividualSpeakerScreen> createState() =>
      _IndividualSpeakerScreenState();
}

class _IndividualSpeakerScreenState extends State<IndividualSpeakerScreen> {

  @override
  Widget build(BuildContext context) {
    print("linkedin url is ${widget.linkedinurl}");
    return  SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                verticalSpace(height: 40),
              CircleAvatar(
              radius: 75.0, // Specify the radius of the avatar
              backgroundImage: NetworkImage( widget.imageUrl,),
              // Use a local asset image
            ),verticalSpace(height: 5), Text(
                  widget.speakerName,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),

                Padding(
                  padding:  EdgeInsets.fromLTRB(30,5,30,10),
                  child: Text(
                    "${widget.title}",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w400,color: kTextColorGrey),textAlign: TextAlign.center,
                  ),
                ),linkedinButton(context: context,linkedinURL: widget.linkedinurl),


                verticalSpace(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
                    Container(padding:EdgeInsets.all(10),decoration:BoxDecoration(
                      borderRadius: BorderRadius.circular(15),color: kLightAppbar
                    ),child: Text(widget.Bio,style: TextStyle(fontSize: 14,color: kTextColorGrey),)),
                    verticalSpace(height: 5),
                    const Divider(),
                    verticalSpace(height: 5),





                  ],),
                )

              ],
            ),
          ),
        ));
  }
}
