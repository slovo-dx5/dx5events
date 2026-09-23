/**
 * Flow 1 "Shop — Create Order" · Run Script operation · key: `respond`
 *
 * Terminal operation on the Condition's RESOLVE branch — the new-order path,
 * after the gateway has been called. Shape must match ShopOrder.fromJson in
 * lib/services/payments/payment_models.dart.
 *
 * Expects: plan (Run Script), gateway (Webhook / Request URL)
 */
module.exports = async function (data) {
  const plan = data.plan || {};

  // The Request operation nests the parsed response under `data`.
  const gateway = (data.gateway && data.gateway.data) || {};

  const redirectUrl = gateway.redirect_url || null;
  if (!redirectUrl) {
    // The gateway answered but gave us nowhere to send the buyer. Failing here
    // is deliberate: the app would otherwise show a checkout it cannot open.
    // The order row stays pending with a null redirect_url, which `plan`
    // recognises on a retry.
    throw new Error('The payment provider did not return a checkout page.');
  }

  return {
    order_id: plan.order_id,
    status: 'pending',
    amount: plan.amount,
    currency: plan.currency,
    order_tracking_id: gateway.order_tracking_id || null,
    redirect_url: redirectUrl,
  };
};
