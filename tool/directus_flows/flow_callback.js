/**
 * "Shop — Checkout Complete" / "Shop — Checkout Cancelled"
 * Run Script operation · key: `respond`
 *
 * Pesapal redirects the buyer's *browser* to these after checkout. In the app
 * they are never rendered: PesapalCheckoutScreen matches them by URL prefix in
 * its navigation delegate and closes the webview before the page loads. They
 * exist so the gateway has a real URL to redirect to, and so a buyer who
 * somehow lands here in a real browser sees something sane.
 *
 * The payment result is NOT applied here — the webhook (Flow 3) does that, and
 * the app confirms by polling Flow 2. Never mark an order paid from a redirect;
 * the buyer controls it.
 *
 * Set `OUTCOME` per flow: 'complete' or 'cancelled'.
 */
const OUTCOME = 'complete';

module.exports = async function (data) {
  const query = (data.$trigger && data.$trigger.query) || {};
  return {
    status: 'ok',
    outcome: OUTCOME,
    message: OUTCOME === 'complete'
      ? 'Payment received. You can close this page and return to the app.'
      : 'Checkout cancelled. You can close this page and return to the app.',
    // Echoed for support: Pesapal appends these to the redirect.
    order_tracking_id: query.OrderTrackingId || null,
    merchant_reference: query.OrderMerchantReference || null,
  };
};
