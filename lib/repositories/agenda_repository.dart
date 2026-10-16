import '../database/cache_repository.dart';
import '../dioServices/dioFetchService.dart';
import '../models/agendaModel.dart';

class AgendaRepository {
  static final AgendaRepository instance = AgendaRepository._init();
  AgendaRepository._init();

  static const Duration _ttl = Duration(hours: 24);

  String _key(String eventID) => 'agenda_$eventID';

  Future<AgendaModel> getAgenda({
    required String eventID,
    bool forceRefresh = false,
  }) async {
    final key = _key(eventID);

    if (!forceRefresh) {
      final cached = await CacheRepository.instance.getJson(key, _ttl);
      if (cached != null) {
        try {
          return AgendaModel.fromJson(Map<String, dynamic>.from(cached as Map));
        } catch (_) {
          await CacheRepository.instance.invalidate(key);
        }
      }
    }

    final response =
        await DioFetchService().fetchdx5veAgenda(eventID: eventID);
    await CacheRepository.instance.putJson(key, response.data);
    return AgendaModel.fromJson(response.data);
  }

  Future<void> invalidate(String eventID) =>
      CacheRepository.instance.invalidate(_key(eventID));
}
