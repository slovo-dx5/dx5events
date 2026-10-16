#!/usr/bin/env node
// Unit tests for the Run Script operations in this directory.
//
//   node tool/directus_flows/test_flows.mjs
//
// The scripts are plain CommonJS taking a single `data` object — the bag of
// earlier operation results Directus hands them — so they run outside Directus
// with a hand-built `data`. Debugging them in the flow builder instead costs a
// full round trip per typo and makes the payloads hard to see.
//
// Run this after editing any script here, before pasting it into Directus.

import assert from 'node:assert/strict';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const here = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
const load = (name) => require(join(here, name));

const flow1Plan = load('flow1_plan.js');
const flow2Plan = load('flow2_plan.js');
const flow2Recover = load('flow2_recover.js');
const flow2Reply = load('flow2_reply.js');
const flow3Apply = load('flow3_apply.js');
const flow3Receipt = load('flow3_receipt.js');
const flow4Catalogue = load('flow4_catalogue.js');
const flow5Orders = load('flow5_orders.js');

let passed = 0;
let failed = 0;

async function test(name, body) {
  try {
    await body();
    passed++;
    console.log(`  \x1b[32mok\x1b[0m   ${name}`);
  } catch (e) {
    failed++;
    console.log(`  \x1b[31mFAIL\x1b[0m ${name}`);
    console.log(`       ${e.message.split('\n')[0]}`);
  }
}

const PRODUCTS = [
  { id: 'ts1', name: 'Event Logo Tee', price: 2500, sizes: ['S', 'L'], active: true },
  { id: 'bp1', name: 'Everyday Backpack', price: 4800, sizes: [], active: true },
];
const BILLING = {
  first_name: 'Jane',
  last_name: 'Doe',
  email_address: 'Jane@Example.COM ',
};
const ORDER_REQUEST = {
  order_id: 'shop-1',
  currency: 'KES',
  items: [{ product_id: 'ts1', qty: 2, size: 'L' }],
  billing_address: BILLING,
  callback_url: 'https://x/cb',
  cancellation_url: 'https://x/cx',
};

// ── Flow 1: pricing, identity, idempotency ──────────────────────────────────
console.log('\nFlow 1 — create order');

await test('prices from the catalogue, never from the request', async () => {
  const r = await flow1Plan({
    products: PRODUCTS,
    existing: [],
    // Both a top-level `amount` and a per-line `price`: the shapes a tampered
    // client would send. Neither may contribute to the total.
    $trigger: { body: { ...ORDER_REQUEST, amount: 1, items: [{ product_id: 'ts1', qty: 2, size: 'L', price: 1 }] } },
  });
  assert.equal(r.mode, 'new');
  assert.equal(r.amount, 5000);
  assert.equal(r.gateway_body.order.amount, 5000);
});

await test('rejects an unknown product instead of pricing it at zero', async () => {
  const r = await flow1Plan({
    products: PRODUCTS,
    existing: [],
    $trigger: { body: { ...ORDER_REQUEST, items: [{ product_id: 'nope', qty: 1 }] } },
  });
  assert.equal(r.mode, 'error');
  assert.match(r.response.error, /no longer available/);
});

await test('validates the size against the catalogue, not the request', async () => {
  const r = await flow1Plan({
    products: PRODUCTS,
    existing: [],
    $trigger: { body: { ...ORDER_REQUEST, items: [{ product_id: 'ts1', qty: 1, size: 'XXXL' }] } },
  });
  assert.equal(r.mode, 'error');
  assert.match(r.response.error, /Pick a size/);
});

await test('history key comes from the profile, not the billing form', async () => {
  const r = await flow1Plan({
    products: PRODUCTS,
    existing: [],
    $trigger: { body: { ...ORDER_REQUEST, attendee_id: ' p-99 ', attendee_email: 'signed.in@x.com', event_id: 'ev-1' } },
  });
  assert.equal(r.order_row.attendee_id, 'p-99');
  assert.equal(r.order_row.event_id, 'ev-1');
  // The buyer may have the receipt sent elsewhere; that must not hide the order
  // from their own history.
  assert.equal(r.order_row.email, 'signed.in@x.com');
  assert.equal(r.order_row.billing.email_address, 'Jane@Example.COM ');
});

await test('falls back to the billing email, lowercased for the _eq filter', async () => {
  const r = await flow1Plan({ products: PRODUCTS, existing: [], $trigger: { body: ORDER_REQUEST } });
  assert.equal(r.order_row.email, 'jane@example.com');
  assert.equal(r.order_row.attendee_id, null, 'absent ids must be null, not ""');
});

await test('a retry resumes the same checkout instead of opening a second', async () => {
  const r = await flow1Plan({
    products: PRODUCTS,
    existing: [{ id: 'shop-1', status: 'pending', amount: 5000, redirect_url: 'https://pay/x', order_tracking_id: 'OTX' }],
    $trigger: { body: ORDER_REQUEST },
  });
  assert.equal(r.mode, 'existing');
  assert.equal(r.response.redirect_url, 'https://pay/x');
});

await test('a settled order is reported, not silently re-charged', async () => {
  const r = await flow1Plan({
    products: PRODUCTS,
    existing: [{ id: 'shop-1', status: 'failed', amount: 5000 }],
    $trigger: { body: ORDER_REQUEST },
  });
  assert.equal(r.mode, 'existing');
  assert.equal(r.response.status, 'failed');
  assert.equal(r.response.redirect_url, null);
});

const FREE_PRODUCTS = [...PRODUCTS, { id: 'st1', name: 'Sticker Pack', price: 0, sizes: [], active: true }];

await test('a paid order goes to the gateway, pending', async () => {
  const r = await flow1Plan({ products: PRODUCTS, existing: [], $trigger: { body: ORDER_REQUEST } });
  assert.equal(r.free, false);
  assert.equal(r.order_row.status, 'pending');
  assert.equal(r.order_row.paid_at, null);
  assert.equal(r.response, null);
  assert.ok(r.gateway_body, 'paid orders need a gateway body');
});

await test('a zero-amount order is created completed and skips the gateway', async () => {
  const r = await flow1Plan({
    products: FREE_PRODUCTS,
    existing: [],
    $trigger: { body: { ...ORDER_REQUEST, items: [{ product_id: 'st1', qty: 3 }] } },
  });
  // mode stays "new" so the existing is_new Condition still creates the row.
  assert.equal(r.mode, 'new');
  assert.equal(r.free, true);
  assert.equal(r.amount, 0);
  assert.equal(r.order_row.status, 'completed');
  assert.equal(r.order_row.payment_method, 'free');
  assert.ok(!Number.isNaN(Date.parse(r.order_row.paid_at)), 'paid_at must be a timestamp');
  assert.equal(r.gateway_body, null);
  // What the app parses: completed + no redirect_url → straight to confirmation.
  assert.equal(r.response.status, 'completed');
  assert.equal(r.response.redirect_url, null);
  assert.equal(r.response.order_id, 'shop-1');
});

await test('a free item alongside a paid one is still a paid order', async () => {
  const r = await flow1Plan({
    products: FREE_PRODUCTS,
    existing: [],
    $trigger: { body: { ...ORDER_REQUEST, items: [{ product_id: 'st1', qty: 1 }, { product_id: 'bp1', qty: 1 }] } },
  });
  assert.equal(r.free, false);
  assert.equal(r.amount, 4800);
  assert.equal(r.order_row.status, 'pending');
});

await test('a client cannot claim a free order for a priced product', async () => {
  const r = await flow1Plan({
    products: FREE_PRODUCTS,
    existing: [],
    $trigger: { body: { ...ORDER_REQUEST, amount: 0, items: [{ product_id: 'bp1', qty: 1, price: 0 }] } },
  });
  assert.equal(r.free, false);
  assert.equal(r.amount, 4800);
});

await test('retrying a free order reports it completed, no second row', async () => {
  const r = await flow1Plan({
    products: FREE_PRODUCTS,
    existing: [{ id: 'shop-1', status: 'completed', amount: 0, currency: 'KES' }],
    $trigger: { body: { ...ORDER_REQUEST, items: [{ product_id: 'st1', qty: 3 }] } },
  });
  assert.equal(r.mode, 'existing');
  assert.equal(r.response.status, 'completed');
  assert.equal(r.response.redirect_url, null);
});

// ── Flow 2: status + webhook recovery ───────────────────────────────────────
console.log('\nFlow 2 — order status');

const PENDING = { id: 'o1', status: 'pending', amount: 5000, currency: 'KES', order_tracking_id: 'OTX' };

await test('unknown id errors so the app stops polling', async () => {
  const r = await flow2Plan({ order: [] });
  assert.equal(r.mode, 'error');
  assert.match(r.response.error, /not found/);
});

await test('a settled order is never re-checked against the gateway', async () => {
  const r = await flow2Plan({ order: [{ ...PENDING, status: 'completed' }] });
  assert.equal(r.mode, 'reply');
});

await test('pending with no tracking id has nothing to ask about', async () => {
  const r = await flow2Plan({ order: [{ ...PENDING, order_tracking_id: null }] });
  assert.equal(r.mode, 'reply');
});

await test('pending with a tracking id goes to the gateway', async () => {
  const r = await flow2Plan({ order: [PENDING] });
  assert.equal(r.mode, 'check');
  assert.equal(r.tracking_id, 'OTX');
  assert.equal(r.order_id, 'o1');
  assert.equal(r.response.status, 'pending', 'a fallback answer must be ready');
});

const PLANNED = await flow2Plan({ order: [PENDING] });

await test('an unreachable gateway degrades to pending, not to an error', async () => {
  const r = await flow2Recover({ plan: PLANNED, gateway_status: null });
  assert.equal(r.update, null);
  assert.equal(r.response.status, 'pending');
});

await test('the gateway saying pending writes nothing (no 3s churn)', async () => {
  const r = await flow2Recover({ plan: PLANNED, gateway_status: { data: { payment_status_description: 'Pending' } } });
  assert.equal(r.update, null);
});

await test('a completed lookup settles the order and answers in one poll', async () => {
  const r = await flow2Recover({
    plan: PLANNED,
    gateway_status: { data: { payment_status_description: 'Completed', payment_method: 'MpesaKE', confirmation_code: 'ABC1' } },
  });
  assert.equal(r.update.status, 'completed');
  assert.ok(r.update.paid_at);
  assert.equal(r.response.payment_method, 'MpesaKE');
  assert.equal(r.response.confirmation_code, 'ABC1');
});

await test('Pesapal wording maps the same way as in the webhook', async () => {
  for (const [described, expected] of [['Failed', 'failed'], ['Invalid', 'failed'], ['Reversed', 'reversed']]) {
    const r = await flow2Recover({ plan: PLANNED, gateway_status: { data: { payment_status_description: described } } });
    assert.equal(r.update.status, expected, described);
    assert.equal(r.update.paid_at, null, `${described} must not set paid_at`);
  }
});

await test('the reply leaf prefers a recovered result over the stored row', async () => {
  assert.equal((await flow2Reply({ plan: PLANNED })).status, 'pending');
  assert.equal(
    (await flow2Reply({ plan: PLANNED, recover: { response: { status: 'completed' } } })).status,
    'completed');
});

await test('a broken flow errors rather than inventing a status', async () => {
  assert.ok((await flow2Reply({})).error);
});

// ── Flow 3: webhook ────────────────────────────────────────────────────────
console.log('\nFlow 3 — webhook');

const SECRET = 'sekrit-value-123';
const secretRow = [{ value: SECRET }];
const ipn = (over) => ({
  $trigger: {
    headers: { 'x-webhook-secret': SECRET },
    body: { merchant_reference: 'o1', payment_status_description: 'Completed', payment_method: 'Visa', confirmation_code: 'C1', ...over },
  },
  secret_row: secretRow,
  order: [PENDING],
});

await test('a wrong secret is rejected', async () => {
  await assert.rejects(
    () => flow3Apply({ ...ipn(), $trigger: { headers: { 'x-webhook-secret': 'wrong' }, body: { merchant_reference: 'o1' } } }),
    /Unauthorized/);
});

await test('a missing secret is rejected, and so is an empty stored one', async () => {
  await assert.rejects(() => flow3Apply({ ...ipn(), $trigger: { headers: {}, body: {} } }), /Unauthorized/);
  await assert.rejects(() => flow3Apply({ ...ipn(), secret_row: [{ value: '' }], $trigger: { headers: { 'x-webhook-secret': '' }, body: {} } }), /Unauthorized/);
});

await test('a valid notification settles the order', async () => {
  const r = await flow3Apply(ipn());
  assert.equal(r.status, 'completed');
  assert.equal(r.update.payment_method, 'Visa');
  assert.ok(r.update.paid_at);
});

await test('a duplicate IPN is a no-op, so side effects happen once', async () => {
  const r = await flow3Apply({ ...ipn(), order: [{ ...PENDING, status: 'completed' }] });
  assert.equal(r.skipped, 'already paid');
  assert.equal(r.update, undefined);
});

await test('an unknown order returns normally — the gateway does not retry', async () => {
  const r = await flow3Apply({ ...ipn(), order: [] });
  assert.equal(r.skipped, 'unknown order');
});

// ── Receipt ────────────────────────────────────────────────────────────────
console.log('\nReceipt email');

const PAID_ORDER = {
  id: 'shop-1',
  email: 'signed.in@x.com',
  billing: { email_address: 'buyer@x.com' },
  currency: 'KES',
  amount: 8000,
  items: [
    { name: 'Event Logo Tee', size: 'L', qty: 2, line_total: 5000 },
    { name: 'Cap', qty: 1, line_total: 3000 },
  ],
};

await test('the receipt goes where the buyer asked, not to the account', async () => {
  const r = await flow3Receipt({ order: [PAID_ORDER], apply: { update: { payment_method: 'MpesaKE', confirmation_code: 'XYZ' } } });
  assert.equal(r.to, 'buyer@x.com');
  assert.match(r.subject, /shop-1/);
});

await test('falls back to the account address when there is no billing one', async () => {
  const r = await flow3Receipt({ order: [{ ...PAID_ORDER, billing: {} }], apply: {} });
  assert.equal(r.to, 'signed.in@x.com');
});

await test('no address skips instead of failing a paid order', async () => {
  const r = await flow3Receipt({ order: [{ ...PAID_ORDER, email: '', billing: {} }], apply: {} });
  assert.equal(r.skipped, 'no email address');
});

await test('amounts are grouped in the HTML table', async () => {
  const r = await flow3Receipt({ order: [PAID_ORDER], apply: { update: { payment_method: 'MpesaKE' } } });
  assert.match(r.body, /Event Logo Tee \(L\)<\/td><td[^>]*>2<\/td><td[^>]*>KES 5,000</);
  assert.match(r.body, /Total paid<\/strong><\/td><td[^>]*><strong>KES 8,000</);
});

await test('the mailer request is exactly the shape the mailer takes', async () => {
  const r = await flow3Receipt({ order: [PAID_ORDER], apply: { update: {} } });
  assert.deepEqual(Object.keys(r.request).sort(), ['body', 'emailAddress', 'from', 'subject']);
  assert.equal(r.request.emailAddress, 'buyer@x.com');
  assert.equal(r.request.body, r.body);
});

await test('typed text is escaped, not injected into the email', async () => {
  const r = await flow3Receipt({
    order: [{ ...PAID_ORDER, billing: { email_address: 'b@x.com', first_name: '<b>Eve</b>' },
      items: [{ name: '<script>x</script>', qty: 1, line_total: 1 }] }],
    apply: { update: {} },
  });
  assert.equal(r.body.includes('<script>'), false);
  assert.equal(r.body.includes('<b>Eve'), false);
  assert.match(r.body, /&lt;script&gt;/);
});

await test('a free order from Flow 1 gets a receipt without "Paid with: free"', async () => {
  const r = await flow3Receipt({ plan: { order_row: { ...PAID_ORDER, amount: 0, payment_method: 'free' } } });
  assert.equal(r.to, 'buyer@x.com');
  assert.match(r.body, /<strong>Free<\/strong>/);
  assert.equal(r.body.includes('Paid with'), false);
  assert.equal(r.body.includes('Total paid'), false);
});

await test('details the gateway did not send are omitted, not printed as null', async () => {
  const r = await flow3Receipt({ order: [PAID_ORDER], recover: { update: {} } });
  assert.equal(r.body.includes('null'), false);
  assert.equal(r.body.includes('Paid with'), false);
});

await test('the recovery path produces the same receipt as the webhook', async () => {
  const viaWebhook = await flow3Receipt({ order: [PAID_ORDER], apply: { update: { payment_method: 'Visa' } } });
  const viaRecovery = await flow3Receipt({ order: [PAID_ORDER], recover: { update: { payment_method: 'Visa' } } });
  assert.equal(viaRecovery.body, viaWebhook.body);
});

// ── Flow 4: catalogue ──────────────────────────────────────────────────────
console.log('\nFlow 4 — catalogue');

await test('an empty catalogue errors so the app keeps its bundled list', async () => {
  assert.ok((await flow4Catalogue({ products: [] })).error);
});

await test('sorts, derives categories, and drops unusable rows', async () => {
  const r = await flow4Catalogue({
    products: [
      { id: 'hd1', name: 'Hoodie', category: 'Hoodies', price: 5500, sizes: ['S'] },
      { id: 'ts1', name: 'Tee', category: 'T-Shirts', price: 2500, sizes: ['L'] },
      { id: 'bad', name: 'Unpriced', category: 'X', price: 'abc' },
    ],
  });
  assert.deepEqual(r.products.map((p) => p.id), ['hd1', 'ts1']);
  assert.deepEqual(r.categories, ['Hoodies', 'T-Shirts']);
});

await test('publishes only the listed fields', async () => {
  const r = await flow4Catalogue({
    products: [{ id: 'ts1', name: 'Tee', category: 'T', price: 2500, cost_price: 900, supplier: 'ACME' }],
  });
  assert.equal('cost_price' in r.products[0], false);
  assert.equal('supplier' in r.products[0], false);
});

// ── Stock ───────────────────────────────────────────────────────────────────
console.log('\nStock');

const NOW = Date.now();
const minsAgo = (m) => new Date(NOW - m * 60000).toISOString();
const sold = (status, items, age = 1) => ({ status, date_created: minsAgo(age), items });
const TEE = { id: 'ts1', name: 'Event Logo Tee', price: 2500, sizes: ['S', 'L'], active: true };
const BAG = { id: 'bp1', name: 'Everyday Backpack', price: 4800, sizes: [], active: true };
const order = (items) => ({ ...ORDER_REQUEST, items });
const plan = (products, items, sales) => flow1Plan({ products, existing: [], sales, $trigger: { body: order(items) } });

await test('the stock logic is identical in Flow 1 and Flow 4', async () => {
  const { readFileSync } = await import('node:fs');
  const block = (f) => readFileSync(join(here, f), 'utf8').replace(/\r\n/g, '\n')
    .match(/^\/\/ ── Stock ─+\n[\s\S]*?^\/\/ ─{20,}$/m)?.[0];
  assert.ok(block('flow1_plan.js'), 'block not found in flow1_plan.js');
  assert.equal(block('flow1_plan.js'), block('flow4_catalogue.js'));
});

await test('no stock set means unlimited, and needs no sales read', async () => {
  const r = await plan([TEE], [{ product_id: 'ts1', qty: 99, size: 'L' }], undefined);
  assert.equal(r.mode, 'new');
});

await test('per-size stock: completed and fresh pending orders hold units', async () => {
  const tee = { ...TEE, stock: { S: 5, L: 3 } };
  const sales = [
    sold('completed', [{ product_id: 'ts1', size: 'L', qty: 1 }], 600),
    sold('pending', [{ product_id: 'ts1', size: 'L', qty: 1 }], 5),
  ];
  assert.equal((await plan([tee], [{ product_id: 'ts1', qty: 1, size: 'L' }], sales)).mode, 'new');
  const r = await plan([tee], [{ product_id: 'ts1', qty: 2, size: 'L' }], sales);
  assert.equal(r.mode, 'error');
  assert.equal(r.response.error, 'Only 1 left of Event Logo Tee (L). Reduce the quantity and try again.');
  // Other sizes are unaffected.
  assert.equal((await plan([tee], [{ product_id: 'ts1', qty: 5, size: 'S' }], sales)).mode, 'new');
});

await test('stale pending, failed and cancelled orders release their units', async () => {
  const tee = { ...TEE, stock: { L: 2 } };
  const sales = [
    sold('pending', [{ product_id: 'ts1', size: 'L', qty: 2 }], 31),
    sold('failed', [{ product_id: 'ts1', size: 'L', qty: 2 }]),
    sold('cancelled', [{ product_id: 'ts1', size: 'L', qty: 2 }]),
    { status: 'pending', date_created: null, items: [{ product_id: 'ts1', size: 'L', qty: 2 }] },
  ];
  assert.equal((await plan([tee], [{ product_id: 'ts1', qty: 2, size: 'L' }], sales)).mode, 'new');
});

await test('a size missing from the stock map is sold out', async () => {
  const r = await plan([{ ...TEE, stock: { S: 5 } }], [{ product_id: 'ts1', qty: 1, size: 'L' }], []);
  assert.equal(r.response.error, 'Event Logo Tee (L) is sold out.');
});

await test('a number is one pool shared across sizes', async () => {
  const tee = { ...TEE, stock: 4 };
  const sales = [sold('completed', [{ product_id: 'ts1', size: 'S', qty: 3 }])];
  const r = await plan([tee], [{ product_id: 'ts1', qty: 2, size: 'L' }], sales);
  assert.equal(r.response.error, 'Only 1 left of Event Logo Tee. Reduce the quantity and try again.');
});

await test('lines are summed, so splitting a request cannot dodge the limit', async () => {
  const bag = { ...BAG, stock: 3 };
  const r = await plan([bag], [{ product_id: 'bp1', qty: 2 }, { product_id: 'bp1', qty: 2 }], []);
  assert.equal(r.response.error, 'Only 3 left of Everyday Backpack. Reduce the quantity and try again.');
});

await test('stock as a JSON string (how some Directus setups return it) works', async () => {
  const r = await plan([{ ...BAG, stock: '1' }], [{ product_id: 'bp1', qty: 2 }], []);
  assert.match(r.response.error, /Only 1 left/);
  const t = await plan([{ ...TEE, stock: '{"L":1}' }], [{ product_id: 'ts1', qty: 1, size: 'L' }], []);
  assert.equal(t.mode, 'new');
});

await test('unreadable stock is sold out, not unlimited', async () => {
  const r = await plan([{ ...BAG, stock: 'lots' }], [{ product_id: 'bp1', qty: 1 }], []);
  assert.equal(r.response.error, 'Everyday Backpack is sold out.');
});

await test('limited stock without the sales read refuses; unlimited still sells', async () => {
  const r = await plan([{ ...BAG, stock: 10 }, TEE], [{ product_id: 'bp1', qty: 1 }], undefined);
  assert.match(r.response.error, /Stock could not be checked/);
  const u = await plan([{ ...BAG, stock: 10 }, TEE], [{ product_id: 'ts1', qty: 1, size: 'L' }], undefined);
  assert.equal(u.mode, 'new');
});

await test('a retry of an existing order skips the stock check', async () => {
  const r = await flow1Plan({
    products: [{ ...BAG, stock: 0 }],
    existing: [{ id: 'shop-1', status: 'pending', amount: 4800, redirect_url: 'https://pay/x' }],
    sales: [],
    $trigger: { body: order([{ product_id: 'bp1', qty: 1 }]) },
  });
  assert.equal(r.mode, 'existing');
});

await test('catalogue publishes units left per size, never totals', async () => {
  const r = await flow4Catalogue({
    products: [
      { ...TEE, category: 'T', stock: { S: 5, L: 3 } },
      { ...BAG, category: 'B', stock: 2 },
      { id: 'jk1', name: 'Jacket', category: 'J', price: 8900, sizes: ['M'] },
    ],
    sales: [
      sold('completed', [{ product_id: 'ts1', size: 'L', qty: 3 }, { product_id: 'bp1', size: '', qty: 1 }]),
    ],
  });
  const by = Object.fromEntries(r.products.map((p) => [p.id, p]));
  assert.deepEqual(by.ts1.available, { S: 5, L: 0 });
  assert.deepEqual(by.bp1.available, { '': 1 });
  assert.equal(by.jk1.available, null);
  assert.equal('stock' in by.ts1, false);
});

await test('catalogue without a sales read shows full stock rather than failing', async () => {
  const r = await flow4Catalogue({ products: [{ ...BAG, category: 'B', stock: 2 }] });
  assert.deepEqual(r.products[0].available, { '': 2 });
});

await test('catalogue sends an uploaded photo as a resized asset URL', async () => {
  const uuid = '0f8b2c9e-1d3a-4b5c-8e7f-123456789abc';
  const r = await flow4Catalogue({
    products: [
      { ...BAG, category: 'B', product_image: uuid, product_description: 'Roomy.' },
      { ...TEE, category: 'T', product_image: { id: uuid } },
      { id: 'hd1', name: 'Hoodie', category: 'H', price: 5500, image: 'https://cdn.example/h.jpg' },
      { id: 'jk1', name: 'Jacket', category: 'J', price: 8900, image: 'not-a-url', product_image: 'nope' },
    ],
  });
  const by = Object.fromEntries(r.products.map((p) => [p.id, p]));
  assert.equal(by.bp1.image, `https://subscriptions.cioafrica.co/assets/${uuid}?width=800&quality=80`);
  assert.equal(by.bp1.description, 'Roomy.');
  assert.equal(by.ts1.image, by.bp1.image, 'an expanded file object works too');
  assert.equal(by.hd1.image, 'https://cdn.example/h.jpg', 'a pasted URL still works');
  assert.equal(by.jk1.image, null, 'junk falls back to the bundled photo');
  assert.equal('product_image' in by.bp1, false);
});

// ── Flow 5: order history ──────────────────────────────────────────────────
console.log('\nFlow 5 — my orders');

await test('refuses a half-filled lookup instead of widening it', async () => {
  assert.ok((await flow5Orders({ $trigger: { body: { email: 'a@b.c' } } })).error);
  assert.ok((await flow5Orders({ $trigger: { body: { attendee_id: 'p1' } } })).error);
  assert.ok((await flow5Orders({ $trigger: { body: {} } })).error);
});

await test('both halves of the key must match, whatever the query returned', async () => {
  const r = await flow5Orders({
    $trigger: { body: { attendee_id: 'p1', email: 'A@B.c' } },
    orders: [
      { id: 'mine', attendee_id: 'p1', email: 'a@b.c', status: 'completed', amount: 2500, items: [{ name: 'Tee', qty: 1, line_total: 2500 }] },
      { id: 'same-email-other-person', attendee_id: 'p2', email: 'a@b.c', amount: 1 },
      { id: 'same-person-other-email', attendee_id: 'p1', email: 'other@b.c', amount: 1 },
    ],
  });
  assert.deepEqual(r.orders.map((o) => o.order_id), ['mine']);
});

await test('withholds the billing block', async () => {
  const r = await flow5Orders({
    $trigger: { body: { attendee_id: 'p1', email: 'a@b.c' } },
    orders: [{ id: 'o1', attendee_id: 'p1', email: 'a@b.c', amount: 1, billing: { phone_number: '+254700000000' } }],
  });
  assert.equal('billing' in r.orders[0], false);
  assert.equal(JSON.stringify(r).includes('254700000000'), false);
});

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed === 0 ? 0 : 1);
