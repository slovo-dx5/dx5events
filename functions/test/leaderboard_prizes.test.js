// Run with: node --test functions/test/
const test = require("node:test");
const assert = require("node:assert");
const {_test: t} = require("../leaderboard_prizes");

const people = [
  {attendeeId: 1, first_name: "Ann", last_name: "Lee", work_email: "Ann@X.com"},
  {attendeeId: 2, first_name: "Bob", last_name: "Ng", work_email: "bob@x.com"},
  {attendeeId: 3, first_name: "Cy", last_name: "Oto", work_email: "cy@x.com"},
  {attendeeId: 4, first_name: "Di", last_name: "Pai", work_email: "di@x.com"},
  {attendeeId: 5, first_name: "Ed", last_name: "Qi", work_email: "ed@x.com"},
];
const total = (id, points, at) =>
  ({user_id: id, sum: {points: String(points)}, max: {date_created: at}});
const totals = [
  total(1, 300, "2026-11-27T10:00:00Z"),
  total(2, 500, "2026-11-27T09:00:00Z"),
  total(3, 300, "2026-11-26T08:00:00Z"), // tied with 1, got there earlier
  total(4, 100, "2026-11-25T08:00:00Z"),
  total(5, 900, "2026-11-25T08:00:00Z"), // staff, excluded
  total(99, 800, "2026-11-25T08:00:00Z"), // not registered for this event
  total(6, 0, "2026-11-25T08:00:00Z"),
];
const ranked = () => t.rankPlayers(totals, people, ["5"]);
const PRIZES = [7500, 5000, 3500];

test("ranks by points, ties to whoever reached the score first", () => {
  assert.deepStrictEqual(ranked().map((p) => p.id), ["2", "3", "1", "4"]);
});

test("excluded, unregistered and pointless players never rank", () => {
  const ids = ranked().map((p) => p.id);
  for (const id of ["5", "99", "6"]) assert.ok(!ids.includes(id), id);
});

test("excluded ids may arrive as a JSON string", () => {
  assert.ok(!t.rankPlayers(totals, people, "[5]").some((p) => p.id === "5"));
});

test("prize table defaults, and ignores junk", () => {
  assert.deepStrictEqual(t.prizeTable({}), PRIZES);
  assert.deepStrictEqual(t.prizeTable({prizes: "[1000, \"x\", -5, 200.4]"}), [1000, 200]);
});

test("first run drafts the top three with lowercased emails", () => {
  const plan = t.planDrafts("111", PRIZES, ranked(), []);
  assert.strictEqual(plan.update.length, 0);
  assert.deepStrictEqual(plan.create.map((r) => [r.rank, r.attendee_id, r.amount, r.status]),
      [[1, "2", 7500, "draft"], [2, "3", 5000, "draft"], [3, "1", 3500, "draft"]]);
  assert.strictEqual(plan.create[2].email, "ann@x.com");
  assert.strictEqual(plan.create[2].name, "Ann Lee");
});

test("drafts that already match the board are left alone", () => {
  const rows = t.planDrafts("111", PRIZES, ranked(), []).create
      .map((r, i) => ({...r, id: i + 1}));
  const plan = t.planDrafts("111", PRIZES, ranked(), rows);
  assert.deepStrictEqual(plan, {create: [], update: []});
});

test("before approval, voiding a draft moves everyone below up", () => {
  const rows = t.planDrafts("111", PRIZES, ranked(), []).create
      .map((r, i) => ({...r, id: i + 1}));
  rows[0].status = "void"; // attendee 2 disqualified
  const plan = t.planDrafts("111", PRIZES, ranked(), rows);
  assert.deepStrictEqual(plan.create.map((r) => [r.rank, r.attendee_id]), [[1, "3"]]);
  assert.deepStrictEqual(plan.update.map((u) => [u.id, u.row.rank, u.row.attendee_id]),
      [[2, 2, "1"], [3, 3, "4"]]);
});

test("after approval, a voided rank is refilled by the next person only", () => {
  const rows = [
    {id: 1, rank: 1, attendee_id: "2", status: "approved", points: 500, amount: 7500},
    {id: 2, rank: 2, attendee_id: "3", status: "void", points: 300, amount: 5000},
    {id: 3, rank: 3, attendee_id: "1", status: "active", points: 300, amount: 3500},
  ];
  const plan = t.planDrafts("111", PRIZES, ranked(), rows);
  assert.strictEqual(plan.update.length, 0);
  assert.deepStrictEqual(plan.create.map((r) => [r.rank, r.attendee_id, r.amount]),
      [[2, "4", 5000]]);
});

test("fewer players than prizes drafts only what it can", () => {
  const plan = t.planDrafts("111", PRIZES, ranked().slice(0, 2), []);
  assert.strictEqual(plan.create.length, 2);
});

test("expiry counts from awards close, default 30 days", () => {
  const s = {awards_close_at: "2026-11-27T13:00:00Z"};
  assert.strictEqual(t.expiryFor(s, 0), "2026-12-27T13:00:00.000Z");
  assert.strictEqual(t.expiryFor({...s, prize_expiry_days: 7}, 0),
      "2026-12-04T13:00:00.000Z");
});

test("winner push opens the shop with string-only data", () => {
  const m = t.winnerPush({id: 9, rank: 1, amount: 7500}, "tok", {});
  assert.strictEqual(m.token, "tok");
  assert.strictEqual(m.data.targetPage, "shop");
  assert.ok(Object.values(m.data).every((v) => typeof v === "string"));
  assert.match(m.notification.body, /1st/);
  assert.match(m.notification.body, /KES 7,500/);
  assert.match(m.notification.title, /CIO100/);
});

test("winner email escapes the name and states the prize and expiry", () => {
  const e = t.winnerEmail({rank: 2, amount: 5000, points: 300, email: "a@b.c",
    name: "<b>Ann</b> Lee"}, {}, "2026-12-27T13:00:00Z");
  assert.strictEqual(e.emailAddress, "a@b.c");
  assert.ok(!e.body.includes("<b>Ann</b>"));
  assert.match(e.body, /KES 5,000/);
  assert.match(e.body, /2nd/);
  assert.match(e.body, /27 Dec 2026/);
});

test("ordinals", () => {
  assert.deepStrictEqual([1, 2, 3, 4, 11, 12, 13, 21, 22].map(t.ordinal),
      ["1st", "2nd", "3rd", "4th", "11th", "12th", "13th", "21st", "22nd"]);
});
