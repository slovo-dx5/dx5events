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
    return SafeArea(
        child: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(elevation: 2,
                child: Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: MediaQuery.of(context).size.width * 0.5,

                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.fill,
                      ),
                    ),
                    Container(color: kCIOPink.withOpacity(0.1),
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: MediaQuery.of(context).size.width * 0.5,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.speakerName,
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            verticalSpace(height: 10),
                            Flexible(
                              child: Text(
                                "${widget.title}",style: TextStyle(fontSize: 15),
                              ),
                            ),                      verticalSpace(height: 5),

                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),

              verticalSpace(height: 10),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
                  const Text("About",style: TextStyle(fontSize: 22,fontWeight: FontWeight.w600),),
                  Text(widget.Bio,style: TextStyle(fontSize: 14),),
                  verticalSpace(height: 5),
                  const Divider(),
                  verticalSpace(height: 5),


                  // SizedBox(height: MediaQuery.of(context).size.height*0.18,
                  //   child:
                  //   GridView.builder(
                  //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  //         mainAxisSpacing: 2,
                  //         crossAxisSpacing: 2,
                  //         crossAxisCount: 2,
                  //         childAspectRatio:(2 / .5),
                  //       ),
                  //       itemCount: widget.Interests.length,
                  //       itemBuilder: (context,index){
                  //         final data = widget.Interests[index];
                  //         return interestWidget(interest: data);
                  //       }),

                  //
                  Center(child: linkedinButton(context: context,linkedinURL: widget.linkedinurl),)



                ],),
              )

            ],
          ),
        ));
  }
}
