import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Runtime configuration for the venue map (Mapbox).
///
/// Values resolve in this order (first non-empty wins):
///   1. `assets/.env` (loaded at startup via [load])
///   2. `--dart-define` compile-time values
///
/// The token is a Mapbox *public* token (starts with `pk.`), which is meant to
/// ship in the client. Restrict it to this app's bundle id / package name in the
/// Mapbox dashboard rather than treating it as a secret.
class VenueMapConfig {
  VenueMapConfig._();

  static String accessToken =
      const String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

  /// Whether the venue map can render. When false the screen shows a
  /// "not configured" message instead of a blank map.
  static bool get isConfigured => accessToken.isNotEmpty;

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
        if (key == 'MAPBOX_ACCESS_TOKEN') accessToken = value;
      }
    } catch (_) {
      // No .env asset (or unreadable) — keep dart-define values.
    }
  }
}
