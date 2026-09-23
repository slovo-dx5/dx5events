/**
 * "Shop — Receipt" · Run Script operation · key: `receipt`
 *
 * Builds the receipt email for a paid order. Used by **two** flows, because an
 * order can be settled by either of them and a buyer should get exactly one
 * receipt whichever path it took:
 *
 *   Flow 3 (webhook)      — the normal path
 *   Flow 2 (recovery)     — when the webhook was lost or arrived too late
 *
 * In both cases it sits behind the "was this order already completed?" guard,
 * so the receipt goes out at most once per order. That guard is the only thing
 * preventing duplicates — put nothing with side effects in front of it.
 *
 * Expects:
 *   order — Read Data on shop_orders (the row as it was *before* the update)
 *   Flow 3: apply   — Run Script `flow3_apply.js`
 *   Flow 2: recover — Run Script `flow2_recover.js`
 *
 * Feeds a **Mail** operation:
 *   To       {{receipt.to}}
 *   Subject  {{receipt.subject}}
 *   Type     Markdown
 *   Body     {{receipt.body}}
 */

// ── EDIT ME ──────────────────────────────────────────────────────────────────
const SHOP_NAME = 'CIO Africa Shop';
const SUPPORT_EMAIL = 'support@cioafrica.co';
// ─────────────────────────────────────────────────────────────────────────────

/** "KES 2,500" — thousands separators without Intl, which the sandbox lacks. */
function money(currency, amount) {
  const n = Number(amount);
  if (!Number.isFinite(n)) return String(amount);
  const whole = Math.round(n).toString();
  const grouped = whole.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  return currency + ' ' + grouped;
}

module.exports = async function (data) {
  const rows = data.order || [];
  const order = Array.isArray(rows) ? rows[0] : rows;
  if (!order) return { skipped: 'no order' };

  // Whichever script settled it. The row read earlier still says "pending", so
  // the payment details have to come from the settling script's output.
  const settled = data.apply || data.recover || {};
  const update = settled.update || {};

  // The billing address first: that is where the buyer asked for the receipt.
  // `email` is the signed-in account, kept for the history lookup, and the two
  // can legitimately differ (buying merch for a colleague).
  const to = String((order.billing || {}).email_address || order.email || '')
    .trim();
  if (!to) {
    // No address to send to. Reported rather than thrown: the payment itself
    // succeeded, and failing the flow here would roll nothing back while
    // making a paid order look like a broken one in the logs.
    return { skipped: 'no email address', order_id: order.id };
  }

  const currency = order.currency || 'KES';
  const items = Array.isArray(order.items) ? order.items : [];

  const lines = items.map(function (line) {
    const label = String(line.name || line.product_id || 'Item') +
      (line.size ? ' (' + line.size + ')' : '');
    return '| ' + label + ' | ' + (line.qty || 0) + ' | ' +
      money(currency, line.line_total) + ' |';
  });

  const body = [
    '## Thanks for your order',
    '',
    'Your payment has been received and your order is confirmed.',
    '',
    '| Item | Qty | Total |',
    '| --- | --- | --- |',
  ]
    .concat(lines)
    .concat([
      '',
      '**Total paid:** ' + money(currency, order.amount),
      '',
      '**Order reference:** ' + order.id,
      update.payment_method ? '**Paid with:** ' + update.payment_method : null,
      update.confirmation_code
        ? '**Payment reference:** ' + update.confirmation_code
        : null,
      '',
      'Keep this email — the order reference is what support needs if anything',
      'is wrong with your order.',
      '',
      'Questions? Reply to this email or write to ' + SUPPORT_EMAIL + '.',
      '',
      '— ' + SHOP_NAME,
    ])
    // Drop the details the gateway did not send, rather than emailing a buyer a
    // line reading "**Paid with:** null". Only nulls go — empty strings are the
    // blank lines Markdown needs between paragraphs.
    .filter(function (line) {
      return line !== null;
    })
    .join('\n');

  return {
    to: to,
    subject: SHOP_NAME + ' — order ' + order.id + ' confirmed',
    body: body,
    order_id: order.id,
  };
};
