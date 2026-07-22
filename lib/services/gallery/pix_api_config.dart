import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Runtime configuration for the Event Image Service ("pix") API used by the
/// gallery feature. See `assets/mobile-gallery-api.md`.
///
/// Values resolve in this order (first non-empty wins):
///   1. `assets/.env` (loaded at startup via [load])
///   2. `--dart-define` compile-time values
///
/// The email/password pair is this app's dedicated org-member account — not a
/// real end user. Shipping it in the client is a known, accepted tradeoff for
/// this account (see the guide, §1). Keep `assets/.env` out of git.
class PixApiConfig {
  PixApiConfig._();

  static String baseUrl = const String.fromEnvironment(
    'PIX_API_BASE_URL',
    defaultValue: 'https://api.pix.dx5ve.com',
  );
  static String email = const String.fromEnvironment('PIX_API_EMAIL');
  static String password = const String.fromEnvironment('PIX_API_PASSWORD');

  /// Optional hard override of the pix event id. When set, the gallery skips
  /// matching the app's event name against `GET /events` and uses this id.
  static String eventId = const String.fromEnvironment('PIX_EVENT_ID');

  /// Whether the app has credentials to talk to the real API. When false, the
  /// gallery falls back to the bundled POC assets.
  static bool get isConfigured => email.isNotEmpty && password.isNotEmpty;

  static bool _loaded = false;

  /// Loads values from `assets/.env` if present. Safe to call once at startup;
  /// missing file or parse errors are ignored (falls back to dart-define).
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
          case 'PIX_API_BASE_URL':
            baseUrl = value;
            break;
          case 'PIX_API_EMAIL':
            email = value;
            break;
          case 'PIX_API_PASSWORD':
            password = value;
            break;
          case 'PIX_EVENT_ID':
            eventId = value;
            break;
        }
      }
    } catch (_) {
      // No .env asset (or unreadable) — keep dart-define values.
    }
  }
}