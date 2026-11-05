import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../screens/venue_map/venue_sites.dart';

enum VenueOfflineState { checking, downloading, ready, failed }

/// Downloads the venue area (satellite style + tiles) into Mapbox's TileStore
/// so the map keeps working when mobile data drops out at the resort.
///
/// The 3D models and building footprints are bundled assets, so they're
/// offline from install; only the base map needs this.
class VenueOfflineCache {
  VenueOfflineCache._();
  static final VenueOfflineCache instance = VenueOfflineCache._();

  static const String styleUri = MapboxStyles.STANDARD_SATELLITE;

  /// Bump the suffix when the bounds or zoom range change, so devices that
  /// cached the old area download the new one.
  static const String _regionId = 'dx5-venue-diani-v1';

  final ValueNotifier<VenueOfflineState> state =
      ValueNotifier(VenueOfflineState.checking);

  /// 0..1 while [state] is downloading.
  final ValueNotifier<double> progress = ValueNotifier(0);

  bool _running = false;

  /// Starts the download if the area isn't cached yet. Safe to call every time
  /// the map opens; it returns immediately when already cached or running.
  Future<void> ensureDownloaded() async {
    if (_running || state.value == VenueOfflineState.ready) return;
    _running = true;
    try {
      state.value = VenueOfflineState.checking;
      final tileStore = await TileStore.createDefault();
      final offlineManager = await OfflineManager.create();

      if (await _isCached(tileStore, offlineManager)) {
        state.value = VenueOfflineState.ready;
        return;
      }

      state.value = VenueOfflineState.downloading;
      progress.value = 0;
      double styleDone = 0, tilesDone = 0;
      void report() => progress.value = (styleDone + tilesDone) / 2;

      await Future.wait([
        offlineManager.loadStylePack(
          styleUri,
          StylePackLoadOptions(
            glyphsRasterizationMode:
                GlyphsRasterizationMode.IDEOGRAPHS_RASTERIZED_LOCALLY,
            acceptExpired: false,
          ),
          (p) {
            styleDone = _fraction(p.completedResourceCount,
                p.requiredResourceCount);
            report();
          },
        ),
        tileStore.loadTileRegion(
          _regionId,
          TileRegionLoadOptions(
            geometry: _venuePolygon().toJson(),
            descriptorsOptions: [
              TilesetDescriptorOptions(
                styleURI: styleUri,
                minZoom: 12,
                maxZoom: 18,
              ),
            ],
            acceptExpired: true,
            networkRestriction: NetworkRestriction.NONE,
          ),
          (p) {
            tilesDone = _fraction(p.completedResourceCount,
                p.requiredResourceCount);
            report();
          },
        ),
      ]);
      state.value = VenueOfflineState.ready;
    } catch (e) {
      debugPrint('Venue offline download failed: $e');
      state.value = VenueOfflineState.failed;
    } finally {
      _running = false;
    }
  }

  Future<bool> _isCached(
      TileStore tileStore, OfflineManager offlineManager) async {
    final regions = await tileStore.allTileRegions();
    final region = regions.where((r) => r.id == _regionId).firstOrNull;
    if (region == null ||
        region.completedResourceCount < region.requiredResourceCount) {
      return false;
    }
    final packs = await offlineManager.allStylePacks();
    return packs.any((p) => p.styleURI == styleUri);
  }

  static double _fraction(int done, int required) =>
      required == 0 ? 0 : done / required;

  static Polygon _venuePolygon() => Polygon(coordinates: [
        [
          Position(kVenueBoundsWest, kVenueBoundsSouth),
          Position(kVenueBoundsEast, kVenueBoundsSouth),
          Position(kVenueBoundsEast, kVenueBoundsNorth),
          Position(kVenueBoundsWest, kVenueBoundsNorth),
          Position(kVenueBoundsWest, kVenueBoundsSouth),
        ]
      ]);
}
