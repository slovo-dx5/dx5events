/**
 * G3 "Gamification — Leaderboard" · Run Script operation · key: `board`
 *
 * Webhook GET ?user_id=…&limit=50. Returns the top players plus the caller's
 * own row (so the app can pin it when they are outside the top list).
 *
 * Expects these earlier operation keys:
 *   settings  — Read Data on gamification_settings (singleton).
 *   totals    — Read Data on points_ledger,
 *               {"aggregate":{"sum":["points"]},"groupBy":["user_id"],"limit":-1}
 *               When leaderboard_freeze_at is set, also filter
 *               {"date_created":{"_lte":"<freeze time>"}} — see the README.
 *   people    — Read Data on event_registrations,
 *               {"filter":{"eventId":{"_eq":<event id>}},
 *                "fields":["attendeeId","first_name","last_name","company","role","profile_photo"],
 *                "limit":-1}
 *
 * Shape must match LeaderboardEntry.fromJson in
 * lib/services/gamification_service.dart.
 */

function asList(v) {
  if (Array.isArray(v)) return v;
  if (v && typeof v === 'object') return [v];
  return [];
}

function asArray(v) {
  if (Array.isArray(v)) return v;
  if (typeof v === 'string' && v.trim()) {
    try {
      const parsed = JSON.parse(v);
      return Array.isArray(parsed) ? parsed : [];
    } catch (_) {
      return [];
    }
  }
  return [];
}

function toInt(v, fallback) {
  const n = Number(v);
  return Number.isFinite(n) ? Math.trunc(n) : fallback;
}

module.exports = async function (data) {
  const settings = asList(data.settings)[0] || {};
  if (settings.leaderboard_enabled === false) {
    return { enabled: false, entries: [], me: null };
  }

  const query = (data.$trigger && data.$trigger.query) || {};
  const me = query.user_id ? String(query.user_id) : null;
  const limit = Math.min(Math.max(toInt(query.limit, 50), 1), 200);
  const excluded = new Set(asArray(settings.excluded_user_ids).map(String));

  const people = new Map();
  for (const p of asList(data.people)) {
    if (p && p.attendeeId !== null && p.attendeeId !== undefined) {
      people.set(String(p.attendeeId), p);
    }
  }

  const rows = asList(data.totals)
    .map((row) => ({
      user: String(row.user_id),
      points: toInt(row.sum && typeof row.sum === 'object' ? row.sum.points : row.sum, 0),
    }))
    // Only registered delegates of this event, minus staff and sponsors.
    .filter((row) => row.points > 0 && people.has(row.user) && !excluded.has(row.user))
    // Ties share a rank; within a tie, order is stable by user id.
    .sort((a, b) => b.points - a.points || a.user.localeCompare(b.user));

  let rank = 0;
  let lastPoints = null;
  const ranked = rows.map((row, i) => {
    if (row.points !== lastPoints) {
      rank = i + 1;
      lastPoints = row.points;
    }
    const p = people.get(row.user) || {};
    return {
      rank,
      user_id: toInt(row.user, null),
      points: row.points,
      first_name: p.first_name || '',
      last_name: p.last_name || '',
      company: p.company || '',
      role: p.role || '',
      profile_photo: p.profile_photo || null,
    };
  });

  return {
    enabled: true,
    frozen: Boolean(settings.leaderboard_freeze_at),
    players: ranked.length,
    entries: ranked.slice(0, limit),
    me: me ? ranked.find((r) => String(r.user_id) === me) || null : null,
  };
};
