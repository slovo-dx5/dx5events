/**
 * Flow 2 "Shop — Order Status" · Run Script operation · key: `recover`
 *
 * Applies a gateway status lookup to a still-pending order. This is the
 * recovery path for a webhook that was lost, or that arrived after the
 * gateway's 24h `webhook_url` memory expired.
 *
 * It deliberately mirrors `flow3_apply.js`: both funnel into the same
 * `shop_orders` update shape, so an order settled here is indistinguishable
 * from one settled by the webhook. If you change the status mapping, change it
 * in both — the sandbox cannot `require` a shared file.
 *
 * Expects:
 *   plan           — Run Script `flow2_plan.js` (mode 'check')
 *   gateway_status — Request URL, GET {GATEWAY}/orders/{{plan.tracking_id}}/status
 *                    with header `x-api-key: {{api_key_row[0].value}}`
 *
 * Returns:
 *   {response:{…}, update:{…}|null}
 *
 * `update` is null whenever the gateway still says pending — there is nothing
 * to write, and writing anyway would churn the row on every 3s poll.
 */

/** Pesapal's wording → the vocabulary PaymentStatus.parse expects. */
function normalize(description) {
  switch (String(description || '').trim().toLowerCase()) {
    case 'completed':
      return 'completed';
    case 'failed':
    case 'invalid':
      return 'failed';
    case 'reversed':
      return 'reversed';
    default:
      return 'pending';
  }
}

module.exports = async function (data) {
  const plan = data.plan || {};
  const fallback = plan.response || {};

  // The Request URL operation puts the response body under `.data`. A gateway
  // that answered with something unexpected is treated as "no news" rather than
  // as a failure: the order is genuinely still pending as far as we know, and
  // the app should keep polling.
  const raw = (data.gateway_status && data.gateway_status.data) || null;
  if (!raw || typeof raw !== 'object') {
    return { response: fallback, update: null };
  }

  const status = normalize(raw.payment_status_description || raw.description);
  if (status === 'pending') {
    return { response: fallback, update: null };
  }

  const paidAt = status === 'completed' ? new Date().toISOString() : null;
  const method = raw.payment_method || null;
  const code = raw.confirmation_code || null;

  return {
    // What the app gets back on this same poll — no extra round trip needed.
    response: {
      order_id: fallback.order_id,
      status: status,
      amount: fallback.amount,
      currency: fallback.currency,
      order_tracking_id: fallback.order_tracking_id,
      payment_method: method,
      confirmation_code: code,
      paid_at: paidAt,
    },
    // → Update Data on shop_orders, key {{plan.order_id}}
    update: {
      status: status,
      payment_method: method,
      confirmation_code: code,
      paid_at: paidAt,
      raw_payment: raw,
    },
  };
};
