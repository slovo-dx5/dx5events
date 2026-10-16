/**
 * Flow 3 "Shop — Pesapal Webhook" · Run Script operation · key: `apply`
 *
 * This is the reliable signal — it fires even if the buyer closes the browser
 * before the redirect. It is also public, so it verifies the shared secret
 * before trusting anything in the body.
 *
 * Expects:
 *   secret_row — Read Data on app_secrets,
 *                filter {"key":{"_eq":"pesapal_webhook_secret"}}, limit 1
 *   order      — Read Data on shop_orders,
 *                filter {"id":{"_eq":"{{$trigger.body.merchant_reference}}"}}
 *
 * Set this flow to "Do Not Track" under Activity & Logs Tracking — otherwise
 * the secret and the inbound header are written to the activity log in plain
 * text.
 */

/**
 * Constant-time string comparison.
 *
 * The Run Script sandbox has no `node:crypto`, so `timingSafeEqual` is not
 * available. Comparing with `===` would leak the secret one character at a
 * time through response timing.
 */
function secretsMatch(received, expected) {
  const a = String(received == null ? '' : received);
  const b = String(expected == null ? '' : expected);
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0 && a.length > 0;
}

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
  const trigger = data.$trigger || {};
  const headers = trigger.headers || {};
  const body = trigger.body || {};

  const expected = ((data.secret_row || [])[0] || {}).value;
  if (!secretsMatch(headers['x-webhook-secret'], expected)) {
    // Not from the gateway. Rejecting is correct here — the real caller always
    // sends the header, so this costs us no legitimate notifications.
    throw new Error('Unauthorized');
  }

  const rows = data.order || [];
  const order = Array.isArray(rows) ? rows[0] : rows;
  if (!order) {
    // Unknown order. Return normally so the trigger still answers 200 — the
    // gateway does not retry, and there is nothing for it to retry into.
    return { skipped: 'unknown order', order_id: body.merchant_reference || null };
  }

  // Idempotency. Pesapal can send more than one IPN, and Flow 2's recovery
  // path can apply the same result. Anything with side effects (receipt email,
  // stock decrement) belongs behind this guard, not before it.
  if (order.status === 'completed') {
    return { skipped: 'already paid', order_id: order.id };
  }

  const status = normalize(body.payment_status_description);

  return {
    order_id: order.id,
    status,
    // → Update Data on shop_orders
    update: {
      status,
      payment_method: body.payment_method || null,
      confirmation_code: body.confirmation_code || null,
      order_tracking_id: body.order_tracking_id || order.order_tracking_id || null,
      paid_at: status === 'completed' ? new Date().toISOString() : null,
      raw_payment: body,
    },
  };
};
