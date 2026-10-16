import '../database/cache_repository.dart';
import '../dioServices/dioFetchService.dart';

class EventRepository {
  static final EventRepository instance = EventRepository._init();
  EventRepository._init();

  static const Duration _ttl = Duration(hours: 24);

  String _key(String eventID) => 'event_$eventID';

  /// Returns the raw `data` object from `/items/events/:id` (as produced by
  /// Directus). Callers do their own parsing — some want the speaker list,
  /// some want sponsors, etc.
  Future<Map<String, dynamic>> getEventData({
    required String eventID,
    bool forceRefresh = false,
  }) async {
    final key = _key(eventID);

    if (!forceRefresh) {
      final cached = await CacheRepository.instance.getJson(key, _ttl);
      if (cached is Map) {
        return Map<String, dynamic>.from(cached);
      }
    }

    final response = await DioFetchService().fetchEvents(eventID: eventID);
    final data = response.data['data'];
    if (data is! Map) {
      throw StateError('Unexpected event response shape for $eventID');
    }
    final map = Map<String, dynamic>.from(data);
    await CacheRepository.instance.putJson(key, map);
    return map;
  }

  Future<void> invalidate(String eventID) =>
      CacheRepository.instance.invalidate(_key(eventID));
}
