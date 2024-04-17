import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:dx5veevents/models/cisoAttendeesModel.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'dart:ui';

import '../../constants.dart';
import '../../dioServices/dioFetchService.dart';
import '../../dioServices/dioOTPService.dart';
import 'cisoOTP.dart';

class CISOLogin extends StatefulWidget {

  final String coverImagePath ;
  final String eventLocation ;
  final String eventDate ;
  final String eventName ;
  final String eventID ;
  final String shortEventDescription ; int eventDay;
  int eventMonth;
  int eventYear;
  CISOLogin({  required this.eventDay,
    required this.eventMonth,
    required this.eventYear,

    required this.coverImagePath, required this.eventID,required this.eventName,required this.shortEventDescription,required this.eventDate, required this.eventLocation,


    Key? key}) : super(key: key);
  @override
  State<CISOLogin> createState() => _CISOLoginState();
}

class _CISOLoginState extends State<CISOLogin> {

  List<CISOAttendeeModel>? attendees;
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();

  bool isEmail(String input) => EmailValidator.validate(input);
  bool isCreating=false;

  @override
  void initState() {
    fetchAllAttendees();
    // TODO: implement initState
    super.initState();
  }
  CISOAttendeeModel? findAttendeeByEmail(String emailToCheck) {
    return attendees!.firstWhere(
          (attendee) => attendee.workEmail.toLowerCase() == emailToCheck.toLowerCase(),

    );
  }
  sendOTP({required String email})async{
    Map<String, dynamic> emailData = {
      "email": email,

      // Add other key-value pairs as needed
    };
    try{  ///1.Try to generate otp
      final response=await DioOTPService().generateOTP(emailData);

      if(response.statusCode==200){
        CISOAttendeeModel? attendee = findAttendeeByEmail(email);
        setState(() {
          isCreating=false;
        });

        if(mounted){
          print("login screen attendee id is ${attendee!.id!}");
          PersistentNavBarNavigator.pushNewScreen(
            context,
            screen: OTPScreen(eventDay: widget.eventDay, eventMonth: widget.eventMonth, eventYear: widget.eventYear,email: email,
              isAdmin:"false",
              company: attendee!.company,
              role: attendee.role, lastName: attendee.lastName,
              firstName: attendee.firstName, phone: attendee.phone,
              id:attendee.id, profileID: attendee.profilePhoto??"",
              coverImagePath: widget.coverImagePath, eventName: widget.eventName,
              //eventDate: 'THUR, MAY, 2nd - FRIDAY MAY 3rd',
              eventDate: widget.eventDate,
              //shortEventDescription: 'The Africa Cloud and Cybersecurity Summit is a pivotal event, addressing the accelerating growth of cloud computing and the critical importance of cybersecurity in the African region.',
              shortEventDescription: widget.shortEventDescription,
              //eventLocation: 'Nigeria',);
              eventLocation: widget.eventLocation, eventID: widget.eventID,

            ),
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.slideRight,
          );
        }

      }
      ///2.if response==400 try to update otp



    }

    catch(e){
      if (e is DioError) {
        if (e.response != null &&e.response!.data["success"]==false ) {
          print("Doing catch patch");
        }
        final patchResponse=await DioOTPService().updateOTP(emailData);
        if(patchResponse.statusCode==200){
          setState(() {
            isCreating=false;
          });
          CISOAttendeeModel? attendee = findAttendeeByEmail(email);
          if(mounted){

            PersistentNavBarNavigator.pushNewScreen(

              context,
              screen: OTPScreen(eventDay: widget.eventDay, eventMonth: widget.eventMonth, eventYear: widget.eventYear,email: email,isAdmin:"false",
                company: attendee!.company,
                role: attendee.role, lastName: attendee.lastName,firstName: attendee.firstName, phone: attendee.phone,id: attendee.id, profileID: attendee.profilePhoto??"",
                coverImagePath: widget.coverImagePath, eventName: widget.eventName,
                //eventDate: 'THUR, MAY, 2nd - FRIDAY MAY 3rd',
                eventDate: widget.eventDate,
                //shortEventDescription: 'The Africa Cloud and Cybersecurity Summit is a pivotal event, addressing the accelerating growth of cloud computing and the critical importance of cybersecurity in the African region.',
                shortEventDescription: widget.shortEventDescription,
                //eventLocation: 'Nigeria',);
                eventLocation: widget.eventLocation, eventID: widget.eventID,

              ),
              withNavBar: false,
              pageTransitionAnimation: PageTransitionAnimation.slideRight,
            );
          }
        } else {
          print('Error: ${e.message}');
        }
      } else {
        print('Error: $e');
      }
    }

  }


  Widget buildEmail(){
    return TextFormField(
      style: TextStyle(
        color: kLighterGreenAccent
      ),
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: const TextStyle(fontSize: 12,color:kLighterGreenAccent ),
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email,size: 20,color: kLighterGreenAccent,),
        //contentPadding: EdgeInsets.all(20),
      ),

      // The validator receives the text that the user has entered.
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email is required';
        } else if (!isEmail(value)) {
          return 'Enter a valid email address';
        }
        return null;
      },
    );
  }
  bool doesEmailExist(String emailToCheck) {
    return attendees!.any((attendee) => attendee.workEmail.toLowerCase() == emailToCheck.toLowerCase());
  }





  Future fetchAllAttendees() async {
    final response = await DioFetchService().fetchCISOAttendees(eventID: widget.eventID);

    setState(() {
      //isFetching=false;
    });


    if (response.statusCode == 200) {

      List<dynamic> filteredData = response.data['data'].toList();



      List<CISOAttendeeModel> userList = List<CISOAttendeeModel>.from(filteredData.map((user) => CISOAttendeeModel.fromJson(user)));
      setState(() {
        attendees=userList;
      //  print(attendees![624].firstName);
        print(attendees!.length);

      });

      // return jsonData.map((userJson) => AttendeeModel.fromJson(userJson)).toList();
    } else {
      log(response.data);
      throw Exception('Failed to load data');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Blurry background
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 3, // Horizontal blur
                sigmaY: 3, // Vertical blur
              ),
              child: Image.asset(
                'assets/images/backgrounds/cisobackground.png', // Your background image
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content on top of the blurry background
          SafeArea(
            child: ListView(

                children: [
                  Column(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          height: 300,
                          width: 300,
                          child: Image.asset("assets/images/logos/cisologo.png"),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0,right: 16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              verticalSpace(
                                  height:MediaQuery.of(context).size.height * 0.04),

                              const Text(
                                "Welcome",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: kRightBubble,
                                ),
                              ),verticalSpace(height: 20),const Text(
                                "To access the app enter the email address you used to register for the event.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  // fontSize: 24,
                                  //fontWeight: FontWeight.w600,
                                  color: kRightBubble,
                                ),
                              ),
                              verticalSpace(height: 20),


                              //Email
                              buildEmail(),
                              verticalSpace(height: 10),


                              //Password

                              Align(alignment: Alignment.center,child:

                              isCreating?ElevatedButton(onPressed: (){}, child: const Center(child:  Center(
                                child: SpinKitChasingDots(
                                  color: kCIOPurple,
                                  size: 20,
                                  duration: Duration(milliseconds: 2000),
                                ),
                              ),)):primaryButton(
                                  buttonText: "GET OTP",
                                  onPressedFunction: () async {
                                    if(emailController.text=="admin@applereviewer.com"){
                                      if(mounted){
                                        PersistentNavBarNavigator.pushNewScreen(
                                          context,
                                          screen: OTPScreen(eventDay: widget.eventDay, eventMonth: widget.eventMonth, eventYear: widget.eventYear,email: "admin@applereviewer.com",
                                            isAdmin:"true",
                                            company: "apple",
                                            role: "reviewer", lastName: "Reviewer",firstName: "Apple", phone: "5678900000",id:9789, profileID: "",
                                            coverImagePath: widget.coverImagePath, eventName: widget.eventName,
                                            //eventDate: 'THUR, MAY, 2nd - FRIDAY MAY 3rd',
                                            eventDate: widget.eventDate,
                                            //shortEventDescription: 'The Africa Cloud and Cybersecurity Summit is a pivotal event, addressing the accelerating growth of cloud computing and the critical importance of cybersecurity in the African region.',
                                            shortEventDescription: widget.shortEventDescription,
                                            //eventLocation: 'Nigeria',);
                                            eventLocation: widget.eventLocation, eventID: widget.eventID,

                                          ),
                                          withNavBar: false,
                                          pageTransitionAnimation: PageTransitionAnimation.slideRight,
                                        );
                                      }

                                    }
                                    if (_formKey.currentState!.validate()) {
                                      setState(() {
                                        isCreating=true;
                                      });
                                      bool emailExists = doesEmailExist(emailController.text);
                                      ///Send otp


                                      if (emailExists) {
                                        ///Send otp

                                        await sendOTP(email: emailController.text);



                                      } else {
                                        Fluttertoast.showToast(msg: "Error: Email not found!",backgroundColor: kKeyRedBG);
                                        setState(() {
                                          isCreating=false;
                                        });
                                      }





                                    }


                                  }, context: context),)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  verticalSpace(height: 30)
                ]),
          ),
        ],
      ),
    );
  }
}