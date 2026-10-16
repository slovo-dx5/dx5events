import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Subscribes the device to gallery photo notifications for an event.
///
/// The topic is keyed on the app's own (Directus) event id — the same id
/// provided in `landingPage2.dart` (e.g. `107`) that flows through as
/// `homePageWidget.eventID`. The sending side (Cloud Function
/// `galleryPhotoNotifier`) maps each pix event to that app id and pushes to
/// `gallery_<appEventId>`, so the client needs no pix API call just to
/// subscribe.
class GalleryNotifications {
  GalleryNotifications._();

  static const _kSubscribed = 'gallery_subscribed_topics';

  /// Ensures this device is subscribed to [appEventId]'s gallery topic.
  ///
  /// Safe to call on every home-page open — subscribing is idempotent and
  /// involves no network call beyond FCM's own. Fire-and-forget: failures are
  /// swallowed so a flaky network never breaks the home screen.
  static Future<void> subscribeForEvent(String appEventId) async {
    if (appEventId.isEmpty) return;
    try {
      final topic = _topicFor(appEventId);
      final prefs = await SharedPreferences.getInstance();
      final subscribed = prefs.getStringList(_kSubscribed) ?? <String>[];
      if (subscribed.contains(topic)) return;

      await FirebaseMessaging.instance.subscribeToTopic(topic);
      await prefs.setStringList(_kSubscribed, [...subscribed, topic]);
    } catch (_) {
      // Non-fatal — the user still sees the gallery, just no push for now.
    }
  }

  static String _topicFor(String appEventId) {
    // FCM topics allow [a-zA-Z0-9-_.~%]; app ids are numeric but sanitize
    // anyway so a stray id can never produce an invalid topic name.
    final safe = appEventId.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');
    return 'gallery_$safe';
  }
}
