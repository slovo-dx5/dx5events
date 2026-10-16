import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../dioServices/base_url.dart';

/// Runtime configuration for Rewards (points, challenges, leaderboard).
///
/// Points are awarded server-side by Directus Flows scoring the
/// `app_activity_logs` rows the app already sends — see
/// `docs/features/gamification-backend.md`. The app only reads two webhook
/// Flows: "Gamification — Progress" and "Gamification — Leaderboard".
///
/// Values resolve in this order (first non-empty wins):
///   1. `assets/.env` (loaded at startup via [load])
///   2. `--dart-define` compile-time values
class GamificationConfig {
  GamificationConfig._();

  /// Directus instance hosting the Flows. Same one the activity logs go to.
  static String directusUrl = const String.fromEnvironment(
    'GAMIFICATION_DIRECTUS_URL',
    defaultValue: BaseURL.Baseurl,
  );

  /// Flow id of the progress webhook, called as
  /// `GET {directusUrl}/flows/trigger/{progressFlowId}?user_id=…`.
  static String progressFlowId =
      const String.fromEnvironment('GAMIFICATION_PROGRESS_FLOW_ID');

  /// Flow id of the leaderboard webhook.
  static String leaderboardFlowId =
      const String.fromEnvironment('GAMIFICATION_LEADERBOARD_FLOW_ID');

  /// Rewards entry points stay hidden until the backend is set up, rather than
  /// showing a screen that can only error.
  static bool get isConfigured =>
      directusUrl.isNotEmpty && progressFlowId.isNotEmpty;

  static bool get hasLeaderboard =>
      directusUrl.isNotEmpty && leaderboardFlowId.isNotEmpty;

  static String get progressEndpoint =>
      '$directusUrl/flows/trigger/$progressFlowId';

  static String get leaderboardEndpoint =>
      '$directusUrl/flows/trigger/$leaderboardFlowId';

  static bool _loaded = false;

  /// Loads values from `assets/.env` if present. Safe to call once at startup;
  /// a missing file or parse error is ignored (falls back to dart-define).
  static Future<void> load([String assetPath = 'assets/.env']) async {
    if (_loaded) return;
    _loaded = true;
    try {
      final content = await rootBundle.loadString(assetPath);
      for (final line in const LineSplitter().convert(content)) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final eq = trimmed.indexOf('=');
        if (eq <= 0) continue;
        final key = trimmed.substring(0, eq).trim();
        var value = trimmed.substring(eq + 1).trim();
        if (value.length >= 2 &&
            ((value.startsWith('"') && value.endsWith('"')) ||
                (value.startsWith("'") && value.endsWith("'")))) {
          value = value.substring(1, value.length - 1);
        }
        if (value.isEmpty) continue;
        switch (key) {
          case 'GAMIFICATION_DIRECTUS_URL':
            directusUrl = value;
            break;
          case 'GAMIFICATION_PROGRESS_FLOW_ID':
            progressFlowId = value;
            break;
          case 'GAMIFICATION_LEADERBOARD_FLOW_ID':
            leaderboardFlowId = value;
            break;
        }
      }
    } catch (_) {
      // No .env asset (or unreadable) — keep dart-define values.
    }
  }
}
