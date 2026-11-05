import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show MapboxOptions;

import '../screens/venue_map/venue_map_screen.dart';
import '../services/venue_map/venue_map_config.dart';

/// Opens the venue map on its own, skipping login/Firebase. Handy for checking
/// a new scan or site position:
///
///   flutter run -t lib/dev/venue_map_preview.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VenueMapConfig.load();
  if (VenueMapConfig.isConfigured) {
    MapboxOptions.setAccessToken(VenueMapConfig.accessToken);
  }
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: VenueMapScreen(),
  ));
}
