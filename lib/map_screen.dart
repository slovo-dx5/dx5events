import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late WebViewController _controller;
  Position? _currentPosition;
  bool _locationSent = false;
  bool _locationServicesDisabled = false;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 30; // ~9 seconds total

  @override
  void initState() {
    super.initState();
    _initWebView();
    _requestLocationPermission();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'MAP_READY' || message.message == 'PROFILE_READY') {
            debugPrint('Page signaled ready: ${message.message}');
            _trySendLocation();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // Reset state on every new page load
            _locationSent = false;
            _retryCount = 0;
            _retryTimer?.cancel();
            debugPrint('Page started: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished: $url');
            // Set Flutter flag immediately on every page
            _controller.runJavaScript('window.isFlutterApp = true;');

            // Inject polling script — works for both map and profile pages
            _controller.runJavaScript('''
              (function() {
                var attempts = 0;
                var poll = setInterval(function() {
                  attempts++;
                  // Check for either page's location receiver
                  var ready = typeof receiveFlutterLocation === "function";
                  if (ready) {
                    clearInterval(poll);
                    window.isFlutterApp = true;
                    if (window.FlutterBridge) {
                      FlutterBridge.postMessage("MAP_READY");
                    }
                  }
                  if (attempts > 80) {
                    clearInterval(poll);
                    debugPrint("Gave up waiting for receiveFlutterLocation");
                  }
                }, 150);
              })();
            ''');

            // Also start Flutter-side retry loop as backup
            _startRetryLoop();
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation within residencetechnologies.com
            // Block external apps being opened inside WebView
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            final host = uri.host;
            if (host.contains('residencetechnologies.com') ||
                host.contains('maps.googleapis.com') ||
                host.contains('openweathermap.org')) {
              return NavigationDecision.navigate;
            }

            // External links (wa.me, tel:, etc.) — let device handle them
            debugPrint('External URL blocked from WebView: ${request.url}');
            return NavigationDecision.prevent;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://www.residencetechnologies.com/home/resident_map/'),
      );
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services disabled');
      if (mounted) {
        setState(() => _locationServicesDisabled = true);
        _showLocationServicesDialog();
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() => _currentPosition = position);
      debugPrint('Got position: ${position.latitude}, ${position.longitude}');
      _trySendLocation();
    } catch (e) {
      debugPrint('Location error: $e');
      // Try with lower accuracy as fallback
      try {
        final position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          setState(() => _currentPosition = position);
          _trySendLocation();
        }
      } catch (_) {}
    }
  }

  Future<void> _showLocationServicesDialog() async {
    final opened = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Off'),
        content: const Text(
          'Enable location services so the map can show your position.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    if (opened == true) {
      await Geolocator.openLocationSettings();
      // Re-check after returning from settings
      if (mounted) await _requestLocationPermission();
    }
  }

  void _startRetryLoop() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      _retryCount++;
      if (_locationSent || _retryCount > _maxRetries) {
        timer.cancel();
        return;
      }
      _trySendLocation();
    });
  }

  void _trySendLocation() {
    if (_locationSent || _currentPosition == null) return;

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;

    _controller.runJavaScript('''
      (function() {
        window.isFlutterApp = true;
        if (typeof receiveFlutterLocation === "function") {
          receiveFlutterLocation($lat, $lng);
        }
      })();
    ''').then((_) {
      // Verify the function existed at call time
      _controller.runJavaScriptReturningResult(
          'typeof receiveFlutterLocation === "function" ? "ok" : "not_ready"'
      ).then((result) {
        if (result.toString().contains('ok') && !_locationSent) {
          setState(() => _locationSent = true);
          _retryTimer?.cancel();
          debugPrint('✅ Location sent: $lat, $lng');
        }
      }).catchError((_) {});
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_locationServicesDisabled)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MaterialBanner(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  content: const Text(
                    'Location services are off — your position won\'t appear on the map.',
                  ),
                  leading: const Icon(Icons.location_off),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await Geolocator.openLocationSettings();
                        if (mounted) await _requestLocationPermission();
                      },
                      child: const Text('Enable'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}