# dx5ve Cloud Functions

## `galleryPhotoNotifier`

Scheduled function (every 10 minutes) that polls the Event Image Service API
(`../assets/mobile-gallery-api.md`) and sends an FCM push when a day's photos
first become available — e.g. **"Day 1 photos are now available"**.

### How it works

1. Logs into the pix API with a dedicated poller account (fresh login each run).
2. For every event the account can see, reads `GET /events/:id/days`
   (`[{ day, count }]`, ready photos only).
3. Compares against per-event state in Firestore
   `galleryNotifierState/<pixEventId>`.
4. When a day crosses into "has photos", sends a push to topic
   `gallery_<appEventId>` — keyed on the app's own (Directus) event id, which
   the app subscribes to directly (no pix lookup on the client). The pix UUID
   still rides in the payload for tap-through.

### Event mapping (important)

The topic is keyed on the **app** event id (e.g. `107` = Smart Government
Summit, from `../lib/screens/landingPage2.dart`), not the pix UUID. Each pix
event is translated to its app id via `APP_EVENT_ID_BY_PIX` at the top of
`index.js`, keyed by normalized pix title/slug:

```js
const APP_EVENT_ID_BY_PIX = {
  "smartgovernmentsummit": "107",
};
```

Add one entry per event the app should receive photo pushes for. An event with
no mapping is skipped (logged as a warning) — and because it's skipped before
any state is written, adding its mapping later starts fresh and seeds silently
rather than blasting a backlog of notifications.

Debouncing:

- **First run for an event seeds state silently** — deploying mid-event does
  not blast a notification for every day that already has photos.
- A day's "now available" push fires once, on the transition into having
  photos.
- Additional "more photos added" pushes for the same day are rate-limited to
  once per 2 hours (`MORE_COOLDOWN_MS`).

The `data.targetPage = "gallery"` payload (with `pixEventId` + `day`) drives
tap-through: the app opens `EventGalleryScreen` filtered to that day.

### One-time setup

The poller needs its **own** dedicated pix member account (never a real user,
never the app's account — see the API guide §1). Ask a platform admin to
create one, then store the credentials as function secrets:

```bash
cd "main app"
firebase functions:secrets:set PIX_API_EMAIL       # poller account email
firebase functions:secrets:set PIX_API_PASSWORD    # poller account password
# Optional — defaults to https://api.pix.dx5ve.com:
# firebase functions:config or set PIX_API_BASE_URL in .env for the codebase
```

Base URL override (optional) via `functions/.env`:

```
PIX_API_BASE_URL=https://api.pix.dx5ve.com
```

### Deploy

```bash
cd "main app"
firebase deploy --only functions          # deploys galleryPhotoNotifier only
```

The first deploy also provisions a Cloud Scheduler job for the every-10-minutes
trigger (enable the Cloud Scheduler API if prompted).

### Notes

- State writes use the Admin SDK, which bypasses Firestore security rules, so
  no rules change is required. Clients never read/write `galleryNotifierState`.
- Tune cadence (`schedule`), cooldown (`MORE_COOLDOWN_MS`) and the minimum
  photo count (`MIN_PHOTOS`) at the top of `index.js`.
