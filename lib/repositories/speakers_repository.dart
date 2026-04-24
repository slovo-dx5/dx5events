import '../database/cache_repository.dart';
import '../dioServices/dioFetchService.dart';
import '../models/speakersModel.dart';

class SpeakersRepository {
  static final SpeakersRepository instance = SpeakersRepository._init();
  SpeakersRepository._init();

  static const Duration _ttl = Duration(hours: 24);

  String _key(int id) => 'speaker_$id';

  /// Returns speakers for the requested [ids] keyed by id.
  /// Cached speakers are returned without a network call; missing ones are
  /// fetched in a single bulk request.
  Future<Map<int, IndividualSpeaker>> getByIds(
    List<int> ids, {
    bool forceRefresh = false,
  }) async {
    if (ids.isEmpty) return {};

    final uniqueIds = ids.toSet().toList();
    final result = <int, IndividualSpeaker>{};
    final missing = <int>[];

    for (final id in uniqueIds) {
      if (forceRefresh) {
        missing.add(id);
        continue;
      }
      final cached = await CacheRepository.instance.getJson(_key(id), _ttl);
      if (cached != null) {
        try {
          result[id] = IndividualSpeaker.fromJson(
            Map<String, dynamic>.from(cached as Map),
          );
          continue;
        } catch (_) {
          await CacheRepository.instance.invalidate(_key(id));
        }
      }
      missing.add(id);
    }

    if (missing.isEmpty) return result;

    final response = await DioFetchService().fetchSpeakersByIds(missing);
    final rawList = (response.data['data'] as List?) ?? const [];

    for (final raw in rawList) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final id = map['id'];
      if (id is! int) continue;

      try {
        final speaker = IndividualSpeaker.fromJson(map);
        result[id] = speaker;
        await CacheRepository.instance.putJson(_key(id), map);
      } catch (_) {
        // Skip malformed speaker records rather than failing the whole batch.
      }
    }

    return result;
  }

  Future<IndividualSpeaker?> getById(int id, {bool forceRefresh = false}) async {
    final map = await getByIds([id], forceRefresh: forceRefresh);
    return map[id];
  }
}
