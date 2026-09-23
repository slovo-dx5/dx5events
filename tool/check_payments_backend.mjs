#!/usr/bin/env node
// Verifies the shop-payments backend against a live Directus instance.
//
// Run it yourself — it reads the token from the environment and never prints
// it, so the credential stays on your machine:
//
//   DIRECTUS_TOKEN=<static token> node tool/check_payments_backend.mjs
//
// Optional:
//   DIRECTUS_URL=https://subscriptions.cioafrica.co   (default)
//   PAYMENTS_CREATE_ORDER_FLOW_ID / PAYMENTS_ORDER_STATUS_FLOW_ID
//     — if unset, they're read from assets/.env so this checks the same values
//       the app will actually use.
//
// The token needs read access to `directus_collections`, `directus_fields` and
// `directus_flows`. A read-only role is enough; don't use an admin password.
//
// This is a checklist you can re-run as you build each piece — it's expected
// to fail loudly on a fresh instance. See docs/features/shop-payments-backend.md.

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), '..');

const TOKEN = process.env.DIRECTUS_TOKEN;
if (!TOKEN) {
  console.error('DIRECTUS_TOKEN is not set. Create a static token on a\n' +
    'read-only Directus user (User → Token) and pass it in the environment:\n\n' +
    '  DIRECTUS_TOKEN=… node tool/check_payments_backend.mjs\n');
  process.exit(2);
}

/** Reads assets/.env so we check the ids the app is actually configured with. */
function appEnv() {
  const out = {};
  try {
    const text = readFileSync(join(repoRoot, 'assets', '.env'), 'utf8');
    for (const line of text.split(/\r?\n/)) {
      const t = line.trim();
      if (!t || t.startsWith('#')) continue;
      const eq = t.indexOf('=');
      if (eq <= 0) continue;
      out[t.slice(0, eq).trim()] = t.slice(eq + 1).trim().replace(/^["']|["']$/g, '');
    }
  } catch {
    // No .env — fall back to process env only.
  }
  return out;
}

const env = appEnv();
const BASE = (process.env.DIRECTUS_URL || env.PAYMENTS_DIRECTUS_URL ||
  'https://subscriptions.cioafrica.co').replace(/\/+$/, '');
const CREATE_FLOW = process.env.PAYMENTS_CREATE_ORDER_FLOW_ID ||
  env.PAYMENTS_CREATE_ORDER_FLOW_ID || '';
const STATUS_FLOW = process.env.PAYMENTS_ORDER_STATUS_FLOW_ID ||
  env.PAYMENTS_ORDER_STATUS_FLOW_ID || '';
const CATALOGUE_FLOW = process.env.PAYMENTS_CATALOGUE_FLOW_ID ||
  env.PAYMENTS_CATALOGUE_FLOW_ID || '';
const HISTORY_FLOW = process.env.PAYMENTS_ORDER_HISTORY_FLOW_ID ||
  env.PAYMENTS_ORDER_HISTORY_FLOW_ID || '';

// Mirrors docs/features/shop-payments-backend.md. Fields the app's wire format
// depends on; extra fields in Directus are fine.
const REQUIRED = {
  app_secrets: ['key', 'value'],
  shop_products: ['id', 'name', 'category', 'price', 'sizes', 'active'],
  shop_orders: ['id', 'status', 'amount', 'currency', 'order_tracking_id',
    'items', 'billing', 'payment_method', 'confirmation_code', 'paid_at',
    'raw_payment'],
};

// Fields only some features need. Missing ones are warnings, not failures —
// checkout works without them.
const OPTIONAL = {
  shop_products: {
    description: 'shown on the product page; blank without it',
    image: 'lets a product added after the last release have a picture',
  },
  shop_orders: {
    attendee_id: 'half the order-history lookup key (Flow 5)',
    email: 'the other half — an order without it appears in no history',
    event_id: 'reporting only',
    date_created: 'Directus "Created On"; sorts the order-history list',
  },
};

// The bundled fallback ids in lib/screens/shop/shop_repository.dart. The app
// sends them verbatim, so an unseeded id 400s every order creation — and their
// prices there must match this collection, or an offline buyer is shown one
// price and charged another.
const SEED_IDS = ['ts1', 'hd1', 'bp1', 'jk1'];

let failures = 0;
let warnings = 0;
const pass = (m) => console.log(`  [32mPASS[0m  ${m}`);
const fail = (m, hint) => {
  failures++;
  console.log(`  [31mFAIL[0m  ${m}`);
  if (hint) console.log(`        ↳ ${hint}`);
};
const warn = (m, hint) => {
  warnings++;
  console.log(`  [33mWARN[0m  ${m}`);
  if (hint) console.log(`        ↳ ${hint}`);
};

async function api(path) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { Authorization: `Bearer ${TOKEN}` },
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`${res.status} ${res.statusText} — ${body.slice(0, 200)}`);
  }
  return res.json();
}

async function main() {
  console.log(`\nChecking ${BASE}\n`);

  console.log('Connectivity');
  try {
    const me = await api('/users/me?fields=id,email,role.name,role.admin_access');
    const role = me.data?.role;
    pass(`authenticated (role: ${role?.name ?? 'unknown'})`);
    if (role?.admin_access) {
      warn('this token has admin access',
        'a read-only role is enough for these checks');
    }
  } catch (e) {
    fail(`could not authenticate: ${e.message}`,
      'check DIRECTUS_URL and that the token is a valid static token');
    return report();
  }

  console.log('\nCollections');
  let collections = [];
  try {
    const res = await api('/collections');
    collections = res.data.map((c) => c.collection);
  } catch (e) {
    fail(`could not list collections: ${e.message}`);
    return report();
  }

  for (const [name, fields] of Object.entries(REQUIRED)) {
    if (!collections.includes(name)) {
      fail(`\`${name}\` does not exist`,
        'see docs/features/shop-payments-backend.md → "Collections to provision"');
      continue;
    }
    pass(`\`${name}\` exists`);
    try {
      const res = await api(`/fields/${name}`);
      const present = new Set(res.data.map((f) => f.field));
      const missing = fields.filter((f) => !present.has(f));
      if (missing.length) {
        fail(`\`${name}\` is missing: ${missing.join(', ')}`);
      } else {
        pass(`\`${name}\` has every field the app expects`);
      }
      const optional = OPTIONAL[name] ?? {};
      for (const [field, why] of Object.entries(optional)) {
        if (!present.has(field)) warn(`\`${name}.${field}\` is missing`, why);
      }
    } catch (e) {
      warn(`could not read fields of \`${name}\`: ${e.message}`);
    }
  }

  if (collections.includes('shop_products')) {
    console.log('\nCatalogue seeding');
    try {
      const res = await api(
        `/items/shop_products?fields=id,price,active&filter[id][_in]=${SEED_IDS.join(',')}&limit=100`);
      const found = new Map(res.data.map((p) => [String(p.id), p]));
      const missing = SEED_IDS.filter((id) => !found.has(id));
      if (missing.length) {
        fail(`not seeded: ${missing.join(', ')}`,
          'these ids are hardcoded in lib/screens/shop/shop_repository.dart — ' +
          'the app sends them verbatim');
      } else {
        pass(`all ${SEED_IDS.length} POC products seeded`);
      }
      for (const [id, p] of found) {
        if (p.active === false) warn(`\`${id}\` exists but is inactive`);
        if (p.price == null || Number(p.price) < 0) {
          fail(`\`${id}\` has no usable price (${p.price})`);
        }
      }
      const zero = [...found.values()].filter((p) => Number(p.price) === 0);
      if (zero.length) {
        pass(`${zero.length} zero-priced product(s) — usable for a no-money demo`);
      } else {
        warn('no zero-priced product',
          'seed one to demo the free-order path without spending money');
      }
    } catch (e) {
      warn(`could not read shop_products: ${e.message}`,
        'the token may lack read permission on this collection');
    }
  }

  if (collections.includes('app_secrets')) {
    console.log('\nSecret exposure');

    // The app ships a static Directus bearer token inside the APK, so anything
    // that token can read is effectively public. This is the check that matters
    // most when credentials live in a collection rather than in server env.
    let appToken = null;
    try {
      const src = readFileSync(
        join(repoRoot, 'lib', 'dioServices', 'dioClient.dart'), 'utf8');
      const m = src.match(/Bearer\s+([A-Za-z0-9_-]{16,})/);
      if (m) appToken = m[1];
    } catch { /* file moved — handled below */ }

    if (!appToken) {
      warn('could not find the app token in lib/dioServices/dioClient.dart',
        'check by hand that the app role cannot read app_secrets');
    } else {
      for (const path of ['/items/app_secrets?limit=1', '/collections/app_secrets']) {
        const res = await fetch(`${BASE}${path}`, {
          headers: { Authorization: `Bearer ${appToken}` },
        }).catch(() => null);
        if (!res) { warn(`could not test ${path} with the app token`); continue; }
        if (res.ok) {
          fail(`the app's shipped token can read ${path}`,
            'that token is extractable from the APK — revoke this role\'s access ' +
            'to app_secrets, then rotate the gateway credentials');
        } else {
          pass(`app token is denied ${path} (${res.status})`);
        }
      }
    }

    // Only row presence is checked; values are never read or printed.
    try {
      const res = await api('/items/app_secrets?fields=key&limit=100');
      const keys = new Set(res.data.map((r) => String(r.key)));
      for (const k of ['pesapal_gateway_api_key', 'pesapal_webhook_secret']) {
        if (keys.has(k)) pass(`\`${k}\` is present`);
        else fail(`\`${k}\` is missing from app_secrets`);
      }
      warn("this checker's own token can list app_secrets",
        'prefer a token that cannot, unless you are deliberately running as admin');
    } catch {
      pass("this checker's token cannot read app_secrets (as it should not)");
      console.log('        ↳ row presence not verified — confirm by hand');
    }
  }

  console.log('\nFlows');
  let flows = [];
  try {
    const res = await api('/flows?fields=id,name,status,trigger,options&limit=200');
    flows = res.data;
    pass(`${flows.length} flow(s) visible`);
  } catch (e) {
    warn(`could not list flows: ${e.message}`,
      'needs read access to directus_flows; skipping flow checks');
    return report();
  }

  const checkFlow = (id, label, wantSync) => {
    if (!id) {
      fail(`${label}: no flow id configured`,
        'fill it into assets/.env once the flow exists — until both ids are ' +
        'set the app silently falls back to the demo checkout');
      return;
    }
    const flow = flows.find((f) => f.id === id);
    if (!flow) {
      fail(`${label}: no flow with id ${id}`,
        'the id in assets/.env does not match any flow on this instance');
      return;
    }
    pass(`${label}: found "${flow.name}"`);
    if (flow.status !== 'active') {
      fail(`${label}: status is "${flow.status}", not "active"`);
    }
    if (flow.trigger !== 'webhook') {
      fail(`${label}: trigger is "${flow.trigger}", expected "webhook"`);
    }
    const opts = flow.options ?? {};
    const methods = [].concat(opts.method ?? []).map((m) => String(m).toUpperCase());
    if (methods.length && !methods.includes('POST')) {
      fail(`${label}: does not accept POST (accepts ${methods.join(', ')})`,
        'the app POSTs to /flows/trigger/<id>');
    }
    if (wantSync && opts.async === true) {
      fail(`${label}: set to asynchronous`,
        'must be synchronous with response mode "data of last operation", or ' +
        'the app receives an empty body instead of redirect_url');
    }
    if (wantSync && opts.return !== undefined && opts.return !== 'last') {
      warn(`${label}: response mode is "${opts.return}", expected "last"`);
    }
  };

  checkFlow(CREATE_FLOW, 'Flow 1 (create order)', true);
  checkFlow(STATUS_FLOW, 'Flow 2 (order status)', true);

  // Optional flows. An unset id is a feature switched off, not a fault — the app
  // hides "My orders" and uses its bundled catalogue. A *wrong* id is a fault.
  for (const [id, label] of [
    [CATALOGUE_FLOW, 'Flow 4 (catalogue)'],
    [HISTORY_FLOW, 'Flow 5 (my orders)'],
  ]) {
    if (!id) {
      warn(`${label}: not configured`,
        'optional — the app falls back rather than failing. See ' +
        'tool/directus_flows/README.md');
      continue;
    }
    checkFlow(id, label, true);
  }

  const webhookFlow = flows.find((f) =>
    f.trigger === 'webhook' && f.id !== CREATE_FLOW && f.id !== STATUS_FLOW &&
    /webhook|pesapal|payment|ipn/i.test(f.name ?? ''));
  if (webhookFlow) {
    pass(`Flow 3 (gateway webhook): likely "${webhookFlow.name}"`);
    console.log(`        ↳ webhook_url should be ${BASE}/flows/trigger/${webhookFlow.id}`);
  } else {
    warn('Flow 3 (gateway webhook): not found by name',
      'this is the only signal that actually marks an order paid — its URL is ' +
      'what Flow 1 passes as webhook_url');
  }

  // ── Operation graph ──────────────────────────────────────────────────────
  // The trigger-level checks above cannot see inside a flow, and several of
  // these flows answer *correctly* even when a whole branch is missing — a
  // Flow 2 whose gateway branch was never wired replies to a pending order
  // exactly as a working one does. So check the operations themselves.
  console.log('\nOperation graph');

  // key → Directus operation type.
  const EXPECTED_OPS = {
    [CREATE_FLOW]: {
      label: 'Flow 1',
      ops: {
        api_key_row: 'item-read', products: 'item-read', existing: 'item-read',
        plan: 'exec', is_new: 'condition', create: 'item-create',
        gateway: 'request', track: 'item-update', respond: 'exec',
        respond_existing: 'exec',
      },
    },
    [STATUS_FLOW]: {
      label: 'Flow 2',
      ops: {
        api_key_row: 'item-read', order: 'item-read', plan: 'exec',
        needs_check: 'condition', gateway_status: 'request', recover: 'exec',
        has_update: 'condition', write: 'item-update',
        reply_recovered: 'exec', reply_unchanged: 'exec',
        reply_stored: 'exec', reply_gateway_down: 'exec',
      },
      // Reject connectors that must be wired, and why.
      rejects: {
        gateway_status: 'an unreachable gateway must degrade to "still ' +
          'pending" — the app abandons polling after 5 failed calls, so a ' +
          'flow that dies here breaks confirmation for orders the webhook ' +
          'would have settled anyway',
        needs_check: 'a settled order has no branch to answer on otherwise',
        has_update: 'a gateway that says "pending" has nothing to write',
      },
    },
    [CATALOGUE_FLOW]: {
      label: 'Flow 4',
      ops: { products: 'item-read', respond: 'exec' },
    },
    [HISTORY_FLOW]: {
      label: 'Flow 5',
      ops: { orders: 'item-read', respond: 'exec' },
    },
  };

  for (const [flowId, spec] of Object.entries(EXPECTED_OPS)) {
    if (!flowId || !flows.some((f) => f.id === flowId)) continue;
    let ops;
    try {
      const res = await api(
        `/operations?filter[flow][_eq]=${flowId}&fields=id,key,type,resolve,reject&limit=100`);
      ops = res.data;
    } catch (e) {
      warn(`${spec.label}: could not read operations: ${e.message}`,
        'needs read access to directus_operations');
      continue;
    }

    const byKey = new Map(ops.map((o) => [o.key, o]));
    const missing = [];
    const wrongType = [];
    for (const [key, type] of Object.entries(spec.ops)) {
      const op = byKey.get(key);
      if (!op) { missing.push(key); continue; }
      if (type && op.type !== type) {
        wrongType.push(`${key} is "${op.type}", expected "${type}"`);
      }
    }

    if (missing.length) {
      fail(`${spec.label}: missing operation(s): ${missing.join(', ')}`,
        'the scripts read earlier results out of `data` by these exact keys, ' +
        'so a renamed operation silently reads undefined — see ' +
        'tool/directus_flows/README.md');
    } else {
      pass(`${spec.label}: all ${Object.keys(spec.ops).length} operations present`);
    }
    for (const m of wrongType) fail(`${spec.label}: ${m}`);

    for (const [key, why] of Object.entries(spec.rejects ?? {})) {
      const op = byKey.get(key);
      if (!op) continue;
      if (!op.reject) fail(`${spec.label}: "${key}" has no reject branch`, why);
      else pass(`${spec.label}: "${key}" reject branch is wired`);
    }

    const extra = ops.map((o) => o.key)
      .filter((k) => k && !(k in spec.ops) &&
        !['is_paid', 'receipt', 'mail'].includes(k));
    if (extra.length) {
      warn(`${spec.label}: unrecognised operation(s): ${extra.join(', ')}`,
        'harmless if deliberate — listed in case one is a typo of an ' +
        'expected key');
    }
  }

  console.log('\nApp config (assets/.env)');
  for (const key of ['PAYMENTS_CALLBACK_URL', 'PAYMENTS_CANCEL_URL']) {
    const v = env[key];
    if (!v) { fail(`${key} is not set`); continue; }
    if (!v.startsWith('https://')) fail(`${key} is not https`);
    else pass(`${key} = ${v}`);
  }
  const cb = env.PAYMENTS_CALLBACK_URL, cx = env.PAYMENTS_CANCEL_URL;
  if (cb && cx) {
    // PesapalCheckoutScreen matches these by prefix, so one containing the
    // other would make cancellation indistinguishable from success.
    if (cb.startsWith(cx) || cx.startsWith(cb)) {
      fail('callback and cancellation URLs are prefixes of each other',
        'the checkout webview matches them by prefix — these must be distinct');
    } else {
      pass('callback and cancellation URLs are distinct');
    }
  }

  report();
}

function report() {
  console.log('\n' + '─'.repeat(60));
  if (failures === 0 && warnings === 0) {
    console.log('[32mEverything checks out.[0m');
  } else {
    console.log(`${failures} failure(s), ${warnings} warning(s).`);
    console.log('Details: docs/features/shop-payments-backend.md');
  }
  console.log('');
  process.exit(failures ? 1 : 0);
}

main().catch((e) => {
  console.error(`\nUnexpected error: ${e.message}`);
  process.exit(2);
});
