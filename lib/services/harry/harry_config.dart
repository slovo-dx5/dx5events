import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Runtime configuration for Harry's AI keys.
///
/// Keys resolve in this order (first non-empty wins):
///   1. `assets/.env` (loaded at startup via [load])
///   2. `--dart-define` compile-time values
///
/// This lets the key live in `assets/.env` (as added by the team) without a
/// rebuild, while still supporting `--dart-define` for CI or per-build keys.
///
/// NOTE: bundling a key as an asset makes it extractable from the app package,
/// exactly like an embedded `--dart-define`. Fine for testing; front it with a
/// backend proxy before a public release. Keep `assets/.env` out of git.
class HarryConfig {
  HarryConfig._();

  static String geminiApiKey = const String.fromEnvironment('GEMINI_API_KEY');
  static String anthropicApiKey =
      const String.fromEnvironment('ANTHROPIC_API_KEY');
  static String geminiModel = const String.fromEnvironment(
    'HARRY_GEMINI_MODEL',
    // flash-lite has higher free-tier rate/day limits than flash.
    defaultValue: 'gemini-2.0-flash-lite',
  );

  // OpenAI-compatible providers (Groq, Cerebras, OpenRouter, local Ollama, …).
  // Only the base URL, model and key change between them.
  static String llmApiKey = const String.fromEnvironment(
    'LLM_API_KEY',
    defaultValue: String.fromEnvironment('GROQ_API_KEY'),
  );
  static String llmBaseUrl = const String.fromEnvironment(
    'LLM_BASE_URL',
    defaultValue: 'https://api.groq.com/openai/v1',
  );
  static String llmModel = const String.fromEnvironment(
    'LLM_MODEL',
    defaultValue: 'llama-3.3-70b-versatile',
  );

  /// Optional explicit brain override: anthropic | gemini | groq | demo.
  /// When empty, the controller auto-selects by which key is present.
  static String provider = const String.fromEnvironment('HARRY_PROVIDER');

  static const bool forceDemo = bool.fromEnvironment('HARRY_DEMO');

  static bool _loaded = false;

  /// Loads keys from `assets/.env` if present. Safe to call once at startup;
  /// missing file or parse errors are ignored (falls back to dart-define/demo).
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
          case 'GEMINI_API_KEY':
            geminiApiKey = value;
            break;
          case 'ANTHROPIC_API_KEY':
            anthropicApiKey = value;
            break;
          case 'HARRY_GEMINI_MODEL':
            geminiModel = value;
            break;
          case 'LLM_API_KEY':
          case 'GROQ_API_KEY':
          case 'GROK_API_KEY': // common misspelling / xAI Grok
          case 'XAI_API_KEY':
            llmApiKey = value;
            break;
          case 'LLM_BASE_URL':
            llmBaseUrl = value;
            break;
          case 'LLM_MODEL':
            llmModel = value;
            break;
          case 'HARRY_PROVIDER':
            provider = value;
            break;
        }
      }
    } catch (_) {
      // No .env asset (or unreadable) — keep dart-define values.
    }
  }
}
