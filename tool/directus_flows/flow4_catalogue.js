/**
 * Flow 4 "Shop — Catalogue" · Run Script operation · key: `respond`
 *
 * Returns the active catalogue so the app shows the same prices the backend
 * will charge. Before this existed the app priced from a hardcoded list while
 * Flow 1 priced from `shop_products`, so editing a price in Directus changed
 * what the buyer was charged but not what they were shown.
 *
 * This is a **public, read-only** endpoint. `shop_products` itself stays
 * private — no role can read it, and the app never touches `/items`. Only the
 * fields listed below leave the server, so an internal cost or supplier column
 * added to the collection later is not silently published.
 *
 * Expects:
 *   products — Read Data on shop_products, permissions $full,
 *              query {"filter":{"active":{"_eq":true}},"limit":500}
 *   sales    — Read Data on shop_orders, permissions $full, same query as
 *              Flow 1's `sales`. Optional: without it every limited product
 *              shows its full stock, and Flow 1 still enforces the real figure.
 */

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

/**
 * Units left per size, `{"": n}` for an unsized product, or null when
 * unlimited. Only what is left is published — never the total or sales.
 */
function availability(row, sizes, held) {
  if (parseStock(row.stock) === null) return null;
  const out = {};
  for (const size of sizes.length > 0 ? sizes : ['']) {
    out[size] = unitsLeft(row, size, held);
  }
  return out;
}

/** Fields the app is allowed to see. Anything else stays server-side. */
function publicProduct(row, held) {
  const sizes = Array.isArray(row.sizes) ? row.sizes.map(String) : [];
  return {
    id: String(row.id),
    name: String(row.name || ''),
    category: String(row.category || ''),
    price: Number(row.price),
    sizes: sizes,
    description: String(row.description || ''),
    // Optional. An http(s) value is loaded over the network by the app;
    // anything else (or null) falls back to the asset bundled for this id.
    image: row.image ? String(row.image) : null,
    available: availability(row, sizes, held),
  };
}

module.exports = async function (data) {
  const rows = Array.isArray(data.products) ? data.products : [];
  const held = unitsHeld(data.sales, Date.now());

  const products = rows
    .filter(function (row) {
      // A row with no id or an unusable price would break checkout further
      // down, where the buyer is already committed. Drop it here instead.
      return row && row.id && Number.isFinite(Number(row.price)) &&
        Number(row.price) >= 0;
    })
    .map(function (row) { return publicProduct(row, held); });

  // Sorted server-side so every client shows the catalogue in the same order
  // regardless of how Directus happened to return the rows.
  products.sort(function (a, b) {
    return a.category.localeCompare(b.category) || a.name.localeCompare(b.name);
  });

  // Category chips, derived rather than configured, so adding a product with a
  // new category needs no second edit and no app release.
  const categories = [];
  for (const p of products) {
    if (p.category && categories.indexOf(p.category) === -1) {
      categories.push(p.category);
    }
  }
  categories.sort();

  if (products.length === 0) {
    // An empty catalogue is almost always a misconfiguration (every row
    // inactive, or the Read Data operation missing $full permissions) rather
    // than a shop with nothing in it. Said plainly so the app keeps its
    // bundled fallback instead of rendering an empty grid.
    return { error: 'The catalogue is empty.' };
  }

  return {
    products: products,
    categories: categories,
    currency: 'KES',
  };
};
