import 'dart:convert';

import 'package:dio/dio.dart';

import 'harry_brain.dart';
import 'harry_config.dart';

/// The ONLY place in the app that talks to Anthropic.
///
/// Keeping every Claude request behind this class is deliberate: today it calls
/// the Anthropic Messages API directly with an embedded key (loaded at build
/// time via `--dart-define=ANTHROPIC_API_KEY=...`), but if we later stand up a
/// backend proxy to hold the key, only this file changes.
///
/// Do NOT reuse the app's [DioClient] — that injects the Directus bearer token
/// on every request, which must never be sent to Anthropic.
class HarryClient implements HarryBrain {
  HarryClient()
      : _dio = Dio(
          BaseOptions(
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            responseType: ResponseType.stream,
            // Dio 4 expects milliseconds. Streamed replies can take a while.
            receiveTimeout: 120000,
            sendTimeout: 30000,
          ),
        );

  static const String model =
      String.fromEnvironment('HARRY_MODEL', defaultValue: 'claude-haiku-4-5');
  static const String _endpoint = 'https://api.anthropic.com/v1/messages';

  final Dio _dio;

  static String get apiKey => HarryConfig.anthropicApiKey;

  /// True when a real Anthropic key is available (from .env or --dart-define).
  static bool get hasKey => apiKey.isNotEmpty;

  bool get isConfigured => hasKey;

  /// Runs a full tool-using conversation turn.
  ///
  /// [messages] is the Anthropic-format conversation and is MUTATED in place —
  /// the assistant reply and any tool round-trips are appended so the caller
  /// can keep the running history. Streamed assistant text is delivered through
  /// [onTextDelta]; each tool invocation is announced through [onToolUse].
  @override
  Future<void> runConversation({
    required List<Map<String, dynamic>> messages,
    required String systemPrompt,
    required List<Map<String, dynamic>> tools,
    required Future<String> Function(String name, Map<String, dynamic> input)
        executeTool,
    required void Function(String delta) onTextDelta,
    void Function(String toolName)? onToolUse,
    int maxRounds = 6,
  }) async {
    for (var round = 0; round < maxRounds; round++) {
      final result = await _streamOnce(
        messages: messages,
        systemPrompt: systemPrompt,
        tools: tools,
        onTextDelta: onTextDelta,
      );

      // Preserve the assistant turn (text + any tool_use blocks) verbatim so
      // the follow-up request is valid.
      if (result.assistantContent.isNotEmpty) {
        messages.add({'role': 'assistant', 'content': result.assistantContent});
      }

      if (result.stopReason != 'tool_use' || result.toolUses.isEmpty) {
        return;
      }

      final toolResults = <Map<String, dynamic>>[];
      for (final tu in result.toolUses) {
        onToolUse?.call(tu.name);
        String output;
        try {
          output = await executeTool(tu.name, tu.input);
        } catch (e) {
          output = 'Error running ${tu.name}: $e';
        }
        toolResults.add({
          'type': 'tool_result',
          'tool_use_id': tu.id,
          'content': output,
        });
      }
      messages.add({'role': 'user', 'content': toolResults});
    }
  }

  Future<_RoundResult> _streamOnce({
    required List<Map<String, dynamic>> messages,
    required String systemPrompt,
    required List<Map<String, dynamic>> tools,
    required void Function(String delta) onTextDelta,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'max_tokens': 1024,
      'stream': true,
      'system': systemPrompt,
      'messages': messages,
      if (tools.isNotEmpty) 'tools': tools,
    };

    late final Response response;
    try {
      response = await _dio.post(_endpoint, data: jsonEncode(body));
    } on DioError catch (e) {
      throw HarryClientException(await _describeError(e));
    }

    final responseBody = response.data as ResponseBody;
    final blocks = <int, _BlockAccum>{};
    var stopReason = 'end_turn';

    await responseBody.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
      if (!line.startsWith('data:')) return;
      final payload = line.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') return;

      final Map<String, dynamic> event;
      try {
        event = jsonDecode(payload) as Map<String, dynamic>;
      } catch (_) {
        return; // ignore keep-alive / malformed fragments
      }

      switch (event['type']) {
        case 'content_block_start':
          final idx = event['index'] as int;
          final cb = event['content_block'] as Map<String, dynamic>;
          blocks[idx] = _BlockAccum(
            type: cb['type'] as String,
            id: cb['id'] as String?,
            name: cb['name'] as String?,
          );
          break;
        case 'content_block_delta':
          final idx = event['index'] as int;
          final delta = event['delta'] as Map<String, dynamic>;
          final block = blocks[idx];
          if (block == null) return;
          if (delta['type'] == 'text_delta') {
            final text = delta['text'] as String? ?? '';
            block.text += text;
            if (text.isNotEmpty) onTextDelta(text);
          } else if (delta['type'] == 'input_json_delta') {
            block.partialJson += delta['partial_json'] as String? ?? '';
          }
          break;
        case 'message_delta':
          final sr = (event['delta'] as Map<String, dynamic>?)?['stop_reason'];
          if (sr is String) stopReason = sr;
          break;
        default:
          break;
      }
    });

    final assistantContent = <Map<String, dynamic>>[];
    final toolUses = <_ToolUse>[];
    for (final idx in blocks.keys.toList()..sort()) {
      final b = blocks[idx]!;
      if (b.type == 'text') {
        // Skip empty text blocks (common right before a tool_use); the API can
        // reject an empty-string text block echoed back on the next round.
        if (b.text.isNotEmpty) {
          assistantContent.add({'type': 'text', 'text': b.text});
        }
      } else if (b.type == 'tool_use') {
        Map<String, dynamic> input;
        try {
          input = b.partialJson.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(b.partialJson) as Map<String, dynamic>;
        } catch (_) {
          input = <String, dynamic>{};
        }
        assistantContent.add({
          'type': 'tool_use',
          'id': b.id,
          'name': b.name,
          'input': input,
        });
        toolUses.add(_ToolUse(b.id ?? '', b.name ?? '', input));
      }
    }

    return _RoundResult(assistantContent, toolUses, stopReason);
  }

  Future<String> _describeError(DioError e) async {
    final status = e.response?.statusCode;
    if (status == 401) {
      return 'Harry could not authenticate with the AI service. The API key is '
          'missing or invalid.';
    }
    if (status == 429) {
      return 'Harry is a bit busy right now (rate limited). Please try again in '
          'a moment.';
    }
    // Error bodies also arrive as a stream when responseType is stream.
    final data = e.response?.data;
    if (data is ResponseBody) {
      try {
        final text = await utf8.decodeStream(data.stream.cast<List<int>>());
        return 'AI service error (${status ?? 'network'}): $text';
      } catch (_) {}
    }
    return 'Harry could not reach the AI service (${status ?? e.message}).';
  }
}

class HarryClientException implements Exception {
  HarryClientException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _BlockAccum {
  _BlockAccum({required this.type, this.id, this.name});
  final String type;
  final String? id;
  final String? name;
  String text = '';
  String partialJson = '';
}

class _ToolUse {
  _ToolUse(this.id, this.name, this.input);
  final String id;
  final String name;
  final Map<String, dynamic> input;
}

class _RoundResult {
  _RoundResult(this.assistantContent, this.toolUses, this.stopReason);
  final List<Map<String, dynamic>> assistantContent;
  final List<_ToolUse> toolUses;
  final String stopReason;
}
