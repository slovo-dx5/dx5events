import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import '../providers.dart';


class CheckInWidget extends StatefulWidget {
  const CheckInWidget({super.key});

  @override
  State<CheckInWidget> createState() => _CheckInWidgetState();
}

class _CheckInWidgetState extends State<CheckInWidget> {


  int randomNumber = Random().nextInt(10000); // Generates a number from 0 to 9999

  // Ensuring the number is 4 digits by adding leading zeros if necessary

  String returnedOTP = "";
  bool isSendingOTP=false;
  bool hasSentOTP=false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return  Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Visibility(
        visible: isSendingOTP==false && hasSentOTP==false,
        replacement: Center(child: Text(returnedOTP,style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),)),
        child: InkWell(
          splashColor: kPrimaryColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          onTap: ()async{
            setState(() {
              isSendingOTP=true;

            });


            // try{
            //   final response=await DioPostService().sendCheckInOTP(body: {
            //     "email": profileProvider.email,
            //
            //
            //   },  );
            //   print("update status is ${response.statusCode}");
            //   if(response.statusCode==200){
            //     Fluttertoast.showToast(msg: "Success");
            //     setState(() {
            //       returnedOTP=response.data["otp"];
            //       isSendingOTP=false;
            //       hasSentOTP=true;
            //     });
            //
            //   }else{
            //     setState(() {
            //       isSendingOTP=false ; hasSentOTP=false;
            //     });
            //   }
            // }catch(e){
            //
            //   setState(() {
            //     isSendingOTP=false ; hasSentOTP=false;
            //   });
            // }


          },
          child: Row(
            children: [
              const Icon(
                Icons.check,
                color: Colors.green,
              ),
              horizontalSpace(width: 10),
               Visibility(
                visible: isSendingOTP==false,
                replacement: const SpinKitCircle(color: kCIOPink,),
                child: const Text(
                  "Checkin",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                size: 15,
              )
            ],
          ),
        ),
      ),
    );
  }
}
