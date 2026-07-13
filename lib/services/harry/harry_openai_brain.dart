import 'dart:convert';

import 'package:dio/dio.dart';

import 'harry_brain.dart';
import 'harry_config.dart';

/// OpenAI-compatible [HarryBrain] — works with any provider that exposes the
/// `/chat/completions` API: Groq (default), Cerebras, OpenRouter, Together, a
/// local Ollama server, etc. Switch providers by changing LLM_BASE_URL /
/// LLM_MODEL / the key in `assets/.env`; no code change needed.
///
/// Supports streaming (SSE) and function/tool calling.
class HarryOpenAICompatBrain implements HarryBrain {
  HarryOpenAICompatBrain()
      : _dio = Dio(BaseOptions(
          headers: {
            'authorization': 'Bearer ${HarryConfig.llmApiKey}',
            'content-type': 'application/json',
          },
          responseType: ResponseType.stream,
          receiveTimeout: 120000,
          sendTimeout: 30000,
        ));

  static String get apiKey => HarryConfig.llmApiKey;
  static String get model => HarryConfig.llmModel;
  static bool get hasKey => apiKey.isNotEmpty;

  final Dio _dio;

  String get _endpoint {
    final base = HarryConfig.llmBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/chat/completions';
  }

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
    // Build OpenAI-format messages: system prompt + translated history.
    final chat = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
    ];
    for (final m in messages) {
      final content = m['content'];
      if (content is String && content.isNotEmpty) {
        chat.add({'role': m['role'], 'content': content});
      }
    }

    final toolDefs = tools
        .map((t) => {
              'type': 'function',
              'function': {
                'name': t['name'],
                'description': t['description'],
                'parameters': t['input_schema'],
              },
            })
        .toList();

    final finalText = StringBuffer();

    for (var round = 0; round < maxRounds; round++) {
      final result = await _streamOnce(
        chat: chat,
        tools: toolDefs,
        onTextDelta: (t) {
          finalText.write(t);
          onTextDelta(t);
        },
      );

      // Echo the assistant turn back (text + any tool calls).
      final assistantMsg = <String, dynamic>{
        'role': 'assistant',
        'content': result.text.isEmpty ? null : result.text,
      };
      if (result.calls.isNotEmpty) {
        assistantMsg['tool_calls'] = result.calls
            .map((c) => {
                  'id': c.id,
                  'type': 'function',
                  'function': {'name': c.name, 'arguments': c.rawArgs},
                })
            .toList();
      }
      chat.add(assistantMsg);

      if (result.calls.isEmpty) break;

      for (final call in result.calls) {
        onToolUse?.call(call.name);
        String output;
        try {
          output = await executeTool(call.name, call.parsedArgs());
        } catch (e) {
          output = 'Error running ${call.name}: $e';
        }
        chat.add({
          'role': 'tool',
          'tool_call_id': call.id,
          'content': output,
        });
      }
    }

    if (finalText.isNotEmpty) {
      messages.add({'role': 'assistant', 'content': finalText.toString()});
    }
  }

  Future<_OaiRound> _streamOnce({
    required List<Map<String, dynamic>> chat,
    required List<Map<String, dynamic>> tools,
    required void Function(String delta) onTextDelta,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'messages': chat,
      'max_tokens': 1024,
      'stream': true,
      if (tools.isNotEmpty) 'tools': tools,
    };

    Response? response;
    for (var attempt = 0;; attempt++) {
      try {
        response = await _dio.post(_endpoint, data: jsonEncode(body));
        break;
      } on DioError catch (e) {
        if (e.response?.statusCode == 429 && attempt < 2) {
          await Future.delayed(Duration(seconds: 3 + attempt * 4));
          continue;
        }
        throw HarryOpenAIException(await _describeError(e));
      }
    }

    final textBuf = StringBuffer();
    final toolAccum = <int, _ToolAccum>{};

    await (response.data as ResponseBody)
        .stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
      if (!line.startsWith('data:')) return;
      final payload = line.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') return;

      Map<String, dynamic> chunk;
      try {
        chunk = jsonDecode(payload) as Map<String, dynamic>;
      } catch (_) {
        return;
      }

      final choices = chunk['choices'];
      if (choices is! List || choices.isEmpty) return;
      final choice = choices.first as Map<String, dynamic>;
      final delta = choice['delta'];
      if (delta is! Map) return;

      final content = delta['content'];
      if (content is String && content.isNotEmpty) {
        textBuf.write(content);
        onTextDelta(content);
      }

      final toolCalls = delta['tool_calls'];
      if (toolCalls is List) {
        for (final tc in toolCalls) {
          if (tc is! Map) continue;
          final idx = (tc['index'] as int?) ?? 0;
          final acc = toolAccum.putIfAbsent(idx, () => _ToolAccum());
          if (tc['id'] is String) acc.id = tc['id'] as String;
          final fn = tc['function'];
          if (fn is Map) {
            if (fn['name'] is String) acc.name = fn['name'] as String;
            if (fn['arguments'] is String) {
              acc.args.write(fn['arguments']);
            }
          }
        }
      }
    });

    final calls = <_OaiCall>[];
    for (final idx in toolAccum.keys.toList()..sort()) {
      final a = toolAccum[idx]!;
      if (a.name.isEmpty) continue;
      calls.add(_OaiCall(a.id, a.name, a.args.toString()));
    }

    return _OaiRound(textBuf.toString(), calls);
  }

  Future<String> _describeError(DioError e) async {
    final status = e.response?.statusCode;
    final detail = await _readBody(e);
    if (status == 401 || status == 403) {
      return 'The AI provider rejected the key ($status). '
          '${detail.isNotEmpty ? detail : 'Check LLM_API_KEY / GROQ_API_KEY in assets/.env.'}';
    }
    if (status == 429) {
      return 'AI provider rate limit hit (429). '
          '${detail.isNotEmpty ? detail : 'Wait a moment and retry.'}';
    }
    if (status == 404) {
      return 'Model "$model" not found (404). '
          '${detail.isNotEmpty ? detail : 'Check LLM_MODEL / LLM_BASE_URL.'}';
    }
    return 'Harry could not reach the AI provider (${status ?? e.message}). $detail'
        .trim();
  }

  Future<String> _readBody(DioError e) async {
    final data = e.response?.data;
    if (data is! ResponseBody) return '';
    try {
      final text = await utf8.decodeStream(data.stream.cast<List<int>>());
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map && decoded['error'] is Map) {
          final msg = (decoded['error'] as Map)['message'];
          if (msg is String && msg.isNotEmpty) return msg;
        }
      } catch (_) {}
      return text.length > 300 ? '${text.substring(0, 300)}…' : text;
    } catch (_) {
      return '';
    }
  }
}

class HarryOpenAIException implements Exception {
  HarryOpenAIException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _ToolAccum {
  String id = '';
  String name = '';
  final StringBuffer args = StringBuffer();
}

class _OaiCall {
  _OaiCall(this.id, this.name, this.rawArgs);
  final String id;
  final String name;
  final String rawArgs;

  Map<String, dynamic> parsedArgs() {
    if (rawArgs.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(rawArgs);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }
}

class _OaiRound {
  _OaiRound(this.text, this.calls);
  final String text;
  final List<_OaiCall> calls;
}
