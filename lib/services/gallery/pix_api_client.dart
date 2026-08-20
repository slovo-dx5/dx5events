import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screens/gallery/gallery_models.dart';
import 'pix_api_config.dart';

/// Client for the Event Image Service API (`assets/mobile-gallery-api.md`).
///
/// Handles the full auth lifecycle from the guide:
///  - login with the app's dedicated account, refresh with rotation;
///  - refresh tokens are single-use, so the stored one is overwritten from
///    every refresh response;
///  - a single in-flight auth future so concurrent callers never race each
///    other and burn a rotated refresh token;
///  - a bare-401 backstop: one forced re-auth and one retry of the request.
///
/// Tokens persist in SharedPreferences so a re-opened app refreshes silently
/// instead of logging in with the password again.
class PixApiClient {
  PixApiClient._();

  static final PixApiClient instance = PixApiClient._();

  static const _kToken = 'pix_token';
  static const _kRefreshToken = 'pix_refresh_token';
  static const _kTokenExpiry = 'pix_token_expiry_ms';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: 15000,
    receiveTimeout: 30000,
  ));

  String? _token;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  bool _restored = false;
  Future<String>? _authInFlight;

  // ---------------------------------------------------------------- endpoints

  /// `GET /events` — every event the app account can see.
  Future<List<dynamic>> listEvents() async =>
      (await _get('/events')) as List<dynamic>;

  /// `GET /events/:id/photos` — one page of ready photos.
  Future<Map<String, dynamic>> getPhotos(
    String eventId, {
    String sort = 'captured_at',
    String? day,
    String? sessionId,
    String? search,
    String? cursor,
    int limit = 50,
    List<String>? variants,
  }) async {
    final data = await _get('/events/$eventId/photos', query: {
      'sort': sort,
      if (day != null) 'day': day,
      if (sessionId != null) 'sessionId': sessionId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
      if (variants != null && variants.isNotEmpty)
        'variants': variants.join(','),
    });
    return Map<String, dynamic>.from(data as Map);
  }

  /// `GET /events/:id/days` — valid day filters with ready-photo counts.
  Future<List<dynamic>> getDays(String eventId) async =>
      (await _get('/events/$eventId/days')) as List<dynamic>;

  /// `GET /events/:id/sessions` — special sessions for filtering.
  Future<List<dynamic>> getSessions(String eventId) async =>
      (await _get('/events/$eventId/sessions')) as List<dynamic>;

  /// `POST /events/:id/face-search` — find photos containing [selfie].
  ///
  /// See `assets/face-search-api.pdf`. Multipart body, field name `image`,
  /// results ranked best-first and capped at 100. Every documented failure is
  /// translated into a typed [FaceSearchException] so the UI can tell
  /// "not enabled for this event" apart from "no clear face" apart from a
  /// genuine error — an empty match list is a *success*, not an error.
  ///
  /// The selfie is only read to build the request; nothing is kept, here or
  /// on the server.
  Future<List<FaceMatch>> faceSearch(
    String eventId,
    File selfie, {
    FaceSearchStrictness strictness = FaceSearchStrictness.normal,
  }) async {
    debugPrint('[PixApi] POST /events/$eventId/face-search '
        'strictness=${strictness.value}');
    final url = '${PixApiConfig.baseUrl}/events/$eventId/face-search';
    final query = {'strictness': strictness.value};

    Future<Response<dynamic>> send(String token) async => _dio.post(
          url,
          queryParameters: query,
          data: FormData.fromMap({
            'image': await MultipartFile.fromFile(
              selfie.path,
              filename: selfie.path.split(Platform.pathSeparator).last,
            ),
          }),
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            // Face detection runs before the response, so this is slower than
            // a normal gallery fetch.
            receiveTimeout: 60000,
          ),
        );

    Response<dynamic> res;
    try {
      res = await send(await _validToken());
    } on DioError catch (e) {
      if (e.response?.statusCode == 401) {
        // Same backstop as _get: one forced re-auth, one retry.
        debugPrint('[PixApi] face-search 401 → forcing re-auth and one retry');
        _token = null;
        try {
          res = await send(await _validToken());
        } on DioError catch (e2) {
          throw _faceSearchError(e2);
        }
      } else {
        throw _faceSearchError(e);
      }
    }

    final data = Map<String, dynamic>.from(res.data as Map);
    final raw = (data['matches'] as List?) ?? const [];
    debugPrint('[PixApi] face-search → ${raw.length} match(es)');
    return raw
        .map((m) => FaceMatch.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Maps a failed face-search call onto the documented error table.
  ///
  /// 403 and 422 are each overloaded with two different meanings that need
  /// different UI, so the `{ "error": ... }` body decides between them; an
  /// unrecognisable body degrades to the more conservative case.
  FaceSearchException _faceSearchError(DioError e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    final message =
        (body is Map && body['error'] is String) ? body['error'] as String : '';
    final lower = message.toLowerCase();
    debugPrint('[PixApi] face-search failed: status=$status, '
        'type=${e.type}, body=$body');
    switch (status) {
      case 400:
        return FaceSearchException(FaceSearchError.missingImage, message);
      case 403:
        // "not enabled for this organization" → hide the feature.
        // A bare 403 → this account can't see the event at all.
        return FaceSearchException(
          lower.contains('not enabled')
              ? FaceSearchError.notEnabled
              : FaceSearchError.noAccess,
          message,
        );
      case 404:
        return FaceSearchException(FaceSearchError.noAccess, message);
      case 422:
        return FaceSearchException(
          lower.contains('no clear face')
              ? FaceSearchError.noFaceDetected
              : FaceSearchError.unreadableImage,
          message,
        );
      case 429:
        return FaceSearchException(FaceSearchError.rateLimited, message);
      case 502:
        return FaceSearchException(FaceSearchError.serviceUnavailable, message);
      default:
        return FaceSearchException(
            FaceSearchError.unknown, message.isEmpty ? e.message : message);
    }
  }

  // --------------------------------------------------------------------- http

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) async {
    debugPrint('[PixApi] GET $path query=$query');
    var token = await _validToken();
    try {
      final res = await _request(path, query, token);
      debugPrint('[PixApi] GET $path → ${res.statusCode}');
      return res.data;
    } on DioError catch (e) {
      // Backstop: clock drift or an externally invalidated token. One forced
      // re-auth, one retry.
      debugPrint('[PixApi] GET $path failed: status=${e.response?.statusCode}, '
          'type=${e.type}, message=${e.message}, body=${e.response?.data}');
      if (e.response?.statusCode != 401) rethrow;
      debugPrint('[PixApi] 401 backstop → forcing re-auth and one retry');
      _token = null;
      token = await _validToken();
      final res = await _request(path, query, token);
      debugPrint('[PixApi] GET $path retry → ${res.statusCode}');
      return res.data;
    }
  }

  Future<Response<dynamic>> _request(
          String path, Map<String, dynamic>? query, String token) =>
      _dio.get(
        '${PixApiConfig.baseUrl}$path',
        queryParameters: query,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

  // --------------------------------------------------------------------- auth

  Future<String> _validToken() async {
    await _restore();
    final expiry = _tokenExpiry;
    // 30s buffer so a request never lands right at the expiry boundary.
    if (_token != null &&
        expiry != null &&
        DateTime.now().isBefore(expiry.subtract(const Duration(seconds: 30)))) {
      return _token!;
    }
    // Single-flight: concurrent callers share one refresh/login instead of
    // racing and invalidating each other's rotated refresh token.
    return _authInFlight ??=
        _authenticate().whenComplete(() => _authInFlight = null);
  }

  Future<String> _authenticate() async {
    if (_refreshToken != null) {
      try {
        debugPrint('[PixApi] refreshing session with stored refresh token');
        final res = await _dio.post(
          '${PixApiConfig.baseUrl}/auth/refresh',
          data: {'refreshToken': _refreshToken},
        );
        await _storeSession(Map<String, dynamic>.from(res.data as Map));
        debugPrint('[PixApi] refresh OK, token expires '
            '${_tokenExpiry?.toIso8601String()}');
        return _token!;
      } on DioError catch (e) {
        // Expired/invalid refresh token → fall through to full login.
        debugPrint('[PixApi] refresh failed (status=${e.response?.statusCode}) '
            '→ falling back to password login');
        if (e.response?.statusCode != 401) rethrow;
        _refreshToken = null;
      }
    }
    try {
      debugPrint('[PixApi] logging in as "${PixApiConfig.email}" '
          '(passwordLen=${PixApiConfig.password.length}) at '
          '${PixApiConfig.baseUrl}/auth/login');
      final res = await _dio.post(
        '${PixApiConfig.baseUrl}/auth/login',
        data: {'email': PixApiConfig.email, 'password': PixApiConfig.password},
      );
      await _storeSession(Map<String, dynamic>.from(res.data as Map));
      debugPrint('[PixApi] login OK, token expires ${_tokenExpiry?.toIso8601String()}');
      return _token!;
    } on DioError catch (e) {
      // Surface the API's `{ "error": ... }` body — a bare status code hides
      // e.g. 400 (malformed email in config) vs 401 (wrong credentials).
      throw Exception(
          'pix login failed (${e.response?.statusCode}): ${e.response?.data}');
    }
  }

  Future<void> _storeSession(Map<String, dynamic> data) async {
    _token = data['token'] as String;
    _refreshToken = data['refreshToken'] as String;
    _tokenExpiry =
        DateTime.now().add(Duration(seconds: (data['expiresIn'] as num).toInt()));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, _token!);
    await prefs.setString(_kRefreshToken, _refreshToken!);
    await prefs.setInt(_kTokenExpiry, _tokenExpiry!.millisecondsSinceEpoch);
  }

  Future<void> _restore() async {
    if (_restored) return;
    _restored = true;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _refreshToken = prefs.getString(_kRefreshToken);
    final expiryMs = prefs.getInt(_kTokenExpiry);
    if (expiryMs != null) {
      _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    }
  }
}
