// Run: node tool/directus_flows/test_gamification.mjs
// Exercises the gamification Run Scripts with hand-built `data` bags, the way
// Directus calls them. Run after editing any gamification_*.js file.
import { createRequire } from 'node:module';
import test from 'node:test';
import assert from 'node:assert/strict';

const require = createRequire(import.meta.url);
const engine = require('./gamification_engine.js');
const board = require('./gamification_leaderboard.js');
const mirror = require('./gamification_mirror.js');
const shop = require('./gamification_shop.js');

const DAYS = ['2026-11-03', '2026-11-04', '2026-11-05'];
const settings = [{ utc_offset_minutes: 180, event_days: DAYS, excluded_user_ids: ['999'] }];

let seq = 0;
// `at` is Nairobi local time; converted to UTC like the app sends it.
function log(action, at, extra = {}) {
  seq += 1;
  const utc = new Date(Date.parse(`${at}:00+03:00`)).toISOString();
  return { id: seq, client_event_id: `c${seq}`, user_id: 7, action, occurred_at: utc, ...extra };
}

function awardRun(rules, logs, ledger = [], trigger = logs[logs.length - 1]) {
  return engine({ $trigger: { payload: trigger, key: trigger.id }, rules, settings, logs, ledger });
}

const networker = {
  id: 1, trigger_action: 'contact_scanned', rule_type: 'distinct_tiers', distinct_by: 'target_id',
  tiers: [{ count: 5, points: 50 }, { count: 15, points: 100 }], status: 'published',
};

test('distinct tiers count unique targets only', async () => {
  const logs = [1, 2, 3, 4, 4, 4].map((t) => log('contact_scanned', '2026-11-03T10:00', { target_id: String(t) }));
  assert.equal((await awardRun([networker], logs)).rows.length, 0);
  logs.push(log('contact_scanned', '2026-11-03T11:00', { target_id: '5' }));
  const res = await awardRun([networker], logs);
  assert.equal(res.rows.length, 1);
  assert.equal(res.rows[0].award_key, 'rule:1|user:7|tier:5');
  assert.equal(res.rows[0].points, 50);
});

test('awards already in the ledger are not repeated', async () => {
  const logs = [1, 2, 3, 4, 5, 6].map((t) => log('contact_scanned', '2026-11-03T10:00', { target_id: String(t) }));
  const res = await awardRun([networker], logs, [{ award_key: 'rule:1|user:7|tier:5', points: 50 }]);
  assert.equal(res.rows.length, 0);
});

test('daily uses the event-local day and only event days', async () => {
  const rule = { id: 2, trigger_action: 'app_open', rule_type: 'daily', action_points: 10 };
  const logs = [
    log('app_open', '2026-11-02T12:00'), // before the event
    log('app_open', '2026-11-03T00:30'), // 21:30 UTC on the 2nd, but day 1 locally
    log('app_open', '2026-11-03T18:00'), // same day again
    log('app_open', '2026-11-05T09:00'),
  ];
  const res = await awardRun([rule], logs);
  assert.deepEqual(res.rows.map((r) => r.event_day), ['2026-11-03', '2026-11-05']);
  assert.ok(res.rows.every((r) => r.points === 10));
});

test('all_days needs every event day', async () => {
  const rule = { id: 3, trigger_action: 'app_open', rule_type: 'all_days', action_points: 30 };
  const two = [log('app_open', '2026-11-03T09:00'), log('app_open', '2026-11-04T09:00')];
  assert.equal((await awardRun([rule], two)).rows.length, 0);
  const three = [...two, log('app_open', '2026-11-05T09:00')];
  const res = await awardRun([rule], three);
  assert.equal(res.rows.length, 1);
  assert.equal(res.rows[0].award_key, 'rule:3|user:7|all_days');
});

test('each caps at max_awards and keeps the earliest targets', async () => {
  const rule = { id: 4, trigger_action: 'meeting_request_sent', rule_type: 'each', distinct_by: 'target_id', action_points: 5, max_awards: 2 };
  const logs = ['a', 'b', 'c'].map((t, i) => log('meeting_request_sent', `2026-11-03T1${i}:00`, { target_id: t }));
  const res = await awardRun([rule], logs);
  assert.deepEqual(res.rows.map((r) => r.award_key), ['rule:4|user:7|key:a', 'rule:4|user:7|key:b']);
});

test('quest only counts logs inside its window', async () => {
  const rule = {
    id: 5, trigger_action: 'sponsor_booth_scan', rule_type: 'quest', distinct_by: 'target_id',
    required_occurrence: 2, action_points: 40,
    active_from: '2026-11-03T06:00:00Z', active_to: '2026-11-03T09:00:00Z', // 09:00–12:00 Nairobi
  };
  const late = [log('sponsor_booth_scan', '2026-11-03T11:00', { target_id: 's1' }), log('sponsor_booth_scan', '2026-11-03T13:00', { target_id: 's2' })];
  assert.equal((await awardRun([rule], late)).rows.length, 0);
  const inTime = [...late, log('sponsor_booth_scan', '2026-11-03T11:30', { target_id: 's3' })];
  assert.equal((await awardRun([rule], inTime)).rows.length, 1);
});

test('match and metadata distinct_by', async () => {
  const keynote = { id: 6, trigger_action: 'session_rated', rule_type: 'once', match: { target_id: 'keynote' }, action_points: 50 };
  const spotter = { id: 7, trigger_action: 'session_rated', rule_type: 'once', distinct_by: 'metadata.speaker', required_occurrence: 2, action_points: 60 };
  const logs = [
    log('session_rated', '2026-11-04T10:00', { target_id: 'panel', metadata: { speaker: 'A' } }),
    log('session_rated', '2026-11-04T11:00', { target_id: 'other', metadata: JSON.stringify({ speaker: 'A' }) }),
  ];
  assert.equal((await awardRun([keynote, spotter], logs)).rows.length, 0);
  logs.push(log('session_rated', '2026-11-04T12:00', { target_id: 'keynote', metadata: { speaker: 'B' } }));
  const res = await awardRun([keynote, spotter], logs);
  assert.deepEqual(res.rows.map((r) => r.rule_id).sort(), [6, 7]);
});

test('match lists are any-of; own badge never counts', async () => {
  const entrance = { id: 10, trigger_action: 'hunt_code_found', rule_type: 'daily', match: { target_id: ['door-a', 'door-b'] }, action_points: 20 };
  const logs = [
    log('hunt_code_found', '2026-11-03T08:00', { target_id: 'door-a' }),
    log('hunt_code_found', '2026-11-04T08:00', { target_id: 'coffee' }),
    log('hunt_code_found', '2026-11-05T08:00', { target_id: 'door-b' }),
  ];
  assert.equal((await awardRun([entrance], logs)).rows.length, 2);
  const self = [1, 2, 3, 4, 7].map((t) => log('contact_scanned', '2026-11-03T10:00', { target_type: 'attendee', target_id: String(t) }));
  assert.equal((await awardRun([networker], self)).rows.length, 0);
});

test('triggering log is counted even if the read missed it', async () => {
  const rule = { id: 8, trigger_action: 'view_agenda', rule_type: 'once', action_points: 10 };
  const trigger = log('view_agenda', '2026-11-03T08:00');
  const res = await engine({ $trigger: { payload: trigger, key: 1 }, rules: [rule], settings, logs: [], ledger: [] });
  assert.equal(res.rows.length, 1);
});

test('excluded users earn nothing', async () => {
  const rule = { id: 8, trigger_action: 'view_agenda', rule_type: 'once', action_points: 10 };
  const trigger = { ...log('view_agenda', '2026-11-03T08:00'), user_id: 999 };
  const res = await engine({ $trigger: { payload: trigger }, rules: [rule], settings, logs: [trigger], ledger: [] });
  assert.equal(res.rows.length, 0);
});

test('progress mode reports earned, tiers, days and rank; hides secret rules', async () => {
  const daily = { id: 2, trigger_action: 'app_open', rule_type: 'daily', action_points: 10, category: 'daily' };
  const secret = { id: 9, trigger_action: 'hunt_code_found', rule_type: 'once', action_points: 25, hidden: true };
  const logs = [
    ...[1, 2, 3, 4, 5, 6].map((t) => log('contact_scanned', '2026-11-03T10:00', { target_id: String(t) })),
    log('app_open', '2026-11-03T09:00'),
  ];
  const ledger = [
    { award_key: 'rule:1|user:7|tier:5', points: 50 },
    { award_key: 'rule:2|user:7|day:2026-11-03', points: 10 },
  ];
  const totals = [
    { user_id: 7, sum: { points: 60 } },
    { user_id: 8, sum: { points: 90 } },
    { user_id: 999, sum: { points: 500 } },
  ];
  const res = await engine({ $trigger: { query: { user_id: '7' } }, rules: [networker, daily, secret], settings, logs, ledger, totals });
  assert.equal(res.mode, 'progress');
  assert.equal(res.total, 60);
  assert.equal(res.rank, 2);
  assert.equal(res.rules.length, 2);
  const net = res.rules.find((r) => r.id === 1);
  assert.equal(net.current, 6);
  assert.equal(net.target, 15);
  assert.equal(net.earned, 50);
  assert.equal(net.max_points, 150);
  assert.deepEqual(net.tiers.map((t) => t.done), [true, false]);
  const d = res.rules.find((r) => r.id === 2);
  assert.deepEqual(d.days.map((x) => x.done), [true, false, false]);
  assert.equal(d.max_points, 30);
});

test('leaderboard ranks ties, filters non-delegates and excluded, returns me', async () => {
  const res = await board({
    $trigger: { query: { user_id: '3', limit: '2' } },
    settings,
    totals: [
      { user_id: 1, sum: { points: 100 } },
      { user_id: 2, sum: { points: 100 } },
      { user_id: 3, sum: { points: 40 } },
      { user_id: 4, sum: { points: 300 } }, // not registered for this event
      { user_id: 999, sum: { points: 900 } }, // staff
    ],
    people: [1, 2, 3, 999].map((id) => ({ attendeeId: id, first_name: `P${id}` })),
  });
  assert.equal(res.players, 3);
  assert.deepEqual(res.entries.map((e) => [e.user_id, e.rank]), [[1, 1], [2, 1]]);
  assert.equal(res.me.rank, 3);
});

test('mirror copies accepted meetings to the requester once', async () => {
  const original = { client_event_id: 'x1', user_id: 5, action: 'meeting_accepted', target_id: 'm1', metadata: { requested_by_id: '9' } };
  const res = await mirror({ $trigger: { payload: original } });
  assert.equal(res.rows.length, 1);
  assert.equal(res.rows[0].user_id, 9);
  assert.equal(res.rows[0].client_event_id, 'x1-mirror');
  const again = await mirror({ $trigger: { payload: res.rows[0] } });
  assert.equal(again.rows.length, 0);
});

test('shop logs completed orders only', async () => {
  const res = await shop({
    order: [
      { id: 'o1', status: 'completed', attendee_id: '7', paid_at: '2026-11-04T08:00:00Z' },
      { id: 'o2', status: 'pending', attendee_id: '7' },
      { id: 'o3', status: 'completed', attendee_id: null },
    ],
  });
  assert.deepEqual(res.rows.map((r) => r.client_event_id), ['shop-order-o1']);
});

test('seed rules all parse and score a busy three-day delegate', async () => {
  const { readFileSync } = await import('node:fs');
  const seed = JSON.parse(readFileSync(new URL('./gamification_seed_rules.json', import.meta.url), 'utf8'))
    .map(({ _note, ...r }, i) => ({
      ...r,
      id: 100 + i,
      active_from: r.active_from?.replace(/^DAY([123])/, (_, n) => DAYS[n - 1]),
      active_to: r.active_to?.replace(/^DAY([123])/, (_, n) => DAYS[n - 1]),
    }));
  const known = new Set(['once', 'quest', 'each', 'distinct_tiers', 'daily', 'all_days']);
  for (const r of seed) {
    assert.ok(known.has(r.rule_type), `${r.action_name}: rule_type ${r.rule_type}`);
    assert.ok(['quick', 'challenge', 'daily'].includes(r.category), `${r.action_name}: category`);
    assert.ok(!JSON.stringify(r).includes('map'), `${r.action_name}: map is not part of CIO100`);
  }
  const logs = [];
  DAYS.forEach((d, i) => {
    logs.push(log('app_open', `${d}T08:00`));
    logs.push(log('hunt_code_found', `${d}T08:05`, { target_id: `entrance-day${i + 1}` }));
    logs.push(log('session_rated', `${d}T10:00`, { target_id: `${d}|k${i}`, metadata: { speaker: `S${i}` } }));
    logs.push(log('social_post_created', `${d}T12:00`, { target_id: `p${i}` }));
    for (let c = 0; c < 6; c++) logs.push(log('contact_scanned', `${d}T11:0${c}`, { target_type: 'attendee', target_id: `${i}${c}` }));
  });
  const ledger = [];
  for (const l of logs) {
    const res = await engine({ $trigger: { payload: l, key: l.id }, rules: seed.filter((r) => r.trigger_action === l.action), settings, logs, ledger });
    ledger.push(...res.rows);
  }
  const total = ledger.reduce((s, r) => s + r.points, 0);
  // Daily 30 + hat-trick 30 + on-site 60 + present 50 + daily review 45 + critic 40
  // + keynote critic 50 + session critic 30 + speaker spotter 60 + first post 20
  // + streak 50 + networker (18 contacts: tiers 5 and 15) 150 = 615
  assert.equal(total, 615);
  assert.equal(new Set(ledger.map((r) => r.award_key)).size, ledger.length);
});
