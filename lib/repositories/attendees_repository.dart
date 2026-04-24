import '../database/cache_repository.dart';
import '../dioServices/dioFetchService.dart';
import '../models/eventAttendeesModel.dart';

class AttendeesPage {
  final List<EventAttendeeModel> attendees;
  final bool hasMore;

  AttendeesPage({required this.attendees, required this.hasMore});
}

class AttendeesRepository {
  static final AttendeesRepository instance = AttendeesRepository._init();
  AttendeesRepository._init();

  static const Duration _ttl = Duration(minutes: 15);

  String _pageKey({
    required String eventID,
    required int page,
    required int pageSize,
  }) =>
      'attendees_${eventID}_${pageSize}_p$page';

  String _prefix(String eventID) => 'attendees_${eventID}_';

  Future<AttendeesPage> getPage({
    required String eventID,
    required int page,
    required int pageSize,
    String searchQuery = '',
    bool forceRefresh = false,
  }) async {
    final useCache = searchQuery.isEmpty;
    final key = _pageKey(eventID: eventID, page: page, pageSize: pageSize);

    if (useCache && !forceRefresh) {
      final cached = await CacheRepository.instance.getJson(key, _ttl);
      if (cached is List) {
        return _fromRawList(cached, pageSize);
      }
    }

    final response = await DioFetchService().fetchCIOAttendees(
      eventID: eventID,
      page: page,
      pageSize: pageSize,
      searchQuery: searchQuery,
    );

    final raw = (response.data['data'] as List?) ?? const [];
    if (useCache) {
      await CacheRepository.instance.putJson(key, raw);
    }
    return _fromRawList(raw, pageSize);
  }

  AttendeesPage _fromRawList(List rawList, int pageSize) {
    final parsed = <EventAttendeeModel>[];
    for (final item in rawList) {
      if (item is! Map) continue;
      try {
        parsed.add(
          EventAttendeeModel.fromJson(Map<String, dynamic>.from(item)),
        );
      } catch (_) {
        // Skip malformed rows rather than breaking the whole page.
      }
    }
    return AttendeesPage(
      attendees: parsed,
      hasMore: rawList.length >= pageSize,
    );
  }

  Future<void> invalidateEvent(String eventID) =>
      CacheRepository.instance.invalidatePrefix(_prefix(eventID));
}
