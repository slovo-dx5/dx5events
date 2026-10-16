/**
 * Flow 2 "Shop — Order Status" · Run Script operation
 *
 * The same file goes into **four** operations — every terminal node of the
 * flow's branch tree. Directus flows are trees, not graphs: branches cannot
 * rejoin, so each leaf needs its own "return the answer" operation, and the
 * trigger's "Data of last operation" picks up whichever one ran.
 *
 *   key                      where                       returns
 *   ──────────────────────── ─────────────────────────── ──────────────────────
 *   reply_stored             needs_check ✗ (reject)      our stored record
 *   reply_recovered          after `write`               the recovered status
 *   reply_unchanged          has_update ✗ (reject)       gateway said pending
 *   reply_gateway_down       gateway_status ✗ (reject)   our stored record
 *
 * The last one matters most. The app polls this endpoint every 3s and gives up
 * after five consecutive failures, so a gateway outage that killed this flow
 * would break confirmation for orders the webhook would have settled anyway.
 * Wired to the reject connector, an unreachable gateway degrades to "still
 * pending" instead.
 *
 * Expects whichever of these exist on the path taken:
 *   plan    — Run Script `flow2_plan.js`
 *   recover — Run Script `flow2_recover.js`
 */
module.exports = async function (data) {
  const recover = data.recover;
  if (recover && recover.response) return recover.response;

  const plan = data.plan;
  if (plan && plan.response) return plan.response;

  // Neither ran, so we have nothing to say. Reported as an error rather than a
  // fabricated "pending" — the app stops polling and shows "could not confirm",
  // which is true, instead of waiting three minutes on a broken flow.
  return { error: 'Could not read the order status. Please try again.' };
};
