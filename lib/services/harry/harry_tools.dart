import 'dart:convert';

import '../../dioServices/dioFetchService.dart';
import 'harry_reminders.dart';

/// Defines Harry's tool schemas and executes tool calls against the app's
/// existing services. Read tools reuse [DioFetchService]; actions (navigation,
/// reminders) are delegated to callbacks supplied by the controller so this
/// class stays free of UI/router dependencies.
class HarryTools {
  HarryTools({
    required this.eventId,
    required this.reminders,
    required this.navigate,
  });

  /// The event Harry is currently scoped to (Directus event id as a string).
  final String eventId;

  /// Null only if the notifications plugin failed to initialise.
  final HarryReminders? reminders;

  /// Navigates the app to a named destination and returns a short confirmation.
  /// Supported targets: `meetings`, `notifications`, `home`.
  final Future<String> Function(String target) navigate;

  final DioFetchService _fetch = DioFetchService();

  /// Keeps tool_result payloads from blowing up the context window.
  static const int _maxResultChars = 6000;

  /// Anthropic tool definitions sent on every request.
  List<Map<String, dynamic>> get definitions => [
        {
          'name': 'get_agenda',
          'description':
              'Get the full agenda/schedule for the current event: days, '
                  'sessions, times, stages and session summaries. Use this for '
                  'any question about what is happening and when.',
          'input_schema': {'type': 'object', 'properties': {}},
        },
        {
          'name': 'get_speakers',
          'description':
              'Get the list of speakers for the event, including their names, '
                  'roles and companies. Use for questions about who is speaking.',
          'input_schema': {'type': 'object', 'properties': {}},
        },
        {
          'name': 'get_sponsors',
          'description':
              'Get the list of event sponsors and partners.',
          'input_schema': {'type': 'object', 'properties': {}},
        },
        {
          'name': 'search_attendees',
          'description':
              'Search the attendee directory by name, company or role to help '
                  'the user network or find someone to meet.',
          'input_schema': {
            'type': 'object',
            'properties': {
              'query': {
                'type': 'string',
                'description': 'Name, company or role to search for.',
              },
            },
            'required': ['query'],
          },
        },
        {
          'name': 'open_screen',
          'description':
              'Navigate the app to a screen for the user. Only use when the '
                  'user clearly wants to go somewhere. Valid targets: '
                  '"meetings", "notifications", "home".',
          'input_schema': {
            'type': 'object',
            'properties': {
              'target': {
                'type': 'string',
                'enum': ['meetings', 'notifications', 'home'],
              },
            },
            'required': ['target'],
          },
        },
        {
          'name': 'set_reminder',
          'description':
              'Schedule a local reminder notification. Provide the reminder '
                  'text and an absolute date-time in ISO 8601 format. If the '
                  'user gives a relative time (e.g. "in 30 minutes", "tomorrow '
                  'at 9am"), compute the absolute ISO time yourself from the '
                  'current time provided in the system prompt.',
          'input_schema': {
            'type': 'object',
            'properties': {
              'title': {
                'type': 'string',
                'description': 'What to remind the user about.',
              },
              'when_iso': {
                'type': 'string',
                'description': 'Absolute reminder time, ISO 8601 (local time).',
              },
            },
            'required': ['title', 'when_iso'],
          },
        },
      ];

  Future<String> execute(String name, Map<String, dynamic> input) async {
    switch (name) {
      case 'get_agenda':
        return _readItems(() => _fetch.fetchdx5veAgenda(eventID: eventId));
      case 'get_speakers':
        return _readItems(() => _fetch.fetchEventSpeakers());
      case 'get_sponsors':
        return _readItems(() => _fetch.fetchEventSponsors());
      case 'search_attendees':
        final query = (input['query'] ?? '').toString();
        return _readItems(() => _fetch.fetchCIOAttendees(
              eventID: eventId,
              searchQuery: query,
              pageSize: 15,
            ));
      case 'open_screen':
        final target = (input['target'] ?? '').toString();
        return navigate(target);
      case 'set_reminder':
        return _setReminder(input);
      default:
        return 'Unknown tool: $name';
    }
  }

  Future<String> _setReminder(Map<String, dynamic> input) async {
    final title = (input['title'] ?? 'Reminder').toString();
    final whenIso = (input['when_iso'] ?? '').toString();
    final when = DateTime.tryParse(whenIso);
    if (when == null) {
      return 'Could not understand the reminder time "$whenIso". Ask the user '
          'for a clearer time.';
    }
    final r = reminders;
    if (r == null) {
      return 'Reminders are unavailable on this device right now.';
    }
    try {
      return await r.schedule(title: title, when: when);
    } catch (e) {
      return 'Could not set the reminder: $e';
    }
  }

  /// Fetches a Directus-style list response and returns a compact, truncated
  /// JSON string suitable for a tool_result.
  Future<String> _readItems(Future<dynamic> Function() call) async {
    try {
      final response = await call();
      final data = response.data;
      final encoded = jsonEncode(data is Map ? (data['data'] ?? data) : data);
      if (encoded.length <= _maxResultChars) return encoded;
      return '${encoded.substring(0, _maxResultChars)}… (results truncated; '
          'summarise what is most relevant to the user)';
    } catch (e) {
      return 'Could not load that information right now ($e).';
    }
  }
}
