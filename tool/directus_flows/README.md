# Building the payment Flows

Operation-by-operation layout for the Flows described in
`docs/features/shop-payments-backend.md`. The `.js` files here go into
**Run Script** operations — paste the whole file, `module.exports` included.

Two constraints shape this layout:

- **Run Script is sandboxed.** No `fetch`, no `node:crypto`, no `process.env`.
  All network calls are separate *Webhook / Request URL* operations, and the
  constant-time secret comparison in `flow3_apply.js` is hand-written.
- **Operation keys are referenced by name.** The keys below (`products`,
  `plan`, `gateway`, …) are what the scripts read out of `data`. If you rename
  an operation, rename it in the script too.

Set every flow that touches `app_secrets` — Flows 1, 2 and 3 — to **"Do Not
Track"** under Activity & Logs Tracking. Directus otherwise records every
operation payload, which would write the gateway key and the inbound
`x-webhook-secret` into the activity log in plain text.

| Flow | Name | Purpose | Required? |
|---|---|---|---|
| 3 | Shop — Pesapal Webhook | payment result from the gateway | yes |
| 1 | Shop — Create Order | prices the cart, opens the checkout | yes |
| 2 | Shop — Order Status | polled for confirmation, recovers lost webhooks | yes |
| 4 | Shop — Catalogue | products + prices for the shop screen | optional |
| 5 | Shop — My Orders | order-history screen | optional |
| — | Shop — Checkout Complete / Cancelled | redirect landing pages | yes |

Build order: **Flow 3 first** (Flow 1 needs its URL), then Flow 1, then Flow 2.
Flows 4 and 5 are independent of the others and can be built any time — the app
hides the features they drive until their ids are in `assets/.env`.

---

## Flow 3 — "Shop — Pesapal Webhook"

Public endpoint the gateway calls with the payment result. The reliable signal:
it fires even when the buyer closes the browser before the redirect. Build this
one first — Flow 1 needs its URL.

### Create the flow

**Settings (gear icon) → Flows → "+"**

- **Name:** `Shop — Pesapal Webhook`
- **Status:** Active
- **Activity & Logs Tracking:** **Do Not Track**
  Not optional. On any other setting Directus writes every operation payload to
  the activity log, which means your webhook secret and the inbound
  `x-webhook-secret` header end up stored in plain text.

Click **Next** to pick a trigger.

### The trigger

Choose **Webhook**.

- **Method:** `POST`
- **Asynchronous:** on — nothing reads this response, and answering immediately
  is what the gateway wants.

Save. You now have a canvas with one trigger node.

**Get the URL:** the flow's uuid is in your browser's address bar —
`/admin/settings/flows/<uuid>`. The trigger URL is:

```
https://subscriptions.cioafrica.co/flows/trigger/<uuid>
```

That string goes into the `WEBHOOK_URL` constant at the top of
`flow1_plan.js`. Keep it to hand.

### Operation 1 — read the shared secret

Click the **"+"** on the trigger node. Choose **Read Data**.

- **Name:** `secret_row` — the name generates the *operation key*, which is
  what the script reads out of `data`. Check the key field actually says
  `secret_row`; if it doesn't, edit it.
- **Permissions:** Full Access (it has to read a collection no role can)
- **Collection:** `app_secrets`
- **IDs:** leave empty
- **Query:**

```json
{ "filter": { "key": { "_eq": "pesapal_webhook_secret" } }, "limit": 1 }
```

Note the filter is nested inside a `filter` key — the Query field takes a whole
query object, not a bare filter.

### Operation 2 — find the order

**"+"** on the previous node → **Read Data**.

- **Name / key:** `order`
- **Permissions:** Full Access
- **Collection:** `shop_orders`
- **Query:**

```json
{ "filter": { "id": { "_eq": "{{$trigger.body.merchant_reference}}" } }, "limit": 1 }
```

`merchant_reference` — not `order_tracking_id`. That's the id we generated and
control; Pesapal's own tracking id is a different value.

### Operation 3 — verify and decide

**"+"** → **Run Script**.

- **Name / key:** `apply`
- **Code:** paste the whole of `flow3_apply.js`, `module.exports` included,
  replacing the placeholder body Directus starts you with.

This verifies the secret in constant time, maps Pesapal's wording to our status
vocabulary, and short-circuits if the order is already paid.

### Operation 4 — skip the write when there's nothing to write

**"+"** → **Condition**.

- **Name / key:** `has_update`
- **Condition Rules:**

```json
{ "apply": { "status": { "_nnull": true } } }
```

The script returns a `status` only on the path that actually has an update. A
duplicate IPN or an unknown order returns `{ skipped: … }` with no `status`, so
this routes them down the reject branch and the flow simply ends. Without this
step those cases show up as failed runs.

### Operation 5 — save it

On the Condition's **resolve** (✓) branch → **Update Data**.

- **Name / key:** `save`
- **Permissions:** Full Access
- **Collection:** `shop_orders`
- **Keys:** `{{apply.order_id}}`
- **Payload:** `{{apply.update}}`

Either form works — the explicit one below is what's deployed on
`subscriptions.cioafrica.co` and is verified: on Directus 10.4.2 a lone
`{{ }}` expression resolves to the typed value, so `paid_at` lands as a real
timestamp (and as SQL NULL on a failed payment, not the string `"null"`), and
`raw_payment` is stored as an object rather than `"[object Object]"`.

```json
{
  "status": "{{apply.update.status}}",
  "payment_method": "{{apply.update.payment_method}}",
  "confirmation_code": "{{apply.update.confirmation_code}}",
  "order_tracking_id": "{{apply.update.order_tracking_id}}",
  "paid_at": "{{apply.update.paid_at}}",
  "raw_payment": "{{apply.update.raw_payment}}"
}
```

Leave the Condition's reject (✗) branch empty.

### Operation 6 — email the receipt

Hangs off `save`, so it only ever runs on an order that just became settled.
`apply` already short-circuits an order that was `completed` before this webhook
arrived, which is what keeps a duplicate IPN from sending a second receipt.

| # | Type | Key | Config |
|---|---|---|---|
| 6 | Condition | `is_paid` | `{"apply":{"status":{"_eq":"completed"}}}` |
| 7 | Run Script | `receipt` | `flow3_receipt.js` — edit `SHOP_NAME` / `SUPPORT_EMAIL` at the top |
| 8 | Mail | `mail` | To `{{receipt.to}}` · Subject `{{receipt.subject}}` · Type **Markdown** · Body `{{receipt.body}}` |

`is_paid` matters because `save` also runs for a `failed` or `reversed` payment,
and nobody wants a "thanks for your order" email for a declined card.

Leave `is_paid`'s reject branch empty. This flow's trigger is asynchronous, so a
mail server outage cannot turn into a non-200 for the gateway — it shows up as a
failed run in the flow log, with the payment already correctly recorded.

Directus needs working SMTP (`EMAIL_*` in its env) for the Mail operation. If it
is not configured, build steps 1–5 now and leave 6–8 out rather than shipping a
flow that fails on every payment — and soften the "a receipt has been sent to
your email" line in `order_status_screen.dart` until it is true.

### Test it before moving on

You don't need Pesapal for this. Create a row in `shop_orders` by hand —
id `test-webhook-1`, status `pending`, amount `1`, currency `KES` — then:

```bash
FLOW3=https://subscriptions.cioafrica.co/flows/trigger/<flow-3-uuid>
SECRET='<the pesapal_webhook_secret value from app_secrets>'

curl -X POST "$FLOW3" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: $SECRET" \
  -d '{
    "order_tracking_id": "OTX-TEST",
    "merchant_reference": "test-webhook-1",
    "payment_method": "Visa",
    "confirmation_code": "TEST123",
    "payment_status_description": "Completed",
    "amount": 1,
    "currency": "KES"
  }'
```

`test-webhook-1` should flip to `completed` with `paid_at` set. Then check the
failure modes:

- **Wrong secret** — send the same request with a bad `x-webhook-secret`. The
  order must not change.
- **Replay** — send the correct request twice. The second run should stop at
  the Condition and leave `paid_at` at its original value.
- **Failed payment** — `"payment_status_description": "Failed"` on a fresh
  order. Status becomes `failed` and `paid_at` stays NULL.
- **Unknown order** — any `merchant_reference` that does not exist. The trigger
  must still answer 2xx; the gateway does not retry.

Delete the test rows afterwards.

All five were run against the deployed flow on 2026-09-07 and passed.

## Flow 1 — "Shop — Create Order"

What the app POSTs to when the buyer taps Pay. Prices the cart, records the
order, asks the gateway for a checkout page, and hands the URL back.

**Create the flow:** name `Shop — Create Order`, status Active, Activity & Logs
Tracking **Do Not Track**.

**Trigger:** Webhook · Method `POST` · **Asynchronous OFF** · Response Body
*Data of last operation*. If this is asynchronous the app receives an empty
body instead of `redirect_url` and every checkout fails.

### The shape

Unlike Flow 3 this one branches. A repeat POST for an order we already have
must **not** open a second order at the gateway — the app deliberately reuses
its order id when a checkout is retried (`_orderId` in `checkout_screen.dart`).

```
api_key_row ─▶ products ─▶ existing ─▶ sales ─▶ plan ─▶ is_new ─┬─✓─▶ create ─▶ needs_gateway ─┬─✓─▶ gateway ─▶ track ─▶ respond
                                                        │                              └─✗─▶ respond_free
                                                        └─✗─▶ respond_existing
```

### Operations

| # | Type | Key | Config |
|---|---|---|---|
| 1 | Read Data | `api_key_row` | `app_secrets`, permissions **$full**, query below |
| 2 | Read Data | `products` | `shop_products`, permissions **$full**, query below |
| 3 | Read Data | `existing` | `shop_orders`, permissions **$full**, query below |
| 3a | Read Data | `sales` | `shop_orders`, permissions **$full**, query below — the stock check |
| 4 | Run Script | `plan` | `flow1_plan.js` |
| 5 | Condition | `is_new` | `{"plan":{"mode":{"_eq":"new"}}}` |
| 6 | Create Data | `create` | ✓ branch · `shop_orders` · permissions **$full** · payload below |
| 6a | Condition | `needs_gateway` | `{"plan":{"free":{"_eq":false}}}` |
| 6b | Run Script | `respond_free` | **✗ (reject) branch of step 6a** · `flow1_respond_existing.js` (same script — it returns `plan.response`) |
| 7 | Webhook / Request URL | `gateway` | ✓ branch of step 6a · see below |
| 8 | Update Data | `track` | `shop_orders` · key `{{plan.order_id}}` · payload below |
| 9 | Run Script | `respond` | `flow1_respond.js` |
| 10 | Run Script | `respond_existing` | **✗ (reject) branch of step 5** · `flow1_respond_existing.js` |

Steps 6a/6b are the **zero-amount branch**. When every line is priced 0 in
`shop_products`, `plan` returns `free: true` and an `order_row` that is already
`completed` (with `paid_at` set and `payment_method: "free"`), so the row is
created settled and the gateway is never called — Pesapal would refuse the
amount and no webhook would ever arrive to complete it. The app gets
`status: completed` with no `redirect_url` and goes straight to the
confirmation screen. To add this to an existing Flow 1: drag `create`'s
resolve connector off `gateway` onto a new `needs_gateway` Condition, connect
its ✓ to `gateway`, and hang `respond_free` off its ✗.

Step 10 hangs off the Condition's **reject** connector, not off `respond`. Wire
it after `respond` by mistake and it runs last on the new-order path, returning
`{}` — the app then gets an empty body and every checkout fails.

Step 7 headers are not optional; without `x-api-key` the gateway answers
`401 {"error":"Unauthorized"}`. Step 8 needs `permissions: $full` like the
others, or the update silently fails and `redirect_url` is never stored.

Queries for steps 1–3a:

```json
{ "filter": { "key": { "_eq": "pesapal_gateway_api_key" } }, "limit": 1 }
{ "filter": { "active": { "_eq": true } }, "limit": 500 }
{ "filter": { "id": { "_eq": "{{$trigger.body.order_id}}" } }, "limit": 1 }
{"filter":{"status":{"_in":["pending","completed"]}},"fields":["status","items","date_created"],"limit":-1}
```

Step 3a feeds the stock check (see `shop_products.stock` in the spec). `plan`
refuses a product with a stock limit when `sales` is missing, rather than
treating every unit as free — so if you paste the new `plan` before adding
3a, limited products stop selling and unlimited ones carry on.

Step 3 is the idempotency lookup. Use the **Query** form, not the IDs field —
a query that matches nothing resolves with an empty array, whereas a missing id
in the IDs field can reject and kill the flow before `plan` ever runs.

Step 6 payload. The editor rejects a bare `{{plan.order_row}}`, so list every
field, with each mustache alone inside its quotes so it resolves to a typed
value (a real NULL, a real timestamp, an object). **Leave none out:** a missing
`attendee_id`/`email` hides the order from Flow 5's history, and a missing
`paid_at` leaves free orders completed with no paid date.

```json
{
  "id": "{{plan.order_row.id}}",
  "status": "{{plan.order_row.status}}",
  "amount": "{{plan.order_row.amount}}",
  "currency": "{{plan.order_row.currency}}",
  "items": "{{plan.order_row.items}}",
  "billing": "{{plan.order_row.billing}}",
  "attendee_id": "{{plan.order_row.attendee_id}}",
  "event_id": "{{plan.order_row.event_id}}",
  "email": "{{plan.order_row.email}}",
  "paid_at": "{{plan.order_row.paid_at}}",
  "payment_method": "{{plan.order_row.payment_method}}"
}
```

Step 7:

```
Method  POST
URL     https://paymentapi.cioafrica.co/orders
Headers x-api-key: {{api_key_row[0].value}}
        Content-Type: application/json
Body    {{plan.gateway_body}}
```

The key is referenced straight from the Read Data result, so it never passes
through a script's return value.

Step 8 payload — store the checkout URL, which is what makes a retry able to
resume the same order rather than starting a new one:

```json
{
  "order_tracking_id": "{{gateway.data.order_tracking_id}}",
  "redirect_url": "{{gateway.data.redirect_url}}"
}
```

### How errors come back

`plan` **returns** validation failures instead of throwing:
`{mode: "error", response: {error: "..."}}`. They fall through the same reject
branch as an existing order, so `respond_existing` returns them unchanged.

This is not a style choice. A thrown error terminates a Directus flow, but the
webhook trigger still answers **200 with an empty body** — indistinguishable
from success to the caller. `PaymentService._post` treats a 2xx carrying an
`error` key as a failure, and `createOrder` rejects a body with neither
`status` nor `redirect_url`, so a half-dead flow can't be mistaken for a free
order.

### What the branch does

`plan` returns `mode: "new"` only when no row exists for that order id.
Otherwise it returns `mode: "existing"` with a ready-made response and the
Condition routes past the gateway entirely:

| Prior order | What the buyer gets |
|---|---|
| none | new order, fresh Pesapal checkout |
| none, and the cart prices to 0 | order created `completed`, no gateway call |
| pending, has `redirect_url` | the **same** checkout page, resumed |
| pending, no `redirect_url` | pending status; the app polls Flow 2 |
| completed | confirmation screen, no webview |
| failed / cancelled / reversed | that status, surfaced honestly |

The last row matters: a failed order is reported as failed rather than silently
retried, so the buyer sees what happened instead of a second payment attempt
appearing out of nowhere.

### Test it before wiring the app

Flow 1 calls the real gateway, so a successful run creates a real Pesapal
order. Start with the cases that never reach it:

```bash
FLOW1=https://subscriptions.cioafrica.co/flows/trigger/<flow-1-uuid>

# unknown product -> 4xx with a human-readable error, no order created
curl -X POST "$FLOW1" -H "Content-Type: application/json" -d '{
  "order_id":"test-order-1","currency":"KES",
  "items":[{"product_id":"does-not-exist","qty":1}],
  "billing_address":{"first_name":"A","last_name":"B","email_address":"a@b.c"},
  "callback_url":"https://x/cb","cancellation_url":"https://x/cx"}'

# client-supplied price must be ignored: this must come back as 2500, not 1
curl -X POST "$FLOW1" -H "Content-Type: application/json" -d '{
  "order_id":"test-order-2","currency":"KES","amount":1,
  "items":[{"product_id":"ts1","qty":1,"size":"L","price":1}],
  "billing_address":{"first_name":"A","last_name":"B","email_address":"a@b.c"},
  "callback_url":"https://x/cb","cancellation_url":"https://x/cx"}'

# idempotency: send the SAME request again. Same redirect_url, and
# shop_orders still has exactly one row for test-order-2.
```

Then delete the test rows. The second call is the one that proves the branch —
if `redirect_url` differs between the two responses, the Condition is wired to
the wrong side.

---

## Flow 2 — "Shop — Order Status"

**Trigger:** Webhook · POST · **synchronous**, response body = *Data of last
operation*. Activity & Logs Tracking **Do Not Track** — this one reads
`app_secrets` too.

The app polls this every 3s for up to 3 minutes and stops as soon as `status` is
anything but `pending`.

### Why it is not just "read the row"

Flow 3 is the normal signal, but the gateway does not retry a notification it
failed to deliver, and it forgets `webhook_url` after 24h. A single dropped
webhook would otherwise leave an order `pending` for ever — the buyer's money
gone, with no confirmation and nothing in the app to fix it.

So a still-pending order is re-checked against the gateway on the buyer's own
poll, and settled through the same update shape Flow 3 writes.

### The shape

```
api_key_row ─▶ order ─▶ plan ─▶ needs_check ─┬─✓─▶ gateway_status ─▶ recover ─▶ has_update ─┬─✓─▶ write ─▶ reply_recovered
                                             │            └─✗(error)─▶ reply_gateway_down   └─✗─▶ reply_unchanged
                                             └─✗─▶ reply_stored
```

### Operations

| # | Type | Key | Config |
|---|---|---|---|
| 1 | Read Data | `api_key_row` | `app_secrets`, **$full**, `{"filter":{"key":{"_eq":"pesapal_gateway_api_key"}},"limit":1}` |
| 2 | Read Data | `order` | `shop_orders`, **$full**, `{"filter":{"id":{"_eq":"{{$trigger.body.order_id}}"}},"limit":1}` |
| 3 | Run Script | `plan` | `flow2_plan.js` |
| 4 | Condition | `needs_check` | `{"plan":{"mode":{"_eq":"check"}}}` |
| 5 | Request URL | `gateway_status` | ✓ branch · see below |
| 6 | Run Script | `recover` | `flow2_recover.js` |
| 7 | Condition | `has_update` | `{"recover":{"update":{"_nnull":true}}}` |
| 8 | Update Data | `write` | ✓ branch · `shop_orders`, **$full**, Keys `{{plan.order_id}}`, payload below |
| 9 | Run Script | `reply_recovered` | `flow2_reply.js` |
| 10 | Run Script | `reply_unchanged` | **✗ of step 7** · `flow2_reply.js` |
| 11 | Run Script | `reply_stored` | **✗ of step 4** · `flow2_reply.js` |
| 12 | Run Script | `reply_gateway_down` | **✗ (error) of step 5** · `flow2_reply.js` |

Steps 9–12 are the same file four times. Directus flows are trees, not graphs:
branches cannot rejoin, so every leaf needs its own operation returning the
answer, and "Data of last operation" picks up whichever one ran.

Step 8 is two separate fields, and they take different things:

- **Keys** (or **IDs**) is a plain tags input, not JSON. Type
  `{{plan.order_id}}` and press **Enter** to commit it as a chip. If it does not
  become a chip it was not saved.
- **Payload** is a JSON editor, so a bare `{{recover.update}}` is rejected — it
  is not valid JSON. Name the fields explicitly:

```json
{
  "status": "{{recover.update.status}}",
  "payment_method": "{{recover.update.payment_method}}",
  "confirmation_code": "{{recover.update.confirmation_code}}",
  "paid_at": "{{recover.update.paid_at}}",
  "raw_payment": "{{recover.update.raw_payment}}"
}
```

The quotes do not stringify the values. On Directus 10.4.2 a **lone** `{{ }}`
expression — nothing else inside the quotes — resolves to the typed value, which
is why `paid_at` writes a real timestamp and a real SQL NULL rather than the
string `"null"`, and `raw_payment` stores an object rather than
`"[object Object]"`. Verified on Flow 3's identical `save` operation. Add any
other text inside those quotes and it does stringify, as you would expect.

Like step 5, this needs `permissions: $full`, or the update silently does
nothing and the recovered status is never stored.

Step 5:

```
Method   GET
URL      https://paymentapi.cioafrica.co/orders/{{plan.tracking_id}}/status
Headers  x-api-key: {{api_key_row[0].value}}
```

> Confirm that path against `assets/payment_api_ref/INTEGRATION.pdf` before you
> save it. Everything else here is verified against the live gateway; this one
> endpoint is not, because the app never called it.

**Step 12 is the important one.** Wire `flow2_reply.js` to `gateway_status`'s
**error** connector. The app gives up after five consecutive failed polls, so a
gateway outage that killed this flow would break confirmation for orders the
webhook was going to settle anyway. On the error branch, an unreachable gateway
degrades to "still pending" instead.

### Receipt on the recovery path

An order settled here should get the same receipt as one settled by the webhook.
Hang the receipt operations off step 8 (`write`), exactly as in Flow 3:

| # | Type | Key | Config |
|---|---|---|---|
| 8a | Condition | `is_paid` | `{"recover":{"update":{"status":{"_eq":"completed"}}}}` |
| 8b | Run Script | `receipt` | `flow3_receipt.js` |
| 8c | Mail | `mail` | To `{{receipt.to}}`, Subject `{{receipt.subject}}`, Type Markdown, Body `{{receipt.body}}` |

Then `reply_recovered` hangs off the **✗** of `is_paid` *and* off `mail` — two
copies again, for the same tree reason.

`recover` only ever runs for an order the row still calls `pending`, so this
cannot double up with Flow 3's receipt. Two *simultaneous* polls could in
principle both see pending and both send; the window is one round trip and the
cost is a duplicate email, which is why the guard is where it is rather than
being made bulletproof.

### Test it

```bash
FLOW2=https://subscriptions.cioafrica.co/flows/trigger/<flow-2-uuid>

# unknown id -> error, so the app stops polling instead of spinning
curl -sX POST "$FLOW2" -H 'Content-Type: application/json'   -d '{"order_id":"does-not-exist"}'

# a real pending order -> pending, and the gateway was asked
curl -sX POST "$FLOW2" -H 'Content-Type: application/json'   -d '{"order_id":"<a pending order id>"}'

# a completed order -> completed, and the gateway was NOT asked
# (check the flow's log: `needs_check` should have taken the reject branch)
```

To exercise step 12, temporarily point step 5's URL at a host that refuses
connections. A pending order must still come back as `pending`, not as an error.

---

## Flow 4 — "Shop — Catalogue" (optional)

Products and prices for the shop screen. Without it the app shows a hardcoded
list, which is not merely stale — Flow 1 prices every order from
`shop_products`, so a price edited in Directus changed what the buyer was
charged but not what they were shown.

**Trigger:** Webhook · POST · **synchronous**, response body = *Data of last
operation*. Ordinary Activity tracking is fine; this one never reads
`app_secrets`.

| # | Type | Key | Config |
|---|---|---|---|
| 1 | Read Data | `products` | `shop_products`, **$full**, `{"filter":{"active":{"_eq":true}},"limit":500}` |
| 1a | Read Data | `sales` | `shop_orders`, **$full**, `{"filter":{"status":{"_in":["pending","completed"]}},"fields":["status","items","date_created"],"limit":-1}` |
| 2 | Run Script | `respond` | `flow4_catalogue.js` |

Each product carries `available`: units left per size (`{"":n}` when unsized),
or `null` when it has no limit. Only what is left is published, never the
total or sales. Without step 1a every limited product shows its full stock;
Flow 1 still enforces the real figure.

`shop_products` stays private — no role gets read access. The script returns a
fixed field list, so an internal cost or supplier column added to the collection
later is not published by accident.

The app treats any failure (including the `{"error":…}` an empty catalogue
returns) as "use the bundled list", and shows a "showing saved prices" banner
when it does. So a broken Flow 4 degrades the shop rather than closing it.

```bash
curl -sX POST "https://subscriptions.cioafrica.co/flows/trigger/<flow-4-uuid>"   -H 'Content-Type: application/json' -d '{}'
# -> {"products":[{"id":"bp1",…}],"categories":["Backpacks",…],"currency":"KES"}
```

Then put the id in `assets/.env` as `PAYMENTS_CATALOGUE_FLOW_ID`.

**Photos and descriptions.** `shop_products.product_image` is a file field
(upload in Directus) and `product_description` a text field. Flow 4 sends the
photo as `https://subscriptions.cioafrica.co/assets/<uuid>?width=800&quality=80`
— resized server-side — which the app loads without a session because the
public role can read `directus_files`. The app shows the uploaded photo when
there is one, and otherwise the shot bundled for that product id (`ts1`,
`hd1`, `bp1`, `jk1` only). A new product with no upload shows a placeholder.

---

## Flow 5 — "Shop — My Orders" (optional)

Backs the order-history screen.

**Trigger:** Webhook · POST · **synchronous**, response body = *Data of last
operation*.

| # | Type | Key | Config |
|---|---|---|---|
| 1 | Read Data | `orders` | `shop_orders`, **$full**, query below |
| 2 | Run Script | `respond` | `flow5_orders.js` |

```json
{
  "filter": { "_and": [
    { "attendee_id": { "_eq": "{{$trigger.body.attendee_id}}" } },
    { "email": { "_eq": "{{$trigger.body.email}}" } }
  ] },
  "sort": ["-date_created"],
  "limit": 50
}
```

### Read this before changing the filter

Like every flow the app calls, this endpoint is public — the only credential the
app has is the Directus token shipped in the APK, which is extractable and so
not a credential at all. The lookup is therefore *hard to guess* rather than
authenticated:

- it matches `attendee_id` **and** `email` together, because either alone is
  guessable or enumerable;
- it refuses a request missing either, instead of widening the filter — a filter
  that silently widens is how this sort of endpoint becomes a customer-list
  dump;
- it returns no `billing` block. An order list is not a reason to hand back
  phone numbers, and the app already knows who the buyer is.

It remains, by design, "whoever knows the pair can read the list". If that stops
being acceptable, the fix is a real session token on the app, not a cleverer
filter here.

The script re-checks both fields on the rows it got back, so a future edit that
drops half the query still cannot leak other buyers' orders.

Then put the id in `assets/.env` as `PAYMENTS_ORDER_HISTORY_FLOW_ID`. Until it is
set, the app hides the "My orders" button rather than showing one that errors.

---

## Wiring it back to the app

Once Flows 1–3 exist, put their trigger ids into `assets/.env`:

```
PAYMENTS_CREATE_ORDER_FLOW_ID=<flow 1 uuid>     # required
PAYMENTS_ORDER_STATUS_FLOW_ID=<flow 2 uuid>     # required
PAYMENTS_CATALOGUE_FLOW_ID=<flow 4 uuid>        # optional
PAYMENTS_ORDER_HISTORY_FLOW_ID=<flow 5 uuid>    # optional
```

Until **both** required ids are non-empty, `PaymentConfig.isConfigured` is false
and the cart quietly falls back to the demo checkout — a half-configured build
looks like it works. The two optional ids each turn one feature on: the live
catalogue and the "My orders" screen. Empty is a supported state for both, not a
broken one.

`PAYMENTS_CALLBACK_URL` / `PAYMENTS_CANCEL_URL` point at two more trivial
flows — Webhook trigger, method **GET**, one Run Script each running
`flow_callback.js` with `OUTCOME` set to `complete` or `cancelled`:

```
Shop — Checkout Complete   632dd809-a6a8-4a7f-bef4-3fad00dd7ccc
Shop — Checkout Cancelled  3fe03d98-be5b-4fa4-a7f2-2d0bca705f6e
```

Pesapal redirects the buyer's *browser* to these. The app never renders them:
`PesapalCheckoutScreen` matches them by URL prefix in its navigation delegate
and closes the webview first. They exist so the gateway has somewhere real to
redirect, and so a buyer who reaches one in an ordinary browser sees something
sane rather than a 404.

They must not apply the payment result. Flow 3 does that; a redirect is under
the buyer's control and proves nothing.

Because the app matches by prefix, the two URLs must not be prefixes of one
another — two distinct flow uuids satisfy that. Verified answering 200 to an
unauthenticated `GET ?OrderTrackingId=…&OrderMerchantReference=…`, which is
exactly how Pesapal calls them.

Then verify:

```
DIRECTUS_TOKEN=<token> node tool/check_payments_backend.mjs
```

## Testing the logic without Directus

Every `.js` file here is plain CommonJS taking a single `data` object — the bag
of earlier operation results Directus hands it — so it runs outside Directus with
a hand-built `data`:

```bash
node tool/directus_flows/test_flows.mjs
```

34 tests covering pricing, client-amount rejection, size validation, the
constant-time secret comparison, idempotent replay, gateway-status mapping, the
degrade-to-pending behaviour, catalogue field filtering, the order-history lookup
guard and receipt formatting.

**Run it after editing any script here, before pasting it into Directus.**
Debugging in the flow builder instead costs a full round trip per typo and the
payloads are hard to see.
