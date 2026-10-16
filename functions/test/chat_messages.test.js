// Run with: node --test functions/test/
const test = require("node:test");
const assert = require("node:assert");
const {Timestamp} = require("firebase-admin/firestore");
const {_test: t} = require("../chat_messages");

const params = {chatId: "118-42", threadId: "118-42", messageId: "1700000000000"};
const raw = {
  idFrom: "118", idTo: 42, content: "Hello there", type: 0,
  timestamp: Timestamp.fromMillis(1700000000000), isread: false,
  sentFrom: "Ann Lee", sentTo: "Bob", fromPhoto: "file-abc",
};

/** FieldValue sentinels don't compare structurally; describe them instead. */
function isIncrement(v, n) {
  return v && v.constructor && v.constructor.name.includes("Increment") &&
    (v.operand === n || v._operand === n);
}

test("truncate keeps short text and cuts long text with an ellipsis", () => {
  assert.strictEqual(t.truncate("  hi  ", 10), "hi");
  assert.strictEqual(t.truncate(null, 10), "");
  const out = t.truncate("a".repeat(300), 200);
  assert.strictEqual(Array.from(out).length, 200);
  assert.ok(out.endsWith("…"));
  // Does not split a surrogate pair.
  const emoji = t.truncate("\u{1F600}".repeat(5), 3);
  assert.strictEqual(emoji, "\u{1F600}\u{1F600}…");
});

test("cleanName drops null-ish values", () => {
  assert.strictEqual(t.cleanName(null), "");
  assert.strictEqual(t.cleanName("null"), "");
  assert.strictEqual(t.cleanName(" Ann "), "Ann");
});

test("userDisplayName joins fistname and lastname", () => {
  assert.strictEqual(t.userDisplayName({fistname: "Ann", lastname: "Lee"}), "Ann Lee");
  assert.strictEqual(t.userDisplayName({fistname: "Ann"}), "Ann");
  assert.strictEqual(t.userDisplayName(null), "");
});

test("toMillis handles Timestamp, Date, numbers and junk", () => {
  assert.strictEqual(t.toMillis(Timestamp.fromMillis(5000), 1), 5000);
  assert.strictEqual(t.toMillis(new Date(6000), 1), 6000);
  assert.strictEqual(t.toMillis("7000", 1), 7000);
  assert.strictEqual(t.toMillis(undefined, 99), 99);
  assert.strictEqual(t.toMillis("nope", 99), 99);
});

test("parseMessage ignores wrong thread, self-chats and missing ids", () => {
  assert.strictEqual(t.parseMessage({...params, threadId: "other"}, raw), null);
  assert.strictEqual(t.parseMessage(params, {...raw, idTo: "118"}), null);
  assert.strictEqual(t.parseMessage(params, {...raw, idFrom: ""}), null);
  assert.strictEqual(t.parseMessage(params, null), null);
  const m = t.parseMessage(params, raw);
  assert.strictEqual(m.from, "118");
  assert.strictEqual(m.to, "42");
  assert.strictEqual(m.fromName, "Ann Lee");
  assert.strictEqual(m.fromPhoto, "file-abc");
});

test("buildChatUpdate creates a full summary for a new chat", () => {
  const m = t.parseMessage(params, raw);
  const u = t.buildChatUpdate(m, undefined, {from: "Ann Lee", to: "Bob"}, 1700000000000);
  assert.deepStrictEqual(u.participants, ["118", "42"]);
  assert.deepStrictEqual(u.names, {"118": "Ann Lee", "42": "Bob"});
  assert.deepStrictEqual(u.photos, {"118": "file-abc"});
  assert.strictEqual(u.unread["118"], 0);
  assert.ok(isIncrement(u.unread["42"], 1), "recipient unread incremented");
  assert.strictEqual(u.lastMessage.text, "Hello there");
  assert.strictEqual(u.lastMessage.from, "118");
  assert.strictEqual(u.lastMessage.type, 0);
  assert.strictEqual(u.updatedAt.toMillis(), 1700000000000);
  assert.deepStrictEqual(u.recentIds, ["1700000000000"]);
});

test("buildChatUpdate on an existing chat leaves sender unread and names alone", () => {
  const m = t.parseMessage(params, {...raw, sentFrom: null, sentTo: "", fromPhoto: undefined});
  const existing = {
    participants: ["42", "118"],
    names: {"118": "Ann Lee", "42": "Bob"},
    updatedAt: Timestamp.fromMillis(1600000000000),
    recentIds: ["x"],
  };
  const u = t.buildChatUpdate(m, existing, {from: "", to: ""}, 1700000000000);
  assert.ok(!("118" in u.unread), "sender unread untouched");
  assert.ok(isIncrement(u.unread["42"], 1));
  assert.strictEqual(u.names, undefined, "no empty names written");
  assert.strictEqual(u.photos, undefined);
  assert.strictEqual(u.participants, undefined, "participants not rewritten");
  assert.deepStrictEqual(u.recentIds, ["x", "1700000000000"]);
});

test("buildChatUpdate skips a redelivered message", () => {
  const m = t.parseMessage(params, raw);
  const u = t.buildChatUpdate(m, {recentIds: ["1700000000000"]}, {}, 1);
  assert.strictEqual(u, null);
});

test("buildChatUpdate does not rewind lastMessage for an older message", () => {
  const m = t.parseMessage(params, raw);
  const u = t.buildChatUpdate(m, {updatedAt: Timestamp.fromMillis(2000)}, {}, 1000);
  assert.strictEqual(u.lastMessage, undefined);
  assert.strictEqual(u.updatedAt, undefined);
  assert.ok(isIncrement(u.unread["42"], 1), "still counts as unread");
});

test("buildChatUpdate caps recentIds", () => {
  const m = t.parseMessage(params, raw);
  const recentIds = Array.from({length: 30}, (_, i) => `id${i}`);
  const u = t.buildChatUpdate(m, {recentIds}, {}, 1);
  assert.strictEqual(u.recentIds.length, 20);
  assert.strictEqual(u.recentIds[19], "1700000000000");
});

test("legacyContactDocs mirrors the old client semantics", () => {
  const m = t.parseMessage(params, raw);
  const at = Timestamp.fromMillis(1700000000000);
  const [sender, receiver] = t.legacyContactDocs(m, {from: "Ann Lee", to: "Bob"}, at);
  assert.strictEqual(sender.uid, "118");
  assert.strictEqual(sender.otherUid, "42");
  assert.deepStrictEqual(sender.create, {
    contact_id: "42", Sent_To: "Bob", Sent_From: "Ann Lee", chatID: "118-42",
    my_id: "118", sender_id: "42", latest_message: "Hello there", added_on: at,
  });
  assert.strictEqual(receiver.uid, "42");
  assert.strictEqual(receiver.otherUid, "118");
  assert.deepStrictEqual(receiver.create, {
    contact_id: "42", Sent_To: "Bob", Sent_From: "Ann Lee", chatID: "118-42",
    my_id: "42", sender_id: "118", latest_message: "Hello there", added_on: at,
  });
  assert.deepStrictEqual(receiver.update, {latest_message: "Hello there", added_on: at});
});

test("buildPush builds a high-priority chat notification", () => {
  const m = t.parseMessage(params, {...raw, content: "x".repeat(500)});
  const p = t.buildPush(m, "tok", "Ann Lee");
  assert.strictEqual(p.token, "tok");
  assert.strictEqual(p.notification.title, "Ann Lee");
  assert.strictEqual(Array.from(p.notification.body).length, 120);
  assert.deepStrictEqual(p.data, {
    targetPage: "chat", chatWith: "118", chatWithName: "Ann Lee", chatId: "118-42",
  });
  for (const v of Object.values(p.data)) assert.strictEqual(typeof v, "string");
  assert.deepStrictEqual(p.android, {
    priority: "high", notification: {channelId: "chat_messages", tag: "118-42"},
  });
  assert.deepStrictEqual(p.apns, {payload: {aps: {"sound": "default", "thread-id": "118-42"}}});
});

test("buildPush falls back when name or text is missing", () => {
  const m = t.parseMessage(params, {...raw, content: ""});
  const p = t.buildPush(m, "tok", "");
  assert.strictEqual(p.notification.title, "New message");
  assert.strictEqual(p.notification.body, "New message");
  assert.strictEqual(p.data.chatWithName, "");
  const img = t.parseMessage(params, {...raw, type: 1});
  assert.strictEqual(t.pushBody(img), "Sent you an attachment");
});
