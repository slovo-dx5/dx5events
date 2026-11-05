import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// One part of the event venue: a hall, deck, beach stage, etc.
///
/// POC: the list below is hard-coded. Once real scans exist this moves to
/// Firestore (`events/{id}/venueSites/{siteId}`) with the GLBs in Storage —
/// see docs/features/venue-navigation-plan.md.
class VenueSite {
  const VenueSite({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.modelAsset,
    this.headingDeg = 0,
    this.scale = 1,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;

  /// Bundled GLB for this site (a scan exported from Polycam/3D Scanner App and
  /// converted in Blender). Null = pin only, no 3D model.
  final String? modelAsset;

  /// Rotation of the model around its vertical axis, degrees clockwise from
  /// north. Tweak until the scan lines up with the satellite image.
  final double headingDeg;

  /// Uniform scale. Scans are already in metres, so this stays 1 unless the
  /// export used other units.
  final double scale;

  Position get position => Position(lng, lat);
}

/// Diamonds Leisure Beach & Golf Resort, Diani (OSM node 6063297416).
const double kResortLat = -4.28117;
const double kResortLng = 39.59005;

/// Area cached for offline use: the resort grounds plus the beach, with some
/// margin (~1.3 km x 1.1 km).
const double kVenueBoundsSouth = -4.2875;
const double kVenueBoundsNorth = -4.2755;
const double kVenueBoundsWest = 39.5840;
const double kVenueBoundsEast = 39.5960;

/// PLACEHOLDER positions, picked from OpenStreetMap to exercise the map.
/// Replace with the real event spaces once they're confirmed on site.
const List<VenueSite> kVenueSites = [
  VenueSite(
    id: 'main-hall',
    name: 'Main Hall',
    lat: -4.28117,
    lng: 39.59005,
    // Stand-in box until the first real scan replaces it.
    modelAsset: 'assets/venue_map/placeholder_hall.glb',
  ),
  VenueSite(
    id: 'pool-deck',
    name: 'Pool Deck',
    lat: -4.28415,
    lng: 39.59217,
  ),
  VenueSite(
    id: 'golf-club',
    name: 'Golf Club',
    lat: -4.28085,
    lng: 39.58975,
  ),
  VenueSite(
    id: 'beach-stage',
    name: 'Beach Stage',
    lat: -4.28190,
    lng: 39.59300,
  ),
];
