import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers.dart';
import '../services/active_event/active_event_service.dart';
import '../services/activity_logger.dart';
import '../services/webview_links/webview_links_service.dart';
import 'feedback_page.dart';
import 'webview_form_screen.dart';

/// Opens the hosted feedback form (`app_webview_links.event_feedback_form`)
/// when one is set in Directus, and the native [FeedbackPage] otherwise or
/// when the hosted form fails to load.
class FeedbackEntry extends StatelessWidget {
  final String eventID;

  const FeedbackEntry({super.key, required this.eventID});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final url = context.watch<WebviewLinksService>().feedbackFormUrl;
    final event = context.watch<ActiveEventService>().current;

    FeedbackPage nativeForm() => FeedbackPage(
          eventID: eventID,
          attendeeID: profile.userID?.toString() ?? '',
          attendeeName: '${profile.firstName} ${profile.lastName}',
        );

    if (url == null) return nativeForm();

    return WebViewFormScreen(
      url: url,
      title: 'Feedback',
      userDetails: {
        ...buildUserDetails(profile, event),
        // The screen that opened the form passes the event it belongs to.
        'event_id': eventID,
      },
      activityAction: ActivityAction.feedbackSubmitted,
      eventId: eventID,
      onFallback: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nativeForm()),
      ),
    );
  }
}
