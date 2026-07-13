/// A source of Harry's replies. Implemented by [HarryClient] (real Anthropic
/// API) and [HarryDemoBrain] (keyless scripted mode). Keeping both behind one
/// interface lets the controller swap providers without any other changes.
abstract class HarryBrain {
  /// Drives one assistant turn. Streams assistant text through [onTextDelta],
  /// announces tool use through [onToolUse], and runs tools via [executeTool].
  /// [messages] is the Anthropic-format history (used by the real brain; the
  /// demo brain only reads the latest user message from it).
  Future<void> runConversation({
    required List<Map<String, dynamic>> messages,
    required String systemPrompt,
    required List<Map<String, dynamic>> tools,
    required Future<String> Function(String name, Map<String, dynamic> input)
        executeTool,
    required void Function(String delta) onTextDelta,
    void Function(String toolName)? onToolUse,
    int maxRounds,
  });
}
