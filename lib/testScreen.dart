import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';



class MapScreenTest extends StatefulWidget {

  @override

  _MapScreenTestState createState() => _MapScreenTestState();

}



class _MapScreenTestState extends State<MapScreenTest> {

  WebViewController? _controller;

  Position? _currentPosition;

  bool _locationSent = false;
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  bool _isCheckingPermission = true;
  String? _errorMessage;



  @override
  void initState() {
    super.initState();
    // Only request location permission on init, don't load webview yet
    _requestLocationPermission();
  }



  // Show dialog prompting user to open Settings or go back
  Future<void> _showSettingsDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('Go Back'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop(true);
                await openAppSettings();
              },
            ),
          ],
        );
      },
    );

    // If user chose to go back, navigate back
    if (result == false) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      setState(() {
        _isCheckingPermission = true;
      });

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them in settings.';
          _isCheckingPermission = false;
        });
        await _showSettingsDialog(
          title: 'Location Services Disabled',
          message: 'Please enable location services in Settings to use this feature.',
        );
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied.';
            _isCheckingPermission = false;
          });
          // User denied, go back
          if (mounted) {
            Navigator.of(context).pop();
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied. Please enable them in settings.';
          _isCheckingPermission = false;
        });
        await _showSettingsDialog(
          title: 'Location Permission Required',
          message: 'Location permission has been permanently denied. Please enable it in Settings to use this feature.',
        );
        return;
      }

      // Permission granted, get current position and initialize webview
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ));

        setState(() {
          _currentPosition = position;
          _errorMessage = null;
          _hasLocationPermission = true;
          _isCheckingPermission = false;
        });

        // Now initialize the webview
        _initializeWebView();

        // Send location to map after webview is ready
        if (!_locationSent) {
          _sendLocationToMap(position);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: ${e.toString()}';
        _isCheckingPermission = false;
      });
      debugPrint('Location error: $e');
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

    if (_controller != null) {
      _controller!.runJavaScript(jsCode);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Resident Map")),
      body: _isCheckingPermission
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking location permissions...'),
                ],
              ),
            )
          : !_hasLocationPermission
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Location permission required',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          'This feature requires location access to show your position on the map.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        onPressed: _requestLocationPermission,
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    if (_controller != null)
                      WebViewWidget(controller: _controller!),
                    if (_isLoading && _controller != null)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    if (_errorMessage != null)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Material(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _errorMessage = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text('Retry'),
                                      onPressed: () {
                                        setState(() {
                                          _errorMessage = null;
                                        });
                                        _requestLocationPermission();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      icon: const Icon(Icons.settings, size: 18),
                                      label: const Text('Settings'),
                                      onPressed: () async {
                                        await openAppSettings();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: _hasLocationPermission
          ? FloatingActionButton(
              child: const Icon(Icons.my_location),
              onPressed: () async {
                try {
                  Position position = await Geolocator.getCurrentPosition(
                      locationSettings: const LocationSettings(
                        accuracy: LocationAccuracy.high,
                        distanceFilter: 10,
                      ));
                  _sendLocationToMap(position);
                } catch (e) {
                  setState(() {
                    _errorMessage = 'Error getting location: ${e.toString()}';
                  });
                }
              },
            )
          : null,
    );
  }

}

