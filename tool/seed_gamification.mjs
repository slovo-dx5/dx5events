#!/usr/bin/env node
// Loads the starter Rewards rules into point_actions and sets the event days.
//
// Run it yourself — it reads the token from the environment and never prints
// it:
//
//   DIRECTUS_TOKEN=<admin static token> node tool/seed_gamification.mjs \
//     --days 2026-11-03,2026-11-04,2026-11-05 [--dry-run]
//
// Optional: DIRECTUS_URL (default https://subscriptions.cioafrica.co)
//
// What it does:
//   1. Replaces DAY1/DAY2/DAY3 in the quest windows with the --days dates.
//   2. Drops the `_note` helper fields (they are not Directus columns).
//   3. Archives the old point_actions rows (no trigger_action — the v1 rules
//      the app used to award client-side).
//   4. Creates the rules from tool/directus_flows/gamification_seed_rules.json,
//      skipping any whose action_name already exists, so re-running is safe.
//   5. Writes event_days into the gamification_settings singleton.
//
// Create the collections and fields first — docs/features/gamification-backend.md.

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const URL_BASE = (process.env.DIRECTUS_URL || 'https://subscriptions.cioafrica.co').replace(/\/$/, '');
const TOKEN = process.env.DIRECTUS_TOKEN;
const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const daysArg = args[args.indexOf('--days') + 1];

if (!TOKEN && !dryRun) {
  console.error('DIRECTUS_TOKEN is not set. See the header of this file.');
  process.exit(2);
}
const days = (args.includes('--days') ? daysArg : '').split(',').map((d) => d.trim()).filter(Boolean);
if (days.length !== 3 || !days.every((d) => /^\d{4}-\d{2}-\d{2}$/.test(d))) {
  console.error('Pass the three event days: --days 2026-11-03,2026-11-04,2026-11-05');
  process.exit(2);
}

const rules = JSON.parse(readFileSync(join(here, 'directus_flows', 'gamification_seed_rules.json'), 'utf8'))
  .map((rule) => {
    const { _note, ...row } = rule;
    for (const key of ['active_from', 'active_to']) {
      if (typeof row[key] === 'string') {
        row[key] = row[key].replace(/^DAY([123])/, (_, n) => days[Number(n) - 1]);
      }
    }
    return row;
  });

async function api(method, path, body) {
  if (dryRun && method !== 'GET') {
    console.log(`[dry-run] ${method} ${path}`, body ? JSON.stringify(body).slice(0, 160) : '');
    return { data: null };
  }
  const res = await fetch(`${URL_BASE}${path}`, {
    method,
    headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${method} ${path} → ${res.status} ${text.slice(0, 300)}`);
  return text ? JSON.parse(text) : {};
}

const existing = dryRun && !TOKEN
  ? []
  : (await api('GET', '/items/point_actions?fields=id,action_name,trigger_action,status&limit=-1')).data || [];

const legacy = existing.filter((r) => !r.trigger_action && r.status !== 'archived').map((r) => r.id);
if (legacy.length) {
  console.log(`Archiving ${legacy.length} v1 rule(s): ${legacy.join(', ')}`);
  await api('PATCH', '/items/point_actions', { keys: legacy, data: { status: 'archived' } });
}

const have = new Set(existing.map((r) => r.action_name));
const fresh = rules.filter((r) => !have.has(r.action_name));
console.log(`Creating ${fresh.length} rule(s); ${rules.length - fresh.length} already present.`);
if (fresh.length) await api('POST', '/items/point_actions', fresh);

await api('PATCH', '/items/gamification_settings', { event_days: days });
console.log(`event_days set to ${days.join(', ')}. Review the rules in Directus before the event.`);
