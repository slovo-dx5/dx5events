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
 * Note the app lowercases `email` before sending, and Flow 1 lowercases it
 * before storing, so `_eq` is safe on both sides.
 */

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

  return { orders: mine.map(publicOrder) };
};
