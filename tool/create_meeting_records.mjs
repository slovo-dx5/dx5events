// Creates the Directus collection `meeting_records`: one row per accepted
// meeting, written by the meetingRecord* Cloud Functions
// (functions/meeting_records.js). Admin-only: no public/app role access is
// granted, so the emails in it never reach the APK token's normal reads.
//
// Run it yourself — it reads the token from the environment and never prints
// it. Safe to re-run: does nothing if the collection already exists.
//
//   DIRECTUS_TOKEN=<admin static token> node tool/create_meeting_records.mjs
//   node tool/create_meeting_records.mjs --dry-run     (shows the payload only)

const URL_BASE = (process.env.DIRECTUS_URL || 'https://subscriptions.cioafrica.co').replace(/\/$/, '');
const TOKEN = process.env.DIRECTUS_TOKEN;
const dryRun = process.argv.includes('--dry-run');
const COLLECTION = 'meeting_records';

if (!TOKEN && !dryRun) {
  console.error('DIRECTUS_TOKEN is not set. See the header of this file.');
  process.exit(1);
}

async function api(method, path, body) {
  const res = await fetch(URL_BASE + path, {
    method,
    headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let json = null;
  try { json = text ? JSON.parse(text) : null; } catch { /* not JSON */ }
  return { status: res.status, json, text };
}

const str = (field, note, width = 'half') => ({
  field, type: 'string',
  schema: { is_nullable: true },
  meta: { interface: 'input', width, note, readonly: true },
});
const int = (field, note) => ({
  field, type: 'integer',
  schema: { is_nullable: true },
  meta: { interface: 'input', width: 'half', note, readonly: true },
});
const ts = (field, note) => ({
  field, type: 'timestamp',
  schema: { is_nullable: true },
  meta: { interface: 'datetime', display: 'datetime', width: 'half', note, readonly: true },
});

const fields = [
  {
    field: 'meeting_id', type: 'string',
    schema: { is_primary_key: true, length: 64, has_auto_increment: false },
    meta: { interface: 'input', readonly: true, width: 'half', note: 'Firestore meeting id' },
  },
  int('event_id', 'app_config.active_event when the meeting was accepted'),
  {
    field: 'status', type: 'string',
    schema: { is_nullable: false, default_value: 'accepted' },
    meta: {
      interface: 'select-dropdown', display: 'labels', width: 'half', readonly: true,
      options: { choices: [
        { text: 'Accepted', value: 'accepted' },
        { text: 'Cancelled', value: 'cancelled' },
      ] },
    },
  },
  str('source', 'trigger = live, backfill = tool/backfill_meeting_records.mjs'),
  ts('requested_at', 'When the request was sent'),
  ts('accepted_at', 'When it was accepted (empty for backfilled rows)'),
  int('response_minutes', 'Minutes from request to acceptance'),
  ts('meeting_time', 'When the meeting takes place'),
  str('start_time', 'As shown in the app, e.g. 2:00 PM'),
  str('table_slot', 'Table / slot, if one was chosen'),
  { field: 'message', type: 'text', schema: { is_nullable: true },
    meta: { interface: 'input-multiline', width: 'full', readonly: true, note: 'Request message' } },

  int('requester_id', 'Attendee id of the person who asked'),
  str('requester_name'),
  str('requester_email'),
  str('requester_company'),
  str('requester_role'),

  int('invitee_id', 'Attendee id of the person who accepted'),
  str('invitee_name'),
  str('invitee_email'),
  str('invitee_company'),
  str('invitee_role'),

  ts('cancelled_at', 'Set if the accepted meeting was later deleted'),
  { field: 'concierge_handled', type: 'boolean', schema: { is_nullable: false, default_value: false },
    meta: { interface: 'boolean', width: 'half', readonly: true, note: 'Marked Done on the concierge desk' } },
  str('concierge_handled_by'),
  ts('concierge_handled_at'),
  {
    field: 'date_created', type: 'timestamp', schema: { is_nullable: true },
    meta: { special: ['date-created'], interface: 'datetime', readonly: true, hidden: true, width: 'half' },
  },
];

const payload = {
  collection: COLLECTION,
  meta: {
    icon: 'handshake',
    note: 'Accepted delegate meetings (from Firestore, via Cloud Functions). Read-only.',
    sort_field: null,
    archive_field: null,
    display_template: '{{requester_name}} → {{invitee_name}}',
  },
  schema: {},
  fields,
};

if (dryRun) {
  console.log('Dry run — would POST /collections', JSON.stringify(payload, null, 2));
  process.exit(0);
}

const existing = await api('GET', `/collections/${COLLECTION}`);
if (existing.status === 200) {
  console.log(`${COLLECTION} already exists. Nothing to do.`);
  process.exit(0);
}

const created = await api('POST', '/collections', payload);
if (created.status !== 200) {
  console.error(`Create failed (HTTP ${created.status}): ${created.text.slice(0, 500)}`);
  process.exit(1);
}

const check = await api('GET', `/fields/${COLLECTION}`);
console.log(check.status === 200
  ? `Created ${COLLECTION} with ${check.json.data.length} fields.`
  : `Created, but the read-back returned HTTP ${check.status}.`);
