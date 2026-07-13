import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../services/harry/harry_brain.dart';
import '../services/harry/harry_client.dart';
import '../services/harry/harry_config.dart';
import '../services/harry/harry_demo_brain.dart';
import '../services/harry/harry_gemini_brain.dart';
import '../services/harry/harry_knowledge.dart';
import '../services/harry/harry_openai_brain.dart';
import '../services/harry/harry_reminders.dart';
import '../services/harry/harry_tools.dart';
import '../widgets/harry/harry_message.dart';

/// Drives the Harry assistant: holds the chat transcript, the running
/// conversation, the current event context, and the open/closed UI state.
class HarryController extends ChangeNotifier {
  HarryController() {
    _brain = _selectBrain();
    isDemo = _brain is HarryDemoBrain;
    _loadAuthState();
  }

  /// Whether the user is logged in (past the OTP screen). Used for event
  /// context/name and restore, not for visibility.
  bool authed = false;

  /// Whether the user is currently inside an event (the MainNavigationPage
  /// shell). Harry is only shown here — never on the event-selection landing,
  /// login or OTP screens.
  bool inEvent = false;

  /// Toggles Harry's visibility as the user enters/leaves an event. Leaving an
  /// event closes the panel and clears the transcript so each event starts
  /// fresh.
  void setInEvent(bool value) {
    if (inEvent == value) return;
    inEvent = value;
    if (!value) {
      isOpen = false;
      messages.clear();
      _history.clear();
      _current = null;
    }
    notifyListeners();
  }

  /// Restores auth state on cold start (so a returning, still-logged-in user
  /// sees Harry without re-verifying).
  Future<void> _loadAuthState() async {
    final wasAuthed = await getBoolPref('isAuthenticated');
    final name = await getStringPref(kFirstName);
    if (name.isNotEmpty) userFirstName = name;
    if (wasAuthed) {
      authed = true;
      notifyListeners();
    }
  }

  /// Enables/disables Harry with the user's login state. Called after OTP
  /// success (true) and on logout (false). Logout also clears the transcript.
  void setAuthenticated(bool value, {String? firstName}) {
    authed = value;
    if (firstName != null && firstName.isNotEmpty) userFirstName = firstName;
    if (!value) {
      isOpen = false;
      messages.clear();
      _history.clear();
      _current = null;
    }
    notifyListeners();
  }

  /// Chooses the AI backend. An explicit HARRY_PROVIDER wins (when its key is
  /// present); otherwise auto-selects by whichever key is configured, and falls
  /// back to the keyless demo brain.
  HarryBrain _selectBrain() {
    if (HarryConfig.forceDemo) return HarryDemoBrain();

    switch (HarryConfig.provider.trim().toLowerCase()) {
      case 'anthropic':
      case 'claude':
        if (HarryClient.hasKey) return HarryClient();
        break;
      case 'gemini':
      case 'google':
        if (HarryGeminiBrain.hasKey) return HarryGeminiBrain();
        break;
      case 'groq':
      case 'grok':
      case 'xai':
      case 'openai':
      case 'cerebras':
      case 'openrouter':
      case 'ollama':
      case 'llm':
        if (HarryOpenAICompatBrain.hasKey) return HarryOpenAICompatBrain();
        break;
      case 'demo':
        return HarryDemoBrain();
    }

    // Auto-select by available key.
    if (HarryClient.hasKey) return HarryClient(); // Anthropic Claude
    if (HarryGeminiBrain.hasKey) return HarryGeminiBrain(); // Google Gemini
    if (HarryOpenAICompatBrain.hasKey) {
      return HarryOpenAICompatBrain(); // Groq / OpenAI-compatible
    }
    return HarryDemoBrain(); // keyless scripted fallback
  }

  late final HarryBrain _brain;

  /// True when running the keyless scripted brain (no Anthropic key supplied).
  late final bool isDemo;

  /// Injected from `main()` once the local-notifications plugin is ready.
  HarryReminders? reminders;

  /// Set by the overlay so tools can drive app navigation (uses go_router).
  Future<String> Function(String target)? navigateHandler;

  /// Set by the voice service to speak Harry's replies aloud.
  Future<void> Function(String text)? speakHandler;
  bool speakReplies = false;

  // ---- Event context (defaults mirror the active event in landingPage2). ----
  String eventId = '107';
  String eventName = 'the current event';
  String eventDate = '';
  String eventLocation = '';
  String eventDescription = '';
  String userFirstName = '';

  // ---- UI state ----
  bool isOpen = false;
  bool isBusy = false;
  final List<HarryMessage> messages = [];

  // ---- Anthropic conversation history (role/content maps) ----
  final List<Map<String, dynamic>> _history = [];

  HarryMessage? _current;

  /// True when a real AI brain (Claude or Gemini) is active, rather than the
  /// keyless demo fallback.
  bool get isConfigured => !isDemo;

  void open() {
    if (!isOpen) {
      isOpen = true;
      if (messages.isEmpty) _greet();
      notifyListeners();
    }
  }

  void close() {
    if (isOpen) {
      isOpen = false;
      notifyListeners();
    }
  }

  void toggle() => isOpen ? close() : open();

  void toggleSpeak() {
    speakReplies = !speakReplies;
    notifyListeners();
  }

  /// Update the event Harry answers about. Called when the user enters an event.
  void updateEvent({
    required String eventId,
    String? name,
    String? date,
    String? location,
    String? description,
  }) {
    this.eventId = eventId;
    if (name != null && name.isNotEmpty) eventName = name;
    if (date != null && date.isNotEmpty) eventDate = date;
    if (location != null && location.isNotEmpty) eventLocation = location;
    if (description != null && description.isNotEmpty) {
      eventDescription = description;
    }
  }

  void setUserName(String first) => userFirstName = first;

  void _greet() {
    final hi = userFirstName.isEmpty ? 'Hi there!' : 'Hi $userFirstName!';
    final demoNote = isDemo
        ? " (I'm in demo mode right now, so my answers are scripted — but "
            "reminders, navigation and live event data all really work.)"
        : '';
    messages.add(HarryMessage(
      sender: HarrySender.harry,
      text: "$hi I'm Harry, your event assistant. Ask me about the agenda, "
          "speakers, sponsors or how to use the app — or ask me to set a "
          "reminder or open a screen for you.$demoNote",
    ));
  }

  Future<void> sendUserMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || isBusy) return;
    // A brain is always assigned (Claude, Gemini, or the demo fallback), so
    // Harry can always respond — no key guard needed here.

    messages.add(HarryMessage(sender: HarrySender.user, text: text));
    _history.add({'role': 'user', 'content': text});
    isBusy = true;
    _current = null;
    notifyListeners();

    final tools = HarryTools(
      eventId: eventId,
      reminders: reminders,
      navigate: (target) async =>
          navigateHandler == null
              ? 'I can point you there, but navigation is not available on this '
                  'screen. Please use the bottom tabs.'
              : await navigateHandler!(target),
    );

    try {
      await _brain.runConversation(
        messages: _history,
        systemPrompt: _buildSystemPrompt(),
        tools: tools.definitions,
        executeTool: tools.execute,
        onTextDelta: _appendDelta,
        onToolUse: _announceTool,
      );
    } on HarryClientException catch (e) {
      _appendDelta('\n\n⚠️ ${e.message}');
    } on HarryGeminiException catch (e) {
      _appendDelta('\n\n⚠️ ${e.message}');
    } on HarryOpenAIException catch (e) {
      _appendDelta('\n\n⚠️ ${e.message}');
    } catch (e) {
      _appendDelta('\n\n⚠️ Something went wrong: $e');
    } finally {
      _finishCurrent();
      isBusy = false;
      notifyListeners();
      if (speakReplies && speakHandler != null) {
        final last = messages.lastWhere(
          (m) => m.isHarry && m.text.trim().isNotEmpty,
          orElse: () => HarryMessage(sender: HarrySender.harry),
        );
        if (last.text.trim().isNotEmpty) speakHandler!(last.text);
      }
    }
  }

  void _appendDelta(String delta) {
    _current ??= _newAssistantBubble();
    _current!.text += delta;
    notifyListeners();
  }

  void _announceTool(String toolName) {
    _finishCurrent();
    messages.add(HarryMessage(
      sender: HarrySender.tool,
      toolLabel: _toolLabel(toolName),
    ));
    notifyListeners();
  }

  HarryMessage _newAssistantBubble() {
    final m = HarryMessage(sender: HarrySender.harry, isStreaming: true);
    messages.add(m);
    return m;
  }

  void _finishCurrent() {
    if (_current != null) {
      _current!.isStreaming = false;
      _current = null;
    }
  }

  String _toolLabel(String name) {
    switch (name) {
      case 'get_agenda':
        return 'Checking the agenda…';
      case 'get_speakers':
        return 'Looking up speakers…';
      case 'get_sponsors':
        return 'Looking up sponsors…';
      case 'search_attendees':
        return 'Searching attendees…';
      case 'open_screen':
        return 'Opening screen…';
      case 'set_reminder':
        return 'Setting a reminder…';
      default:
        return 'Working…';
    }
  }

  String _buildSystemPrompt() {
    final now = DateTime.now().toLocal();
    final event = StringBuffer('Current event: $eventName');
    if (eventDate.isNotEmpty) event.write(', $eventDate');
    if (eventLocation.isNotEmpty) event.write(', $eventLocation');
    if (eventDescription.isNotEmpty) event.write('. $eventDescription');

    return '''
You are Harry, a warm, concise in-app assistant inside the DX5VE Events mobile app (by CIO Africa). You help conference attendees with (1) how to use the app, and (2) information about the current event, plus light actions on their behalf.

Use the app handbook below as your source of truth for how the app works and what it can do. Everything in it, you know.

===== APP HANDBOOK =====
$harryAppHandbook
===== END HANDBOOK =====

How to behave:
- Be brief and friendly — usually 1-3 short sentences unless asked for detail.
- Answer from the handbook for "how do I…" questions.
- For live event facts (session times, who is speaking, sponsors, attendees), ALWAYS call a tool to fetch current data for this event — never guess or invent details.
- When the user wants to go somewhere the app supports (meetings, notifications, home), use open_screen. For other screens, tell them exactly which tab/tile to tap (per the handbook).
- For reminders, convert relative times ("in 30 min", "tomorrow at 9am") into an absolute ISO 8601 local time using the current time below, then call set_reminder.
- To book a meeting, guide the user: search attendees, then have them open that person and tap "Schedule a Meeting".
- If a tool result is truncated, summarise only what's most relevant.
- If you genuinely don't know something event-specific, say so and point to the right screen or the organisers — don't make it up.

Context:
- $event
- Current local time: ${now.toIso8601String()}
- User's first name: ${userFirstName.isEmpty ? 'unknown' : userFirstName}
''';
  }
}
