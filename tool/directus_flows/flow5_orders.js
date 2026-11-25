/**
 * Flow 5 "Shop — My Orders" · Run Script operation · key: `respond`
 *
 * Lists a buyer's past orders for the order-history screen.
 *
 * ── Read this before changing the lookup ────────────────────────────────────
 * This endpoint is **public** — like every other flow the app calls, because
 * the only credential the app has is the Directus token shipped in the APK,
 * which is extractable and therefore not a credential at all. So the lookup
 * has to be hard to guess rather than authenticated:
 *
 *   - It matches on `attendee_id` **and** `email` together. Either alone is
 *     guessable (an email) or enumerable; the pair is not.
 *   - It refuses a request missing either one, rather than falling back to a
 *     broader filter. A filter that silently widens is how this kind of
 *     endpoint turns into a customer-list dump.
 *   - It returns no billing block. The app already knows who the buyer is, and
 *     an order list is not a reason to hand back phone numbers.
 *
 * It is still, by design, "whoever knows the pair can read the list". If that
 * becomes unacceptable — real money, real addresses — the fix is a real session
 * token on the app, not a cleverer filter here.
 * ────────────────────────────────────────────────────────────────────────────
 *
 * Expects:
 *   orders — Read Data on shop_orders, permissions $full, query:
 *     {"filter":{"_and":[
 *        {"attendee_id":{"_eq":"{{$trigger.body.attendee_id}}"}},
 *        {"email":{"_eq":"{{$trigger.body.email}}"}}]},
 *      "sort":["-date_created"],"limit":50}
 *
 *   vouchers — Read Data on shop_vouchers, permissions $full, query:
 *     {"filter":{"_and":[
 *        {"attendee_id":{"_eq":"{{$trigger.body.attendee_id}}"}},
 *        {"status":{"_eq":"active"}}]},"limit":5}
 *   voucher_use — Read Data on shop_orders, permissions $full, query:
 *     {"filter":{"_and":[
 *        {"attendee_id":{"_eq":"{{$trigger.body.attendee_id}}"}},
 *        {"voucher_id":{"_nnull":true}},
 *        {"status":{"_in":["pending","completed"]}}]},
 *      "fields":["status","voucher_id","credit_applied","date_created"],"limit":-1}
 *   (both optional: without them the reply simply has `credit: null`)
 *
 * Note the app lowercases `email` before sending, and Flow 1 lowercases it
 * before storing, so `_eq` is safe on both sides.
 */

// Same hold as Flow 1's stock and credit rules.
const HOLD_MINUTES = 30;

// ── Prize credit ─────────────────────────────────────────────────────────────
// Identical in flow1_plan.js and flow5_orders.js; test_flows.mjs checks the two
// copies agree.
//
// A `shop_vouchers` row is a prize (leaderboard top 3) worth `amount` KES. The
// balance is never stored: it is the amount minus `credit_applied` on the
// winner's orders that hold it — completed ones for good, pending ones for
// HOLD_MINUTES (the same rule as stock) — so a failed or abandoned payment
// hands its credit back on its own.
//
// A voucher only counts when it is `active`, not expired, and belongs to BOTH
// the attendee id and the signed-in email the request carries.
function activeVoucher(vouchers, attendeeId, email, now) {
  const id = String(attendeeId || '').trim();
  const mail = String(email || '').trim().toLowerCase();
  if (!id || !mail) return null;
  const rows = Array.isArray(vouchers) ? vouchers : (vouchers ? [vouchers] : []);
  for (const v of rows) {
    if (!v || String(v.status) !== 'active') continue;
    if (String(v.attendee_id) !== id) continue;
    if (String(v.email || '').trim().toLowerCase() !== mail) continue;
    const expires = Date.parse(v.expires_at);
    if (!Number.isFinite(expires) || expires <= now) continue;
    const amount = Number(v.amount);
    if (!Number.isFinite(amount) || amount <= 0) continue;
    return v;
  }
  return null;
}

/** KES left on `voucher` after the orders in `uses` that still hold credit. */
function creditBalance(voucher, uses, now) {
  if (!voucher) return 0;
  const cutoff = now - HOLD_MINUTES * 60 * 1000;
  let spent = 0;
  for (const order of Array.isArray(uses) ? uses : []) {
    if (!order || String(order.voucher_id) !== String(voucher.id)) continue;
    const status = String(order.status || '');
    if (status === 'pending') {
      const at = Date.parse(order.date_created);
      if (!Number.isFinite(at) || at < cutoff) continue;
    } else if (status !== 'completed') {
      continue;
    }
    const used = Number(order.credit_applied);
    if (Number.isFinite(used) && used > 0) spent += used;
  }
  return Math.max(0, Math.round(Number(voucher.amount) - spent));
}
// ─────────────────────────────────────────────────────────────────────────────

/** Fields the app is allowed to see. Deliberately excludes `billing`. */
function publicOrder(row) {
  const items = Array.isArray(row.items) ? row.items : [];
  return {
    order_id: String(row.id),
    status: row.status || 'pending',
    amount: row.amount,
    currency: row.currency || 'KES',
    order_tracking_id: row.order_tracking_id || null,
    payment_method: row.payment_method || null,
    credit_applied: Number(row.credit_applied) > 0 ? Number(row.credit_applied) : 0,
    confirmation_code: row.confirmation_code || null,
    paid_at: row.paid_at || null,
    created_at: row.date_created || null,
    items: items.map(function (line) {
      return {
        product_id: line.product_id || null,
        name: line.name || '',
        size: line.size || '',
        qty: line.qty || 0,
        unit_price: line.unit_price,
        line_total: line.line_total,
      };
    }),
  };
}

module.exports = async function (data) {
  const body = (data.$trigger && data.$trigger.body) || {};
  const attendeeId = String(body.attendee_id || '').trim();
  const email = String(body.email || '').trim().toLowerCase();

  // Both or nothing — see the note above. Returned as an error rather than
  // thrown so the app gets a readable message instead of an empty 200 body.
  if (!attendeeId || !email) {
    return { error: 'Sign in to see your orders.' };
  }

  const rows = Array.isArray(data.orders) ? data.orders : [];

  // Belt and braces: if the Read Data query is ever edited to drop half the
  // filter, the wrong rows still do not leave here.
  const mine = rows.filter(function (row) {
    return row &&
      String(row.attendee_id || '') === attendeeId &&
      String(row.email || '').toLowerCase() === email;
  });

  // Prize credit, if this buyer won one. Only reported when the spending read
  // is present too, so the app never shows a balance that ignores past orders.
  const now = Date.now();
  const voucher = activeVoucher(data.vouchers, attendeeId, email, now);
  const credit = voucher && Array.isArray(data.voucher_use)
    ? {
        amount: Math.round(Number(voucher.amount)),
        balance: creditBalance(voucher, data.voucher_use, now),
        rank: Number(voucher.rank) || null,
        expires_at: voucher.expires_at,
      }
    : null;

  return { orders: mine.map(publicOrder), credit };
};
