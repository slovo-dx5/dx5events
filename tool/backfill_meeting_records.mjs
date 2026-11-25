// Copies meetings that were accepted BEFORE the meetingRecordOnAccept Cloud
// Function went live into Directus `meeting_records` (source = "backfill").
// Rows that already exist are left alone, so it is safe to re-run.
//
// Reads Firestore over REST with the app's public API key (the meetings
// collection is readable that way), and enriches with event_registrations
// exactly like the function does.
//
//   DIRECTUS_TOKEN=<admin static token> node tool/backfill_meeting_records.mjs
//   node tool/backfill_meeting_records.mjs --dry-run   (lists what it would write)
//   ... --since=2026-11-20   only meetings requested on/after that day
//   ... --event=111 | none   event_id to stamp (default: today's
//                            app_config.active_event, which is wrong for
//                            meetings from earlier events — use none for those)
//
// For CIO100 2026:  --since=2026-11-20            (stamped with event 111)
// Older history:    --event=none                  (event_id left empty)

import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const records = require('../functions/meeting_records.js');

const TOKEN = process.env.DIRECTUS_TOKEN;
const dryRun = process.argv.includes('--dry-run');
const sinceArg = process.argv.find((a) => a.startsWith('--since='));
const since = sinceArg ? new Date(sinceArg.slice(8)) : null;
const eventArg = process.argv.find((a) => a.startsWith('--event='));
const eventId = !eventArg ? undefined :
  eventArg.slice(8) === 'none' ? null : Number(eventArg.slice(8));
if (!TOKEN && !dryRun) {
  console.error('DIRECTUS_TOKEN is not set. See the header of this file.');
  process.exit(1);
}

const options = readFileSync(new URL('../lib/firebase_options.dart', import.meta.url), 'utf8');
const API_KEY = process.env.FIREBASE_API_KEY || /apiKey:\s*'([^']+)'/.exec(options)[1];
const PROJECT = /projectId:\s*'([^']+)'/.exec(options)[1];
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

/** Firestore REST value → plain JS. */
function decode(v) {
  if (v == null) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('timestampValue' in v) return new Date(v.timestampValue);
  if ('nullValue' in v) return null;
  if ('mapValue' in v) return Object.fromEntries(
    Object.entries(v.mapValue.fields || {}).map(([k, x]) => [k, decode(x)]));
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(decode);
  return null;
}

const res = await fetch(`${BASE}:runQuery?key=${API_KEY}`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    structuredQuery: {
      // No server-side filter: isAccepted on a collection group needs an index.
      from: [{ collectionId: 'meetings', allDescendants: true }],
    },
  }),
});
if (!res.ok) {
  console.error(`Firestore query failed (HTTP ${res.status}): ${(await res.text()).slice(0, 300)}`);
  process.exit(1);
}

// Keep only the invitee's copy (users/{invitee}/meetings/{id}), one per meeting.
const meetings = new Map();
for (const row of await res.json()) {
  if (!row.document) continue;
  const parts = row.document.name.split('/');
  const uid = parts[parts.length - 3];
  const id = parts[parts.length - 1];
  const m = decode({ mapValue: { fields: row.document.fields } });
  if (m.isAccepted !== true || !records._test.isInviteeCopy(uid, m)) continue;
  if (since && !(m.date_requested >= since)) continue;
  meetings.set(id, m);
}
console.log(`${meetings.size} accepted meeting(s) found in Firestore.`);

let created = 0, existed = 0, failed = 0;
for (const [id, m] of meetings) {
  if (dryRun) {
    const asked = m.date_requested ? m.date_requested.toISOString().slice(0, 10) : '?';
    console.log(`  ${asked}  ${m.requested_by} → ${m.wants_to_meet_with}  ${m.startTime || ''}`);
    continue;
  }
  try {
    const ok = await records.recordAccepted(m, id, { acceptedAt: null, source: 'backfill', token: TOKEN, eventId });
    ok ? created++ : existed++;
  } catch (err) {
    failed++;
    console.error(`  ${id}: ${String(err).slice(0, 200)}`);
  }
}
if (!dryRun) console.log(`Created ${created}, already there ${existed}, failed ${failed}.`);
