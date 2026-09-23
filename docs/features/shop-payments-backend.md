# Shop payments — backend contract

The shop's checkout pays through **CIO Africa's shared Pesapal gateway**
(`https://paymentapi.cioafrica.co`, see `assets/payment_api_ref/INTEGRATION.pdf`).

That gateway is deliberately dumb: it knows nothing about products, prices or
orders, and it is **server-to-server only** — its `x-api-key` must never ship
inside the app binary. It also requires two publicly-reachable HTTPS endpoints
that *we* own: a webhook receiver and a browser-facing callback page.

So the app never calls the gateway. It calls two Directus Flow webhooks on
`subscriptions.cioafrica.co`, which hold the key and are the system of record
for shop orders.

```
Flutter app ──POST──▶ Directus Flow: create order ──POST /orders──▶ Pesapal gateway
     │                        │                                          │
     │  redirect_url          ▼                                          │
     └──webview──▶ pay.pesapal.com ──redirect──▶ callback page           │
     │                                                                   │
     └──POST (poll)──▶ Directus Flow: order status ──GET /status──────────┤
     │                        ▲                    (recovery path)        │
     │              Directus Flow: webhook receiver ◀──x-webhook-secret───┘
     │
     ├──POST──▶ Directus Flow: catalogue      (products + prices)
     └──POST──▶ Directus Flow: my orders      (order history)
```

## What the app already does

| Concern | File |
| --- | --- |
| Endpoint / URL config | `lib/services/payments/payment_config.dart` |
| Wire types + status normalisation | `lib/services/payments/payment_models.dart` |
| Order creation, status polling | `lib/services/payments/payment_service.dart` |
| Billing form + orchestration | `lib/screens/shop/checkout_screen.dart` |
| Hosted checkout webview | `lib/screens/shop/pesapal_checkout_screen.dart` |
| Confirmation / polling UI | `lib/screens/shop/order_status_screen.dart` |
| Catalogue fetch + bundled fallback | `lib/screens/shop/shop_repository.dart` |
| Order history | `lib/screens/shop/order_history_screen.dart` |

Until `PAYMENTS_CREATE_ORDER_FLOW_ID` and `PAYMENTS_ORDER_STATUS_FLOW_ID` are
set, `PaymentConfig.isConfigured` is false and the cart falls back to the
existing demo checkout, so nothing breaks in the meantime.

**Status:** Flows 1–3 and both redirect pages are deployed on
`subscriptions.cioafrica.co` and verified end to end against the live gateway on
2026-09-22 — a real Pesapal order was created and returned a `pay.pesapal.com`
checkout URL, an idempotent replay returned the same one without opening a
second, and a client-supplied `amount` was correctly ignored in favour of the
catalogue price. Flows 4 and 5, the Flow 2 recovery path and the receipt email
are written and unit-tested but **not yet built in the Directus UI**; see
`tool/directus_flows/README.md`.

## Config the app expects

Added to `assets/.env` (kept out of git, same scheme as the gallery keys):

```
PAYMENTS_DIRECTUS_URL=https://subscriptions.cioafrica.co
PAYMENTS_CREATE_ORDER_FLOW_ID=<flow uuid>
PAYMENTS_ORDER_STATUS_FLOW_ID=<flow uuid>
PAYMENTS_CALLBACK_URL=https://subscriptions.cioafrica.co/shop/checkout/complete
PAYMENTS_CANCEL_URL=https://subscriptions.cioafrica.co/shop/checkout/cancelled
PAYMENTS_CURRENCY=KES

# Optional — each switches one feature on. Empty is a supported state.
PAYMENTS_CATALOGUE_FLOW_ID=<flow uuid>
PAYMENTS_ORDER_HISTORY_FLOW_ID=<flow uuid>
```

None of these are secrets — the gateway key and webhook secret live only in
the `app_secrets` collection below, and never leave the server.

## Collections to provision

### `app_secrets`

Holds the gateway credentials issued by CIO Africa engineering. Admin-only.

| Field | Type | Notes |
| --- | --- | --- |
| `key` | string (PK, manually entered) | `pesapal_gateway_api_key`, `pesapal_webhook_secret` |
| `value` | string | The credential |
| `description` | string | Where it came from, when it was last rotated |

Flows read it with a **Read Data** operation, which runs with admin
permissions regardless of role configuration — so no role needs read access,
and none should have it. In particular the app's shipped Directus bearer token
(see `lib/dioServices/dioClient.dart`) must not be able to reach this
collection: that token is extractable from the APK, so any role it holds is
effectively public.

Set these flows to **"Do Not Track"** under Activity & Logs Tracking. Directus
otherwise records each operation's payload, which would write the credentials —
and the inbound `x-webhook-secret` header — into the activity log in plain text.

Rotation is then a single field edit, with no redeploy and no app release.

### `shop_products`

The catalogue currently lives hardcoded in `lib/screens/shop/shop_repository.dart`.
Prices must move server-side, because the gateway docs are explicit that
amounts are never to be trusted from a client.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | string (PK) | Matches `Product.id` in the app (`ts1`, `hd1`, …) |
| `name` | string | |
| `category` | string | |
| `price` | decimal | Whole shillings for KES |
| `sizes` | json | `[]` for unsized items |
| `description` | text | Shown on the product page |
| `image` | string | Optional. An `http(s)` URL, for a product the installed app has no bundled shot for |
| `active` | boolean | Hide without deleting |
| `stock` | json, nullable | Empty = unlimited. `12` = one pool shared by all sizes; `{"S":10,"L":4}` = per size (a size not listed has none). The **total ever on sale**, not what is left: what is left is derived from `shop_orders` (completed orders, plus pending ones under 30 min old), so nothing is decremented. **To restock, add the new units to this number.** |

### `shop_orders`

| Field | Type | Notes |
| --- | --- | --- |
| `id` | string (PK) | Our `merchant_reference`; the app generates `shop-<uuid>` |
| `status` | string | `pending` / `completed` / `failed` / `cancelled` / `reversed` |
| `amount` | decimal | **Computed server-side** from `shop_products` |
| `currency` | string | |
| `order_tracking_id` | string | Pesapal's id, from `POST /orders` |
| `items` | json | Priced snapshot of the lines |
| `billing` | json | first/last name, email, phone |
| `attendee_id` | string | The buyer's `profileId`. Half the order-history lookup key |
| `email` | string | Lowercased. The other half. A plain column because Directus cannot filter inside a JSON field, and the **signed-in** address rather than the billing one — see below |
| `event_id` | string | Optional, for reporting |
| `date_created` | timestamp | Directus "Created On" special field. Sorts the history list |
| `payment_method` | string | From the webhook |
| `confirmation_code` | string | From the webhook |
| `paid_at` | timestamp | Set once, when first marked paid |
| `raw_payment` | json | Last webhook body, for support |
| `redirect_url` | text | Pesapal checkout URL, kept so a retry resumes the same order |

`email` and `billing.email_address` are allowed to differ, and the difference is
deliberate. `billing` is whatever the buyer typed on the checkout form, and it is
where the receipt goes; `email` is the account they were signed in as, and it is
what the history lookup matches. So buying merch for a colleague and having the
receipt sent to them does not hide the order from your own order list.

All three collections should be **private** — the app reaches `shop_products`
and `shop_orders` only through the Flows below, never through `/items`, and
never reaches `app_secrets` at all.

## Flow 1 — create order

Webhook trigger, `POST /flows/trigger/{PAYMENTS_CREATE_ORDER_FLOW_ID}`.

Request from the app:

```json
{
  "order_id": "shop-3f2b…",
  "currency": "KES",
  "items": [{ "product_id": "ts1", "qty": 2, "size": "L", "name": "Event Logo Tee" }],
  "billing_address": {
    "first_name": "Jane", "last_name": "Doe",
    "email_address": "jane@example.com", "phone_number": "+254700000000"
  },
  "callback_url": "https://…/shop/checkout/complete",
  "cancellation_url": "https://…/shop/checkout/cancelled"
}
```

Steps:

1. **Idempotency.** If `shop_orders[order_id]` already exists, do not re-create
   it and do not call the gateway. If it is already paid, return it with
   `redirect_url: null`; if it is still pending with a stored `redirect_url`,
   return that same URL so the buyer resumes the checkout they started. The app
   reuses its order id across retries specifically so this works. Implemented
   as a Condition branch — see `tool/directus_flows/README.md`.
2. **Price it.** Look every `product_id` up in `shop_products` and compute the
   total. Ignore any price-shaped field the client sent — it doesn't send one.
   Reject unknown or inactive products with a 400.
3. **Record it.** Create `shop_orders` with `status: pending` and the priced
   item snapshot.
4. **Zero-amount short-circuit.** If the total is `<= 0`, mark the order paid
   now and return `redirect_url: null` — the gateway makes no Pesapal call and
   **no webhook will ever fire** for it.
5. **Call the gateway.** `POST https://paymentapi.cioafrica.co/orders` with
   `x-api-key`, the computed `amount`, our `order.id`, the callback/cancel URLs
   and `webhook_url` pointing at Flow 3. Note the gateway only remembers
   `webhook_url` for 24h.
6. Store `order_tracking_id` and return.

Response the app parses (`ShopOrder.fromJson`):

```json
{
  "order_id": "shop-3f2b…",
  "status": "pending",
  "amount": 5000,
  "currency": "KES",
  "order_tracking_id": "OTX123456789",
  "redirect_url": "https://pay.pesapal.com/…"
}
```

Errors: return a non-2xx with `{ "error": "<message shown to the buyer>" }`.

## Flow 2 — order status

Webhook trigger, `POST /flows/trigger/{PAYMENTS_ORDER_STATUS_FLOW_ID}`, body
`{ "order_id": "shop-3f2b…" }`.

Reads `shop_orders` and returns the same shape as Flow 1 (minus
`redirect_url`), plus `payment_method`, `confirmation_code`, `paid_at`.

If the order is still `pending` and has an `order_tracking_id`, it also calls
`GET /orders/{tracking_id}/status` on the gateway and applies the result through
the same update shape as Flow 3 — the recovery path for a webhook that was lost
or arrived outside the 24h window. Without it a single dropped notification
leaves an order pending for ever: the buyer's money gone, with no confirmation
and nothing in the app able to fix it.

A settled order is never re-checked, and a gateway that says "still pending"
writes nothing — otherwise the row would churn on every 3s poll. The gateway
request is wired to its **error** branch as well, so an outage degrades to "still
pending" instead of failing the poll; the app gives up after five consecutive
failures, so a flow that died here would break confirmation for orders the
webhook was going to settle anyway.

The app polls this every 3s for up to 3 minutes
(`PaymentService.pollUntilSettled`) and stops on any status other than
`pending`.

## Flow 3 — gateway webhook receiver

Webhook trigger, public. This is the URL passed as `webhook_url` in step 5, and
it is **the reliable signal** — it fires even if the buyer closes the browser
before the redirect.

1. Compare `x-webhook-secret` against `pesapal_webhook_secret` (read from
   `app_secrets`) using a constant-time comparison. `Run Script` is sandboxed
   with no `node:crypto`, so write the comparison in plain JS — check lengths
   first, then XOR every character and compare the accumulated result to 0.
2. Look the order up by `merchant_reference` (**not** `order_tracking_id` —
   `merchant_reference` is the id we generated and control).
3. If already `completed`, return 200 and do nothing else. Pesapal can send
   more than one IPN, and Flow 2's recovery path can apply the same result, so
   side-effects (receipt email, stock decrement, fulfilment) must happen at
   most once.
4. Otherwise map `payment_status_description` → our status, set `paid_at`,
   store `raw_payment`, and fire the side-effects — currently one: the receipt
   email, behind a further condition that the status is `completed`, so a
   declined card does not get a "thanks for your order". Flow 2's recovery path
   sends the same receipt from the same script, so an order settled either way
   produces exactly one.
5. **Always return 200**, even on internal failure — the gateway does not
   retry, and a non-200 just loses the notification. Log failures instead.

Status mapping (`PaymentStatus.parse` accepts either side's spelling):

| Pesapal | Ours |
| --- | --- |
| `Completed` | `completed` |
| `Failed`, `Invalid` | `failed` |
| `Reversed` | `reversed` |
| `Pending` | `pending` |

## Callback / cancellation pages

`PAYMENTS_CALLBACK_URL` and `PAYMENTS_CANCEL_URL` must resolve to something,
but they do almost no work: `PesapalCheckoutScreen` matches them **by URL
prefix** in its navigation delegate and closes the webview before the page
finishes rendering. A minimal "Confirming payment…" HTML page is enough. The
real confirmation happens when the app polls Flow 2.

Both are matched by prefix, so the `?OrderTrackingId=…` Pesapal appends is
fine, but the two URLs must not be prefixes of each other.

## Flow 4 — catalogue (optional)

Webhook trigger, `POST /flows/trigger/{PAYMENTS_CATALOGUE_FLOW_ID}`, empty body.
Returns the active products so the app shows the prices the backend will charge.

```json
{ "products": [{ "id": "ts1", "name": "Event Logo Tee", "category": "T-Shirts",
                 "price": 2500, "sizes": ["S","M","L"], "description": "…",
                 "image": null }],
  "categories": ["Hoodies", "T-Shirts"], "currency": "KES" }
```

`ShopRepository.load()` treats any failure as "use the bundled list" and shows a
banner saying the prices are saved ones. The bundled ids and prices must stay in
step with `shop_products` — that list is the offline display fallback, never the
authority, and Flow 1 re-prices every order regardless.

## Flow 5 — order history (optional)

Webhook trigger, `POST /flows/trigger/{PAYMENTS_ORDER_HISTORY_FLOW_ID}`, body
`{ "attendee_id": "…", "email": "…" }`. Returns
`{ "orders": [ … ] }`, newest first, with the priced item lines and no billing
block.

Both keys are required and matched together, because this endpoint — like every
other one the app calls — is public: the only credential the app has is the
Directus token in the APK, which is extractable and therefore not a credential.
The pair is guess-resistant where either half alone is not. It is still "whoever
knows the pair can read the list"; if that stops being good enough, the answer is
a real session token on the app, not a cleverer filter. See the note at the top
of `tool/directus_flows/flow5_orders.js`.

## Still open

- **Flows 4 and 5, the Flow 2 recovery path and the receipt email exist only as
  scripts.** They are unit-tested but not yet built in the Directus UI, and the
  two optional flow ids are blank in `assets/.env`, so the app currently runs
  with the bundled catalogue and no "My orders" button.
- The Flow 2 recovery step's gateway path, `GET /orders/{tracking_id}/status`,
  has not been called for real — it is the one endpoint in this document taken
  from `INTEGRATION.pdf` rather than verified against the live gateway. Confirm
  it before trusting the recovery path.
- `shop_orders` needs three fields added for the above: `attendee_id`, `email`
  and Directus's `date_created`. Orders created before that have none of them and
  will not appear in anyone's history.
- The Mail operation needs SMTP configured on Directus (`EMAIL_*`). Until it is,
  leave the receipt steps out of Flow 3 and soften the "a receipt has been sent
  to your email" line in `order_status_screen.dart`, which currently promises
  something that doesn't happen.
- Stock is not tracked. Nothing decrements on a sale and nothing stops an order
  for a sold-out size.
