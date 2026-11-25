// Run with: node --test functions/test/
const test = require("node:test");
const assert = require("node:assert");
const {_test: t} = require("../meeting_records");

const meeting = {
  id: "m1",
  requested_by: "Ann Lee",
  requested_by_id: "1",
  requested_by_email: "ann@old.com",
  wants_to_meet_with: "Bob Ng",
  wants_to_meet_with_id: 2,
  wants_to_meet_with_email: "bob@x.com",
  company: "Acme",
  date_requested: new Date("2026-11-25T08:00:00Z"),
  meeting_time: new Date("2026-11-25T11:00:00Z"),
  startTime: "2:00 PM",
  message: "Talk cloud",
  isAccepted: true,
};

const regs = [
  {attendeeId: 1, eventId: 107, first_name: "Old", last_name: "Ann", company: "Was"},
  {attendeeId: 1, eventId: 111, first_name: "Ann", last_name: "Lee",
    work_email: "ann@acme.com", company: "Acme Ltd", role: "CIO"},
  {attendeeId: 2, eventId: 107, first_name: "Bob", last_name: "Ng",
    work_email: "bob@x.com", company: "Beta", role: "CTO"},
];

test("prefers the registration for the active event", () => {
  const m = t.pickRegistrations(regs, 111);
  assert.strictEqual(m.get("1").company, "Acme Ltd");
  assert.strictEqual(m.get("2").company, "Beta"); // only one on file
});

test("builds a row with both people's name, email, company and role", () => {
  const r = t.buildRecord(meeting, "m1", t.pickRegistrations(regs, 111), {
    eventId: 111, acceptedAt: new Date("2026-11-25T08:45:00Z"),
  });
  assert.deepStrictEqual(
      [r.requester_name, r.requester_email, r.requester_company, r.requester_role],
      ["Ann Lee", "ann@acme.com", "Acme Ltd", "CIO"]);
  assert.deepStrictEqual(
      [r.invitee_name, r.invitee_email, r.invitee_company, r.invitee_role],
      ["Bob Ng", "bob@x.com", "Beta", "CTO"]);
  assert.strictEqual(r.requester_id, 1);
  assert.strictEqual(r.invitee_id, 2);
  assert.strictEqual(r.event_id, 111);
  assert.strictEqual(r.response_minutes, 45);
  assert.strictEqual(r.meeting_time, "2026-11-25T11:00:00.000Z");
  assert.strictEqual(r.status, "accepted");
});

test("falls back to the meeting doc when nobody is registered", () => {
  const r = t.buildRecord(meeting, "m1", new Map(), {});
  assert.strictEqual(r.requester_name, "Ann Lee");
  assert.strictEqual(r.requester_email, "ann@old.com");
  assert.strictEqual(r.requester_company, "Acme");
  assert.strictEqual(r.invitee_company, null);
  assert.strictEqual(r.requester_role, null);
  assert.strictEqual(r.response_minutes, null);
});

test("reads Firestore Timestamps", () => {
  const ts = {toDate: () => new Date("2026-11-25T09:00:00Z")};
  assert.strictEqual(t.iso(ts), "2026-11-25T09:00:00.000Z");
  assert.strictEqual(t.iso(null), null);
});

test("only the invitee copy counts", () => {
  assert.ok(t.isInviteeCopy("2", meeting));
  assert.ok(!t.isInviteeCopy("1", meeting));
});
