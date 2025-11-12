import 'package:flutter/material.dart';

import 'package:webview_flutter/webview_flutter.dart';

import 'package:geolocator/geolocator.dart';



class MapScreenTest extends StatefulWidget {

  @override

  _MapScreenTestState createState() => _MapScreenTestState();

}



class _MapScreenTestState extends State<MapScreenTest> {

  late WebViewController _controller;

  Position? _currentPosition;

  bool _locationSent = false;
  bool _isLoading = true;
  String? _errorMessage;



  @override

  void initState() {

    super.initState();
    _initializeWebView();
    _requestLocationPermission();

  }



  Future<void> _requestLocationPermission() async {

    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.always ||

        permission == LocationPermission.whileInUse) {

      Position position = await Geolocator.getCurrentPosition(

          desiredAccuracy: LocationAccuracy.high);

      setState(() => _currentPosition = position);

      if (_controller != null && !_locationSent) {

        _sendLocationToMap(position);

      }

    }

  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar if needed
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            //_injectLocationScript();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to load map: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.residencetechnologies.com/home/resident_map/'));
  }

  void _sendLocationToMap(Position position) {

    final jsCode = """

      if (typeof receiveFlutterLocation === 'function') {

        receiveFlutterLocation(${position.latitude}, ${position.longitude});

      }

    """;

    _locationSent = true;

    _controller.runJavaScript(jsCode);

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: Text("Resident Map")),

      body: WebViewWidget(
        controller: _controller



      ),

      floatingActionButton: FloatingActionButton(

        child: Icon(Icons.my_location),

        onPressed: () async {

          Position position = await Geolocator.getCurrentPosition(

              desiredAccuracy: LocationAccuracy.high);

          _sendLocationToMap(position);

        },

      ),

    );

  }

}

