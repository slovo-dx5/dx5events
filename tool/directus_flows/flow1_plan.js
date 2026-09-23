/**
 * Flow 1 "Shop — Create Order" · Run Script operation · key: `plan`
 *
 * Prices the cart from `shop_products` and builds both the `shop_orders` row
 * and the gateway request body. This is where the "never trust client amounts"
 * rule is enforced — nothing in the request body contributes to the total.
 *
 * Expects these earlier operation keys:
 *   products  — Read Data on shop_products,
 *               query {"filter":{"active":{"_eq":true}},"limit":500}
 *   existing  — Read Data on shop_orders,
 *               query {"filter":{"id":{"_eq":"{{$trigger.body.order_id}}"}},"limit":1}
 *   sales     — Read Data on shop_orders, for the stock check,
 *               query {"filter":{"status":{"_in":["pending","completed"]}},
 *                      "fields":["status","items","date_created"],"limit":-1}
 *
 * Returns `mode`:
 *   "existing" — do not touch the gateway; `response` is ready to return.
 *   "new"      — create the row, then:
 *                  free: false → call the gateway, then respond.
 *                  free: true  → nothing to pay. The row is created already
 *                                `completed` and `response` is ready to return;
 *                                the `needs_gateway` Condition routes past the
 *                                gateway, because Pesapal would refuse a zero
 *                                amount and never fire a webhook for it.
 *
 * Validation failures are RETURNED as {mode:"error"}, never thrown: a thrown
 * error ends the flow but the webhook trigger still answers 200 with an empty
 * body. PaymentService surfaces `error` verbatim to the buyer, so the messages
 * below are written to be read by a person.
 */

// ── EDIT ME ──────────────────────────────────────────────────────────────────
// Flow 3's TRIGGER url — the /flows/trigger/<uuid> form, not the
// /admin/settings/flows/<uuid> page you edit it on. Both contain the same uuid,
// so they are easy to confuse; posting results at the admin page silently loses
// every payment notification.
const WEBHOOK_URL =
  'https://subscriptions.cioafrica.co/flows/trigger/c55ec7e1-5ee7-4361-a8c0-386d65373fc3';
// ─────────────────────────────────────────────────────────────────────────────

// ── Stock ────────────────────────────────────────────────────────────────────
// Identical in flow1_plan.js and flow4_catalogue.js (Run Scripts cannot import
// each other); test_flows.mjs checks the two copies agree.
//
// `shop_products.stock` is the TOTAL ever on sale, not what is left:
//   null / empty     unlimited
//   12               one pool shared by every size (or the only pool, unsized)
//   {"S":10,"L":4}   per size; a size not listed has none
// What is left is derived from shop_orders on every request, so nothing is
// ever decremented and nothing can drift. A completed order holds its units
// for good; a pending one only for HOLD_MINUTES, so an abandoned checkout
// releases them on its own, as does a failed or cancelled one.
const HOLD_MINUTES = 30;

function parseStock(raw) {
  if (raw === null || raw === undefined || raw === '') return null;
  if (typeof raw === 'string') {
    try { raw = JSON.parse(raw); } catch (e) { return 0; }
    if (raw === null) return null;
  }
  const units = function (v) {
    const n = Number(v);
    return Number.isFinite(n) ? Math.max(0, Math.trunc(n)) : 0;
  };
  if (typeof raw === 'number') return units(raw);
  if (raw && typeof raw === 'object' && !Array.isArray(raw)) {
    const out = {};
    for (const size of Object.keys(raw)) out[size] = units(raw[size]);
    return out;
  }
  // Unreadable: sold out rather than unlimited. A typo shows up as "Sold out"
  // in the app the moment it is saved; the other way round it oversells.
  return 0;
}

/** Units held by existing orders, keyed both `id` and `id|size`. */
function unitsHeld(sales, now) {
  const held = {};
  const cutoff = now - HOLD_MINUTES * 60 * 1000;
  for (const order of Array.isArray(sales) ? sales : []) {
    const status = String((order && order.status) || '');
    if (status === 'pending') {
      const at = Date.parse(order.date_created);
      if (!Number.isFinite(at) || at < cutoff) continue;
    } else if (status !== 'completed') {
      continue;
    }
    let items = order.items;
    if (typeof items === 'string') {
      try { items = JSON.parse(items); } catch (e) { items = []; }
    }
    for (const item of Array.isArray(items) ? items : []) {
      const qty = Math.trunc(Number(item && item.qty)) || 0;
      if (qty <= 0) continue;
      const id = String(item.product_id);
      const bySize = id + '|' + String(item.size || '');
      held[id] = (held[id] || 0) + qty;
      held[bySize] = (held[bySize] || 0) + qty;
    }
  }
  return held;
}

/** Units left for product + size; null when the product is unlimited. */
function unitsLeft(product, size, held) {
  const stock = parseStock(product.stock);
  if (stock === null) return null;
  const id = String(product.id);
  if (typeof stock === 'number') return Math.max(0, stock - (held[id] || 0));
  return Math.max(0, (stock[size] || 0) - (held[id + '|' + size] || 0));
}

/** The key two cart lines share when they draw on the same units. */
function stockKey(product, size) {
  return typeof parseStock(product.stock) === 'number'
    ? String(product.id)
    : String(product.id) + '|' + size;
}
// ─────────────────────────────────────────────────────────────────────────────

module.exports = async function (data) {
  const body = (data.$trigger && data.$trigger.body) || {};
  const products = data.products || [];

  const orderId = String(body.order_id || '').trim();

  // Errors travel back as data, never as exceptions — see the note above.
  const fail = (message) => ({
    mode: 'error',
    order_id: orderId || null,
    response: { error: message },
  });

  if (!orderId) return fail('This order is missing an id. Please try again.');

  // Fail loudly at checkout rather than quietly losing webhooks later.
  if (!WEBHOOK_URL.includes('/flows/trigger/') ||
      WEBHOOK_URL.includes('PUT-FLOW-3-ID-HERE') ||
      WEBHOOK_URL.includes('/admin/')) {
    return fail('Payment backend is not fully configured yet.');
  }

  // ── Idempotency ────────────────────────────────────────────────────────────
  // The app deliberately reuses its order id when a checkout is retried (see
  // _orderId in checkout_screen.dart), so a second POST for the same id is
  // normal, not an error. Never open a second order at the gateway for it.
  const existingRows = data.existing || [];
  const prior = Array.isArray(existingRows) ? existingRows[0] : existingRows;

  if (prior) {
    const priorStatus = String(prior.status || 'pending');
    const base = {
      order_id: prior.id,
      amount: prior.amount,
      currency: prior.currency || 'KES',
      order_tracking_id: prior.order_tracking_id || null,
    };

    // Already settled — the app skips the webview when redirect_url is null
    // and goes straight to the confirmation screen.
    if (priorStatus !== 'pending') {
      return {
        mode: 'existing',
        order_id: prior.id,
        response: Object.assign({}, base, {
          status: priorStatus,
          redirect_url: null,
        }),
      };
    }

    // Still pending. If we kept the checkout URL, hand back the same one so the
    // buyer resumes the order they already started. If we did not, a previous
    // gateway call failed part-way: report pending and let the status screen
    // poll, because there is nowhere to send them and creating a second row
    // would fail on the primary key anyway.
    return {
      mode: 'existing',
      order_id: prior.id,
      response: Object.assign({}, base, {
        status: 'pending',
        redirect_url: prior.redirect_url || null,
      }),
    };
  }
  // ───────────────────────────────────────────────────────────────────────────


  const items = Array.isArray(body.items) ? body.items : [];
  if (items.length === 0) return fail('Your cart is empty.');

  const billing = body.billing_address || {};
  for (const field of ['first_name', 'last_name', 'email_address']) {
    if (!String(billing[field] || '').trim()) {
      return fail(`Billing detail missing: ${field.replace(/_/g, ' ')}.`);
    }
  }

  const catalogue = new Map(products.map((p) => [String(p.id), p]));
  const priced = [];
  const description = [];
  let amount = 0;
  // Units asked for per stock pool, summed across lines — a request can split
  // one size over several lines, and a pooled product shares across sizes.
  const wanted = new Map();

  for (const line of items) {
    const id = String(line.product_id || '');
    const product = catalogue.get(id);
    if (!product) return fail(`That product is no longer available (${id}).`);

    const qty = Math.trunc(Number(line.qty));
    if (!Number.isFinite(qty) || qty < 1 || qty > 99) {
      return fail(`Invalid quantity for ${product.name}.`);
    }

    // Validate the size against the catalogue, not against what the app sent.
    const sizes = Array.isArray(product.sizes) ? product.sizes : [];
    const size = String(line.size || '');
    if (sizes.length > 0 && !sizes.includes(size)) {
      return fail(`Pick a size for ${product.name}.`);
    }

    const unit = Number(product.price);
    if (!Number.isFinite(unit) || unit < 0) {
      return fail(`${product.name} is not priced correctly. Contact support.`);
    }

    const key = stockKey(product, size);
    const pool = wanted.get(key) || { product, size, qty: 0 };
    pool.qty += qty;
    wanted.set(key, pool);

    const lineTotal = unit * qty;
    amount += lineTotal;
    priced.push({
      product_id: product.id,
      name: product.name,
      size,
      qty,
      unit_price: unit,
      line_total: lineTotal,
    });
    description.push(`${qty}x ${product.name}${size ? ` (${size})` : ''}`);
  }

  // ── Stock ──────────────────────────────────────────────────────────────────
  // Checked after pricing so every line has already been validated. Two
  // checkouts landing in the same instant can both pass — there is no lock to
  // take in a flow — so a limit can be overshot by a unit in a genuine race.
  const pools = Array.from(wanted.values());
  const limited = pools.some((p) => parseStock(p.product.stock) !== null);
  if (limited) {
    // Without the sales read we would see every unit as free. Refuse instead,
    // but only for limited products, so unlimited ones keep selling.
    if (!Array.isArray(data.sales)) {
      return fail('Stock could not be checked. Please try again shortly.');
    }
    const held = unitsHeld(data.sales, Date.now());
    for (const pool of pools) {
      const left = unitsLeft(pool.product, pool.size, held);
      if (left === null || pool.qty <= left) continue;
      const label = pool.product.name +
        (typeof parseStock(pool.product.stock) === 'number' || !pool.size
          ? '' : ` (${pool.size})`);
      return fail(left === 0
        ? `${label} is sold out.`
        : `Only ${left} left of ${label}. Reduce the quantity and try again.`);
    }
  }

  // Pesapal takes KES in whole shillings.
  const currency = String(body.currency || 'KES').toUpperCase();
  amount = currency === 'KES' ? Math.round(amount) : Math.round(amount * 100) / 100;

  // Only reachable when every line is priced 0 in shop_products — the amount
  // comes from the catalogue, so a client cannot talk its way onto this branch.
  const free = amount <= 0;
  const paidAt = free ? new Date().toISOString() : null;

  return {
    mode: 'new',
    free,
    order_id: orderId,
    amount,
    currency,

    // Ready-made reply for the free branch, same shape as flow1_respond.js.
    // A null redirect_url is what tells the app to skip the webview.
    response: free
      ? {
          order_id: orderId,
          status: 'completed',
          amount,
          currency,
          order_tracking_id: null,
          redirect_url: null,
        }
      : null,

    // → Create Data on shop_orders
    order_row: {
      id: orderId,
      // A free order is settled the moment it exists: no webhook will ever
      // arrive to complete it. Flow 2 answers a completed row from the row
      // alone, and Flow 1 treats a retry of it as already settled.
      status: free ? 'completed' : 'pending',
      paid_at: paidAt,
      payment_method: free ? 'free' : null,
      amount,
      currency,
      items: priced,

      // Who this order belongs to, for the order-history flow and reporting.
      //
      // `email` is a plain column rather than being read out of `billing`
      // because Directus cannot filter inside a JSON field — a history lookup
      // would have nothing to match on. It holds the *signed-in* address the
      // app sends, falling back to the billing one, so that a buyer who has the
      // receipt sent to a colleague still sees the order in their own history.
      attendee_id: String(body.attendee_id || '').trim() || null,
      event_id: String(body.event_id || '').trim() || null,
      email: String(body.attendee_email || billing.email_address || '')
        .trim()
        .toLowerCase(),

      billing: {
        first_name: billing.first_name,
        last_name: billing.last_name,
        email_address: billing.email_address,
        phone_number: billing.phone_number || '',
      },
    },

    // → request body of the Webhook / Request URL operation (unused when free)
    gateway_body: free ? null : {
      order: {
        id: orderId,
        description: description.join(', ').slice(0, 100),
        currency,
        amount,
        callback_url: body.callback_url,
        cancellation_url: body.cancellation_url,
        billing_address: {
          first_name: billing.first_name,
          last_name: billing.last_name,
          email_address: billing.email_address,
          phone_number: billing.phone_number || '',
        },
      },
      webhook_url: WEBHOOK_URL,
    },
  };
};
