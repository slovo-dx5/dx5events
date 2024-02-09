import 'dart:async';

import 'package:flutter/material.dart';

import 'mainNavigationPage.dart';


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 4 seconds and then navigate to the main page
    Timer(const Duration(seconds: 0), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainNavigationPage()),
      );
    });
  }



  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Center(child: Container(height:MediaQuery.of(context).size.height,width:MediaQuery.of(context).size.width,child: Image.asset("assets/images/master3.jpg",fit: BoxFit.fill,)),),
    );
  }
}