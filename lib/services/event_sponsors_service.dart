import '../dioServices/base_url.dart';
import '../dioServices/dioFetchService.dart';
import '../models/eventModel.dart';
import '../models/sponsor_data_model.dart';

/// A sponsor as listed on one event: Directus details plus the tier
/// (`category`) and position from the event's sponsor junction.
class EventSponsor {
  final SponsorData data;
  final String category;
  final int order;

  const EventSponsor({
    required this.data,
    required this.category,
    required this.order,
  });

  /// Resolves a bare Directus UUID to a full asset URL. If already a URL,
  /// returns as-is. Prefers transparent_logo over logo when present.
  String get logoUrl {
    final logo = data.transparent_logo ?? data.logo ?? '';
    return logo.startsWith('http') ? logo : '${BaseURL.Baseurl}/assets/$logo';
  }

  String get websiteUrl =>
      (data.websites?.isNotEmpty == true) ? (data.websites!.first.link ?? '') : '';

  bool get isExhibitor => category.toLowerCase() == 'exhibitor_only';
}

class EventSponsors {
  final List<EventSponsor> sponsors;
  final List<EventSponsor> exhibitors;

  const EventSponsors({required this.sponsors, required this.exhibitors});

  static const empty = EventSponsors(sponsors: [], exhibitors: []);
}

/// Loads an event's sponsors once per app session. Shared by the Sponsors
/// screen, the home carousel and the booth-scan message.
class EventSponsorsService {
  EventSponsorsService._();
  static final EventSponsorsService instance = EventSponsorsService._();

  // Canonical display order, matching SponsorsSection.svelte
  static const categoryOrder = [
    'simba', 'ndovu', 'kifaru', 'twiga', 'nyati', 'chui', 'duma', 'kiboko',
  ];

  final Map<String, Future<EventSponsors>> _cache = {};

  /// A failed load is dropped from the cache so the next call retries.
  Future<EventSponsors> load(String eventID) {
    return _cache.putIfAbsent(eventID, () {
      final future = _fetch(eventID);
      future.catchError((_) {
        _cache.remove(eventID);
        return EventSponsors.empty;
      });
      return future;
    });
  }

  Future<EventSponsors> _fetch(String eventID) async {
    // 1. Fetch event to get sponsor associations (key + category + order)
    final eventResponse = await DioFetchService().fetchEvents(eventID: eventID);
    final Map<String, dynamic> eventData = eventResponse.data['data'];

    final rawSponsors = eventData['sponsors'] as List<dynamic>? ?? [];
    if (rawSponsors.isEmpty) return EventSponsors.empty;

    final associations =
        rawSponsors.map((s) => SponsorAssociation.fromJson(s)).toList();

    // 2. Record original order and category from the junction records
    final orderMap = <int, int>{};
    final categoryMap = <int, String>{};
    for (var i = 0; i < associations.length; i++) {
      final id = associations[i].sponsor.key;
      orderMap[id] = i;
      categoryMap[id] = associations[i].category;
    }

    // 3. Bulk-fetch sponsor details in a single API call
    final ids = associations.map((a) => a.sponsor.key).toList();
    final sponsorsResponse = await DioFetchService().fetchSponsorsByIds(ids);
    final sponsorsModel = RootSponsorDataModel.fromJson(sponsorsResponse.data);

    if (sponsorsModel.data == null || sponsorsModel.data!.isEmpty) {
      return EventSponsors.empty;
    }

    // 4. Enrich: attach category from junction and original order
    final enriched = sponsorsModel.data!
        .where((s) => s.id != null && orderMap.containsKey(s.id))
        .map((s) => EventSponsor(
              data: s,
              category: categoryMap[s.id!] ?? '',
              order: orderMap[s.id!] ?? 0,
            ))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    // 5. Split: exhibitors are category == 'exhibitor_only', rest are sponsors
    return EventSponsors(
      sponsors: enriched.where((s) => !s.isExhibitor).toList(),
      exhibitors: enriched.where((s) => s.isExhibitor).toList(),
    );
  }

  /// The sponsor behind a booth QR code (`sponsor-<id>` or `sponsor-<name>`),
  /// or null when the code doesn't match anyone on this event.
  Future<EventSponsor?> findByBoothCode(String eventID, String code) async {
    final key = code.toLowerCase().replaceFirst(RegExp(r'^sponsor[-_:]?'), '');
    if (key.isEmpty) return null;
    final EventSponsors all;
    try {
      all = await load(eventID);
    } catch (_) {
      return null;
    }
    final everyone = [...all.sponsors, ...all.exhibitors];
    final id = int.tryParse(key);
    if (id != null) {
      for (final s in everyone) {
        if (s.data.id == id) return s;
      }
    }
    final slug = _slug(key);
    for (final s in everyone) {
      if (_slug(s.data.sponsorName ?? '') == slug) return s;
    }
    return null;
  }

  static String _slug(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Toast text after a booth QR scan. Names the sponsor when the code can be
  /// matched to one; never mentions points, since not every event runs Rewards.
  Future<String> boothVisitMessage(String eventID, String code) async {
    // Usually cached by the home carousel; don't hold the toast on a slow fetch.
    final sponsor = await findByBoothCode(eventID, code)
        .timeout(const Duration(seconds: 3), onTimeout: () => null);
    final name = sponsor?.data.sponsorName?.trim();
    return name == null || name.isEmpty
        ? 'Booth visit recorded. Thanks for stopping by!'
        : 'Booth visit recorded: $name. Thanks for stopping by!';
  }
}
