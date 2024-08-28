import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../landingPage2.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize the video player controller with the local video file
    _controller = VideoPlayerController.asset('assets/splash.mp4')
      ..initialize().then((_) {
        // Ensure the video plays automatically
        _controller.play();

        // Ensure the video is displayed as soon as it's ready
        setState(() {});

        // Set the video to loop for 8 seconds, then navigate to the next screen
        _controller.addListener(() {
          if (_controller.value.position >= Duration(seconds: 6)) {
            _navigateToHome();
          }
        });
      });
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    // Navigate to the main screen after the splash screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LandingPage2(),),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _controller.value.isInitialized
              ? Center(
                child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
              )
              : Center(child: CircularProgressIndicator()),

          // Optional: Add a fade-out effect towards the end of the video
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedOpacity(
                opacity: _controller.value.position >= Duration(seconds: 7) ? 0.0 : 1.0,
                duration: Duration(seconds: 1),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


