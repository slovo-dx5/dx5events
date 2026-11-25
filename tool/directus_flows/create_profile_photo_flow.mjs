// Creates the Directus flow "Profile photo — attach to registration".
//
// App builds before the profile_screen.dart fix upload the photo file but never
// set event_registrations.profile_photo, so other delegates only see initials.
// Every upload is logged as app_activity_logs action `profile_photo_updated`
// with target_id = the file id, so this flow finishes the job server-side:
//
//   Event hook (action, items.create, app_activity_logs)
//     is_photo  condition: action = profile_photo_updated, user_id + target_id set
//     config    read app_config (active_event)
//     pick      run script: event id, whatever shape the singleton read returns
//     attach    update event_registrations where attendeeId = user_id and
//               eventId = active event: profile_photo = target_id
//
// Safe alongside fixed builds (they set the same value directly).
// Does nothing if a flow with the same name exists.
//
//   DIRECTUS_TOKEN=<admin static token> node tool/directus_flows/create_profile_photo_flow.mjs

const URL_BASE = (process.env.DIRECTUS_URL || 'https://subscriptions.cioafrica.co').replace(/\/$/, '');
const TOKEN = process.env.DIRECTUS_TOKEN;
const NAME = 'Profile photo — attach to registration';
if (!TOKEN) {
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
  if (!res.ok) throw new Error(`${method} ${path} → ${res.status} ${text.slice(0, 400)}`);
  return text ? JSON.parse(text).data : null;
}

const existing = await api('GET', `/flows?filter[name][_eq]=${encodeURIComponent(NAME)}&fields=id`);
if (existing.length) {
  console.log(`Flow already exists: ${existing[0].id}. Nothing to do.`);
  process.exit(0);
}

const flow = await api('POST', '/flows', {
  name: NAME,
  icon: 'account_circle',
  color: '#2ECDA7',
  description: 'Sets event_registrations.profile_photo from profile_photo_updated activity logs ' +
    '(older app builds upload the file but never attach it).',
  status: 'active',
  trigger: 'event',
  accountability: null, // no run logs: it fires on every activity log
  options: { type: 'action', scope: ['items.create'], collections: ['app_activity_logs'] },
});

const PICK_CODE = `module.exports = async function (data) {
  const c = Array.isArray(data.config) ? data.config[0] : data.config;
  const ev = c && c.active_event;
  const id = ev && typeof ev === 'object' ? ev.id : ev;
  if (id === null || id === undefined || id === '') throw new Error('app_config.active_event is not set');
  return { event_id: id };
};`;

// Created last-to-first so each can point at the next.
const attach = await api('POST', '/operations', {
  flow: flow.id, key: 'attach', name: 'Attach photo', type: 'item-update', position_x: 73, position_y: 1,
  options: {
    collection: 'event_registrations',
    permissions: '$full',
    emitEvents: false,
    payload: { profile_photo: '{{$trigger.payload.target_id}}' },
    query: { filter: {
      attendeeId: { _eq: '{{$trigger.payload.user_id}}' },
      eventId: { _eq: '{{pick.event_id}}' },
    } },
  },
});
const pick = await api('POST', '/operations', {
  flow: flow.id, key: 'pick', name: 'Active event id', type: 'exec', position_x: 55, position_y: 1,
  options: { code: PICK_CODE }, resolve: attach.id,
});
const config = await api('POST', '/operations', {
  flow: flow.id, key: 'config', name: 'Read app_config', type: 'item-read', position_x: 37, position_y: 1,
  options: { collection: 'app_config', permissions: '$full', query: { fields: ['active_event'] } },
  resolve: pick.id,
});
const isPhoto = await api('POST', '/operations', {
  flow: flow.id, key: 'is_photo', name: 'Is a photo upload?', type: 'condition', position_x: 19, position_y: 1,
  options: { filter: { $trigger: { payload: {
    action: { _eq: 'profile_photo_updated' },
    user_id: { _nnull: true },
    target_id: { _nnull: true },
  } } } },
  resolve: config.id,
});
await api('PATCH', `/flows/${flow.id}`, { operation: isPhoto.id });
console.log(`Created flow ${flow.id} (is_photo → config → pick → attach).`);
