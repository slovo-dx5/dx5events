// Re-pastes tool/directus_flows/flow4_catalogue.js into Flow 4's `respond`
// Run Script operation ("Shop — Catalogue"), then reads it back to confirm.
// Only that one operation's code changes; the flow, trigger and the other
// operations are left exactly as they are.
//
// Run it yourself — it reads the token from the environment and never prints
// it. Safe to re-run: does nothing when the live code already matches.
//
//   DIRECTUS_TOKEN=<admin static token> node tool/deploy_flow4.mjs
//   node tool/deploy_flow4.mjs --dry-run       (finds the operation, no write)
//
// The flow is found by PAYMENTS_CATALOGUE_FLOW_ID in assets/.env (the id the
// app calls), or FLOW_ID in the environment.

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const URL_BASE = (process.env.DIRECTUS_URL || 'https://subscriptions.cioafrica.co').replace(/\/$/, '');
const TOKEN = process.env.DIRECTUS_TOKEN;
const dryRun = process.argv.includes('--dry-run');
const OP_KEY = 'respond';

if (!TOKEN) {
  console.error('DIRECTUS_TOKEN is not set. See the header of this file.');
  process.exit(1);
}

function flowIdFromEnv() {
  if (process.env.FLOW_ID) return process.env.FLOW_ID;
  try {
    const env = readFileSync(join(here, '..', 'assets', '.env'), 'utf8');
    const m = env.match(/^PAYMENTS_CATALOGUE_FLOW_ID=\s*"?([^"\r\n]+)"?/m);
    return m ? m[1].trim() : null;
  } catch {
    return null;
  }
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

const flowId = flowIdFromEnv();
if (!flowId) {
  console.error('No flow id: set PAYMENTS_CATALOGUE_FLOW_ID in assets/.env or FLOW_ID.');
  process.exit(1);
}

const code = readFileSync(join(here, 'directus_flows', 'flow4_catalogue.js'), 'utf8');

const flow = await api('GET', `/flows/${flowId}?fields=id,name,status`);
if (flow.status !== 200) {
  console.error(`Could not read flow ${flowId} (HTTP ${flow.status}): ${flow.text.slice(0, 300)}`);
  process.exit(1);
}
console.log(`Flow: ${flow.json.data.name} (${flow.json.data.status})`);

const ops = await api('GET',
  `/operations?filter[flow][_eq]=${flowId}&filter[key][_eq]=${OP_KEY}&fields=id,key,type,options`);
const matches = ops.json?.data ?? [];
if (ops.status !== 200 || matches.length !== 1) {
  console.error(`Expected exactly one '${OP_KEY}' operation, found ${matches.length} (HTTP ${ops.status}).`);
  process.exit(1);
}
const op = matches[0];
if (op.type !== 'exec') {
  console.error(`'${OP_KEY}' is a ${op.type} operation, not Run Script. Not touching it.`);
  process.exit(1);
}

const norm = (s) => String(s ?? '').replace(/\r\n/g, '\n').trim();
if (norm(op.options?.code) === norm(code)) {
  console.log('Live code already matches flow4_catalogue.js. Nothing to do.');
  process.exit(0);
}
if (dryRun) {
  console.log(`Dry run — would update operation ${op.id} (${norm(op.options?.code).length} → ${norm(code).length} chars).`);
  process.exit(0);
}

// Keep every other option on the operation; replace only the code.
const updated = await api('PATCH', `/operations/${op.id}`, {
  options: { ...(op.options || {}), code },
});
if (updated.status !== 200) {
  console.error(`Update failed (HTTP ${updated.status}): ${updated.text.slice(0, 500)}`);
  process.exit(1);
}

const back = await api('GET', `/operations/${op.id}?fields=options`);
console.log(norm(back.json?.data?.options?.code) === norm(code)
  ? `Updated '${OP_KEY}' (operation ${op.id}). Flow 4 now runs the current flow4_catalogue.js.`
  : 'Updated, but the read-back does not match. Check the operation in Directus.');
