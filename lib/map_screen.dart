// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class MapScreen extends StatefulWidget {
//   const MapScreen({Key? key}) : super(key: key);
//
//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }
//
// class _MapScreenState extends State<MapScreen> {
//   late final WebViewController _controller;
//   bool _isLoading = true;
//   String? _errorMessage;
//   Position? _currentPosition;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeWebView();
//     _requestLocationPermission();
//   }
//
//   void _initializeWebView() {
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onProgress: (int progress) {
//             // Update loading bar if needed
//           },
//           onPageStarted: (String url) {
//             setState(() {
//               _isLoading = true;
//               _errorMessage = null;
//             });
//           },
//           onPageFinished: (String url) {
//             setState(() {
//               _isLoading = false;
//             });
//             _injectLocationScript();
//           },
//           onWebResourceError: (WebResourceError error) {
//             setState(() {
//               _isLoading = false;
//               _errorMessage = 'Failed to load map: ${error.description}';
//             });
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse('https://www.residencetechnologies.com/home/resident_map/'));
//   }
//
//   Future<void> _requestLocationPermission() async {
//     try {
//       // Check if location services are enabled
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() {
//           _errorMessage = 'Location services are disabled. Please enable them in settings.';
//         });
//         return;
//       }
//
//       // Check for location permission
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           setState(() {
//             _errorMessage = 'Location permission denied. Please grant permission for better experience.';
//           });
//           return;
//         }
//       }
//
//       if (permission == LocationPermission.deniedForever) {
//         setState(() {
//           _errorMessage = 'Location permission permanently denied. Please enable it in app settings.';
//         });
//         return;
//       }
//
//       // Get current location
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//
//       setState(() {
//         _currentPosition = position;
//       });
//
//       // Send location to webview
//       _sendLocationToWebView(position);
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error getting location: $e';
//       });
//     }
//   }
//
//   void _injectLocationScript() {
//     // Inject JavaScript to handle geolocation
//     const script = '''
//       (function() {
//         // Override the navigator.geolocation object
//         if (navigator.geolocation) {
//           const originalGetCurrentPosition = navigator.geolocation.getCurrentPosition;
//           const originalWatchPosition = navigator.geolocation.watchPosition;
//
//           navigator.geolocation.getCurrentPosition = function(success, error, options) {
//             // This will be called from Flutter
//             window.flutterLocationSuccess = success;
//             window.flutterLocationError = error;
//
//             // Request location from Flutter
//             window.postMessage({type: 'GET_LOCATION'}, '*');
//           };
//
//           navigator.geolocation.watchPosition = function(success, error, options) {
//             // Similar implementation for watch position
//             window.flutterLocationSuccess = success;
//             window.flutterLocationError = error;
//
//             // Request location from Flutter
//             window.postMessage({type: 'WATCH_LOCATION'}, '*');
//
//             // Return a dummy watchId
//             return 1;
//           };
//         }
//       })();
//     ''';
//
//     _controller.runJavaScript(script);
//   }
//
//   void _sendLocationToWebView(Position position) {
//     // Send the location data to the webview
//     final script = '''
//       if (window.flutterLocationSuccess) {
//         const position = {
//           coords: {
//             latitude: ${position.latitude},
//             longitude: ${position.longitude},
//             accuracy: ${position.accuracy},
//             altitude: ${position.altitude},
//             altitudeAccuracy: null,
//             heading: ${position.heading},
//             speed: ${position.speed},
//           },
//           timestamp: ${position.timestamp.millisecondsSinceEpoch}
//         };
//         window.flutterLocationSuccess(position);
//       }
//     ''';
//
//     _controller.runJavaScript(script);
//   }
//
//   Future<void> _refreshLocation() async {
//     await _requestLocationPermission();
//   }
//
//   Future<void> _openSettings() async {
//     await openAppSettings();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Resident Map'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.my_location),
//             onPressed: _refreshLocation,
//             tooltip: 'Refresh Location',
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               _controller.reload();
//             },
//             tooltip: 'Refresh Map',
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           if (_errorMessage != null)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               color: Colors.orange.shade100,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     _errorMessage!,
//                     style: TextStyle(color: Colors.orange.shade800),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       ElevatedButton(
//                         onPressed: _refreshLocation,
//                         child: const Text('Retry'),
//                       ),
//                       const SizedBox(width: 8),
//                       ElevatedButton(
//                         onPressed: _openSettings,
//                         child: const Text('Settings'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           Padding(
//             padding: EdgeInsets.only(top: _errorMessage != null ? 100 : 0),
//             child: WebViewWidget(controller: _controller),
//           ),
//           if (_isLoading)
//             const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text('Loading map...'),
//                 ],
//               ),
//             ),
//           // Location indicator
//           if (_currentPosition != null)
//             Positioned(
//               top: 10,
//               right: 10,
//               child: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade100,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.green),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.location_on, color: Colors.green.shade700, size: 16),
//                     const SizedBox(width: 4),
//                     Text(
//                       'Location Enabled',
//                       style: TextStyle(
//                         color: Colors.green.shade700,
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
//
//


import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late WebViewController _controller;
  Position? _currentPosition;
  bool _locationSent = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (_currentPosition != null && !_locationSent) {
              _sendLocationToMap(_currentPosition!);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(
          "https://www.residencetechnologies.com/home/resident_map/"));

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

  void _sendLocationToMap(Position position) {
    final jsCode = """
        window.isFlutterApp = true;

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
      body: WebViewWidget(controller: _controller),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.my_location),
      //   onPressed: () async {
      //     Position position = await Geolocator.getCurrentPosition(
      //         desiredAccuracy: LocationAccuracy.high);
      //     _sendLocationToMap(position);
      //   },
      // ),
    );
  }
}
