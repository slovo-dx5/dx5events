/**
 * "Shop — Receipt" · Run Script operation · key: `receipt`
 *
 * Builds the receipt email for a settled order. Used by **three** flows,
 * because an order can be settled by any of them and a buyer should get
 * exactly one receipt whichever path it took:
 *
 *   Flow 3 (webhook)      — the normal path
 *   Flow 2 (recovery)     — when the webhook was lost or arrived too late
 *   Flow 1 (free order)   — a zero-amount order never reaches the gateway
 *
 * In each case it sits behind a guard that only passes an order that has just
 * become completed, so the receipt goes out at most once per order. That guard
 * is the only thing preventing duplicates — put nothing with side effects in
 * front of it.
 *
 * Expects one of:
 *   order + apply   — Flow 3: Read Data on shop_orders, Run Script flow3_apply.js
 *   order + recover — Flow 2: Read Data on shop_orders, Run Script flow2_recover.js
 *   plan            — Flow 1: Run Script flow1_plan.js (the row is plan.order_row)
 *
 * Feeds a **Request URL** operation that calls the CIO Africa mailer — the same
 * service the app uses for meeting emails. Directus SMTP is not configured and
 * is not going to be:
 *
 *   Method   POST
 *   URL      https://mailer.cioafrica.co/api/email/send
 *   Headers  X-API-Key: {{mailer_key_row[0].value}}
 *   Body     {{receipt.request}}
 */

// ── EDIT ME ──────────────────────────────────────────────────────────────────
const SHOP_NAME = 'CIO Africa Store';
const SUPPORT_EMAIL = 'support@cioafrica.co';
// Same banner the meeting-request email uses.
const BANNER_URL =
  'https://subscriptions.cioafrica.co/assets/923024d9-53c8-459a-942a-1d487e0099f9?banner.jpg';
// App sponsor credit at the foot of the receipt (mirrors AppSponsor in
// lib/widgets/app_sponsor.dart). Set to null to drop it.
const SPONSOR = {
  name: 'MBCOM Technologies',
  logoUrl:
    'https://subscriptions.cioafrica.co/assets/6990f48c-b77b-4fd0-bc27-36e548876d51?width=600',
};
// ─────────────────────────────────────────────────────────────────────────────

/** "KES 2,500" — thousands separators without Intl, which the sandbox lacks. */
function money(currency, amount) {
  const n = Number(amount);
  if (!Number.isFinite(n)) return String(amount);
  const whole = Math.round(n).toString();
  const grouped = whole.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  return currency + ' ' + grouped;
}

/** Product names and billing details are typed by people; never trust them. */
function esc(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

const CELL = 'padding:8px 6px;border-bottom:1px solid #eee;';

module.exports = async function (data) {
  const rows = data.order || (data.plan && data.plan.order_row) || [];
  const order = Array.isArray(rows) ? rows[0] : rows;
  if (!order) return { skipped: 'no order' };

  // Whichever script settled it. On Flows 2 and 3 the row read earlier still
  // says "pending", so the payment details come from the settling script's
  // output. Flow 1's free order_row already carries them.
  const settled = data.apply || data.recover || {};
  const update = settled.update || order;

  // The billing address first: that is where the buyer asked for the receipt.
  // `email` is the signed-in account, kept for the history lookup, and the two
  // can legitimately differ (buying merch for a colleague).
  const to = String((order.billing || {}).email_address || order.email || '')
    .trim();
  if (!to) {
    // No address to send to. Reported rather than thrown: the payment itself
    // succeeded. With no `request` the mailer call fails and takes its error
    // branch, which every flow wires to its normal reply.
    return { skipped: 'no email address', order_id: order.id };
  }

  const currency = order.currency || 'KES';
  const items = Array.isArray(order.items) ? order.items : [];
  const free = !(Number(order.amount) > 0);
  const firstName = String((order.billing || {}).first_name || '').trim();

  const lines = items
    .map(function (line) {
      const label = String(line.name || line.product_id || 'Item') +
        (line.size ? ' (' + line.size + ')' : '');
      return '<tr>' +
        '<td style="' + CELL + '">' + esc(label) + '</td>' +
        '<td style="' + CELL + 'text-align:center;">' + esc(line.qty || 0) + '</td>' +
        '<td style="' + CELL + 'text-align:right;">' +
        esc(money(currency, line.line_total)) + '</td>' +
        '</tr>';
    })
    .join('');

  // "free" is how Flow 1 marks a zero-amount order, not a way anyone paid.
  const method = update.payment_method && update.payment_method !== 'free'
    ? update.payment_method
    : null;

  const details = [
    ['Order reference', order.id],
    method ? ['Paid with', method] : null,
    update.confirmation_code ? ['Payment reference', update.confirmation_code] : null,
  ]
    // Drop the details the gateway did not send, rather than emailing a buyer a
    // line reading "Paid with: null".
    .filter(function (row) {
      return row !== null;
    })
    .map(function (row) {
      return '<strong>' + row[0] + ':</strong> ' + esc(row[1]);
    })
    .join('<br>');

  const body = [
    '<div style="max-width:600px;font-family:Arial,Helvetica,sans-serif;color:#222;">',
    '<img src="' + BANNER_URL + '" alt="' + esc(SHOP_NAME) + '" ' +
      'style="width:100%;max-width:600px;height:auto;margin-bottom:20px;">',
    '<h2 style="margin:0 0 12px;">Thanks for your order' +
      (firstName ? ', ' + esc(firstName) : '') + '</h2>',
    '<p>' + (free
      ? 'Your order is confirmed.'
      : 'Your payment has been received and your order is confirmed.') + '</p>',
    '<table style="width:100%;border-collapse:collapse;font-size:14px;">',
    '<tr>' +
      '<th style="' + CELL + 'text-align:left;">Item</th>' +
      '<th style="' + CELL + 'text-align:center;">Qty</th>' +
      '<th style="' + CELL + 'text-align:right;">Total</th>' +
      '</tr>',
    lines,
    '<tr><td colspan="2" style="padding:10px 6px;"><strong>' +
      (free ? 'Total' : 'Total paid') + '</strong></td>' +
      '<td style="padding:10px 6px;text-align:right;"><strong>' +
      (free ? 'Free' : esc(money(currency, order.amount))) +
      '</strong></td></tr>',
    '</table>',
    '<p>' + details + '</p>',
    '<p>Keep this email — the order reference is what support needs if ' +
      'anything is wrong with your order.</p>',
    '<p>Questions? Write to <a href="mailto:' + SUPPORT_EMAIL + '">' +
      SUPPORT_EMAIL + '</a>.</p>',
    '<p>— ' + esc(SHOP_NAME) + '</p>',
    SPONSOR
      ? '<div style="margin-top:28px;padding-top:16px;border-top:1px solid #eee;text-align:center;">' +
        '<div style="font-size:11px;letter-spacing:1px;color:#888;margin-bottom:8px;">APP SPONSORED BY</div>' +
        '<img src="' + SPONSOR.logoUrl + '" alt="' + esc(SPONSOR.name) + '" style="height:36px;width:auto;">' +
        '</div>'
      : '',
    '</div>',
  ].join('\n');

  const subject = SHOP_NAME + ' — order ' + order.id + ' confirmed';

  return {
    to: to,
    subject: subject,
    body: body,
    order_id: order.id,
    // Exactly the mailer's request shape, so the Request URL body is one lone
    // mustache — which Directus passes through as an object, not a string.
    // `from` is the sender *name*; the mailer picks the address.
    request: { emailAddress: to, subject: subject, body: body, from: SHOP_NAME },
  };
};
