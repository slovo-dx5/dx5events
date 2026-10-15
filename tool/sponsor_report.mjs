#!/usr/bin/env node
// App sponsor report: how often each placement was seen and tapped, by how
// many people, plus booth scans and leads.
//
//   DIRECTUS_TOKEN=... node tool/sponsor_report.mjs [--since 2026-10-01] [--csv]
//
// Reads the app's own activity log (app_activity_logs, written by
// lib/services/activity_logger.dart via AppSponsor in
// lib/widgets/app_sponsor.dart) and the booth leads in sponsordata.
// Impressions are logged once per placement per app run, so "views" means app
// sessions that showed it and "people" is distinct signed-in users.

const BASE = process.env.DIRECTUS_URL || 'https://subscriptions.cioafrica.co';
const TOKEN = process.env.DIRECTUS_TOKEN;
const BOOTH_CODE = 'sponsor-mbcom';
const BOOTH_ACTION_ID = 14;

if (!TOKEN) {
  console.error('Set DIRECTUS_TOKEN.');
  process.exit(1);
}

const args = process.argv.slice(2);
const sinceIdx = args.indexOf('--since');
const since = sinceIdx >= 0 ? args[sinceIdx + 1] : null;
const csv = args.includes('--csv');

async function get(path, params) {
  const url = new URL(BASE + path);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  const r = await fetch(url, { headers: { Authorization: `Bearer ${TOKEN}` } });
  if (!r.ok) throw new Error(`${path} -> ${r.status} ${(await r.text()).slice(0, 200)}`);
  return (await r.json()).data;
}

const filter = { target_type: { _eq: 'app_sponsor' } };
if (since) filter.occurred_at = { _gte: since };

const logs = await get('/items/app_activity_logs', {
  filter: JSON.stringify(filter),
  fields: 'action,target_id,user_id,occurred_at',
  limit: '-1',
});

const rows = new Map();
const row = (p) => {
  if (!rows.has(p)) rows.set(p, { views: 0, taps: 0, viewers: new Set(), tappers: new Set() });
  return rows.get(p);
};
let boothScans = 0;
for (const l of logs) {
  if (l.action === 'sponsor_impression') {
    const r = row(l.target_id);
    r.views++;
    if (l.user_id) r.viewers.add(l.user_id);
  } else if (l.action === 'sponsor_tap') {
    const r = row(l.target_id);
    r.taps++;
    if (l.user_id) r.tappers.add(l.user_id);
  } else if (l.action === 'sponsor_booth_scan') {
    boothScans++;
  }
}

const leads = await get('/items/sponsordata', {
  filter: JSON.stringify({ sponsorid: { _eq: BOOTH_CODE } }),
  aggregate: JSON.stringify({ count: '*' }),
}).catch(() => [{ count: '?' }]);
const points = await get('/items/user_points', {
  filter: JSON.stringify({ action_id: { _eq: BOOTH_ACTION_ID } }),
  aggregate: JSON.stringify({ count: '*' }),
}).catch(() => [{ count: '?' }]);

const table = [...rows.entries()]
  .map(([placement, r]) => ({
    placement,
    views: r.views,
    people: r.viewers.size,
    taps: r.taps,
    tappers: r.tappers.size,
    tap_rate: r.views ? `${((r.taps / r.views) * 100).toFixed(1)}%` : '-',
  }))
  .sort((a, b) => b.views - a.views);

if (csv) {
  console.log('placement,views,people,taps,tappers,tap_rate');
  for (const t of table) console.log(Object.values(t).join(','));
} else {
  console.log(`App sponsor report${since ? ` since ${since}` : ''}\n`);
  console.table(table);
  console.log(`\nBooth scans (app):        ${boothScans}`);
  console.log(`Booth leads (sponsordata): ${leads[0]?.count ?? 0}`);
  console.log(`Booth points awarded:      ${points[0]?.count ?? 0}`);
}
