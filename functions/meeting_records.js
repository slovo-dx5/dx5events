/**
 * Meeting records: a row in Directus for every accepted meeting.
 *
 * Meetings live in Firestore (users/{uid}/meetings/{meetingId}, one copy per
 * person) and leave nothing behind once someone deletes them. For analytics and
 * the concierge desk, each accepted meeting is copied to the Directus
 * collection `meeting_records` (created by tool/create_meeting_records.mjs),
 * keyed by meeting id:
 *
 *   isAccepted false → true        → create the row (status "accepted") with
 *                                    name, email, company and role of BOTH
 *                                    people, taken from event_registrations at
 *                                    that moment (the meeting doc only carries
 *                                    the requester's company and no roles)
 *   accepted copy deleted          → status "cancelled", cancelled_at
 *   meeting_concierge_status write → concierge_handled / _by / _at
 *
 * Like the emails, only the invitee's copy (`wants_to_meet_with_id == uid`) is
 * acted on. It is also the only copy that keeps the original date_requested
 * and emails: accepting rewrites the requester's copy from scratch.
 *
 * The meeting id is the primary key, so a retried trigger cannot add a second
 * row (Directus answers RECORD_NOT_UNIQUE, which counts as done).
 *
 * Secret: DIRECTUS_TOKEN (same one leaderboardPrizes uses).
 * Deploy BY NAME ONLY:
 *   firebase deploy --only functions:meetingRecordOnAccept,functions:meetingRecordOnDelete,functions:meetingRecordConcierge
 */

const {onDocumentUpdated, onDocumentDeleted, onDocumentWritten} =
  require("firebase-functions/v2/firestore");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

const directusToken = defineSecret("DIRECTUS_TOKEN");

const DIRECTUS_URL = "https://subscriptions.cioafrica.co";
const COLLECTION = "meeting_records";
const MEETING_DOC = "users/{uid}/meetings/{meetingId}";

// ------------------------------------------------------------ pure helpers

const str = (v) => (v == null ? "" : String(v).trim());

/** Firestore Timestamp | Date | ISO string | null → ISO string | null. */
function iso(v) {
  if (v == null) return null;
  if (typeof v.toDate === "function") return v.toDate().toISOString();
  const d = v instanceof Date ? v : new Date(v);
  return isNaN(d.getTime()) ? null : d.toISOString();
}

const toInt = (v) => {
  const n = Number.parseInt(String(v), 10);
  return Number.isFinite(n) ? n : null;
};

/** Only the invitee's copy of a meeting is acted on. */
const isInviteeCopy = (uid, m) =>
  Boolean(m) && String(m.wants_to_meet_with_id) === String(uid);

/**
 * Picks each attendee's registration, preferring the one for [eventId].
 * Returns Map(attendeeId string → registration row).
 */
function pickRegistrations(rows, eventId) {
  const byId = new Map();
  for (const r of rows || []) {
    if (!r || r.attendeeId == null) continue;
    const key = String(r.attendeeId);
    const prev = byId.get(key);
    const matches = eventId != null && String(r.eventId) === String(eventId);
    const prevMatches = prev && eventId != null &&
      String(prev.eventId) === String(eventId);
    if (!prev || (matches && !prevMatches)) byId.set(key, r);
  }
  return byId;
}

/** A person's fields: registration first, meeting doc as the fallback. */
function person(reg, fallback) {
  const regName = reg ? `${str(reg.first_name)} ${str(reg.last_name)}`.trim() : "";
  return {
    name: regName || str(fallback.name) || null,
    email: str(reg && reg.work_email) || str(fallback.email) || null,
    company: str(reg && reg.company) || str(fallback.company) || null,
    role: str(reg && reg.role) || null,
  };
}

/**
 * The meeting_records row for an accepted meeting.
 * @param {object} m        the invitee's meeting doc
 * @param {string} id       meeting id
 * @param {Map} regs        from pickRegistrations
 * @param {object} opts     {eventId, acceptedAt, source}
 */
function buildRecord(m, id, regs, {eventId = null, acceptedAt = null, source = "trigger"} = {}) {
  const requesterId = toInt(m.requested_by_id);
  const inviteeId = toInt(m.wants_to_meet_with_id);
  const requester = person(regs.get(String(m.requested_by_id)), {
    name: m.requested_by, email: m.requested_by_email, company: m.company,
  });
  const invitee = person(regs.get(String(m.wants_to_meet_with_id)), {
    name: m.wants_to_meet_with, email: m.wants_to_meet_with_email,
  });

  const requestedAt = iso(m.date_requested);
  const accepted = iso(acceptedAt);
  const responseMinutes = requestedAt && accepted ?
    Math.max(0, Math.round((Date.parse(accepted) - Date.parse(requestedAt)) / 60000)) :
    null;

  return {
    meeting_id: String(id),
    event_id: toInt(eventId),
    status: "accepted",
    source,
    requested_at: requestedAt,
    accepted_at: accepted,
    response_minutes: responseMinutes,
    meeting_time: iso(m.meeting_time),
    start_time: str(m.startTime) || null,
    table_slot: str(m.tableSlot) || null,
    message: str(m.message) || null,

    requester_id: requesterId,
    requester_name: requester.name,
    requester_email: requester.email,
    requester_company: requester.company,
    requester_role: requester.role,

    invitee_id: inviteeId,
    invitee_name: invitee.name,
    invitee_email: invitee.email,
    invitee_company: invitee.company,
    invitee_role: invitee.role,
  };
}

// ------------------------------------------------------------- side effects

async function directus(path, {method = "GET", body, token} = {}) {
  const res = await fetch(DIRECTUS_URL + path, {
    method,
    headers: {
      "Authorization": `Bearer ${token || directusToken.value()}`,
      "Content-Type": "application/json",
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  if (!res.ok) {
    const err = new Error(`Directus ${method} ${path.split("?")[0]} → ${res.status} ` +
      text.slice(0, 300));
    err.status = res.status;
    err.notUnique = text.includes("RECORD_NOT_UNIQUE");
    throw err;
  }
  return text ? JSON.parse(text).data : null;
}

const q = (obj) => encodeURIComponent(JSON.stringify(obj));

/** The event the app is running on (app_config.active_event), or null. */
async function activeEventId(token) {
  try {
    const cfg = await directus("/items/app_config?fields=active_event", {token});
    const row = Array.isArray(cfg) ? cfg[0] : cfg;
    const ev = row && row.active_event;
    return toInt(ev && typeof ev === "object" ? ev.id : ev);
  } catch (err) {
    logger.warn("meeting record: app_config unreadable", {err: String(err)});
    return null;
  }
}

async function loadRegistrations(attendeeIds, token) {
  const ids = attendeeIds.map(toInt).filter((v) => v != null);
  if (!ids.length) return [];
  return directus(
      `/items/event_registrations?filter=${q({attendeeId: {_in: ids}})}` +
      "&fields=attendeeId,eventId,first_name,last_name,work_email,company,role" +
      "&sort=-id&limit=50", {token});
}

/** Creates the row; true if created, false if it already existed. */
async function createRecord(record, token) {
  try {
    await directus(`/items/${COLLECTION}`, {method: "POST", body: record, token});
    return true;
  } catch (err) {
    if (err.notUnique) return false;
    throw err;
  }
}

/** Patches a row; quietly does nothing if there is no row for this meeting. */
async function patchRecord(meetingId, patch) {
  try {
    await directus(`/items/${COLLECTION}/${encodeURIComponent(meetingId)}`,
        {method: "PATCH", body: patch});
    return true;
  } catch (err) {
    // Directus answers 403 (not 404) for an id that doesn't exist.
    if (err.status === 403 || err.status === 404) return false;
    throw err;
  }
}

/** eventId: undefined = app_config.active_event; null = leave empty. */
async function recordAccepted(m, meetingId, {acceptedAt, source, token, eventId: given}) {
  const [eventId, rows] = await Promise.all([
    given === undefined ? activeEventId(token) : given,
    loadRegistrations([m.requested_by_id, m.wants_to_meet_with_id], token),
  ]);
  const record = buildRecord(m, meetingId, pickRegistrations(rows, eventId),
      {eventId, acceptedAt, source});
  return createRecord(record, token);
}

// ---------------------------------------------------------------- triggers

exports.meetingRecordOnAccept = onDocumentUpdated(
    {document: MEETING_DOC, secrets: [directusToken]},
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (!isInviteeCopy(event.params.uid, after)) return;
      if (before.isAccepted === true || after.isAccepted !== true) return;
      const created = await recordAccepted(after, event.params.meetingId, {
        acceptedAt: event.time || new Date(),
        source: "trigger",
      });
      logger.info(created ? "meeting record created" : "meeting record already there",
          {meetingId: event.params.meetingId});
    },
);

exports.meetingRecordOnDelete = onDocumentDeleted(
    {document: MEETING_DOC, secrets: [directusToken]},
    async (event) => {
      const m = event.data && event.data.data();
      if (!isInviteeCopy(event.params.uid, m) || m.isAccepted !== true) return;
      const patched = await patchRecord(event.params.meetingId, {
        status: "cancelled",
        cancelled_at: iso(event.time || new Date()),
      });
      if (patched) logger.info("meeting record cancelled", {meetingId: event.params.meetingId});
    },
);

exports.meetingRecordConcierge = onDocumentWritten(
    {document: "meeting_concierge_status/{meetingId}", secrets: [directusToken]},
    async (event) => {
      const after = event.data.after.exists ? event.data.after.data() : null;
      await patchRecord(event.params.meetingId, {
        concierge_handled: Boolean(after && after.handled === true),
        concierge_handled_by: after ? str(after.handledBy) || null : null,
        concierge_handled_at: after ? iso(after.handledAt) : null,
      });
    },
);

// Used by tool/backfill_meeting_records.mjs and the local tests.
exports.recordAccepted = recordAccepted;
exports._test = {buildRecord, pickRegistrations, person, iso, isInviteeCopy};
