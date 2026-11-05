# Venue Navigation — Plan (draft, 2026-10-22)

## Goal
Venue map page showing a 3D map of the event venue with a live "you are here" marker.
The event is spread across several sites on an island. **The developer captures the
venue beforehand; attendees never scan anything.** GPS is the position source
(no beacons, no AR for attendees).

## Reference
`assets/nav plan.mp4` is a screen recording of the "Signl" Wi-Fi app. It's only a visual
reference for the end result: a 3D plan of a space captured on an iPhone, lined up with the
real world, with live data drawn on top.

## Decisions so far
- Capture: done by the developer on an iPhone 14 Pro (LiDAR).
  - Indoor halls: RoomPlan via Polycam Room mode or 3D Scanner App → USDZ → GLB (Blender).
  - Outdoor areas: Polycam LiDAR/photo mode or Scaniverse, or a footprint traced from the
    satellite view and raised into 3D.
  - Keep each GLB under about 3–5 MB.
- Positioning: device GPS (geolocator, already a dependency). Accurate to about 3–10 m
  outdoors; only approximate inside buildings, which is acceptable.
- Rendering: MapLibre GL JS in a WebView (satellite + terrain base map) with a custom
  three.js layer that draws each site's GLB at its location. Reuse the Flutter → JS
  location push pattern from `lib/map_screen.dart` (`receiveFlutterLocation`).
- Placing scans on the map: an admin placement page where you drag, rotate and scale each GLB
  over the satellite map, then save its pose.

## Proposed data
- `events/{id}/venueSites/{siteId}`: `{name, glbUrl, lat, lng, headingDeg, altitudeM, scale}`
- POIs (stages, registration, food, toilets, shuttle stops): `{name, type, lat, lng, siteId}`
- GLBs in Firebase Storage.
- Agenda items currently have no location field; add `siteId`/`poiId` later for
  "Take me there".

## Build order
1. Map page (satellite + 3D) with the GPS dot from Flutter and one test GLB at hard-coded coordinates.
2. Firestore/Storage data + loading all sites.
3. Admin placement page.
4. Developer scans each site and places it.
5. Offline caching (GLBs, page, optional tile pack for the event area), then routes and agenda links.

## Answers (2026-10-23)
- Venue: Diamonds Leisure Beach & Golf Resort, Diani (OSM node 6063297416, -4.28117, 39.59005).
- Map provider: **Mapbox** (`mapbox_maps_flutter` **2.31.x**, not 3.x: 3.x needs Dart 3.10
  and the iOS build machine is on Flutter 3.32 / Dart 3.8), picked over MapLibre/WebView because it
  ships native offline tile packs, a GLB `ModelLayer` and a GPS puck out of the box.
  This replaces the MapLibre + WebView approach above.
- Mobile data is unreliable, so the map caches the resort area for offline use.
- No scan yet; the first test scan will be done in the office.

## Proof of concept (built 2026-10-23)
- `lib/screens/venue_map/venue_map_screen.dart`: Standard Satellite style, 3D tilt,
  extruded OSM buildings, GLB model per site, site pins + chips, GPS puck with
  heading/accuracy ring, "Where am I" (follow puck) and "Whole venue" buttons.
- `lib/screens/venue_map/venue_sites.dart`: hard-coded **placeholder** sites (Main Hall,
  Pool Deck, Golf Club, Beach Stage) and the offline bounds. Move to Firestore later.
- `lib/services/venue_map/venue_offline_cache.dart`: downloads the style pack + a
  tile region (z12–18) for the resort on first open; shows status chip.
- `lib/services/venue_map/venue_map_config.dart`: `MAPBOX_ACCESS_TOKEN` from
  `assets/.env` or `--dart-define`; set in `main.dart`.
- `assets/venue_map/resort_buildings.geojson`: 167 OSM footprints within 500 m (© OSM, ODbL).
- `assets/venue_map/placeholder_hall.glb`: 24×16 m box hall standing in for a scan.
- Home screen "Venue Map" card (flag `kVenueMapFeatureEnabled` in `constants.dart`).
- `lib/dev/venue_map_preview.dart`: opens the map on its own (no login/Firebase):
  `flutter run -t lib/dev/venue_map_preview.dart`.

### Device testing log
- 2026-10-23, Redmi K20 Pro (crDroid 11.1 / Android 15 custom ROM), mapbox 3.33:
  run 1 crashed natively in libmapbox-maps.so (SIGSEGV on an "MB Worker" thread);
  run 2 (GLB regenerated with indices) rebooted the phone. Suspected cause is the custom ROM's
  GPU driver; not confirmed. Model shadows have been turned off since. Next test: the iPhone 14 Pro.
- 2026-10-23, same phone, reboot confirmed via a live kernel log (`dmesg -w` over adb):
  about 5 s after the map opened, the Adreno 640 hit 20 GPU page faults at address 0 from the
  app's Vulkan context (Flutter Impeller, which imports the map's texture-mode frames), and then
  the kernel's own `kgsl_iommu_fault_handler` hit `refcount_t overflow` and the phone went down.
  Tried `ImpellerBackend=opengles` in `AndroidManifest.xml` (Flutter on OpenGL ES, not Vulkan): the
  map ran and panned for about 4.5 min, then the same address-0 GPU faults came from the app
  (context type "any", not VK) and the phone rebooted again. That was around 11:20, right after
  Mapbox native activity resumed. So Vulkan is not the root cause; something the app draws (likely Mapbox
  itself) faults the GPU, and this ROM's kernel can't survive a GPU fault. (HC mode was only
  watched for ~2 min, so it proves nothing either; reverted.)
- 2026-10-23, bisect: user repro is "Where am I" then "Whole venue" (the fly to Diani). Removing
  one piece at a time, each run flying to Diani:
  - model off: crash.
  - model + buildings off: crash.
  - classic SATELLITE_STREETS style: crash.
  - tile cache wiped + offline download off: crash.
  - everything off (no pins, no puck): **no crash**.
  - pins only: crash.
  - pin circles only (no labels): **crash**.
  So the `CircleLayer` site dots are a trigger. The labels-only run never reached Diani (see the
  next bug), so text labels are untested. GPU memory stayed flat (~80 MB mapped) and RAM was free
  at the time of the crash, so it isn't memory exhaustion.
- Open bug, seen with both fixes: the map shows Mapbox's default style over Europe. The
  satellite style, the Diani camera and our layers never appear, the Flutter buttons don't move the
  camera, and the offline chip sits at 93%. The Dart isolate is idle (not stuck) and nothing is
  logged. Not yet investigated.

### Trying an office scan in the POC
1. Scan with Polycam (Room/LiDAR mode) or 3D Scanner App → export GLB (or USDZ → Blender → GLB).
   In Blender: decimate if needed, keep it under about 5 MB, apply transforms, export glTF Binary (+Y up).
2. Drop it in `assets/venue_map/`, then in `venue_sites.dart` either point `main-hall`'s
   `modelAsset` at it or add a site with the office's lat/lng.
3. Tweak `headingDeg` until it lines up with the satellite image.

## Still open
- How many sites are there, and where exactly are they in the resort? (Replace the placeholders.)
- Mapbox account + public token (free tier: 25k mobile MAU).
- Admin placement tool + Firestore-backed sites (build steps 2–3).

## Notes
- `lib/map_screen.dart` navigation delegate only allows certain hosts; the new page
  (hosted in app assets or Firebase Hosting) will need its own allow-list.
- iOS deployment target is 15.0; nothing in this plan needs a higher one (no native
  RoomPlan code in the app).
