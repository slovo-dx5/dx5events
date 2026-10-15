/**
 * G5 "Gamification — Shop Purchase" · Run Script operation · key: `purchase`
 *
 * Event Hook on shop_orders items.create + items.update. Purchases are scored
 * from the order row the payment flows wrote, never from anything the app
 * says, so a cancelled or unpaid checkout earns nothing.
 *
 * Expects:
 *   order — Read Data on shop_orders, keys {{$trigger.keys}} (update) or
 *           {{$trigger.key}} (create), fields id,status,attendee_id,paid_at,date_created
 *
 * Returns { rows: [...] } for a Create Data operation on app_activity_logs
 * (Emit Events: ON — G1 must see it). client_event_id is fixed per order, so a
 * second IPN or the Flow 2 recovery path cannot log the same order twice; that
 * insert just fails on the unique constraint.
 */
module.exports = async function (data) {
  const orders = Array.isArray(data.order) ? data.order : data.order ? [data.order] : [];
  const rows = [];
  for (const order of orders) {
    if (!order || order.status !== 'completed') continue;
    const userId = Number(order.attendee_id);
    if (!Number.isFinite(userId) || userId <= 0) continue;
    rows.push({
      client_event_id: `shop-order-${order.id}`,
      user_id: userId,
      action: 'shop_order_paid',
      target_type: 'shop_order',
      target_id: String(order.id),
      metadata: null,
      platform: 'server',
      occurred_at: order.paid_at || order.date_created || new Date().toISOString(),
    });
  }
  return { rows };
};
