/**
 * Flow 2 "Shop — Order Status" · Run Script operation · key: `plan`
 *
 * Decides whether this poll can be answered from `shop_orders` alone, or
 * whether it has to ask the gateway. It never mutates anything — the write
 * happens later, from `flow2_recover.js`'s output.
 *
 * Why ask the gateway at all: Flow 3 (the webhook) is the normal signal, but
 * the gateway does not retry a failed notification and forgets `webhook_url`
 * after 24h. Without this recovery path a single dropped webhook leaves an
 * order `pending` forever, and the buyer's money is gone with no confirmation.
 *
 * Expects:
 *   order — Read Data on shop_orders,
 *           filter {"id":{"_eq":"{{$trigger.body.order_id}}"}}, limit 1
 *
 * Returns one of:
 *   {mode:'error',  response:{error}}      unknown order id
 *   {mode:'reply',  response:{…}}          answerable from our own record
 *   {mode:'check',  response:{…}, order_id, tracking_id}
 *                                          pending; go ask the gateway. The
 *                                          `response` is still filled in, so
 *                                          every downstream branch — including
 *                                          a gateway outage — has something
 *                                          honest to return.
 */

/** The reply shape `ShopOrder.fromJson` parses. Keep in step with it. */
function reply(order) {
  return {
    order_id: order.id,
    status: order.status || 'pending',
    amount: order.amount,
    currency: order.currency || 'KES',
    order_tracking_id: order.order_tracking_id || null,
    payment_method: order.payment_method || null,
    confirmation_code: order.confirmation_code || null,
    paid_at: order.paid_at || null,
  };
}

module.exports = async function (data) {
  const rows = data.order || [];
  const order = Array.isArray(rows) ? rows[0] : rows;

  if (!order) {
    // Returned rather than thrown: a thrown error ends the flow but the trigger
    // still answers 200 with an empty body, which the app cannot tell from a
    // real answer. Reported as an error rather than "pending" so the app stops
    // polling instead of spinning for three minutes on an id that will never
    // exist.
    return { mode: 'error', response: { error: 'Order not found.' } };
  }

  const response = reply(order);
  const pending = (order.status || 'pending') === 'pending';
  const tracking = order.order_tracking_id;

  // A settled order is final — never re-ask the gateway about it. A pending
  // order with no tracking id never reached the gateway (zero-amount orders,
  // or a flow that died before step 7 of Flow 1), so there is nothing to ask.
  if (!pending || !tracking) {
    return { mode: 'reply', response: response };
  }

  return {
    mode: 'check',
    response: response,
    order_id: order.id,
    tracking_id: tracking,
  };
};
