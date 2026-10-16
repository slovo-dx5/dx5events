/**
 * 1:1 chat fan-out.
 *
 * Every app build (old and new) writes messages to
 *
 *   messages/{chatId}/{chatId}/{messageId}
 *
 * and this trigger does the rest, so clients no longer have to:
 *
 *   chats/{chatId}                      summary doc the new inbox reads
 *                                       (participants, names, photos,
 *                                       lastMessage, updatedAt, unread)
 *   users/{uid}/contacts/{otherUid}     legacy inbox, still read by old builds
 *   FCM push to the recipient           old builds called the legacy FCM HTTP
 *                                       API from the device, which is gone
 *
 * Firestore triggers are at-least-once. The chats/{chatId} update runs in a
 * transaction that also records the message id in `recentIds`; a redelivered
 * event finds its id there, does not increment unread again and sends no
 * second push.
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {getFirestore, FieldValue, Timestamp} =
  require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

const MESSAGE_DOC = "messages/{chatId}/{threadId}/{messageId}";
const LAST_MESSAGE_MAX = 200;
const PUSH_BODY_MAX = 120;
// How many processed message ids the summary remembers for de-duplication.
// Redeliveries arrive within minutes, so a short window is plenty.
const RECENT_IDS_MAX = 20;

const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

// ------------------------------------------------------------ pure helpers

/** Trims to `max` characters without splitting an emoji / surrogate pair. */
function truncate(text, max) {
  const s = String(text == null ? "" : text).trim();
  const chars = Array.from(s);
  if (chars.length <= max) return s;
  return chars.slice(0, max - 1).join("").trimEnd() + "…";
}

/** Ids come in as strings or numbers depending on the build; normalise. */
function cleanId(value) {
  if (value == null) return "";
  return String(value).trim();
}

/** Non-empty trimmed string, or "" — names may be missing, null or "null". */
function cleanName(value) {
  if (value == null) return "";
  const s = String(value).trim();
  return s === "null" || s === "undefined" ? "" : s;
}

/** Display name from a users/{id} doc ("fistname" is the real field name). */
function userDisplayName(user) {
  if (!user) return "";
  return [cleanName(user.fistname), cleanName(user.lastname)]
      .filter(Boolean).join(" ");
}

/**
 * Message timestamp in millis. Normally a resolved server Timestamp, but very
 * old builds wrote epoch millis; fall back to `nowMs` if absent or junk.
 */
function toMillis(value, nowMs) {
  if (value) {
    if (typeof value.toMillis === "function") return value.toMillis();
    if (value instanceof Date) return value.getTime();
    const n = Number(value);
    if (Number.isFinite(n) && n > 0) return n;
  }
  return nowMs;
}

/**
 * Validates a message and pulls out what the fan-out needs. Returns null for
 * messages to ignore (self-chats, missing ids, wrong subcollection).
 */
function parseMessage(params, msg) {
  if (!msg || params.threadId !== params.chatId) return null;
  const from = cleanId(msg.idFrom);
  const to = cleanId(msg.idTo);
  if (!from || !to || from === to) return null;
  const type = Number.isInteger(msg.type) ? msg.type : Number(msg.type) || 0;
  return {
    chatId: params.chatId,
    messageId: params.messageId,
    from,
    to,
    type,
    content: msg.content == null ? "" : String(msg.content),
    fromName: cleanName(msg.sentFrom),
    toName: cleanName(msg.sentTo),
    fromPhoto: cleanName(msg.fromPhoto),
    timestamp: msg.timestamp,
  };
}

/**
 * The set(..., {merge: true}) payload for chats/{chatId}, or null when this
 * message was already applied.
 *
 * `existing` is the current summary doc data (or undefined). `names` holds
 * the best names we found ({from, to}). Names already stored are kept when
 * the new one is empty. lastMessage/updatedAt only move forward, so a late
 * redelivery of an older message cannot rewind the preview.
 */
function buildChatUpdate(m, existing, names, atMs) {
  const prev = existing || {};
  const recent = Array.isArray(prev.recentIds) ? prev.recentIds : [];
  if (recent.includes(m.messageId)) return null;

  const update = {
    unread: {[m.to]: FieldValue.increment(1)},
    recentIds: [...recent, m.messageId].slice(-RECENT_IDS_MAX),
  };
  if (!existing) update.unread[m.from] = 0;
  // Set once (order = who wrote first) so it doesn't flip on every reply;
  // readers query with array-contains, so order is irrelevant to them.
  const known = Array.isArray(prev.participants) ? prev.participants : [];
  if (!known.includes(m.from) || !known.includes(m.to)) {
    update.participants = [m.from, m.to];
  }

  const nameUpdate = {};
  if (names.from) nameUpdate[m.from] = names.from;
  if (names.to) nameUpdate[m.to] = names.to;
  if (Object.keys(nameUpdate).length) update.names = nameUpdate;

  if (m.fromPhoto) update.photos = {[m.from]: m.fromPhoto};

  const prevAt = prev.updatedAt && typeof prev.updatedAt.toMillis === "function" ?
    prev.updatedAt.toMillis() : 0;
  if (atMs >= prevAt) {
    const at = Timestamp.fromMillis(atMs);
    update.lastMessage = {
      text: truncate(m.content, LAST_MESSAGE_MAX),
      from: m.from,
      type: m.type,
      at,
    };
    update.updatedAt = at;
  }
  return update;
}

/**
 * Legacy contacts docs, mirroring what old builds wrote themselves
 * (chat_screen.dart addtocontacts / AddToOtherPersonContacts). Note the odd
 * semantics are deliberate: both docs carry contact_id = receiver and
 * Sent_To/Sent_From from the message's point of view.
 *
 * Returns [{uid, otherUid, create, update}] — `create` is the full doc for a
 * missing contact, `update` the fields refreshed on every message.
 */
function legacyContactDocs(m, names, at) {
  const latest = truncate(m.content, LAST_MESSAGE_MAX);
  const common = {
    contact_id: m.to,
    Sent_To: names.to || "",
    Sent_From: names.from || "",
    chatID: m.chatId,
  };
  const update = {latest_message: latest, added_on: at};
  return [
    {
      uid: m.from,
      otherUid: m.to,
      create: {...common, my_id: m.from, sender_id: m.to, ...update},
      update,
    },
    {
      uid: m.to,
      otherUid: m.from,
      create: {...common, my_id: m.to, sender_id: m.from, ...update},
      update,
    },
  ];
}

/** Body text for the push; non-text types get a generic line. */
function pushBody(m) {
  if (m.type !== 0) return "Sent you an attachment";
  return truncate(m.content, PUSH_BODY_MAX) || "New message";
}

/** FCM message for the recipient. `data` values must all be strings. */
function buildPush(m, token, senderName) {
  const title = senderName || "New message";
  return {
    token,
    notification: {title, body: pushBody(m)},
    data: {
      targetPage: "chat",
      chatWith: m.from,
      chatWithName: senderName || "",
      chatId: m.chatId,
    },
    android: {
      priority: "high",
      notification: {channelId: "chat_messages", tag: m.chatId},
    },
    apns: {
      payload: {aps: {"sound": "default", "thread-id": m.chatId}},
    },
  };
}

// ------------------------------------------------------------- side effects

async function upsertSummary(db, m, names, atMs) {
  const ref = db.doc(`chats/${m.chatId}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const update = buildChatUpdate(m, snap.exists ? snap.data() : undefined,
        names, atMs);
    if (!update) return false;
    tx.set(ref, update, {merge: true});
    return true;
  });
}

async function upsertLegacyContacts(db, m, names, atMs) {
  const at = Timestamp.fromMillis(atMs);
  await Promise.all(legacyContactDocs(m, names, at).map(async (c) => {
    const ref = db.doc(`users/${c.uid}/contacts/${c.otherUid}`);
    try {
      await ref.create(c.create);
    } catch (err) {
      if (err.code !== 6) throw err; // 6 = ALREADY_EXISTS
      await ref.update(c.update);
    }
  }));
}

async function sendPush(db, m, recipient, senderName) {
  const token = recipient && cleanName(recipient.messaging_token);
  if (!token) {
    logger.info("chat push skipped: no token", {chatId: m.chatId, to: m.to});
    return;
  }
  try {
    await getMessaging().send(buildPush(m, token, senderName));
  } catch (err) {
    const code = err && (err.code || (err.errorInfo && err.errorInfo.code));
    if (DEAD_TOKEN_CODES.has(code)) {
      logger.info("chat push: dropping dead token", {to: m.to, code});
      await db.doc(`users/${m.to}`)
          .update({messaging_token: FieldValue.delete()})
          .catch((e) => logger.warn("token delete failed", {err: String(e)}));
      return;
    }
    logger.warn("chat push failed", {chatId: m.chatId, code, err: String(err)});
  }
}

exports.onChatMessageCreated = onDocumentCreated(
    {document: MESSAGE_DOC},
    async (event) => {
      const m = parseMessage(event.params, event.data && event.data.data());
      if (!m) return;

      // Lazily, so requiring this module in tests needs no initializeApp().
      const db = getFirestore();
      const [fromSnap, toSnap] = await Promise.all([
        db.doc(`users/${m.from}`).get(),
        db.doc(`users/${m.to}`).get(),
      ]);
      const recipient = toSnap.exists ? toSnap.data() : null;
      const names = {
        from: m.fromName || userDisplayName(fromSnap.exists && fromSnap.data()),
        to: m.toName || userDisplayName(recipient),
      };
      const atMs = toMillis(m.timestamp, Date.now());

      const fresh = await upsertSummary(db, m, names, atMs);
      if (!fresh) {
        logger.info("chat message already processed",
            {chatId: m.chatId, messageId: m.messageId});
        return;
      }

      // Legacy inbox and push are independent; neither should block the other.
      await Promise.all([
        upsertLegacyContacts(db, m, names, atMs).catch((err) =>
          logger.error("legacy contacts update failed",
              {chatId: m.chatId, err: String(err)})),
        sendPush(db, m, recipient, names.from),
      ]);
    },
);

// Exposed for the local tests.
exports._test = {
  truncate,
  cleanId,
  cleanName,
  userDisplayName,
  toMillis,
  parseMessage,
  buildChatUpdate,
  legacyContactDocs,
  pushBody,
  buildPush,
};
