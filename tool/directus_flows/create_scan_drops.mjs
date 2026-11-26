// Builds "Scan drops": live QR codes switched on/off from Directus.
// Usage: node build_scan_drops.mjs <token-file> <out-json> [count]
import { readFileSync, writeFileSync } from 'node:fs';
import { randomBytes } from 'node:crypto';

const B = 'https://subscriptions.cioafrica.co';
const T = readFileSync(process.argv[2], 'utf8').trim();
const OUT = process.argv[3];
const COUNT = Number(process.argv[4] || 10);

async function api(method, path, body) {
  const res = await fetch(B + path, {
    method,
    headers: { Authorization: `Bearer ${T}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  const json = text ? JSON.parse(text) : {};
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${text.slice(0, 400)}`);
  return json.data;
}

// ── 1. Collection ───────────────────────────────────────────────────────────
const half = (extra = {}) => ({ width: 'half', ...extra });
await api('POST', '/collections', {
  collection: 'scan_drops',
  meta: {
    icon: 'qr_code_2',
    display_template: '{{title}}',
    note: 'Live QR scan drops. Put the drop\'s slide on screen, switch Live on; '
      + 'everyone who scans while it is on gets the points. Switch Live off to close it.',
  },
  schema: {},
  fields: [
    { field: 'id', type: 'integer', meta: { hidden: true, readonly: true, interface: 'input' },
      schema: { is_primary_key: true, has_auto_increment: true } },
    { field: 'title', type: 'string', schema: {},
      meta: half({ interface: 'input', required: true, sort: 1,
        note: 'Delegates see "Live scan: <title>" on Rewards while it is live.' }) },
    { field: 'live', type: 'boolean', schema: { default_value: false },
      meta: half({ interface: 'boolean', display: 'boolean', sort: 2,
        options: { label: 'Live — code pays now' },
        note: 'ON opens the code. OFF closes it; later scans get nothing.' }) },
    { field: 'points', type: 'integer', schema: { default_value: 50 },
      meta: half({ interface: 'input', sort: 3, note: 'Points per delegate. Set before switching on.' }) },
    { field: 'auto_stop_minutes', type: 'integer', schema: {},
      meta: half({ interface: 'input', sort: 4,
        note: 'Optional safety net: switches itself off after this many minutes (checked every minute).' }) },
    { field: 'slide', type: 'string', schema: {},
      meta: half({ interface: 'input', readonly: true, sort: 5, note: 'The slide to show for this drop.' }) },
    { field: 'code', type: 'string', schema: {},
      meta: half({ interface: 'input', readonly: true, sort: 6, note: 'What the QR code contains.' }) },
    { field: 'started_at', type: 'timestamp', schema: {},
      meta: half({ interface: 'datetime', display: 'datetime', readonly: true, sort: 7 }) },
    { field: 'ended_at', type: 'timestamp', schema: {},
      meta: half({ interface: 'datetime', display: 'datetime', readonly: true, sort: 8 }) },
    { field: 'rule_id', type: 'integer', schema: {},
      meta: half({ interface: 'input', readonly: true, sort: 9, note: 'point_actions rule this drop controls.' }) },
  ],
});
console.log('collection scan_drops created');

// ── 2. Drops + their (draft) rules ──────────────────────────────────────────
const drops = [];
for (let n = 1; n <= COUNT; n++) {
  const code = `drop-${String(n).padStart(2, '0')}-${randomBytes(3).toString('hex')}`;
  const rule = await api('POST', '/items/point_actions', {
    action_name: `Live scan: Scan drop ${n}`,
    action_description: 'A QR code is on the screens right now. Scan it with QR Scanner on the Home screen before it disappears.',
    action_points: 50,
    trigger_action: 'hunt_code_found',
    rule_type: 'once',
    match: { target_id: [code] },
    category: 'daily',
    sort: 70 + n,
    status: 'draft', // draft = never awards, never shown; the toggle flow publishes it
    hidden: false,
    screen_name: 'scanner',
  });
  const slide = `scan_drop_${String(n).padStart(2, '0')}.png`;
  const drop = await api('POST', '/items/scan_drops', {
    title: `Scan drop ${n}`, points: 50, live: false, code, slide, rule_id: rule.id,
  });
  drops.push({ n, drop_id: drop.id, rule_id: rule.id, code, slide });
  console.log('drop', n, drop.id, 'rule', rule.id, code);
}
writeFileSync(OUT, JSON.stringify(drops, null, 1));

// ── 3. Flows ────────────────────────────────────────────────────────────────
async function flow(def, ops) {
  // ops: [{key, type, options}] in order; each resolves to the next.
  const f = await api('POST', '/flows', { status: 'active', accountability: null, ...def });
  let next = null;
  for (let i = ops.length - 1; i >= 0; i--) {
    const o = await api('POST', '/operations', {
      flow: f.id, name: ops[i].key, key: ops[i].key, type: ops[i].type, options: ops[i].options,
      position_x: 19 + i * 18, position_y: 1, resolve: next,
    });
    next = o.id;
  }
  await api('PATCH', `/flows/${f.id}`, { operation: next });
  return f.id;
}

const togglePlan = `module.exports = async function (data) {
  const d = Array.isArray(data.drop) ? data.drop[0] : data.drop;
  if (!d || !d.rule_id) throw new Error('scan drop has no rule_id');
  const live = data.$trigger.payload.live === true || data.$trigger.payload.live === 'true';
  const now = new Date().toISOString();
  if (live) {
    return {
      rule_id: d.rule_id,
      drop_id: d.id,
      rule: {
        status: 'published', hidden: false, active_from: now, active_to: null,
        action_points: Number(d.points) > 0 ? Number(d.points) : 50,
        action_name: 'Live scan: ' + (d.title || 'Scan drop'),
        action_description: 'A QR code is on the screens right now. Scan it with QR Scanner on the Home screen before it disappears.',
      },
      drop: { started_at: now, ended_at: null },
    };
  }
  // Closed: no new scans count; only people who earned it still see the card.
  return { rule_id: d.rule_id, drop_id: d.id, rule: { active_to: now, hidden: true }, drop: { ended_at: now } };
};`;

const toggleId = await flow(
  {
    name: 'Scan drops — Live toggle', icon: 'qr_code_2', color: '#E35169', trigger: 'event',
    description: 'Opens/closes a scan drop\'s points rule when its Live toggle changes.',
    options: { type: 'action', scope: ['items.update'], collections: ['scan_drops'] },
  },
  [
    { key: 'live_changed', type: 'condition',
      options: { filter: { $trigger: { payload: { live: { _nnull: true } } } } } },
    { key: 'drop', type: 'item-read',
      options: { collection: 'scan_drops', permissions: '$full', key: '{{$trigger.keys}}',
        query: { fields: ['id', 'title', 'points', 'rule_id'] } } },
    { key: 'plan', type: 'exec', options: { code: togglePlan } },
    { key: 'rule', type: 'item-update',
      options: { collection: 'point_actions', permissions: '$full', emitEvents: false,
        key: '{{plan.rule_id}}', payload: '{{plan.rule}}' } },
    { key: 'stamp', type: 'item-update',
      options: { collection: 'scan_drops', permissions: '$full', emitEvents: false,
        key: '{{plan.drop_id}}', payload: '{{plan.drop}}' } },
  ],
);
console.log('toggle flow', toggleId);

const stopPlan = `module.exports = async function (data) {
  const rows = Array.isArray(data.live_drops) ? data.live_drops : (data.live_drops ? [data.live_drops] : []);
  const t = Date.now();
  const due = rows.filter((r) => r.started_at && Number(r.auto_stop_minutes) > 0
    && Date.parse(r.started_at) + Number(r.auto_stop_minutes) * 60000 <= t && r.rule_id);
  const now = new Date(t).toISOString();
  return {
    any: due.length > 0,
    drop_ids: due.map((r) => r.id),
    rule_ids: due.map((r) => r.rule_id),
    rule: { active_to: now, hidden: true },
    drop: { live: false, ended_at: now },
  };
};`;

const stopId = await flow(
  {
    name: 'Scan drops — Auto stop', icon: 'timer_off', color: '#E35169', trigger: 'schedule',
    description: 'Every minute: closes live scan drops whose auto_stop_minutes has run out.',
    options: { cron: '*/1 * * * *' },
  },
  [
    { key: 'live_drops', type: 'item-read',
      options: { collection: 'scan_drops', permissions: '$full',
        query: { filter: { live: { _eq: true }, auto_stop_minutes: { _nnull: true } },
          fields: ['id', 'started_at', 'auto_stop_minutes', 'rule_id'], limit: -1 } } },
    { key: 'plan', type: 'exec', options: { code: stopPlan } },
    { key: 'has_due', type: 'condition', options: { filter: { plan: { any: { _eq: true } } } } },
    { key: 'close_rules', type: 'item-update',
      options: { collection: 'point_actions', permissions: '$full', emitEvents: false,
        key: '{{plan.rule_ids}}', payload: '{{plan.rule}}' } },
    { key: 'close_drops', type: 'item-update',
      options: { collection: 'scan_drops', permissions: '$full', emitEvents: false,
        key: '{{plan.drop_ids}}', payload: '{{plan.drop}}' } },
  ],
);
console.log('auto-stop flow', stopId);
