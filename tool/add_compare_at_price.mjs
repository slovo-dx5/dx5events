// Adds `shop_products.compare_at_price`: the struck-through "was" price shown
// next to `price` in the app (KES 300, was KES 500). Display only — Flow 1
// always charges `price`. Flow 4 publishes it only when it is above `price`.
//
// Run it yourself — it reads the token from the environment and never prints
// it. Safe to re-run: does nothing if the field already exists.
//
//   DIRECTUS_TOKEN=<admin static token> node tool/add_compare_at_price.mjs
//   node tool/add_compare_at_price.mjs --dry-run     (shows the payload only)

const URL_BASE = (process.env.DIRECTUS_URL || 'https://subscriptions.cioafrica.co').replace(/\/$/, '');
const TOKEN = process.env.DIRECTUS_TOKEN;
const dryRun = process.argv.includes('--dry-run');
const COLLECTION = 'shop_products';
const FIELD = 'compare_at_price';

if (!TOKEN && !dryRun) {
  console.error('DIRECTUS_TOKEN is not set. See the header of this file.');
  process.exit(1);
}

async function api(method, path, body) {
  const res = await fetch(URL_BASE + path, {
    method,
    headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let json = null;
  try { json = text ? JSON.parse(text) : null; } catch { /* not JSON */ }
  return { status: res.status, json, text };
}

// Same storage type as `price`, so the two compare like for like.
let type = 'decimal';
let schemaExtra = { numeric_precision: 10, numeric_scale: 2 };
if (TOKEN) {
  const price = await api('GET', `/fields/${COLLECTION}/price`);
  if (price.status !== 200) {
    console.error(`Could not read ${COLLECTION}.price (HTTP ${price.status}): ${price.text.slice(0, 300)}`);
    process.exit(1);
  }
  const f = price.json.data;
  type = f.type;
  schemaExtra = type === 'decimal'
    ? { numeric_precision: f.schema?.numeric_precision ?? 10, numeric_scale: f.schema?.numeric_scale ?? 2 }
    : {};
  console.log(`price is ${type}${type === 'decimal' ? ` (${schemaExtra.numeric_precision},${schemaExtra.numeric_scale})` : ''}`);

  const existing = await api('GET', `/fields/${COLLECTION}/${FIELD}`);
  if (existing.status === 200) {
    console.log(`${COLLECTION}.${FIELD} already exists (type ${existing.json.data.type}). Nothing to do.`);
    process.exit(0);
  }
}

const payload = {
  field: FIELD,
  type,
  schema: { is_nullable: true, default_value: null, ...schemaExtra },
  meta: {
    interface: 'input',
    special: null,
    width: 'half',
    required: false,
    note: 'Optional "was" price, shown struck through next to Price. To discount ' +
      'KES 500 to KES 300: set Price = 300 and this = 500. Buyers are always ' +
      'charged Price. Leave empty (or not above Price) for no discount.',
    options: { placeholder: 'e.g. 500 (leave empty for no discount)' },
  },
};

if (dryRun) {
  console.log('Dry run — would POST', `/fields/${COLLECTION}`, JSON.stringify(payload, null, 2));
  process.exit(0);
}

const created = await api('POST', `/fields/${COLLECTION}`, payload);
if (created.status !== 200) {
  console.error(`Create failed (HTTP ${created.status}): ${created.text.slice(0, 500)}`);
  process.exit(1);
}

const check = await api('GET', `/fields/${COLLECTION}/${FIELD}`);
console.log(check.status === 200
  ? `Created ${COLLECTION}.${FIELD} (${check.json.data.type}, nullable). Next: re-paste Flow 4's respond script.`
  : `Created, but the read-back returned HTTP ${check.status}.`);
