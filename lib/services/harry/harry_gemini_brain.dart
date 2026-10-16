import 'dart:convert';

import 'package:dio/dio.dart';

import 'harry_brain.dart';
import 'harry_config.dart';

/// Google Gemini implementation of [HarryBrain]. Uses the free-tier Generative
/// Language API (an AI Studio key, no billing required) with streaming (SSE)
/// and function calling. Kept behind [HarryBrain] so the rest of the app is
/// provider-agnostic.
///
/// This is a Google API, deliberately separate from [HarryClient] (Anthropic).
class HarryGeminiBrain implements HarryBrain {
  HarryGeminiBrain()
      : _dio = Dio(BaseOptions(
          headers: {'content-type': 'application/json'},
          responseType: ResponseType.stream,
          receiveTimeout: 120000,
          sendTimeout: 30000,
        ));

  static String get model => HarryConfig.geminiModel;

  static String get apiKey => HarryConfig.geminiApiKey;
  static bool get hasKey => apiKey.isNotEmpty;

  final Dio _dio;

  String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:streamGenerateContent?alt=sse&key=$apiKey';

  @override
  Future<void> runConversation({
    required List<Map<String, dynamic>> messages,
    required String systemPrompt,
    required List<Map<String, dynamic>> tools,
    required Future<String> Function(String name, Map<String, dynamic> input)
        executeTool,
    required void Function(String delta) onTextDelta,
    void Function(String toolName)? onToolUse,
    int maxRounds = 4,
  }) async {
    // Translate the shared (Anthropic-style) history to Gemini `contents`.
    // Only simple string turns exist in the shared history; internal tool
    // rounds are tracked locally below.
    final contents = <Map<String, dynamic>>[];
    for (final m in messages) {
      final content = m['content'];
      if (content is String && content.isNotEmpty) {
        contents.add({
          'role': m['role'] == 'assistant' ? 'model' : 'user',
          'parts': [
            {'text': content}
          ],
        });
      }
    }

    final geminiTools = _functionDeclarations(tools);
    final buffer = StringBuffer();

    for (var round = 0; round < maxRounds; round++) {
      final result = await _streamOnce(
        systemPrompt: systemPrompt,
        contents: contents,
        tools: geminiTools,
        onTextDelta: (t) {
          buffer.write(t);
          onTextDelta(t);
        },
      );

      // Record the model turn (text + any function calls) for the next request.
      final modelParts = <Map<String, dynamic>>[];
      if (result.text.isNotEmpty) modelParts.add({'text': result.text});
      for (final call in result.calls) {
        modelParts.add({
          'functionCall': {'name': call.name, 'args': call.args}
        });
      }
      if (modelParts.isNotEmpty) {
        contents.add({'role': 'model', 'parts': modelParts});
      }

      if (result.calls.isEmpty) break;

      final responseParts = <Map<String, dynamic>>[];
      for (final call in result.calls) {
        onToolUse?.call(call.name);
        String output;
        try {
          output = await executeTool(call.name, call.args);
        } catch (e) {
          output = 'Error running ${call.name}: $e';
        }
        responseParts.add({
          'functionResponse': {
            'name': call.name,
            'response': {'result': output},
          }
        });
      }
      contents.add({'role': 'user', 'parts': responseParts});
    }

    // Persist the final assistant text to the shared history for continuity.
    if (buffer.isNotEmpty) {
      messages.add({'role': 'assistant', 'content': buffer.toString()});
    }
  }

  Future<_GeminiRound> _streamOnce({
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
    required List<Map<String, dynamic>> tools,
    required void Function(String delta) onTextDelta,
  }) async {
    final body = <String, dynamic>{
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      if (tools.isNotEmpty) 'tools': tools,
      'generationConfig': {'maxOutputTokens': 1024},
    };

    // Retry transient 429s with backoff (free tier has low per-minute limits).
    Response? response;
    for (var attempt = 0;; attempt++) {
      try {
        response = await _dio.post(_endpoint, data: jsonEncode(body));
        break;
      } on DioError catch (e) {
        final status = e.response?.statusCode;
        if (status == 429 && attempt < 2) {
          await Future.delayed(Duration(seconds: 3 + attempt * 4)); // 3s, 7s
          continue;
        }
        throw HarryGeminiException(await _describeError(e));
      }
    }

    final roundText = StringBuffer();
    final calls = <_GeminiCall>[];

    await (response.data as ResponseBody)
        .stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
      if (!line.startsWith('data:')) return;
      final payload = line.substring(5).trim();
      if (payload.isEmpty) return;

      Map<String, dynamic> event;
      try {
        event = jsonDecode(payload) as Map<String, dynamic>;
      } catch (_) {
        return;
      }

      final candidates = event['candidates'];
      if (candidates is! List || candidates.isEmpty) return;
      final content = (candidates.first as Map)['content'];
      final parts = (content is Map ? content['parts'] : null);
      if (parts is! List) return;

      for (final part in parts) {
        if (part is! Map) continue;
        if (part['text'] is String) {
          final text = part['text'] as String;
          if (text.isNotEmpty) {
            roundText.write(text);
            onTextDelta(text);
          }
        } else if (part['functionCall'] is Map) {
          final fc = part['functionCall'] as Map;
          calls.add(_GeminiCall(
            (fc['name'] ?? '').toString(),
            (fc['args'] is Map)
                ? Map<String, dynamic>.from(fc['args'] as Map)
                : <String, dynamic>{},
          ));
        }
      }
    });

    return _GeminiRound(roundText.toString(), calls);
  }

  /// Converts the Anthropic-style tool definitions into Gemini
  /// `functionDeclarations`. Tools with no parameters omit `parameters`
  /// entirely (Gemini rejects empty property objects).
  List<Map<String, dynamic>> _functionDeclarations(
      List<Map<String, dynamic>> tools) {
    final decls = <Map<String, dynamic>>[];
    for (final t in tools) {
      final schema = t['input_schema'];
      final decl = <String, dynamic>{
        'name': t['name'],
        'description': t['description'],
      };
      if (schema is Map) {
        final props = schema['properties'];
        if (props is Map && props.isNotEmpty) {
          decl['parameters'] = _geminiSchema(schema);
        }
      }
      decls.add(decl);
    }
    return [
      {'functionDeclarations': decls}
    ];
  }

  /// Deep-copies a JSON schema, upper-casing `type` values to Gemini's enum
  /// form (STRING, OBJECT, …).
  dynamic _geminiSchema(dynamic node) {
    if (node is Map) {
      final out = <String, dynamic>{};
      node.forEach((k, v) {
        if (k == 'type' && v is String) {
          out[k] = v.toUpperCase();
        } else {
          out[k] = _geminiSchema(v);
        }
      });
      return out;
    }
    if (node is List) return node.map(_geminiSchema).toList();
    return node;
  }

  Future<String> _describeError(DioError e) async {
    final status = e.response?.statusCode;
    final detail = await _readBody(e);
    if (status == 400 || status == 403) {
      return 'Gemini rejected the request ($status). '
          '${detail.isNotEmpty ? detail : 'Check the GEMINI_API_KEY in assets/.env.'}';
    }
    if (status == 429) {
      return 'Gemini quota/rate limit hit (429). '
          '${detail.isNotEmpty ? detail : 'The free tier has per-minute and per-day limits — wait a bit and retry.'}';
    }
    if (status == 404) {
      return 'Gemini model "$model" not found for this key (404). '
          '${detail.isNotEmpty ? detail : 'Try a different HARRY_GEMINI_MODEL.'}';
    }
    return 'Harry could not reach Gemini (${status ?? e.message}). $detail'.trim();
  }

  /// Extracts Google's `error.message` from an error response (falls back to a
  /// truncated raw body).
  Future<String> _readBody(DioError e) async {
    final data = e.response?.data;
    if (data is! ResponseBody) return '';
    try {
      final text = await utf8.decodeStream(data.stream.cast<List<int>>());
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map && decoded['error'] is Map) {
          final err = decoded['error'] as Map;
          final msg = err['message'] ?? err['status'];
          if (msg is String && msg.isNotEmpty) return msg;
        }
      } catch (_) {}
      return text.length > 300 ? '${text.substring(0, 300)}…' : text;
    } catch (_) {
      return '';
    }
  }
}

class HarryGeminiException implements Exception {
  HarryGeminiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _GeminiCall {
  _GeminiCall(this.name, this.args);
  final String name;
  final Map<String, dynamic> args;
}

class _GeminiRound {
  _GeminiRound(this.text, this.calls);
  final String text;
  final List<_GeminiCall> calls;
}
