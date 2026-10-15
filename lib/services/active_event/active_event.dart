import '../../dioServices/base_url.dart';

/// The event the app opens on: picked in Directus (`app_config.active_event`)
/// and fetched at startup by [ActiveEventService]. Every screen that used to
/// hard-code an event id, name or date reads it from here instead.
class ActiveEvent {
  final String id;
  final String title;

  /// Event-local wall-clock times, exactly as Directus stores them on
  /// `events.date_from` / `date_to` (no timezone conversion).
  final DateTime dateFrom;
  final DateTime dateTo;

  final String country;
  final String venue;
  final String tagline;

  /// Directus asset URLs, or null to use the bundled artwork.
  final String? cardImageUrl;
  final String? coverImageUrl;

  const ActiveEvent({
    required this.id,
    required this.title,
    required this.dateFrom,
    required this.dateTo,
    this.country = '',
    this.venue = '',
    this.tagline = '',
    this.cardImageUrl,
    this.coverImageUrl,
  });

  /// Used until the first fetch succeeds (first launch offline, or
  /// `app_config` not reachable). Keep in step with Directus.
  static final ActiveEvent fallback = ActiveEvent(
    id: '111',
    title: 'CIO100 Symposium and Awards 2026',
    dateFrom: DateTime(2026, 11, 25, 8),
    dateTo: DateTime(2026, 11, 27, 18),
    country: 'Kenya',
    venue: 'Diamonds Leisure Beach & Golf Resort, Diani, Kenya',
    tagline: 'Driving Business Growth Through IT Leadership',
  );

  // Artwork for [fallback], shown when no Directus image is set.
  static const String bundledCardImage =
      'assets/images/themes/cio100_portrait.jpg';
  static const String bundledCoverImage =
      'assets/images/themes/cio100_landscape.jpg';

  /// Builds from an `app_config` row fetched with `active_event.*` expanded.
  /// Returns null when the row has no usable event.
  static ActiveEvent? fromAppConfig(Map<String, dynamic> config) {
    final event = config['active_event'];
    if (event is! Map) return null;
    final id = event['id']?.toString() ?? '';
    final from = DateTime.tryParse(event['date_from']?.toString() ?? '');
    if (id.isEmpty || from == null) return null;
    final to = DateTime.tryParse(event['date_to']?.toString() ?? '') ?? from;
    // The bundled artwork is the fallback event's, and beats its small
    // banner; any other event without app artwork uses its banner.
    final banner = id == fallback.id ? null : _assetUrl(event['banner']);
    final tagline = (config['tagline'] ?? '').toString().trim();
    return ActiveEvent(
      id: id,
      title: (event['title'] ?? '').toString(),
      dateFrom: from,
      dateTo: to,
      country: (event['country'] ?? '').toString(),
      venue: (event['venue'] ?? '').toString(),
      tagline: tagline.isNotEmpty
          ? tagline
          : (event['summary'] ?? '').toString(),
      cardImageUrl: _assetUrl(config['card_image']) ?? banner,
      coverImageUrl: _assetUrl(config['cover_image']) ?? banner,
    );
  }

  static String? _assetUrl(dynamic fileId) {
    final id = fileId is Map ? fileId['id'] : fileId;
    if (id == null || id.toString().isEmpty) return null;
    return '${BaseURL.Baseurl}/assets/$id';
  }

  // ---- Values in the shapes the existing screens take ----

  String get displayName => title.toUpperCase();
  String get displayLocation => country.toUpperCase();
  String get dayOfWeek => _weekdays[dateFrom.weekday - 1];

  /// "WED, NOV, 25TH", or "WED, NOV, 25TH - FRI, NOV, 27TH" for multi-day.
  String get dateLabel {
    final start = dayLabel(dateFrom);
    final sameDay = dateFrom.year == dateTo.year &&
        dateFrom.month == dateTo.month &&
        dateFrom.day == dateTo.day;
    return sameDay ? start : '$start - ${dayLabel(dateTo)}';
  }

  static String dayLabel(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]}, '
      '${d.day}${_ordinal(d.day).toUpperCase()}';

  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  // ---- Offline cache ----

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date_from': dateFrom.toIso8601String(),
        'date_to': dateTo.toIso8601String(),
        'country': country,
        'venue': venue,
        'tagline': tagline,
        'card_image_url': cardImageUrl,
        'cover_image_url': coverImageUrl,
      };

  static ActiveEvent? fromJson(Map<String, dynamic> json) {
    final from = DateTime.tryParse(json['date_from']?.toString() ?? '');
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty || from == null) return null;
    return ActiveEvent(
      id: id,
      title: (json['title'] ?? '').toString(),
      dateFrom: from,
      dateTo: DateTime.tryParse(json['date_to']?.toString() ?? '') ?? from,
      country: (json['country'] ?? '').toString(),
      venue: (json['venue'] ?? '').toString(),
      tagline: (json['tagline'] ?? '').toString(),
      cardImageUrl: json['card_image_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
    );
  }
}
