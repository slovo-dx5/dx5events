import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../services/gallery/pix_api_client.dart';
import '../../services/gallery/pix_api_config.dart';
import 'gallery_models.dart';

export 'gallery_models.dart';

/// Source of gallery photos.
///
/// When the pix API is configured (see [PixApiConfig]) everything comes from
/// the Event Image Service; otherwise [assetPhotos] provides the bundled POC
/// set so the feature still demos without credentials.
class GalleryRepository {
  static const String placeholder = 'assets/images/gallery/placeholder.png';

  /// Variant labels we ask the server to sign — `thumb` for the grid,
  /// `medium` for the viewer, `xlarge` for downloads/pinch-zoom. Requesting
  /// only these keeps payloads small (guide §3).
  static const List<String> requestedVariants = ['thumb', 'medium', 'xlarge'];

  static final PixApiClient _api = PixApiClient.instance;

  static bool get isRemote => PixApiConfig.isConfigured;

  /// Resolves this app-event to a pix event id.
  ///
  /// Uses the `PIX_EVENT_ID` override when set; otherwise matches [eventName]
  /// against the titles/slugs from `GET /events` (the app's Directus event ids
  /// are unrelated to pix ids). Falls back to the only event when the account
  /// sees exactly one. Returns null when no confident match exists.
  static Future<String?> resolveEventId({String? eventName}) async {
    debugPrint('[Gallery] resolveEventId(eventName="$eventName"), '
        'isConfigured=${PixApiConfig.isConfigured}, '
        'baseUrl=${PixApiConfig.baseUrl}, '
        'overrideEventId="${PixApiConfig.eventId}"');
    if (PixApiConfig.eventId.isNotEmpty) {
      debugPrint('[Gallery] using PIX_EVENT_ID override: ${PixApiConfig.eventId}');
      return PixApiConfig.eventId;
    }
    final events = await _api.listEvents();
    debugPrint('[Gallery] listEvents returned ${events.length} event(s): '
        '${events.map((e) => '${e['id']}:${e['title']}').toList()}');
    if (events.isEmpty) {
      debugPrint('[Gallery] no events visible to this account → returning null');
      return null;
    }
    if (events.length == 1) {
      debugPrint('[Gallery] exactly one event → using ${events.first['id']}');
      return events.first['id'] as String;
    }
    if (eventName == null || eventName.isEmpty) {
      debugPrint('[Gallery] ${events.length} events but no eventName to match '
          '→ returning null (cannot pick). Set PIX_EVENT_ID or pass eventName.');
      return null;
    }

    final wanted = _normalize(eventName);
    for (final e in events) {
      final title = _normalize(e['title'] as String? ?? '');
      final slug = _normalize(e['slug'] as String? ?? '');
      if (title.isNotEmpty &&
          (title == wanted || wanted.contains(title) || title.contains(wanted))) {
        debugPrint('[Gallery] matched "$eventName" → title "${e['title']}" '
            '(${e['id']})');
        return e['id'] as String;
      }
      if (slug.isNotEmpty && (slug == wanted || wanted.contains(slug))) {
        debugPrint('[Gallery] matched "$eventName" → slug "${e['slug']}" '
            '(${e['id']})');
        return e['id'] as String;
      }
    }
    debugPrint('[Gallery] no event matched "$eventName" (normalized "$wanted") '
        '→ returning null. Available titles: '
        '${events.map((e) => e['title']).toList()}');
    return null;
  }

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static Future<PhotosPage> fetchPhotos(
    String eventId, {
    String? day,
    String? sessionId,
    String? search,
    String? cursor,
  }) async {
    debugPrint('[Gallery] fetchPhotos(eventId=$eventId, day=$day, '
        'sessionId=$sessionId, search=$search, cursor=$cursor)');
    final data = await _api.getPhotos(
      eventId,
      day: day,
      sessionId: sessionId,
      search: search,
      cursor: cursor,
      variants: requestedVariants,
    );
    final rawPhotos = (data['photos'] as List?) ?? const [];
    debugPrint('[Gallery] fetchPhotos → response keys=${data.keys.toList()}, '
        'photos=${rawPhotos.length}, nextCursor=${data['nextCursor']}');
    final page = PhotosPage(
      photos: rawPhotos
          .map((p) => GalleryPhoto.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      nextCursor: data['nextCursor'] as String?,
    );
    debugPrint('[Gallery] fetchPhotos → parsed ${page.photos.length} photo(s)');
    return page;
  }

  /// Events whose organization has face search switched off. There's no
  /// endpoint to check the flag up front — the only signal is a 403 from the
  /// search itself — so the first one we see is remembered for the session and
  /// the "find my photos" entry point stays hidden after that.
  static final Set<String> _faceSearchUnavailable = <String>{};

  static bool faceSearchAvailable(String eventId) =>
      isRemote && !_faceSearchUnavailable.contains(eventId);

  static void markFaceSearchUnavailable(String eventId) {
    debugPrint('[Gallery] face search unavailable for event $eventId');
    _faceSearchUnavailable.add(eventId);
  }

  /// Finds photos of the person in [selfie] (`assets/face-search-api.pdf`).
  ///
  /// Throws [FaceSearchException] for every documented failure; an empty list
  /// means "searched fine, nothing matched".
  static Future<List<FaceMatch>> faceSearch(
    String eventId,
    File selfie, {
    FaceSearchStrictness strictness = FaceSearchStrictness.normal,
  }) async {
    debugPrint('[Gallery] faceSearch(eventId=$eventId, '
        'strictness=${strictness.value})');
    final matches =
        await _api.faceSearch(eventId, selfie, strictness: strictness);
    debugPrint('[Gallery] faceSearch → ${matches.length} match(es)');
    return matches;
  }

  static Future<List<GalleryDay>> fetchDays(String eventId) async =>
      (await _api.getDays(eventId))
          .map((d) => GalleryDay.fromJson(Map<String, dynamic>.from(d)))
          .toList();

  static Future<List<GallerySession>> fetchSessions(String eventId) async =>
      (await _api.getSessions(eventId))
          .map((s) => GallerySession.fromJson(Map<String, dynamic>.from(s)))
          .toList();

  /// POC fallback used only when the API isn't configured.
  static List<GalleryPhoto> assetPhotos() => const [
        GalleryPhoto.asset('assets/images/gallery/AfricaCISOSummit-0113.png'),
        GalleryPhoto.asset('assets/images/gallery/BFSI_DAY2SESSION-65.png'),
        GalleryPhoto.asset('assets/images/gallery/CAS-12.png'),
        GalleryPhoto.asset('assets/images/gallery/CIO_2026-22.png'),
        GalleryPhoto.asset('assets/images/gallery/CISO2_other-25.png'),
        GalleryPhoto.asset('assets/images/gallery/CISO_Other-167.png'),
        GalleryPhoto.asset('assets/images/gallery/ConnectedAfricaSummit2026(Day4)-111.jpg'),
        GalleryPhoto.asset('assets/images/gallery/ConnectedAfricaSummit2026(Day4)-114.jpg'),
        GalleryPhoto.asset('assets/images/gallery/ConnectedAfricaSummit2026(Day4)-122.jpg'),
        GalleryPhoto.asset('assets/images/gallery/ConnectedAfricaSummit2026DayivGalaDinner(241of261).jpg'),
        GalleryPhoto.asset('assets/images/gallery/DayiiiConnectedSummitKeyengagements-580.jpg'),
        GalleryPhoto.asset('assets/images/gallery/DayiiiConnectedSummitKeyengagements-613.jpg'),
        GalleryPhoto.asset('assets/images/gallery/Latt_2025-7.png'),
        GalleryPhoto.asset('assets/images/gallery/Latt_2025-78.png'),
        GalleryPhoto.asset('assets/images/gallery/S_CIO100DAY_3-321.png'),
        GalleryPhoto.asset('assets/images/gallery/TYA222026-11.png'),
        GalleryPhoto.asset('assets/images/gallery/TYA222026-16.png'),
      ];
}
