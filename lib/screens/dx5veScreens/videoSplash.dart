import 'package:dx5veevents/screens/landingPage2.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../constants.dart';

class VideoSplashScreen extends StatefulWidget {
  @override
  _VideoSplashScreenState createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.asset('assets/splash2.mp4');

    await _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      showControls: false,
      //aspectRatio: MediaQuery.of(context).size.aspectRatio, // Ensure the aspect ratio fits the screen
      allowFullScreen: true, // Disable fullscreen controls
      autoInitialize: true,
    );

    setState(() {});

    _videoPlayerController!.addListener(() {
      if (_videoPlayerController!.value.position == _videoPlayerController!.value.duration) {
        // Video finished, navigate to the main screen
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LandingPage2()));
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScreenDark,
      body: Center(
        child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : CircularProgressIndicator(),
      ),
    );
  }
}