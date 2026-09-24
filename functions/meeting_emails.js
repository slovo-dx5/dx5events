/**
 * Meeting emails.
 *
 * The app used to POST these straight to the CIO Africa mailer, which now
 * requires an API key the app must never hold. Instead they are sent from here,
 * off the Firestore writes the app already makes (lib/helpers/helper_functions
 * .dart requestMeeting, lib/meetings/pending_Meetings.dart accept):
 *
 *   users/{uid}/meetings/{meetingId}
 *
 * Every meeting is written twice, once under each person. Only the copy under
 * the person being asked (`wants_to_meet_with_id`) is acted on, so each email
 * goes out once:
 *
 *   created                      → "Meeting requested" to wants_to_meet_with_email
 *   isAccepted false → true      → "Meeting accepted"  to requested_by_email
 *
 * Firestore triggers are at-least-once, so each send first claims
 * `meetingEmails/<meetingId>_<kind>`; a retry finds it and stops.
 *
 * Set the key with:
 *   firebase functions:secrets:set MAILER_API_KEY
 */

const {onDocumentCreated, onDocumentUpdated} =
  require("firebase-functions/v2/firestore");
const {defineSecret} = require("firebase-functions/params");
const {getFirestore} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

const mailerKey = defineSecret("MAILER_API_KEY");
const MAILER_URL = "https://mailer.cioafrica.co/api/email/send";
const MEETING_DOC = "users/{uid}/meetings/{meetingId}";

const BANNER_URL =
  "https://subscriptions.cioafrica.co/assets/923024d9-53c8-459a-942a-1d487e0099f9?banner.jpg";
const MEETINGS_URL = "https://cioafrica.co/meetings";
const PLAY_URL =
  "https://play.google.com/store/apps/details?id=com.cioafrica.dx5veevents&hl=en";
const APP_STORE_URL = "https://apps.apple.com/lt/app/dx5ve-events/id6479024266";
const MEETING_MINUTES = 30;

/** Everything here is typed by attendees; none of it is trusted HTML. */
function esc(value) {
  return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
}

const paragraphs = (text) => esc(text).trim().replace(/\r?\n/g, "<br>");

/** "10:30 AM" + 30 min → "11:00 AM", matching the app's DateFormat("h:mm a"). */
function addMinutes(startTime, minutes) {
  const m = /^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])\s*$/.exec(String(startTime || ""));
  if (!m) return null;
  let h = Number(m[1]) % 12;
  if (m[3].toUpperCase() === "PM") h += 12;
  const total = (h * 60 + Number(m[2]) + minutes) % (24 * 60);
  const hh = Math.floor(total / 60);
  const mm = String(total % 60).padStart(2, "0");
  return `${hh % 12 || 12}:${mm} ${hh < 12 ? "AM" : "PM"}`;
}

function layout(inner) {
  return [
    "<div style=\"max-width:600px;font-family:Arial,Helvetica,sans-serif;color:#222;\">",
    `<img src="${BANNER_URL}" alt="CIO Africa" ` +
      "style=\"width:100%;max-width:600px;height:auto;margin-bottom:20px;\">",
    inner,
    "<p>If you have not downloaded the app, you can get it using the buttons below:</p>",
    "<p>",
    `<a href="${PLAY_URL}" style="margin-right:10px;display:inline-block;">` +
      "<img src=\"https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg\" " +
      "alt=\"Get it on Google Play\" style=\"height:40px;\"></a>",
    `<a href="${APP_STORE_URL}" style="display:inline-block;">` +
      "<img src=\"https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg\" " +
      "alt=\"Download on the App Store\" style=\"height:40px;\"></a>",
    "</p>",
    "</div>",
  ].join("\n");
}

function requestEmail(m) {
  const from = String(m.requested_by || "An attendee").trim();
  const company = String(m.company || "").trim();
  return {
    emailAddress: String(m.wants_to_meet_with_email || "").trim(),
    subject: `Meeting Requested by ${from}${company ? ` from ${company}` : ""}`,
    // `message` already carries the proposed date and times — the app builds
    // it that way (cio_bottomsheets.dart), so they are not repeated here.
    body: layout([
      `<p>Hello ${esc(m.wants_to_meet_with)},</p>`,
      `<p><strong>${esc(from)}</strong>${company ? ` from ${esc(company)}` : ""} ` +
        "would like to meet you.</p>",
      `<p>${paragraphs(m.message)}</p>`,
      "<p>",
      `<a href="${MEETINGS_URL}" style="display:inline-block;padding:10px 20px;` +
        "background-color:#007BFF;color:white;text-decoration:none;border-radius:4px;\">" +
        "Accept Request</a>",
      "</p>",
    ].join("\n")),
  };
}

function acceptedEmail(m) {
  const end = addMinutes(m.startTime, MEETING_MINUTES);
  return {
    emailAddress: String(m.requested_by_email || "").trim(),
    subject: "Meeting Accepted",
    body: layout([
      `<p>Hello ${esc(m.requested_by)},</p>`,
      `<p>${esc(m.wants_to_meet_with)} accepted your meeting request.<br>` +
        "Our meetings concierge service team will reach out to show you the " +
        "meeting venue.</p>",
      m.startTime ?
        "<p><strong>Meeting time:</strong><br>" +
          `Start time: ${esc(m.startTime)}` +
          (end ? `<br>End time: ${esc(end)}` : "") + "</p>" :
        "",
    ].join("\n")),
  };
}

/** Only the invitee's copy of a meeting triggers mail. */
const isInviteeCopy = (uid, m) =>
  m && String(m.wants_to_meet_with_id) === String(uid);

async function send(meetingId, kind, email) {
  if (!email.emailAddress) {
    logger.warn("meeting email skipped: no address", {meetingId, kind});
    return;
  }

  // Claim first: create() fails if a previous delivery of this event got here.
  const claim = getFirestore().doc(`meetingEmails/${meetingId}_${kind}`);
  try {
    await claim.create({kind, to: email.emailAddress, claimedAt: new Date()});
  } catch (err) {
    if (err.code === 6) { // ALREADY_EXISTS
      logger.info("meeting email already sent", {meetingId, kind});
      return;
    }
    throw err;
  }

  const res = await fetch(MAILER_URL, {
    method: "POST",
    headers: {"Content-Type": "application/json", "X-API-Key": mailerKey.value()},
    body: JSON.stringify(email),
  });
  const text = await res.text();
  if (!res.ok) {
    // Release the claim so a retry of this event can try again.
    await claim.delete().catch(() => {});
    throw new Error(`mailer ${res.status}: ${text.slice(0, 200)}`);
  }
  await claim.update({sentAt: new Date()});
  logger.info("meeting email sent", {meetingId, kind});
}

exports.meetingRequestEmail = onDocumentCreated(
    {document: MEETING_DOC, secrets: [mailerKey]},
    async (event) => {
      const m = event.data && event.data.data();
      if (!isInviteeCopy(event.params.uid, m)) return;
      if (m.isAccepted === true) return; // a copy re-created as accepted
      await send(event.params.meetingId, "request", requestEmail(m));
    },
);

exports.meetingAcceptedEmail = onDocumentUpdated(
    {document: MEETING_DOC, secrets: [mailerKey]},
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (!isInviteeCopy(event.params.uid, after)) return;
      if (before.isAccepted === true || after.isAccepted !== true) return;
      await send(event.params.meetingId, "accepted", acceptedEmail(after));
    },
);

// Exposed for the local tests.
exports._test = {requestEmail, acceptedEmail, addMinutes, isInviteeCopy};
