import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import '../database/activity_queue_db.dart';
import '../dioServices/dioFetchService.dart';

/// Canonical list of action names. Using constants here prevents typos from
/// reaching the server; the names mirror the seed rows in
/// `app_activity_action_types`.
class ActivityAction {
  static const otpRequest = 'otp_request';
  static const otpLogin = 'otp_login';

  static const viewAgenda = 'view_agenda';
  static const viewSpeakers = 'view_speakers';
  static const viewAttendees = 'view_attendees';
  static const viewSessionDetail = 'view_session_detail';
  static const viewAttendeeDetail = 'view_attendee_detail';
  static const viewSpeakerDetail = 'view_speaker_detail';

  static const meetingRequestSent = 'meeting_request_sent';
  static const meetingAccepted = 'meeting_accepted';
  static const meetingDeclined = 'meeting_declined';
  static const meetingCancelled = 'meeting_cancelled';
}

/// Singleton activity logger. Writes go to a local sqflite queue first, then
/// flush in batches to Directus. Callers treat log() as fire-and-forget —
/// the returned future resolves once the row is persisted locally, but the
/// server-side flush happens independently on a timer.
class ActivityLogger {
  static final ActivityLogger instance = ActivityLogger._internal();
  ActivityLogger._internal();

  static const Duration _flushInterval = Duration(seconds: 60);
  static const int _batchSize = 50;
  static const Uuid _uuid = Uuid();

  Timer? _flushTimer;
  bool _flushing = false;
  bool _initialized = false;
  String? _platform;

  /// Start the background flush loop. Safe to call multiple times.
  void init() {
    if (_initialized) return;
    _initialized = true;

    _platform = Platform.isIOS
        ? 'ios'
        : Platform.isAndroid
            ? 'android'
            : 'other';

    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());

    // Opportunistic flush on startup to drain anything left over from a
    // previous session.
    Future.microtask(flush);
  }

  /// Enqueue an activity log row. Non-blocking from the caller's perspective
  /// — the returned future completes once persisted locally, but callers
  /// typically discard it.
  Future<void> log({
    required String action,
    String? eventId,
    int? userId,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_initialized) init();

      // If the caller didn't supply user_id, try to pull it from prefs.
      // Some events (pre-login OTP request) legitimately have no user id.
      int? resolvedUserId = userId;
      if (resolvedUserId == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final stored = prefs.getInt(kUserID);
          if (stored != null && stored > 0) resolvedUserId = stored;
        } catch (_) {}
      }

      final entry = PendingActivity(
        clientEventId: _uuid.v4(),
        userId: resolvedUserId,
        eventId: eventId,
        action: action,
        targetType: targetType,
        targetId: targetId,
        metadata: metadata,
        platform: _platform ?? 'other',
        occurredAt: DateTime.now().toUtc(),
      );

      await ActivityQueueDatabase.instance.insert(entry);

      // Opportunistic flush — cheap if nothing needs doing.
      unawaited(flush());
    } catch (e) {
      // Never let logging crash the caller.
      debugPrint('ActivityLogger.log failed: $e');
    }
  }

  /// Send a batch of queued rows to Directus. Safe to call concurrently;
  /// only one flush runs at a time.
  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;

    try {
      final batch =
          await ActivityQueueDatabase.instance.takeBatch(_batchSize);
      if (batch.isEmpty) return;

      final payload = batch.map((e) => e.toDirectusPayload()).toList();

      var treatAsPersisted = false;
      try {
        await DioFetchService().postActivityLogs(payload);
        treatAsPersisted = true;
      } catch (e) {
        if (_isDuplicateBatchError(e)) {
          // A previous flush already persisted these rows server-side but the
          // response was lost; the retry is hitting the unique constraint on
          // client_event_id. Safe to discard locally.
          debugPrint(
            'ActivityLogger flush: batch already persisted server-side, discarding locally',
          );
          treatAsPersisted = true;
        } else {
          // Network / transient server error — leave queued for next cycle.
          debugPrint('ActivityLogger flush failed (will retry): $e');
        }
      }

      if (!treatAsPersisted) return;

      final ids = batch
          .map((e) => e.id)
          .whereType<int>()
          .toList(growable: false);
      await ActivityQueueDatabase.instance.deleteByIds(ids);

      // If we just drained a full batch, more may be waiting.
      if (batch.length == _batchSize) {
        unawaited(flush());
      }
    } finally {
      _flushing = false;
    }
  }

  /// True when the server rejected the batch because client_event_ids are
  /// already present — indicates a successful previous flush whose response
  /// never reached us.
  bool _isDuplicateBatchError(Object error) {
    DioError? dio;
    if (error is DioError) {
      dio = error;
    } else if (error is Exception) {
      // DioFetchService rewraps DioError as a plain Exception — we can't
      // recover the code path in that case, but the wrapped message still
      // contains enough to match on.
    }

    final data = dio?.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is List) {
        for (final err in errors) {
          if (err is Map) {
            final code = err['extensions']?['code'];
            if (code == 'RECORD_NOT_UNIQUE') return true;
          }
        }
      }
    }

    return error.toString().contains('RECORD_NOT_UNIQUE');
  }

  @visibleForTesting
  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _initialized = false;
  }
}
