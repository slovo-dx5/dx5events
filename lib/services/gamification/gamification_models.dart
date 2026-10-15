/// Shapes returned by the gamification Flows. Field names mirror
/// `tool/directus_flows/gamification_engine.js` (progress) and
/// `gamification_leaderboard.js` (leaderboard) — change both together.

int _int(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}') ?? fallback;
}

int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}

DateTime? _time(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

enum RewardCategory { quick, challenge, daily }

RewardCategory _category(dynamic v) {
  switch (v) {
    case 'quick':
      return RewardCategory.quick;
    case 'daily':
      return RewardCategory.daily;
    default:
      return RewardCategory.challenge;
  }
}

class RewardTier {
  final int count;
  final int points;
  final bool done;

  const RewardTier({required this.count, required this.points, required this.done});

  factory RewardTier.fromJson(Map<String, dynamic> j) => RewardTier(
        count: _int(j['count']),
        points: _int(j['points']),
        done: j['done'] == true,
      );
}

class RewardDay {
  /// yyyy-MM-dd in the event's timezone.
  final String date;
  final bool done;

  const RewardDay({required this.date, required this.done});

  factory RewardDay.fromJson(Map<String, dynamic> j) =>
      RewardDay(date: '${j['date']}', done: j['done'] == true);
}

/// One earnable rule (a row of `point_actions`) with the user's progress.
class RewardRule {
  final int id;
  final String name;
  final String description;
  final String? icon;

  /// Key of the screen the card opens — see RewardsPage._openScreen.
  final String? screen;
  final RewardCategory category;

  /// once | quest | each | distinct_tiers | daily | all_days
  final String type;
  final int points;
  final int maxPoints;
  final int earned;
  final bool complete;
  final int current;
  final int? target;
  final List<RewardTier> tiers;
  final List<RewardDay> days;
  final DateTime? activeFrom;
  final DateTime? activeTo;
  final bool upcoming;
  final bool expired;

  const RewardRule({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.screen,
    required this.category,
    required this.type,
    required this.points,
    required this.maxPoints,
    required this.earned,
    required this.complete,
    required this.current,
    required this.target,
    required this.tiers,
    required this.days,
    required this.activeFrom,
    required this.activeTo,
    required this.upcoming,
    required this.expired,
  });

  bool get isQuest => type == 'quest' || activeTo != null;

  /// 0..1 towards the next milestone (or the whole rule when there is none).
  double get fraction {
    if (complete) return 1;
    final t = target;
    if (t == null || t <= 0) return 0;
    return (current / t).clamp(0, 1).toDouble();
  }

  factory RewardRule.fromJson(Map<String, dynamic> j) => RewardRule(
        id: _int(j['id']),
        name: '${j['name'] ?? ''}',
        description: '${j['description'] ?? ''}',
        icon: (j['icon'] as String?)?.isNotEmpty == true ? j['icon'] as String : null,
        screen: (j['screen'] as String?)?.isNotEmpty == true ? j['screen'] as String : null,
        category: _category(j['category']),
        type: '${j['type'] ?? 'once'}',
        points: _int(j['points']),
        maxPoints: _int(j['max_points']),
        earned: _int(j['earned']),
        complete: j['complete'] == true,
        current: _int(j['current']),
        target: _intOrNull(j['target']),
        tiers: [
          for (final t in (j['tiers'] as List? ?? const []))
            if (t is Map) RewardTier.fromJson(Map<String, dynamic>.from(t)),
        ],
        days: [
          for (final d in (j['days'] as List? ?? const []))
            if (d is Map) RewardDay.fromJson(Map<String, dynamic>.from(d)),
        ],
        activeFrom: _time(j['active_from']),
        activeTo: _time(j['active_to']),
        upcoming: j['upcoming'] == true,
        expired: j['expired'] == true,
      );
}

class RewardsProgress {
  final int total;
  final int? rank;
  final int players;
  final List<String> eventDays;

  /// yyyy-MM-dd in the event's timezone, as the server sees it.
  final String today;
  final List<RewardRule> rules;

  const RewardsProgress({
    required this.total,
    required this.rank,
    required this.players,
    required this.eventDays,
    required this.today,
    required this.rules,
  });

  /// 1-based event day for today, or null outside the event.
  int? get dayNumber {
    final i = eventDays.indexOf(today);
    return i < 0 ? null : i + 1;
  }

  factory RewardsProgress.fromJson(Map<String, dynamic> j) => RewardsProgress(
        total: _int(j['total']),
        rank: _intOrNull(j['rank']),
        players: _int(j['players']),
        eventDays: [for (final d in (j['event_days'] as List? ?? const [])) '$d'],
        today: '${j['today'] ?? ''}',
        rules: [
          for (final r in (j['rules'] as List? ?? const []))
            if (r is Map) RewardRule.fromJson(Map<String, dynamic>.from(r)),
        ],
      );
}

class LeaderboardEntry {
  final int rank;
  final int userId;
  final int points;
  final String firstName;
  final String lastName;
  final String company;
  final String role;
  final String? profilePhoto;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.points,
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.role,
    required this.profilePhoto,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: _int(j['rank']),
        userId: _int(j['user_id']),
        points: _int(j['points']),
        firstName: '${j['first_name'] ?? ''}',
        lastName: '${j['last_name'] ?? ''}',
        company: '${j['company'] ?? ''}',
        role: '${j['role'] ?? ''}',
        profilePhoto: (j['profile_photo'] as String?)?.isNotEmpty == true
            ? j['profile_photo'] as String
            : null,
      );
}

class Leaderboard {
  final bool enabled;
  final bool frozen;
  final int players;
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? me;

  const Leaderboard({
    required this.enabled,
    required this.frozen,
    required this.players,
    required this.entries,
    required this.me,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> j) => Leaderboard(
        enabled: j['enabled'] != false,
        frozen: j['frozen'] == true,
        players: _int(j['players']),
        entries: [
          for (final e in (j['entries'] as List? ?? const []))
            if (e is Map) LeaderboardEntry.fromJson(Map<String, dynamic>.from(e)),
        ],
        me: j['me'] is Map
            ? LeaderboardEntry.fromJson(Map<String, dynamic>.from(j['me'] as Map))
            : null,
      );
}
