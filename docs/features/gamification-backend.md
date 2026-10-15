# Rewards (gamification) backend

Delegates earn points for things they do in the app across the three event
days. There are quick wins, multi-step challenges, and daily rules that only
pay off when the delegate comes back each day.

**The app never awards points.** It logs activities through `ActivityLogger`
(`lib/services/activity_logger.dart`). Rows queue offline in sqflite and flush
in batches to `app_activity_logs`; `client_event_id` is unique, so retries
never duplicate. Directus Flows score those rows into an append-only
`points_ledger`. The Rewards screen reads two webhook Flows.

```
app ── ActivityLogger ──► app_activity_logs ──(G1 hook)──► points_ledger
                               ▲      ▲                         │
          G4 mirror (meetings) ┘      └ G5 shop_orders (paid)   │
app ◄── G2 Progress / G3 Leaderboard (webhooks) ◄───────────────┘
```

All Run Script code is in `tool/directus_flows/gamification_*.js`. Paste each
file whole, `module.exports` included. Test the scripts before pasting them:

```bash
node tool/directus_flows/test_gamification.mjs
```

This replaces the v1 system: client-side `UserPointsService` writes to
`user_points`. Archive `user_points`; don't drop it.

---

## 1. Data model

### `point_actions`: extend the existing collection (one row per rule)

| Field | Type | Notes |
|---|---|---|
| `action_name`, `action_description` | existing | Card title and description |
| `action_url` | existing | Optional icon image URL |
| `screen_name` | existing (string) | Screen the card opens: `agenda`, `networking`, `scanner`, `speakers`, `sponsors`, `social`, `gallery`, `shop` or `feedback` |
| `action_points` | existing | Points for `once`, `quest`, `each`, `daily` and `all_days` |
| `required_occurrence` | existing | Threshold for `once`, `quest`, `daily` and `all_days` (default 1) |
| `trigger_action` | string, **new** | Activity action name, e.g. `contact_scanned` |
| `rule_type` | dropdown, **new** | `once`, `quest`, `each`, `distinct_tiers`, `daily`, `all_days` |
| `distinct_by` | string, **new** | `target_id`, `day`, `metadata.<key>` or empty (empty means every log counts) |
| `tiers` | JSON, **new** | `[{"count":5,"points":50}, …]` for `distinct_tiers` |
| `max_awards` | integer, **new** | Cap for `each` and `daily` |
| `match` | JSON, **new** | Log fields that must match, e.g. `{"target_type":"app_sponsor"}`. An array value means "any of". |
| `active_from`, `active_to` | timestamp, **new** | Window for quests. Logs outside it don't count. |
| `category` | dropdown, **new** | `quick`, `challenge`, `daily`; sets the tab and section |
| `sort` | integer, **new** | Order on screen |
| `hidden` | boolean, **new** | Secret: not shown until earned |
| `status` | `published` / `draft` / `archived`, **new if missing** | Only `published` rules are scored |

What each rule type pays:

- **once / quest:** `action_points` once, when the number of distinct keys reaches `required_occurrence`.
- **each:** `action_points` per distinct key, up to `max_awards`.
- **distinct_tiers:** each tier's points when the distinct count reaches that tier's `count`.
- **daily:** `action_points` for each event day with at least `required_occurrence` logs.
- **all_days:** `action_points` once, when every event day qualifies.

### `points_ledger`: new collection

| Field | Type | Notes |
|---|---|---|
| `id` | auto int | |
| `user_id` | integer | Attendee id (the same id as `app_activity_logs.user_id`) |
| `rule_id` | M2O → point_actions | |
| `points` | integer | |
| `award_key` | string, **unique** | e.g. `rule:42\|user:118\|tier:15`. This is what makes double awards impossible. |
| `event_day` | date | |
| `source_log` | integer | The `app_activity_logs` id that triggered it |
| `date_created` | timestamp, auto | |

Add an index on `user_id`.

### `gamification_settings`: new singleton

| Field | Type | Default |
|---|---|---|
| `event_days` | JSON | `["2026-11-03","2026-11-04","2026-11-05"]` (yyyy-MM-dd, local) |
| `utc_offset_minutes` | integer | `180` (Nairobi, no DST) |
| `awards_open_at`, `awards_close_at` | timestamp | Empty means always open. Set `close` to the end of Day 3. |
| `leaderboard_enabled` | boolean | `true` |
| `leaderboard_freeze_at` | timestamp | Empty. See G3. |
| `excluded_user_ids` | JSON | `[]`: staff and sponsor attendee ids |
| `event_id` | integer | For G3's attendee lookup |

### `app_activity_logs`: existing

Add the new action names to `app_activity_action_types`:

- `app_open`, `profile_photo_updated`, `agenda_bookmark_added`
- `contact_scanned`, `session_rated`
- `social_post_created`, `social_reaction`, `social_comment`
- `harry_question`, `gallery_face_search`, `feedback_submitted`
- `hunt_code_found`, `shop_order_paid`

`platform` must accept `server`, which is used by G4 and G5.

### Permissions: read before the event

The app sends every Directus request with the **static token in
`lib/dioServices/dioClient.dart`**. Anyone who unpacks the APK has that token,
so its role decides what a cheater can do. That role must have:

- `app_activity_logs`: **create** only.
- `points_ledger`, `point_actions`, `gamification_settings`: **no create, update or delete**.

If that token is an admin token, the server-side scoring is only as safe as
the token. The Flows use Full Access permissions and don't depend on it.

---

## 2. Flows

### G1 "Gamification — Award": scores every new log

- **Trigger:** Event Hook, type **Action (non-blocking)**, scope `items.create`, collection `app_activity_logs`.
- **Activity & Logs Tracking:** "Don't track" (it runs for every log).

| # | Key | Operation | Config |
|---|---|---|---|
| 1 | `rules` | Read Data, point_actions, Full Access | `{"filter":{"status":{"_eq":"published"},"trigger_action":{"_eq":"{{$trigger.payload.action}}"}},"limit":-1}` |
| 2 | `has_rules` | Condition | `{"rules":{"_nempty":true}}`. The reject branch ends the flow. Most logs (views, impressions) stop here. |
| 3 | `settings` | Read Data, gamification_settings | singleton, no query |
| 4 | `logs` | Read Data, app_activity_logs | `{"filter":{"user_id":{"_eq":"{{$trigger.payload.user_id}}"},"action":{"_eq":"{{$trigger.payload.action}}"}},"fields":["id","client_event_id","action","target_type","target_id","metadata","occurred_at"],"sort":["occurred_at"],"limit":-1}` |
| 5 | `ledger` | Read Data, points_ledger | `{"filter":{"user_id":{"_eq":"{{$trigger.payload.user_id}}"}},"fields":["award_key","points"],"limit":-1}` |
| 6 | `engine` | Run Script | `gamification_engine.js` |
| 7 | `has_awards` | Condition | `{"engine":{"rows":{"_nempty":true}}}` |
| 8 | `save` | Create Data, points_ledger, Full Access, **Emit Events off** | Payload `{{engine.rows}}` |

The engine is stateless. Each run recomputes every award the user qualifies
for and drops `award_key`s already in the ledger. When two logs race, the
second insert fails on the unique key. Nothing is lost: the next log of that
action awards whatever is missing.

### G2 "Gamification — Progress": the Rewards screen

- **Trigger:** Webhook, **GET**, synchronous, response body: data of last operation.

| # | Key | Operation | Config |
|---|---|---|---|
| 1 | `rules` | Read Data, point_actions | `{"filter":{"status":{"_eq":"published"}},"sort":["sort"],"limit":-1}` |
| 2 | `settings` | Read Data, gamification_settings | |
| 3 | `logs` | Read Data, app_activity_logs | `{"filter":{"user_id":{"_eq":"{{$trigger.query.user_id}}"},"action":{"_nin":["sponsor_impression","sponsor_tap","shop_impression","shop_tap","otp_request","otp_login"]}},"fields":["id","client_event_id","action","target_type","target_id","metadata","occurred_at"],"limit":-1}` |
| 4 | `ledger` | Read Data, points_ledger | `{"filter":{"user_id":{"_eq":"{{$trigger.query.user_id}}"}},"fields":["award_key","points"],"limit":-1}` |
| 5 | `totals` | Read Data, points_ledger | `{"aggregate":{"sum":["points"]},"groupBy":["user_id"],"limit":-1}` |
| 6 | `engine` | Run Script | the **same** `gamification_engine.js` (it detects webhook mode) |

### G3 "Gamification — Leaderboard"

- **Trigger:** Webhook, **GET**, synchronous.

| # | Key | Operation | Config |
|---|---|---|---|
| 1 | `settings` | Read Data, gamification_settings | |
| 2 | `totals` | Read Data, points_ledger | `{"aggregate":{"sum":["points"]},"groupBy":["user_id"],"limit":-1}` |
| 3 | `people` | Read Data, event_registrations | `{"filter":{"eventId":{"_eq":"{{settings.event_id}}"}},"fields":["attendeeId","first_name","last_name","company","role","profile_photo"],"limit":-1}` |
| 4 | `board` | Run Script | `gamification_leaderboard.js` |

**Freezing for prize-giving:** set `leaderboard_freeze_at` (the app then
shows "Final standings"). Also add
`"filter":{"date_created":{"_lte":"<same time>"}}` to `totals`, so later
awards don't move the board. To hide the board entirely, untick
`leaderboard_enabled`.

### G4 "Gamification — Meeting Mirror": both people earn "Deal maker"

- **Trigger:** Event Hook, Action, `items.create`, `app_activity_logs`.
- Operations, in order:
  1. Run Script `mirror` (`gamification_mirror.js`).
  2. Condition `{"mirror":{"rows":{"_nempty":true}}}`.
  3. Create Data on `app_activity_logs`, payload `{{mirror.rows}}`, **Emit Events on**, so that G1 scores it.

The acceptor's log carries `metadata.requested_by_id`; the mirrored row is for
that requester. Its `client_event_id` is `<original>-mirror` and it is marked
`mirrored: true`, so replays and loops are impossible.

### G5 "Gamification — Shop Purchase"

Build it as **two flows** with the same operations: **G5a** on `items.update`
and **G5b** on `items.create`. The created and updated ids arrive in different
trigger fields, and one Read Data op can't take both.

- **Trigger:** Event Hook, Action, collection `shop_orders`. Scope `items.update` (G5a) or `items.create` (G5b).
- Operations, in order:
  1. Read Data `order` on `shop_orders`. IDs `{{$trigger.keys}}` (G5a) or `{{$trigger.key}}` (G5b). Fields `id,status,attendee_id,paid_at,date_created`.
  2. Run Script `purchase` (`gamification_shop.js`).
  3. Condition `{"purchase":{"rows":{"_nempty":true}}}`.
  4. Create Data on `app_activity_logs`, payload `{{purchase.rows}}`, **Emit Events on**.

**Shop flow change:** turn **Emit Events on** for the writes that complete an order:

- Flow 3 operation `save`
- the Flow 2 recovery save
- Flow 1's create, for free orders

Without that, G5 never fires. Purchases are scored only from rows the
payment flows wrote, so an abandoned checkout earns nothing. `client_event_id`
is `shop-order-<id>`, so a repeat IPN can't count twice.

---

## 3. App config

Add the flow ids to `assets/.env`, then rebuild:

```
GAMIFICATION_PROGRESS_FLOW_ID=<G2 uuid>
GAMIFICATION_LEADERBOARD_FLOW_ID=<G3 uuid>
# GAMIFICATION_DIRECTUS_URL defaults to BaseURL.Baseurl
```

Use the `/flows/trigger/<uuid>` id, not the admin page's. Without
`GAMIFICATION_PROGRESS_FLOW_ID`, the Home tile and Rewards screen stay
hidden. `kRewardsFeatureEnabled` in `lib/constants.dart` is the kill switch.

## 4. Rules

Load the starter set, about 30 rules, once the collections exist:

```bash
DIRECTUS_TOKEN=<admin token> node tool/seed_gamification.mjs --days 2026-11-03,2026-11-04,2026-11-05 --dry-run
DIRECTUS_TOKEN=<admin token> node tool/seed_gamification.mjs --days 2026-11-03,2026-11-04,2026-11-05
```

The script archives the v1 rows, fills in the quest dates and sets
`event_days`. Points, tiers and copy are all editable in Directus afterwards,
with no app release needed. Things to check before the event:

- **Booth crawl:** set the last tier's `count` to the number of sponsor booths.
- **Session critic:** only past *keynotes* show a rating button (`lib/widgets/agendaWidget.dart`), so size the tiers to the number of keynotes.
- **On site / Present all three days:** print one code per day, with QR content `hunt:entrance-day1`, `hunt:entrance-day2` and `hunt:entrance-day3`. Show only that day's code, at the registration desk.
- **Treasure hunter:** draft by default. Print `hunt:<id>` codes (lower-case ids), put the ids in `match`, then publish.
- **MBCOM booth:** keep its points equal to `AppSponsor.boothPoints` (100), which the booth copy shows.
- The venue map is not part of CIO100, so there is no map rule.

| Group | Rule | Signal |
|---|---|---|
| Quick wins | Profile photo · Explore agenda · First bookmark · Ask Harry, your AI assistant · Face search · First post · MBCOM booth | one log each |
| Challenges | Networker (5/15/30) · Booth crawl (3/6/all) · Deal maker (1/3/5) · Reach out (5 × 5 pts) · Session critic · Speaker spotter · Cheerleader · Conversationalist · Agenda architect · First purchase · Loyal shopper · Treasure hunter | distinct targets |
| Every day | Daily check-in · Hat-trick · On site · Present all three days · Daily review · Critic of the week · Social streak | per event day |
| Quests | Day 1 Morning booth dash · Day 2 Keynote critic · Day 2 Make it count · Day 3 Closing words | time windows |

## 5. Testing against Directus

1. As a test attendee, POST five `app_activity_logs` rows with
   `action: contact_scanned` and distinct `target_id`s. One
   `…|tier:5` ledger row should appear.
2. Re-POST one of them with a new `client_event_id` and the same `target_id`.
   No new row should appear.
3. POST `app_open` rows with `occurred_at` on all three days. You should get
   three daily rows plus the Hat-trick row.
4. POST a quest log outside its window. Nothing should be awarded.
5. Call G2 with `curl "<url>/flows/trigger/<G2>?user_id=<id>"` and check that
   `total` equals the ledger sum. G3 should rank the user.
6. Make a sandbox shop purchase. A `shop_order_paid` log and a First purchase
   ledger row should appear.
7. In the app: scan a badge, then wait about a minute (one flush). A "+50 pts ·
   Networker" toast should appear and the Rewards tabs should update.
