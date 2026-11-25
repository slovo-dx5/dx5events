/**
 * Leaderboard prizes — shop credit for the top of the gamification board.
 *
 * Runs every 5 minutes. Does nothing until `gamification_settings
 * .awards_close_at` has passed, then:
 *
 *   A. Draft the winners. Ranks the board from `points_ledger` the way G3 does
 *      (registered for the event, not in `excluded_user_ids`, points > 0) and
 *      breaks ties by who reached their score FIRST (earliest last point).
 *      Writes one `shop_vouchers` row per prize, status `draft`, and emails the
 *      prize admin the list. Nothing reaches a winner at this stage.
 *
 *      While no voucher has been approved the drafts follow the board, so a
 *      late point or an admin setting a row to `void` (staff, cheat) re-ranks
 *      everyone below. Once any voucher is approved the order is fixed, and a
 *      rank whose row is voided is refilled by the next eligible person.
 *
 *   B. Notify. Every `approved` voucher not yet notified gets a push to
 *      `users/{attendeeId}.messaging_token` (opens the shop) and an email, and
 *      is then set `active` with an `expires_at`. Only `active` vouchers can be
 *      spent (flow1_plan.js). A `prizeNotices/{voucherId}` claim in Firestore
 *      makes the send happen at most once even if a run dies half-way.
 *
 * Admin workflow: open shop_vouchers in Directus after the event, check the
 * drafts, set any to `void` that should not win, set the rest to `approved`.
 *
 * Settings read from gamification_settings (all optional except event_id /
 * awards_close_at): prizes ([7500,5000,3500]), prize_expiry_days (30),
 * prize_admin_email, prize_event_name, leaderboard_freeze_at,
 * excluded_user_ids.
 *
 * Secrets:
 *   firebase functions:secrets:set DIRECTUS_TOKEN
 *   MAILER_API_KEY (already set for meeting emails)
 *
 * Deploy BY NAME ONLY (the project has functions whose source is not here):
 *   firebase deploy --only functions:leaderboardPrizes
 */

const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret} = require("firebase-functions/params");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

const directusToken = defineSecret("DIRECTUS_TOKEN");
const mailerKey = defineSecret("MAILER_API_KEY");

const DIRECTUS_URL = "https://subscriptions.cioafrica.co";
const MAILER_URL = "https://mailer.cioafrica.co/api/email/send";
const DEFAULT_PRIZES = [7500, 5000, 3500];
const DEFAULT_EXPIRY_DAYS = 30;
const DEFAULT_EVENT_NAME = "CIO100";
const BANNER_URL =
  "https://subscriptions.cioafrica.co/assets/0d1e6f06-4b27-4d67-aa52-3925058a378b?width=1200";

const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

// ------------------------------------------------------------ pure helpers

function asArray(v) {
  if (Array.isArray(v)) return v;
  if (typeof v === "string" && v.trim()) {
    try {
      const parsed = JSON.parse(v);
      return Array.isArray(parsed) ? parsed : [];
    } catch (_) {
      return [];
    }
  }
  return [];
}

/** Prize amounts in rank order; bad entries dropped. */
function prizeTable(settings) {
  const raw = asArray(settings && settings.prizes);
  const list = (raw.length ? raw : DEFAULT_PRIZES)
      .map(Number)
      .filter((n) => Number.isFinite(n) && n > 0)
      .map(Math.round);
  return list;
}

function ordinal(n) {
  const s = ["th", "st", "nd", "rd"];
  const v = n % 100;
  return n + (s[(v - 20) % 10] || s[v] || s[0]);
}

function money(amount) {
  return "KES " + Math.round(Number(amount)).toString()
      .replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function esc(value) {
  return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
}

/**
 * The board, best first. `totals` rows come from a Directus aggregate:
 *   {user_id, sum:{points}, max:{date_created}}
 * Ties on points go to whoever got their last point earliest, then by id so
 * the order is stable.
 */
function rankPlayers(totals, people, excludedIds) {
  const registered = new Map();
  for (const p of Array.isArray(people) ? people : []) {
    if (p && p.attendeeId != null) registered.set(String(p.attendeeId), p);
  }
  const excluded = new Set(asArray(excludedIds).map(String));
  const players = [];
  for (const row of Array.isArray(totals) ? totals : []) {
    if (!row || row.user_id == null) continue;
    const id = String(row.user_id);
    const points = Number(row.sum && row.sum.points);
    if (!Number.isFinite(points) || points <= 0) continue;
    if (excluded.has(id) || !registered.has(id)) continue;
    const reachedAt = Date.parse(row.max && row.max.date_created);
    players.push({
      id,
      points,
      reachedAt: Number.isFinite(reachedAt) ? reachedAt : Infinity,
      person: registered.get(id),
    });
  }
  players.sort((a, b) =>
    b.points - a.points ||
    a.reachedAt - b.reachedAt ||
    a.id.localeCompare(b.id, undefined, {numeric: true}));
  return players;
}

function voucherRow(eventId, rank, amount, player) {
  const p = player.person || {};
  return {
    event_id: eventId,
    attendee_id: player.id,
    email: String(p.work_email || "").trim().toLowerCase(),
    name: [p.first_name, p.last_name].filter(Boolean).join(" ").trim(),
    rank,
    points: player.points,
    amount,
    status: "draft",
  };
}

/**
 * What to write to shop_vouchers so the drafts match the board.
 * Returns {create: [row], update: [{id, row}]}.
 */
function planDrafts(eventId, prizes, ranked, vouchers) {
  const rows = Array.isArray(vouchers) ? vouchers : [];
  const voided = new Set(rows.filter((v) => v.status === "void")
      .map((v) => String(v.attendee_id)));
  const live = rows.filter((v) => v.status !== "void");
  const locked = live.some((v) => v.status !== "draft");
  const eligible = ranked.filter((p) => !voided.has(p.id));
  const create = [];
  const update = [];

  if (!locked) {
    // Nothing promised to anyone yet: drafts simply mirror the top of the
    // board. Each rank keeps its row id so an admin's link stays valid.
    prizes.forEach((amount, i) => {
      const rank = i + 1;
      const player = eligible[i];
      const existing = live.find((v) => Number(v.rank) === rank);
      if (!player) return;
      const row = voucherRow(eventId, rank, amount, player);
      if (!existing) {
        create.push(row);
      } else if (String(existing.attendee_id) !== player.id ||
          Number(existing.points) !== player.points ||
          Number(existing.amount) !== amount) {
        update.push({id: existing.id, row});
      }
    });
    return {create, update};
  }

  // Order is fixed: only a rank left with no live row gets the next person
  // who does not already hold one.
  const holders = new Set(live.map((v) => String(v.attendee_id)));
  const queue = eligible.filter((p) => !holders.has(p.id));
  prizes.forEach((amount, i) => {
    const rank = i + 1;
    if (live.some((v) => Number(v.rank) === rank)) return;
    const player = queue.shift();
    if (player) create.push(voucherRow(eventId, rank, amount, player));
  });
  return {create, update};
}

function expiryFor(settings, nowMs) {
  const days = Number(settings.prize_expiry_days);
  const span = (Number.isFinite(days) && days > 0 ? days : DEFAULT_EXPIRY_DAYS) *
    86400000;
  const closes = Date.parse(settings.awards_close_at);
  const from = Number.isFinite(closes) ? Math.max(closes, 0) : nowMs;
  return new Date(from + span).toISOString();
}

function eventName(settings) {
  return String(settings.prize_event_name || DEFAULT_EVENT_NAME).trim();
}

/** FCM message for a winner. `data` values must all be strings. */
function winnerPush(voucher, token, settings) {
  const rank = Number(voucher.rank);
  return {
    token,
    notification: {
      title: `You're a ${eventName(settings)} winner! \u{1F3C6}`,
      body: `You finished ${ordinal(rank)} on the leaderboard and won ` +
        `${money(voucher.amount)} to spend in the app shop. Tap to redeem.`,
    },
    data: {
      targetPage: "shop",
      prizeRank: String(rank),
      prizeAmount: String(voucher.amount),
    },
    android: {
      priority: "high",
      // Exists in every build, old ones included.
      notification: {channelId: "meeting_notifications", tag: `prize-${voucher.id}`},
    },
    apns: {payload: {aps: {sound: "default"}}},
  };
}

function winnerEmail(voucher, settings, expiresAt) {
  const first = String(voucher.name || "").split(" ")[0];
  const until = new Date(expiresAt).toUTCString().slice(5, 16);
  return {
    emailAddress: voucher.email,
    from: "CIO Africa",
    subject: `You won ${money(voucher.amount)} at ${eventName(settings)}!`,
    body: [
      "<div style=\"max-width:600px;font-family:Arial,Helvetica,sans-serif;color:#222;\">",
      `<img src="${BANNER_URL}" alt="CIO Africa" style="width:100%;max-width:600px;height:auto;margin-bottom:20px;">`,
      `<h2 style="margin:0 0 12px;">Congratulations${first ? ", " + esc(first) : ""}! \u{1F3C6}</h2>`,
      `<p>You finished <strong>${ordinal(Number(voucher.rank))}</strong> on the ` +
        `${esc(eventName(settings))} app leaderboard with ${esc(voucher.points)} points.</p>`,
      `<p>Your prize is <strong>${money(voucher.amount)}</strong> of credit in the ` +
        "app shop. Open the event app, go to the Shop, and the credit comes off " +
        "your order automatically at checkout. You can spread it over several orders.</p>",
      `<p>The credit is valid until <strong>${esc(until)}</strong>.</p>`,
      "<p>Thank you for taking part!</p>",
      "<p>— The CIO Africa team</p>",
      "</div>",
    ].join("\n"),
  };
}

function adminEmail(to, settings, drafts) {
  const rows = drafts
      .slice()
      .sort((a, b) => Number(a.rank) - Number(b.rank))
      .map((v) => `<tr><td>${esc(ordinal(Number(v.rank)))}</td>` +
        `<td>${esc(v.name)}</td><td>${esc(v.email)}</td>` +
        `<td>${esc(v.points)}</td><td>${money(v.amount)}</td></tr>`)
      .join("");
  return {
    emailAddress: to,
    from: "CIO Africa App",
    subject: `${eventName(settings)} leaderboard winners — approval needed`,
    body: [
      "<div style=\"font-family:Arial,Helvetica,sans-serif;color:#222;\">",
      "<p>The awards window has closed. These are the draft prize winners:</p>",
      "<table cellpadding=\"6\" style=\"border-collapse:collapse;\">",
      "<tr><th>Place</th><th>Name</th><th>Email</th><th>Points</th><th>Prize</th></tr>",
      rows,
      "</table>",
      "<p>Nobody has been told yet. In Directus, open <strong>shop_vouchers</strong>, " +
        "set anyone who should not win to <em>void</em> (the next person moves up), " +
        "then set the winners to <em>approved</em>. They are notified within 5 minutes.</p>",
      `<p><a href="${DIRECTUS_URL}/admin/content/shop_vouchers">Open shop_vouchers</a></p>`,
      "</div>",
    ].join("\n"),
  };
}

// ------------------------------------------------------------- side effects

async function directus(path, {method = "GET", body} = {}) {
  const res = await fetch(DIRECTUS_URL + path, {
    method,
    headers: {
      "Authorization": `Bearer ${directusToken.value()}`,
      "Content-Type": "application/json",
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (!res.ok) {
    throw new Error(`Directus ${method} ${path.split("?")[0]} → ${res.status} ` +
      (await res.text()).slice(0, 300));
  }
  if (res.status === 204) return null;
  const json = await res.json();
  return json.data;
}

const q = (obj) => encodeURIComponent(JSON.stringify(obj));

async function sendMail(request) {
  const res = await fetch(MAILER_URL, {
    method: "POST",
    headers: {"Content-Type": "application/json", "X-API-Key": mailerKey.value()},
    body: JSON.stringify(request),
  });
  if (!res.ok) {
    throw new Error(`mailer → ${res.status} ${(await res.text()).slice(0, 200)}`);
  }
}

async function loadBoard(settings) {
  const filter = settings.leaderboard_freeze_at ?
    `&filter=${q({date_created: {_lte: settings.leaderboard_freeze_at}})}` : "";
  const totals = await directus(
      "/items/points_ledger?aggregate[sum]=points&aggregate[max]=date_created" +
      `&groupBy[]=user_id&limit=-1${filter}`);
  const people = await directus(
      `/items/event_registrations?filter=${q({eventId: {_eq: settings.event_id}})}` +
      "&fields=attendeeId,first_name,last_name,work_email&limit=-1");
  return rankPlayers(totals, people, settings.excluded_user_ids);
}

async function draftWinners(settings, vouchers) {
  const prizes = prizeTable(settings);
  if (!prizes.length) return;
  const ranked = await loadBoard(settings);
  const plan = planDrafts(String(settings.event_id), prizes, ranked, vouchers);
  if (!plan.create.length && !plan.update.length) return;

  for (const row of plan.create) {
    await directus("/items/shop_vouchers", {method: "POST", body: row});
  }
  for (const {id, row} of plan.update) {
    await directus(`/items/shop_vouchers/${id}`, {method: "PATCH", body: row});
  }
  logger.info("prize drafts written",
      {created: plan.create.length, updated: plan.update.length});

  const to = String(settings.prize_admin_email || "").trim();
  if (!to) return;
  const drafts = await directus(
      `/items/shop_vouchers?filter=${q({_and: [
        {event_id: {_eq: String(settings.event_id)}},
        {status: {_eq: "draft"}},
      ]})}&limit=-1`);
  try {
    await sendMail(adminEmail(to, settings, drafts || []));
  } catch (err) {
    logger.warn("prize admin email failed", {err: String(err)});
  }
}

async function pushTo(db, voucher, settings) {
  const snap = await db.doc(`users/${voucher.attendee_id}`).get();
  const token = snap.exists ? String(snap.get("messaging_token") || "").trim() : "";
  if (!token) {
    logger.info("prize push skipped: no token", {voucher: voucher.id});
    return false;
  }
  try {
    await getMessaging().send(winnerPush(voucher, token, settings));
    return true;
  } catch (err) {
    const code = err && (err.code || (err.errorInfo && err.errorInfo.code));
    if (DEAD_TOKEN_CODES.has(code)) {
      await db.doc(`users/${voucher.attendee_id}`)
          .update({messaging_token: FieldValue.delete()})
          .catch(() => {});
    }
    logger.warn("prize push failed", {voucher: voucher.id, code, err: String(err)});
    return false;
  }
}

async function notifyApproved(settings, vouchers) {
  const db = getFirestore();
  const due = vouchers.filter((v) => v.status === "approved" && !v.notified_at);
  for (const voucher of due) {
    const expiresAt = voucher.expires_at || expiryFor(settings, Date.now());
    const claim = db.doc(`prizeNotices/${voucher.id}`);
    let fresh = true;
    try {
      await claim.create({voucherId: voucher.id, at: FieldValue.serverTimestamp()});
    } catch (err) {
      if (err.code !== 6) throw err; // 6 = ALREADY_EXISTS: sent on an earlier run
      fresh = false;
    }

    let pushed = false;
    let mailed = false;
    if (fresh) {
      pushed = await pushTo(db, voucher, settings);
      if (voucher.email) {
        try {
          await sendMail(winnerEmail(voucher, settings, expiresAt));
          mailed = true;
        } catch (err) {
          logger.warn("prize email failed", {voucher: voucher.id, err: String(err)});
        }
      }
      await claim.set({pushed, mailed}, {merge: true});
    }

    // Activated even if the push found no token: the shop banner and the
    // email are the backstop, and the credit must be spendable regardless.
    await directus(`/items/shop_vouchers/${voucher.id}`, {
      method: "PATCH",
      body: {status: "active", notified_at: new Date().toISOString(), expires_at: expiresAt},
    });
    logger.info("prize activated", {voucher: voucher.id, rank: voucher.rank, pushed, mailed});
  }
}

async function run() {
  const settings = await directus("/items/gamification_settings");
  const closes = Date.parse(settings && settings.awards_close_at);
  if (!settings || !settings.event_id || !Number.isFinite(closes)) return;
  if (Date.now() < closes) return;

  const eventId = String(settings.event_id);
  const vouchers = await directus(
      `/items/shop_vouchers?filter=${q({event_id: {_eq: eventId}})}&limit=-1`) || [];

  await draftWinners(settings, vouchers);
  await notifyApproved(settings, vouchers);
}

exports.leaderboardPrizes = onSchedule(
    {
      schedule: "every 5 minutes",
      timeoutSeconds: 120,
      secrets: [directusToken, mailerKey],
      // Serialize runs so two overlapping invocations can't double-draft.
      maxInstances: 1,
    },
    run,
);

exports._test = {
  prizeTable, rankPlayers, planDrafts, expiryFor, winnerPush, winnerEmail,
  adminEmail, ordinal, money,
};
