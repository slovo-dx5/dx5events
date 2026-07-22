/**
 * Gallery photo notifier.
 *
 * The Event Image Service API (assets/mobile-gallery-api.md) is read-only and
 * has no webhook/push, so this scheduled function polls it and turns "a day
 * now has photos" into an FCM push to a per-event topic. The Flutter app
 * subscribes to `gallery_<pixEventId>` (see lib/services/gallery/
 * gallery_notifications.dart) and users receive e.g. "Day 1 photos are now
 * available".
 *
 * State per event lives in Firestore `galleryNotifierState/<pixEventId>` so we
 * only notify on the transition into "has photos", not on every poll.
 */

const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret, defineString} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

initializeApp();
const db = getFirestore();

// The poller's own dedicated pix account (see the guide, §1 — one account per
// consumer, never a real user). Set with:
//   firebase functions:secrets:set PIX_API_EMAIL
//   firebase functions:secrets:set PIX_API_PASSWORD
const pixEmail = defineSecret("PIX_API_EMAIL");
const pixPassword = defineSecret("PIX_API_PASSWORD");
const pixBaseUrl = defineString("PIX_API_BASE_URL", {
  default: "https://api.pix.dx5ve.com",
});

// Don't re-notify "more photos" for the same day more often than this.
const MORE_COOLDOWN_MS = 2 * 60 * 60 * 1000; // 2 hours
// Ignore a day until it has at least this many ready photos (guards against a
// single stray test upload firing a push).
const MIN_PHOTOS = 1;

// Maps a pix event to the app's (Directus) event id, which is what the topic
// is keyed on. The app subscribes to `gallery_<appEventId>` using the id from
// landingPage2.dart (e.g. 107 = Smart Government Summit) with no pix lookup, so
// the pix->app translation lives here. Keyed by normalized pix title or slug.
// Add one entry per event the app should receive photo pushes for.
const APP_EVENT_ID_BY_PIX = {
  "smartgovernmentsummit": "107",
};

function normalize(s) {
  return (s || "").toLowerCase().replace(/[^a-z0-9]/g, "");
}

function appEventIdFor(event) {
  return (
    APP_EVENT_ID_BY_PIX[normalize(event.title)] ||
    APP_EVENT_ID_BY_PIX[normalize(event.slug)] ||
    null
  );
}

// ---------------------------------------------------------------- pix client

async function pixFetch(path, token) {
  const res = await fetch(`${pixBaseUrl.value()}${path}`, {
    headers: {Authorization: `Bearer ${token}`},
  });
  if (!res.ok) {
    throw new Error(`GET ${path} -> ${res.status} ${await res.text()}`);
  }
  return res.json();
}

/**
 * Log in fresh each run. A 10-minute poller doesn't benefit from persisting
 * rotating refresh tokens — a new short-lived access token per invocation is
 * simpler and the login route isn't rate-limited for this account.
 */
async function pixLogin() {
  const res = await fetch(`${pixBaseUrl.value()}/auth/login`, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      email: pixEmail.value(),
      password: pixPassword.value(),
    }),
  });
  if (!res.ok) {
    throw new Error(`login -> ${res.status} ${await res.text()}`);
  }
  const json = await res.json();
  return json.token;
}

// ------------------------------------------------------------------- sending

async function sendGalleryPush(event, appEventId, {day, dayLabel, more}) {
  const title = event.title || "Event photos";
  const body = more ?
    `More ${dayLabel} photos have just been added` :
    `${dayLabel} photos are now available`;

  await getMessaging().send({
    // Keyed on the app event id (e.g. gallery_107), which is what the app
    // subscribes to. pixEventId still rides in the payload for tap-through.
    topic: `gallery_${appEventId}`,
    notification: {title, body},
    data: {
      targetPage: "gallery",
      appEventId: String(appEventId),
      pixEventId: String(event.id),
      day: String(day),
      dayLabel,
    },
    android: {
      priority: "high",
      notification: {channelId: "gallery_notifications"},
    },
    apns: {payload: {aps: {sound: "default"}}},
  });
  logger.info(`sent gallery push`, {appEventId, pixEventId: event.id, day, more});
}

// -------------------------------------------------------------- per-event run

async function processEvent(token, event) {
  // Skip before any Firestore/day work if no app subscribes to this event, so
  // that adding a mapping later starts fresh and seeds silently (no blast).
  const appEventId = appEventIdFor(event);
  if (!appEventId) {
    logger.warn("no app event id mapping; skipping event", {
      pixEventId: event.id,
      title: event.title,
    });
    return;
  }

  // days: [{ day: "YYYY-MM-DD", count }], ascending, ready photos only.
  const days = await pixFetch(`/events/${event.id}/days`, token);
  if (!Array.isArray(days) || days.length === 0) return;

  const ref = db.collection("galleryNotifierState").doc(String(event.id));
  const snap = await ref.get();
  const now = Date.now();

  // First time we ever see this event: seed silently. Without this, deploying
  // mid-event would blast "Day 1..Day N available" for every day that already
  // has photos.
  if (!snap.exists) {
    const seeded = {};
    days.forEach(({day, count}, i) => {
      seeded[day] = {count, dayIndex: i, notifiedAt: 0, seededAt: now};
    });
    await ref.set({days: seeded, updatedAt: now});
    logger.info(`seeded gallery state`, {eventId: event.id, days: days.length});
    return;
  }

  const seen = {...(snap.data().days || {})};
  const toSend = [];

  days.forEach(({day, count}, i) => {
    if (count < MIN_PHOTOS) return;
    const dayLabel = `Day ${i + 1}`;
    const prev = seen[day];

    if (!prev || prev.count < MIN_PHOTOS) {
      // Transition into "has photos" → the main notification.
      toSend.push({day, dayLabel, more: false});
      seen[day] = {count, dayIndex: i, notifiedAt: now};
    } else if (
      count > prev.count &&
      now - (prev.notifiedAt || 0) > MORE_COOLDOWN_MS
    ) {
      // Meaningfully more photos, past the cooldown → a gentle follow-up.
      toSend.push({day, dayLabel, more: true});
      seen[day] = {count, dayIndex: i, notifiedAt: now};
    } else if (count !== prev.count) {
      // Track the new count without notifying (still within cooldown).
      seen[day] = {...prev, count};
    }
  });

  // Send first; only persist notifiedAt for pushes that actually went out, so
  // a transient FCM failure retries next run instead of being silently lost.
  const sent = [];
  for (const item of toSend) {
    try {
      await sendGalleryPush(event, appEventId, item);
      sent.push(item.day);
    } catch (err) {
      logger.error(`gallery push failed`, {eventId: event.id, day: item.day, err: String(err)});
      // Roll this day back to its previous state so we retry next run.
      const prev = snap.data().days ? snap.data().days[item.day] : undefined;
      if (prev) {
        seen[item.day] = prev;
      } else {
        delete seen[item.day];
      }
    }
  }

  await ref.set({days: seen, updatedAt: now}, {merge: false});
  if (sent.length) logger.info(`gallery pushes sent`, {eventId: event.id, days: sent});
}

// --------------------------------------------------------------- entry point

exports.galleryPhotoNotifier = onSchedule(
  {
    schedule: "every 10 minutes",
    timeoutSeconds: 300,
    secrets: [pixEmail, pixPassword],
    // Serialize runs so two overlapping invocations can't double-notify.
    maxInstances: 1,
  },
  async () => {
    const token = await pixLogin();
    const events = await pixFetch("/events", token);
    if (!Array.isArray(events)) {
      logger.warn("GET /events did not return an array");
      return;
    }
    logger.info(`polling ${events.length} event(s) for new photos`);
    for (const event of events) {
      try {
        await processEvent(token, event);
      } catch (err) {
        // One bad event shouldn't stop the rest.
        logger.error(`processEvent failed`, {eventId: event.id, err: String(err)});
      }
    }
  },
);
