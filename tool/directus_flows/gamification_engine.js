/**
 * Gamification engine · Run Script operation · key: `engine`
 *
 * Pasted unchanged into two flows; it picks its mode from the trigger:
 *
 *   G1 "Gamification — Award"     Event Hook on app_activity_logs items.create.
 *                                 $trigger.payload is the new log row.
 *                                 Returns { mode: "award", rows: [...] } —
 *                                 the points_ledger rows still to be created.
 *   G2 "Gamification — Progress"  Webhook GET ?user_id=…
 *                                 Returns { mode: "progress", total, rank, rules }.
 *
 * Both modes run the same evaluation, so what the Rewards screen shows and what
 * actually gets awarded can never disagree. Awarding is stateless: every run
 * recomputes every award the user qualifies for and drops the award_keys that
 * are already in the ledger. An award missed because two flows raced (the
 * second insert hits the unique award_key and fails) is picked up by the next
 * log of the same action.
 *
 * Expects these earlier operation keys:
 *   rules     — Read Data on point_actions.
 *               G1: {"filter":{"status":{"_eq":"published"},
 *                     "trigger_action":{"_eq":"{{$trigger.payload.action}}"}},"limit":-1}
 *               G2: {"filter":{"status":{"_eq":"published"}},"sort":["sort"],"limit":-1}
 *   settings  — Read Data on gamification_settings (singleton).
 *   logs      — Read Data on app_activity_logs for this user,
 *               fields id,client_event_id,action,target_id,metadata,occurred_at.
 *               G1 also filters action = the trigger's action; G2 excludes the
 *               high-volume impression/tap actions.
 *   ledger    — Read Data on points_ledger for this user, fields award_key,points.
 *   totals    — (G2 only) Read Data on points_ledger,
 *               {"aggregate":{"sum":["points"]},"groupBy":["user_id"],"limit":-1}
 */

function asList(v) {
  if (Array.isArray(v)) return v;
  if (v && typeof v === 'object') return [v];
  return [];
}

function asObject(v) {
  if (v && typeof v === 'object' && !Array.isArray(v)) return v;
  if (typeof v === 'string' && v.trim()) {
    try {
      const parsed = JSON.parse(v);
      return parsed && typeof parsed === 'object' ? parsed : null;
    } catch (_) {
      return null;
    }
  }
  return null;
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

function toTime(v) {
  if (!v) return null;
  const t = Date.parse(v);
  return Number.isFinite(t) ? t : null;
}

/** yyyy-MM-dd of `t` in the event's timezone (fixed offset; Nairobi has no DST). */
function localDay(t, offsetMinutes) {
  return new Date(t + offsetMinutes * 60 * 1000).toISOString().slice(0, 10);
}

/** Reads `target_id`, `action`, `day` or `metadata.<key>` off a log. */
function fieldOf(log, path) {
  if (!path) return null;
  if (path === 'day') return log._day;
  if (path.startsWith('metadata.')) {
    const meta = asObject(log.metadata) || {};
    const v = meta[path.slice('metadata.'.length)];
    return v === undefined || v === null || v === '' ? null : String(v);
  }
  const v = log[path];
  return v === undefined || v === null || v === '' ? null : String(v);
}

function normaliseSettings(raw) {
  const s = asList(raw)[0] || {};
  return {
    offset: toInt(s.utc_offset_minutes, 180),
    eventDays: asArray(s.event_days).map(String).sort(),
    opensAt: toTime(s.awards_open_at),
    closesAt: toTime(s.awards_close_at),
    excluded: asArray(s.excluded_user_ids).map(String),
  };
}

function normaliseRule(r) {
  const tiers = asArray(r.tiers)
    .map((t) => ({ count: toInt(t && t.count, 0), points: toInt(t && t.points, 0) }))
    .filter((t) => t.count > 0)
    .sort((a, b) => a.count - b.count);
  return {
    id: r.id,
    trigger: r.trigger_action,
    type: r.rule_type || 'once',
    distinctBy: r.distinct_by || null,
    required: Math.max(1, toInt(r.required_occurrence, 1)),
    points: toInt(r.action_points, 0),
    maxAwards: r.max_awards === null || r.max_awards === undefined ? null : toInt(r.max_awards, null),
    tiers,
    match: asObject(r.match),
    activeFrom: toTime(r.active_from),
    activeTo: toTime(r.active_to),
    raw: r,
  };
}

/** Logs this rule can see: right action, inside every window, matching `match`. */
function logsFor(rule, logs, settings) {
  return logs.filter((log) => {
    if (log.action !== rule.trigger) return false;
    const t = log._t;
    if (t === null) return false;
    if (settings.opensAt !== null && t < settings.opensAt) return false;
    if (settings.closesAt !== null && t > settings.closesAt) return false;
    if (rule.activeFrom !== null && t < rule.activeFrom) return false;
    if (rule.activeTo !== null && t > rule.activeTo) return false;
    // Scanning your own badge never counts.
    if (log.target_type === 'attendee' && String(log.target_id) === String(log.user_id)) return false;
    if (rule.match) {
      // {"target_id": "x"} must equal; {"target_id": ["a","b"]} is any-of.
      for (const path of Object.keys(rule.match)) {
        const want = rule.match[path];
        const have = fieldOf(log, path);
        const ok = Array.isArray(want) ? want.map(String).includes(have) : have === String(want);
        if (!ok) return false;
      }
    }
    return true;
  });
}

/** Distinct keys in first-seen order. No distinct_by → every log counts once. */
function distinctKeys(rule, logs, settings) {
  const seen = new Set();
  const keys = [];
  for (const log of logs) {
    const key = rule.distinctBy
      ? fieldOf(log, rule.distinctBy)
      : String(log.client_event_id || log.id);
    if (key === null || seen.has(key)) continue;
    seen.add(key);
    keys.push(key);
  }
  return keys;
}

function countByDay(logs) {
  const counts = {};
  for (const log of logs) counts[log._day] = (counts[log._day] || 0) + 1;
  return counts;
}

/**
 * Evaluates one rule. Returns every award the user has earned under it (as
 * {award_key, points, event_day}) plus the progress the UI shows.
 */
function evaluate(rule, userId, logs, settings) {
  const mine = logsFor(rule, logs, settings);
  const base = `rule:${rule.id}|user:${userId}`;
  const awards = [];
  const progress = { type: rule.type };

  switch (rule.type) {
    case 'each': {
      const keys = distinctKeys(rule, mine, settings);
      const cap = rule.maxAwards === null ? keys.length : Math.min(keys.length, rule.maxAwards);
      for (const key of keys.slice(0, cap)) {
        awards.push({ award_key: `${base}|key:${key}`, points: rule.points });
      }
      progress.current = cap;
      progress.target = rule.maxAwards;
      break;
    }
    case 'distinct_tiers': {
      const count = distinctKeys(rule, mine, settings).length;
      for (const tier of rule.tiers) {
        if (count >= tier.count) {
          awards.push({ award_key: `${base}|tier:${tier.count}`, points: tier.points });
        }
      }
      const next = rule.tiers.find((t) => count < t.count) || null;
      progress.current = count;
      progress.target = next ? next.count : (rule.tiers.length ? rule.tiers[rule.tiers.length - 1].count : null);
      progress.tiers = rule.tiers.map((t) => ({ ...t, done: count >= t.count }));
      break;
    }
    case 'daily': {
      const counts = countByDay(mine);
      let days = settings.eventDays.filter((d) => (counts[d] || 0) >= rule.required);
      if (rule.maxAwards !== null) days = days.slice(0, rule.maxAwards);
      for (const day of days) {
        awards.push({ award_key: `${base}|day:${day}`, points: rule.points, event_day: day });
      }
      progress.current = days.length;
      progress.target = settings.eventDays.length;
      progress.days = settings.eventDays.map((d) => ({ date: d, done: days.includes(d) }));
      break;
    }
    case 'all_days': {
      const counts = countByDay(mine);
      const done = settings.eventDays.filter((d) => (counts[d] || 0) >= rule.required);
      if (settings.eventDays.length > 0 && done.length === settings.eventDays.length) {
        awards.push({ award_key: `${base}|all_days`, points: rule.points });
      }
      progress.current = done.length;
      progress.target = settings.eventDays.length;
      progress.days = settings.eventDays.map((d) => ({ date: d, done: done.includes(d) }));
      break;
    }
    case 'once':
    case 'quest':
    default: {
      const count = distinctKeys(rule, mine, settings).length;
      if (count >= rule.required) {
        awards.push({ award_key: `${base}`, points: rule.points });
      }
      progress.current = Math.min(count, rule.required);
      progress.target = rule.required;
      break;
    }
  }

  return { awards, progress };
}

/** Most points the rule can ever pay out — shown on the card. */
function maxPoints(rule, settings) {
  switch (rule.type) {
    case 'each':
      return rule.maxAwards === null ? rule.points : rule.points * rule.maxAwards;
    case 'distinct_tiers':
      return rule.tiers.reduce((sum, t) => sum + t.points, 0);
    case 'daily': {
      const days = settings.eventDays.length;
      return rule.points * (rule.maxAwards === null ? days : Math.min(days, rule.maxAwards));
    }
    default:
      return rule.points;
  }
}

function prepareLogs(rawLogs, extra, offset) {
  const byId = new Map();
  for (const log of [...asList(rawLogs), ...asList(extra)]) {
    if (!log || !log.action) continue;
    const id = String(log.client_event_id || log.id);
    if (byId.has(id)) continue;
    const t = toTime(log.occurred_at) ?? toTime(log.date_created);
    byId.set(id, { ...log, _t: t, _day: t === null ? null : localDay(t, offset) });
  }
  // Oldest first, so `each` caps keep the earliest targets.
  return [...byId.values()].sort((a, b) => (a._t || 0) - (b._t || 0));
}

function award(data, settings, rules) {
  const payload = data.$trigger.payload || {};
  const userId = payload.user_id;
  if (userId === null || userId === undefined || userId === '') {
    return { mode: 'award', rows: [], reason: 'no user' };
  }
  if (settings.excluded.includes(String(userId))) {
    return { mode: 'award', rows: [], reason: 'excluded' };
  }

  // The log that fired the hook is normally in `logs` already (action hooks run
  // after commit), but it is merged in too in case the read raced the insert.
  const logs = prepareLogs(data.logs, payload, settings.offset);
  const have = new Set(asList(data.ledger).map((r) => r.award_key));
  const sourceLog = data.$trigger.key || null;

  const rows = [];
  for (const rule of rules) {
    for (const a of evaluate(rule, userId, logs, settings).awards) {
      if (have.has(a.award_key)) continue;
      have.add(a.award_key);
      rows.push({
        user_id: userId,
        rule_id: rule.id,
        points: a.points,
        award_key: a.award_key,
        event_day: a.event_day || localDay(Date.now(), settings.offset),
        source_log: sourceLog,
      });
    }
  }
  return { mode: 'award', rows };
}

function progress(data, settings, rules) {
  const query = (data.$trigger && data.$trigger.query) || {};
  const userId = query.user_id;
  if (!userId) return { mode: 'progress', error: 'user_id is required' };

  const logs = prepareLogs(data.logs, null, settings.offset);
  const ledger = asList(data.ledger);
  const earnedByKey = new Map(ledger.map((r) => [r.award_key, toInt(r.points, 0)]));
  const total = ledger.reduce((sum, r) => sum + toInt(r.points, 0), 0);

  const now = Date.now();
  const out = [];
  for (const rule of rules) {
    const { awards, progress: p } = evaluate(rule, userId, logs, settings);
    // Earned = what is really in the ledger, not what evaluate() thinks — an
    // award still in flight shows up on the next refresh.
    const earned = awards.reduce((sum, a) => sum + (earnedByKey.get(a.award_key) || 0), 0);
    const max = maxPoints(rule, settings);
    const r = rule.raw;
    const upcoming = rule.activeFrom !== null && now < rule.activeFrom;
    const expired = rule.activeTo !== null && now > rule.activeTo;
    const complete = max > 0 ? earned >= max : awards.length > 0;
    // Hidden rules stay secret until earned.
    if (r.hidden && earned === 0) continue;
    out.push({
      id: rule.id,
      name: r.action_name || '',
      description: r.action_description || '',
      icon: r.action_url || null,
      screen: r.screen_name || null,
      category: r.category || 'challenge',
      type: rule.type,
      points: rule.points,
      max_points: max,
      earned,
      complete,
      active_from: r.active_from || null,
      active_to: r.active_to || null,
      upcoming,
      expired,
      ...p,
    });
  }

  let rank = null;
  const totals = asList(data.totals)
    .map((row) => ({
      user: String(row.user_id),
      points: toInt(row.sum && typeof row.sum === 'object' ? row.sum.points : row.sum, 0),
    }))
    .filter((row) => !settings.excluded.includes(row.user));
  if (totals.length && total > 0) {
    rank = 1 + totals.filter((row) => row.points > total).length;
  }

  return {
    mode: 'progress',
    user_id: userId,
    total,
    rank,
    players: totals.length,
    event_days: settings.eventDays,
    today: localDay(now, settings.offset),
    rules: out,
  };
}

module.exports = async function (data) {
  const settings = normaliseSettings(data.settings);
  const rules = asList(data.rules)
    .filter((r) => r && r.trigger_action)
    .map(normaliseRule);

  if (data.$trigger && data.$trigger.payload) return award(data, settings, rules);
  return progress(data, settings, rules);
};

// Exposed for tool/directus_flows/test_gamification.mjs. Directus ignores it.
module.exports._internal = { evaluate, normaliseRule, normaliseSettings, prepareLogs, localDay };
