import 'dart:developer';
import 'dart:ui';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../../constants.dart';
import 'package:dio/dio.dart';

import '../../dioServices/dioOTPService.dart';
import '../../testScreen.dart';

class OTPScreen extends StatefulWidget {
  String email;
  String firstName;
  String lastName;
  String phone;
  String role;
  String company;
  String isAdmin;
  int id;
  String profileID;
  OTPScreen({required this.email,required this.isAdmin,required this.profileID,required this.company,required this.role,required this.lastName, required this.firstName, required this.phone,required this.id,

    Key? key}) : super(key: key);
  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  TextEditingController oTPController = TextEditingController();
  final auth=FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();
  TextEditingController passwordController = TextEditingController();
  bool isEmail(String input) => EmailValidator.validate(input);
  bool isValidating=false;
  bool _passwordVisible = false;
  final _auth = FirebaseAuth.instance;
  final usersRef = FirebaseFirestore.instance.collection("users");


  @override
  void initState() {
    super.initState();

  }
  createUserInFirestore() async {
    try {
      final User? user = _auth.currentUser;
      await usersRef.doc(widget.id.toString()).set({
        "id": widget.id,

        "email": widget.email,

        "date_created": Timestamp.now(),
        "fistname": widget.firstName,
        "lastname": widget.lastName,
        "company": widget.company,
        "position": widget.role,
        "isAdmin": widget.isAdmin,
      });
      ///create meetings collection


    } catch (e) {}
  }



  Widget buildOTP() {
    return TextFormField( style: const TextStyle(
        color: kLighterGreenAccent
    ),
      controller: oTPController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelText: 'OTP',
        labelStyle: const TextStyle(fontSize: 12,color:kLighterGreenAccent),
        prefixIcon: const Icon(Icons.pin,size: 20,color: kLighterGreenAccent,),
      ),
      // The validator receives the text that the user has entered.
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'OTP is required';
        }else if(value.length<4|| value.length>4){
          return "OTP must be 4 digits";
        }
        return null;
      },
    );
  }

  verifyOTP({required String email, required String otp})async{

    try{
      final response=await DioOTPService().verifyOTP(email: email, otp: otp);
      SharedPreferences prefs= await SharedPreferences.getInstance();
      if(response.statusCode==200){
        setIntPref(key: 'isFirstTime', value: 1);
        setStringPref(key: kFirstName, value: widget.firstName);
        setStringPref(key: kLastName, value: widget.lastName);
        setStringPref(key: kEmail, value: widget.email);
        setStringPref(key: kPhone, value: widget.phone);
        setStringPref(key: kRole, value: widget.role);
        setStringPref(key: kCompany, value: widget.company);
        setStringPref(key: kProfileID, value: widget.profileID);
        setStringPref(key: kIsAdmin, value: widget.isAdmin);
        setIntPref(key: kUserID, value: widget.id);

        ///Try to create account in firebase
        try{
          final _auth = FirebaseAuth.instance;
          final newUSer = await _auth
              .createUserWithEmailAndPassword(
              email: email, password: kDefaultPassword);
          await createUserInFirestore();
        }catch(e){
          ///If error is account exists, try to login

          if (e is FirebaseAuthException) {
            if (e.code == 'email-already-in-use') {
              print("EMail in use loggin in");
              //final user = await _auth.signInWithEmailAndPassword(email: email, password: kDefaultPassword);
              await createUserInFirestore();
              await _auth.signInWithEmailAndPassword(email: email, password: kDefaultPassword);
            } else {
              // Handle other Firebase Authentication errors.
              print('Error: ${e.code}');
            }


          }else{log("none firebase errror is $e");}
        }
        ///else
        ///



        setState(() {
          isValidating=false;
        });

        if(mounted){
          PersistentNavBarNavigator.pushNewScreen(
            context,
            //screen: SplashScreen(),
            screen: TestScreen(),
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.slideRight,
          );
        }

      }


    }catch(e){
      if (e is DioError) {
        print("is dio eroro");
        if (e.response != null &&e.response!.data["message"]=="OTP has expired" ) {
          setState(() {
            isValidating=false;
          });
          Fluttertoast.showToast(msg: "OTP expired");
          if(mounted){
            Navigator.of(context).pop();
          }
        }else if(e.response != null &&e.response!.data["message"]=="OTP does not match"){
          setState(() {
            isValidating=false;
          });
          Fluttertoast.showToast(msg: "Invalid OTP");

        }

        else {
          print('Error: ${e.message}');
        }
      } else {
        print('Error: $e');
      }
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [Positioned.fill(
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
          SafeArea(
            child: ListView(
              children: <Widget>[
                Column(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        height: 200,
                        width: 200,
                        child: Image.asset("assets/images/logos/cisologo.png"),
                      ),
                    ),
                    const SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: kRightBubble,
                              ),
                            ),
                            verticalSpace(height: 10),
                            Text(
                              "A code expiring in 5 minutes was sent to ${widget.email} Enter it below.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13,  color: kRightBubble,),
                            ),
                            verticalSpace(height: 35),
                            buildOTP(),
                            // verticalSpace(height: 25),
                            // buildPassword(),
                            verticalSpace(height: 10),

                            verticalSpace(height: 10),
                            Align(
                              alignment: Alignment.center,
                              child:

                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      primary: kPrimaryLightGrey, // Background color
                                      onPrimary: kCIOPink, // Text color
                                    ),
                                    onPressed: ()async{

                                      if(widget.email=="admin@applereviewer.com"){
                                        try{



                                          setIntPref(key: 'isFirstTime', value: 1);
                                          setStringPref(key: kFirstName, value: widget.firstName);
                                          setStringPref(key: kLastName, value: widget.lastName);
                                          setStringPref(key: kEmail, value: widget.email);
                                          setStringPref(key: kPhone, value: widget.phone);
                                          setStringPref(key: kRole, value: widget.role);
                                          setStringPref(key: kCompany, value: widget.company);
                                          setStringPref(key: kProfileID, value: widget.profileID);
                                          setStringPref(key: kIsAdmin, value: widget.isAdmin);
                                          setIntPref(key: kUserID, value: widget.id);

                                          ///Try to create account in firebase
                                          try{
                                            final _auth = FirebaseAuth.instance;
                                            final newUSer = await _auth
                                                .createUserWithEmailAndPassword(
                                                email: widget.email, password: kDefaultPassword);
                                            await createUserInFirestore();
                                          }catch(e){
                                            ///If error is account exists, try to login

                                            if (e is FirebaseAuthException) {
                                              if (e.code == 'email-already-in-use') {
                                                print("EMail in use loggin in");
                                                //final user = await _auth.signInWithEmailAndPassword(email: email, password: kDefaultPassword);
                                                await createUserInFirestore();
                                                await _auth.signInWithEmailAndPassword(email: widget.email, password: kDefaultPassword);
                                              } else {
                                                // Handle other Firebase Authentication errors.
                                                print('Error: ${e.code}');
                                              }


                                            }else{log("none firebase errror is $e");}
                                          }
                                          ///else
                                          ///



                                          setState(() {
                                            isValidating=false;
                                          });

                                          if(mounted){
                                            PersistentNavBarNavigator.pushNewScreen(
                                              context,
                                             // screen: SplashScreen(),
                                              screen: TestScreen(),
                                              withNavBar: false,
                                              pageTransitionAnimation: PageTransitionAnimation.slideRight,
                                            );
                                          }




                                        }catch(e){
                                          if (e is DioError) {
                                            print("is dio eroro");
                                            if (e.response != null &&e.response!.data["message"]=="OTP has expired" ) {
                                              setState(() {
                                                isValidating=false;
                                              });
                                              Fluttertoast.showToast(msg: "OTP expired");
                                              if(mounted){
                                                Navigator.of(context).pop();
                                              }
                                            }else if(e.response != null &&e.response!.data["message"]=="OTP does not match"){
                                              setState(() {
                                                isValidating=false;
                                              });
                                              Fluttertoast.showToast(msg: "Invalid OTP");

                                            }

                                            else {
                                              print('Error: ${e.message}');
                                            }
                                          } else {
                                            print('Error: $e');
                                          }
                                        }

                                      }
                                      else if (_formKey.currentState!.validate()) {
                                        setState(() {
                                          isValidating=true;
                                        });
                                        //Call verify otp endpoint
                                        await verifyOTP(email: widget.email, otp: oTPController.text);
                                      }
                                    },
                                    child: Visibility(visible: !isValidating,replacement: const SpinKitCircle(color: Colors.white,),
                                      child: const Text(
                                        "Login",
                                        style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                                      ),
                                    )),
                              ),
                            ),
                            verticalSpace(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Didn't receive OTP?",style: TextStyle(fontSize: 13, color: kRightBubble,),),
                                const SizedBox(width: 5.0),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop();},
                                  child: const Text(
                                    "Resend",
                                    style: TextStyle(color: kLightAccent,fontSize: 13,fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
