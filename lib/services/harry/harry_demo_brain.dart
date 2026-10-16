import 'harry_brain.dart';

/// Keyless, offline "brain" that scripts Harry's replies so the whole flow can
/// be tested without an Anthropic key. It still drives the REAL tools — it
/// fetches live agenda/speaker/attendee data, schedules real reminders and
/// performs real navigation — so everything except the language understanding
/// is genuine. Intent is chosen by simple keyword matching.
class HarryDemoBrain implements HarryBrain {
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
    final raw = _lastUserText(messages);
    final q = raw.toLowerCase();

    if (q.trim().isEmpty) {
      await _stream(
        "I didn't catch that. Try asking about the agenda or speakers, or say "
        "\"remind me about the keynote\".",
        onTextDelta,
      );
      return;
    }

    // --- Reminders (schedules a real local notification ~1 min out) ---
    if (q.contains('remind')) {
      onToolUse?.call('set_reminder');
      final when = DateTime.now().add(const Duration(minutes: 1));
      final result = await executeTool('set_reminder', {
        'title': _reminderTitle(raw),
        'when_iso': when.toIso8601String(),
      });
      final suffix = result.startsWith('Reminder set')
          ? ' (Demo: I scheduled it about a minute out so you can watch it fire.)'
          : '';
      await _stream('$result$suffix', onTextDelta);
      return;
    }

    // --- Navigation ---
    if (q.contains('meeting')) {
      onToolUse?.call('open_screen');
      await _stream(await executeTool('open_screen', {'target': 'meetings'}),
          onTextDelta);
      return;
    }
    if (q.contains('notification')) {
      onToolUse?.call('open_screen');
      await _stream(
          await executeTool('open_screen', {'target': 'notifications'}),
          onTextDelta);
      return;
    }
    if (q.contains('take me home') || q.contains('go home')) {
      onToolUse?.call('open_screen');
      await _stream(
          await executeTool('open_screen', {'target': 'home'}), onTextDelta);
      return;
    }

    // --- Live event data ---
    if (_containsAny(q,
        ['agenda', 'schedule', 'session', 'happening', 'today', 'programme'])) {
      onToolUse?.call('get_agenda');
      await executeTool('get_agenda', {});
      await _stream(
        "I pulled the latest agenda for the event. There are sessions across "
        "the day — open Home > Agenda for the full timetable, and I can point "
        "you to a specific talk if you name it.",
        onTextDelta,
      );
      return;
    }
    if (q.contains('speaker')) {
      onToolUse?.call('get_speakers');
      await executeTool('get_speakers', {});
      await _stream(
        "I loaded the speaker list — you'll find names, roles and companies "
        "under Home > Speakers.",
        onTextDelta,
      );
      return;
    }
    if (q.contains('sponsor') || q.contains('partner')) {
      onToolUse?.call('get_sponsors');
      await executeTool('get_sponsors', {});
      await _stream(
        "Here are the event's sponsors and partners — tap Home > Sponsors to "
        "see them all.",
        onTextDelta,
      );
      return;
    }
    if (_containsAny(
        q, ['attendee', 'network', 'find someone', 'who is', 'meet '])) {
      onToolUse?.call('search_attendees');
      await executeTool('search_attendees', {'query': _searchQuery(raw)});
      await _stream(
        "I searched the attendee directory. Open Home > Networking to browse "
        "results, tap a person, then \"Schedule a Meeting\" to connect.",
        onTextDelta,
      );
      return;
    }

    // --- How-to answers (no tool) ---
    if (_containsAny(q, ['scan', 'qr', 'badge', 'exchange contact'])) {
      await _stream(
        "To swap contacts, go to Home > Scan and point your camera at the other "
        "person's badge QR code — their details save straight to your contacts.",
        onTextDelta,
      );
      return;
    }
    if (_containsAny(q, ['map', 'venue', 'where is', 'room', 'directions'])) {
      await _stream(
        "Open Home > Map to see the venue layout and find rooms and stages.",
        onTextDelta,
      );
      return;
    }
    if (_containsAny(q, ['feedback', 'rate', 'review'])) {
      await _stream(
        "You can rate sessions and the event under Feedback — it helps the "
        "organisers a lot.",
        onTextDelta,
      );
      return;
    }
    if (_containsAny(q, ['reward', 'points', 'gamif'])) {
      await _stream(
        "Check the Rewards page to see the points you've earned for taking part.",
        onTextDelta,
      );
      return;
    }
    if (_containsAny(
        q, ['help', 'what can you', 'how do i', 'who are you', 'hi', 'hello'])) {
      await _stream(
        "I'm Harry, your event assistant. I can look up the agenda, speakers, "
        "sponsors and attendees, set reminders, and open screens for you. Try "
        "\"what's on today?\", \"find people from Safaricom\", or \"remind me "
        "about the keynote\".",
        onTextDelta,
      );
      return;
    }

    // --- Fallback ---
    await _stream(
      "I can help with the agenda, speakers, sponsors and attendees, set "
      "reminders, and open Meetings or Notifications for you. What would you "
      "like to do?",
      onTextDelta,
    );
  }

  // ------------------------------------------------------------------ helpers

  Future<void> _stream(String text, void Function(String) onDelta) async {
    final words = text.split(' ');
    for (var i = 0; i < words.length; i++) {
      onDelta(i == 0 ? words[i] : ' ${words[i]}');
      await Future.delayed(const Duration(milliseconds: 32));
    }
  }

  String _lastUserText(List<Map<String, dynamic>> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (m['role'] == 'user' && m['content'] is String) {
        return m['content'] as String;
      }
    }
    return '';
  }

  String _reminderTitle(String raw) {
    var t = raw.trim();
    final lower = t.toLowerCase();
    for (final prefix in ['remind me to ', 'remind me about ', 'remind me ']) {
      if (lower.startsWith(prefix)) {
        t = t.substring(prefix.length);
        break;
      }
    }
    return t.isEmpty ? 'Reminder' : t;
  }

  String _searchQuery(String raw) {
    // Strip common lead-ins so the search term is cleaner.
    var t = raw.trim();
    final lower = t.toLowerCase();
    for (final prefix in [
      'find people from ',
      'find someone from ',
      'search for ',
      'find ',
      'who is ',
    ]) {
      if (lower.startsWith(prefix)) {
        t = t.substring(prefix.length);
        break;
      }
    }
    return t;
  }

  bool _containsAny(String q, List<String> needles) =>
      needles.any((n) => q.contains(n));
}
