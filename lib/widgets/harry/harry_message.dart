enum HarrySender { user, harry, tool }

/// A single line in Harry's chat transcript.
///
/// Only [HarrySender.user] and [HarrySender.harry] messages are rendered as
/// bubbles. Tool activity is surfaced as a lightweight status line so the user
/// can see what Harry is doing (e.g. "Looking up the agenda…").
class HarryMessage {
  HarryMessage({
    required this.sender,
    this.text = '',
    this.isStreaming = false,
    this.toolLabel,
  });

  final HarrySender sender;
  String text;

  /// True while assistant tokens are still being appended from the stream.
  bool isStreaming;

  /// Human-readable label for a [HarrySender.tool] status line.
  final String? toolLabel;

  bool get isUser => sender == HarrySender.user;
  bool get isHarry => sender == HarrySender.harry;
  bool get isTool => sender == HarrySender.tool;
}
