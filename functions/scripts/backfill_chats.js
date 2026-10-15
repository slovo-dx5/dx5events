/**
 * One-off: create chats/{chatId} summaries for conversations that predate
 * the onChatMessageCreated trigger, so the new inbox shows old threads.
 *
 *   cd functions
 *   gcloud auth application-default login
 *   node scripts/backfill_chats.js            # dry run (default): prints only
 *   node scripts/backfill_chats.js --apply    # writes missing chats/{id}
 *
 * Existing chats/{id} docs are never touched; writes use create(), so a
 * summary the trigger made in the meantime wins.
 *
 * messages/{chatId} parents usually don't exist as documents (the app only
 * writes the subcollection), so listDocuments() is used — it returns refs for
 * missing parents too.
 */

const {initializeApp, applicationDefault} = require("firebase-admin/app");
const {getFirestore, FieldPath, Timestamp} =
  require("firebase-admin/firestore");
const {_test: chat} = require("../chat_messages");

const PROJECT_ID = "dx5ve-events";
const LAST_MESSAGE_MAX = 200;

const args = new Set(process.argv.slice(2));
const APPLY = args.has("--apply");

initializeApp({credential: applicationDefault(), projectId: PROJECT_ID});
const db = getFirestore();

const userNameCache = new Map();
async function userName(uid) {
  if (!userNameCache.has(uid)) {
    const snap = await db.doc(`users/${uid}`).get();
    userNameCache.set(uid, snap.exists ? chat.userDisplayName(snap.data()) : "");
  }
  return userNameCache.get(uid);
}

/** Newest message by timestamp; falls back to doc id (epoch millis). */
async function newestMessage(thread) {
  let q = await thread.orderBy("timestamp", "desc").limit(1).get();
  if (q.empty) {
    q = await thread.orderBy(FieldPath.documentId(), "desc").limit(1).get();
  }
  return q.empty ? null : q.docs[0];
}

/** unread[id] = messages addressed to id still marked isread == false. */
async function unreadCounts(thread, participants) {
  const counts = Object.fromEntries(participants.map((id) => [id, 0]));
  const snap = await thread.where("isread", "==", false).select("idTo").get();
  for (const d of snap.docs) {
    const to = chat.cleanId(d.get("idTo"));
    if (to in counts) counts[to]++;
  }
  return counts;
}

/** Builds the summary, or returns null with a reason to skip. */
async function buildSummary(chatId, thread) {
  const newest = await newestMessage(thread);
  if (!newest) return {skip: "no messages"};
  const msg = newest.data();

  const participants = [...new Set([
    ...chatId.split("-").map(chat.cleanId),
    chat.cleanId(msg.idFrom),
    chat.cleanId(msg.idTo),
  ].filter(Boolean))];
  if (participants.length !== 2) {
    return {skip: `unexpected participants ${JSON.stringify(participants)}`};
  }

  // Names: from the newest message where it names someone, else users docs.
  const names = {};
  const from = chat.cleanId(msg.idFrom);
  const to = chat.cleanId(msg.idTo);
  if (from && chat.cleanName(msg.sentFrom)) names[from] = chat.cleanName(msg.sentFrom);
  if (to && chat.cleanName(msg.sentTo)) names[to] = chat.cleanName(msg.sentTo);
  for (const id of participants) {
    if (!names[id]) {
      const n = await userName(id);
      if (n) names[id] = n;
    }
  }

  const photos = {};
  if (from && chat.cleanName(msg.fromPhoto)) photos[from] = chat.cleanName(msg.fromPhoto);

  const atMs = chat.toMillis(msg.timestamp, Number(newest.id) || Date.now());
  const at = Timestamp.fromMillis(atMs);
  const type = Number.isInteger(msg.type) ? msg.type : Number(msg.type) || 0;

  return {
    summary: {
      participants,
      names,
      photos,
      lastMessage: {
        text: chat.truncate(msg.content, LAST_MESSAGE_MAX),
        from: from || participants[0],
        type,
        at,
      },
      updatedAt: at,
      unread: await unreadCounts(thread, participants),
      recentIds: [newest.id],
    },
  };
}

async function main() {
  console.log(`backfill_chats: ${APPLY ? "APPLY" : "DRY RUN"} on ${PROJECT_ID}`);
  const parents = await db.collection("messages").listDocuments();
  console.log(`found ${parents.length} message threads`);

  const stats = {created: 0, wouldCreate: 0, exists: 0, skipped: 0, failed: 0};
  for (const parent of parents) {
    const chatId = parent.id;
    try {
      const chatRef = db.doc(`chats/${chatId}`);
      if ((await chatRef.get()).exists) {
        stats.exists++;
        continue;
      }
      const result = await buildSummary(chatId, parent.collection(chatId));
      if (result.skip) {
        stats.skipped++;
        console.log(`skip ${chatId}: ${result.skip}`);
        continue;
      }
      const s = result.summary;
      console.log(`${APPLY ? "create" : "would create"} chats/${chatId}`,
          JSON.stringify({names: s.names, unread: s.unread,
            last: s.lastMessage.text.slice(0, 40),
            at: s.updatedAt.toDate().toISOString()}));
      if (!APPLY) {
        stats.wouldCreate++;
        continue;
      }
      try {
        await chatRef.create(s);
        stats.created++;
      } catch (err) {
        if (err.code !== 6) throw err; // 6 = ALREADY_EXISTS: trigger got there first
        stats.exists++;
      }
    } catch (err) {
      stats.failed++;
      console.error(`failed ${chatId}: ${err.message || err}`);
    }
  }
  console.log("done", JSON.stringify(stats));
  if (!APPLY) console.log("dry run only; re-run with --apply to write.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
