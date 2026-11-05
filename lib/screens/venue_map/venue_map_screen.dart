import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart' show Geolocator, LocationPermission;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../constants.dart';
import '../../services/venue_map/venue_map_config.dart';
import '../../services/venue_map/venue_offline_cache.dart';
import 'venue_sites.dart';

/// 3D map of the event venue with the attendee's GPS position.
///
/// Layers, bottom to top: Mapbox satellite (cached offline for the resort
/// area), extruded OSM building footprints, a GLB model per scanned site, site
/// pins with labels, and the location puck.
class VenueMapScreen extends StatefulWidget {
  const VenueMapScreen({super.key});

  @override
  State<VenueMapScreen> createState() => _VenueMapScreenState();
}

class _VenueMapScreenState extends State<VenueMapScreen> {
  static const _sitesSourceId = 'venue-sites';
  static const _buildingsSourceId = 'venue-buildings';

  late ViewportState _viewport = _overview;
  MapboxMap? _mapboxMap;
  bool _locationGranted = false;
  bool _following = false;

  static final _overview = CameraViewportState(
    center: Point(coordinates: Position(kResortLng, kResortLat)),
    zoom: 16.6,
    pitch: 60,
    bearing: -25,
  );

  @override
  void initState() {
    super.initState();
    if (!VenueMapConfig.isConfigured) return;
    VenueOfflineCache.instance.ensureDownloaded();
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (!mounted) return;
    setState(() => _locationGranted = granted);
    await _enablePuck();
  }

  Future<void> _enablePuck() async {
    if (!_locationGranted) return;
    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: kConnectedBlue.toARGB32(),
        showAccuracyRing: true,
        accuracyRingColor: kConnectedBlue.withValues(alpha: 0.15).toARGB32(),
        accuracyRingBorderColor: kConnectedBlue.toARGB32(),
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
      ),
    );
  }

  void _onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    // Keep the logo/attribution clear of the site chips at the bottom.
    map.logo.updateSettings(LogoSettings(marginBottom: 84));
    map.attribution.updateSettings(AttributionSettings(marginBottom: 84));
    _enablePuck();
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final map = _mapboxMap;
    if (map == null) return;
    try {
      await _addBuildings(map);
      await _addSiteModels(map);
      await _addSitePins(map);
    } catch (e) {
      debugPrint('Venue map layers failed: $e');
    }
  }

  /// OSM footprints around the resort, extruded to their (estimated) height.
  /// Bundled, so they show even before the offline tiles finish downloading.
  Future<void> _addBuildings(MapboxMap map) async {
    final geojson =
        await rootBundle.loadString('assets/venue_map/resort_buildings.geojson');
    await map.style.addSource(GeoJsonSource(id: _buildingsSourceId, data: geojson));
    await map.style.addLayer(
      FillExtrusionLayer(id: 'venue-buildings-3d', sourceId: _buildingsSourceId)
        ..fillExtrusionColor = const Color(0xFFF2EEE6).toARGB32()
        ..fillExtrusionHeightExpression = ['get', 'height']
        ..fillExtrusionBase = 0
        ..fillExtrusionOpacity = 0.85,
    );
  }

  Future<void> _addSiteModels(MapboxMap map) async {
    for (final site in kVenueSites) {
      final asset = site.modelAsset;
      if (asset == null) continue;
      final sourceId = 'venue-model-src-${site.id}';
      await map.style.addSource(GeoJsonSource(
        id: sourceId,
        data: json.encode(Point(coordinates: site.position)),
      ));
      await map.style.addLayer(
        ModelLayer(id: 'venue-model-layer-${site.id}', sourceId: sourceId)
          // Bundled models are referenced by asset URI directly; the plugin
          // resolves it to a platform path (mapbox_maps_flutter 2.x).
          ..modelId = 'asset://$asset'
          ..modelType = ModelType.COMMON_3D
          ..modelScale = [site.scale, site.scale, site.scale]
          ..modelRotation = [0, 0, site.headingDeg],
      );
    }
  }

  Future<void> _addSitePins(MapboxMap map) async {
    final features = [
      for (final site in kVenueSites)
        {
          'type': 'Feature',
          'properties': {'id': site.id, 'name': site.name},
          'geometry': Point(coordinates: site.position).toJson(),
        }
    ];
    await map.style.addSource(GeoJsonSource(
      id: _sitesSourceId,
      data: json.encode({'type': 'FeatureCollection', 'features': features}),
    ));
    await map.style.addLayer(
      CircleLayer(id: 'venue-sites-dot', sourceId: _sitesSourceId)
        ..circleRadius = 7
        ..circleColor = kConnectedGreen.toARGB32()
        ..circleStrokeColor = Colors.white.toARGB32()
        ..circleStrokeWidth = 2,
    );
    await map.style.addLayer(
      SymbolLayer(id: 'venue-sites-label', sourceId: _sitesSourceId)
        ..textFieldExpression = ['get', 'name']
        ..textSize = 14
        ..textColor = Colors.white.toARGB32()
        ..textHaloColor = Colors.black.withValues(alpha: 0.75).toARGB32()
        ..textHaloWidth = 1.5
        ..textAnchor = TextAnchor.TOP
        ..textOffset = [0, 1.0]
        ..textAllowOverlap = true,
    );
  }

  void _followMe() {
    if (!_locationGranted) {
      _requestLocation();
      return;
    }
    _moveCamera(const FollowPuckViewportState(zoom: 18, pitch: 55),
        following: true);
  }

  void _showOverview() => _moveCamera(_overview);

  void _flyToSite(VenueSite site) {
    _moveCamera(CameraViewportState(
      center: Point(coordinates: site.position),
      zoom: 18.3,
      pitch: 60,
      bearing: -25,
    ));
  }

  void _moveCamera(ViewportState state, {bool following = false}) {
    // The only animated-viewport API in mapbox_maps_flutter 2.x.
    // ignore: experimental_member_use
    setStateWithViewportAnimation(() {
      _viewport = state;
      _following = following;
    }, transition: const FlyViewportTransition());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Venue Map')),
      body: VenueMapConfig.isConfigured ? _buildMap() : _buildNotConfigured(),
    );
  }

  Widget _buildNotConfigured() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'The venue map isn\'t set up yet.\n'
          'Add MAPBOX_ACCESS_TOKEN to assets/.env.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        MapWidget(
          key: const ValueKey('venueMap'),
          styleUri: VenueOfflineCache.styleUri,
          viewport: _viewport,
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
        ),
        const Positioned(top: 12, left: 12, child: _OfflineStatusChip()),
        Positioned(
          right: 12,
          bottom: 96,
          child: Column(
            children: [
              _MapButton(
                icon: Icons.layers_outlined,
                tooltip: 'Whole venue',
                onPressed: _showOverview,
              ),
              const SizedBox(height: 10),
              _MapButton(
                icon: _following ? Icons.my_location : Icons.location_searching,
                tooltip: 'Where am I',
                onPressed: _followMe,
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: kVenueSites.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final site = kVenueSites[i];
              return ActionChip(
                avatar: const Icon(Icons.place, size: 18, color: kConnectedGreen),
                label: Text(site.name),
                backgroundColor: Colors.white,
                onPressed: () => _flyToSite(site),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        icon: Icon(icon, color: kConnectedBlue),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

/// "Saving map for offline… 40%" / "Available offline".
class _OfflineStatusChip extends StatelessWidget {
  const _OfflineStatusChip();

  @override
  Widget build(BuildContext context) {
    final cache = VenueOfflineCache.instance;
    return ValueListenableBuilder<VenueOfflineState>(
      valueListenable: cache.state,
      builder: (context, state, _) {
        switch (state) {
          case VenueOfflineState.checking:
            return const SizedBox.shrink();
          case VenueOfflineState.downloading:
            return ValueListenableBuilder<double>(
              valueListenable: cache.progress,
              builder: (context, p, _) => _chip(
                Icons.downloading,
                'Saving map for offline… ${(p * 100).round()}%',
              ),
            );
          case VenueOfflineState.ready:
            return _chip(Icons.offline_pin, 'Available offline');
          case VenueOfflineState.failed:
            return GestureDetector(
              onTap: cache.ensureDownloaded,
              child: _chip(Icons.cloud_off, 'Offline save failed – tap to retry'),
            );
        }
      },
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
