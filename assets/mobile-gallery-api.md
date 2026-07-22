# Mobile Gallery API

Reference for consuming the Event Image Service API from a client app — mobile (Flutter, native), web (React or any browser SPA), or plain JS. **Read-only**: authentication and fetching events/galleries/days/sessions, with pagination, sorting, searching, and filtering. All endpoints are on the Fastify API `https://api.pix.dx5ve.com`, as the base URL.

CORS only matters for browser-based clients — a native HTTP client (URLSession, OkHttp, Dart's `http`/`dio`, etc.) is not subject to it. If a web app calls this API directly from browser JS, its origin needs to be added to `CORS_ORIGIN` on the API, or every request gets blocked client-side regardless of a valid token.

## 1. Authentication

Each client app should authenticate as its **own dedicated org-member account** (ask a platform admin to create one per app/team), not a real end user's personal login — your app's users never see any of this, never enter credentials, and never know the account exists. The account has full member privileges (whatever its assigned org role can do) at the server level, but this doc only covers — and consumer apps should only ever call — the read routes below.

### Login

```
POST /auth/login
Content-Type: application/json

{ "email": "app-account@example.com", "password": "..." }
```

Success (`200`):

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "expiresIn": 3600,
  "refreshToken": "9f1c2e...64-hex-chars",
  "refreshExpiresIn": 2592000,
  "user": {
    "id": "uuid",
    "email": "app-account@example.com",
    "name": "string | null",
    "role": "platform_admin | user",
    "isEmailVerified": true
  }
}
```

Failure (`401`): `{ "error": "Invalid email or password" }`

There is no public signup — accounts are created via an organization admin's invite flow, or platform-admin bootstrap. Your app's dedicated account will be created for you; you won't self-register it.

### Using the token

Every other endpoint requires:

```
Authorization: Bearer <token>
```

`token` is a JWT signed with the API's `AUTH_SECRET`, expiring in **`expiresIn` seconds (1 hour)**. The same token shape is issued by the web app's `GET /api/session-token` (used by the browser UI) — both are interchangeable against every route below.

### Refreshing the session

The access token's 1-hour expiry is intentionally short — don't try to work around it by caching the account's password client-side. Instead, use the `refreshToken` from login to silently mint a new access token, indefinitely, without ever touching the password again:

```
POST /auth/refresh
Content-Type: application/json

{ "refreshToken": "9f1c2e...64-hex-chars" }
```

Success (`200`): same shape as login's response — a **new** `token` *and a new, rotated* `refreshToken`.

Failure (`401`): `{ "error": "Invalid or expired refresh token" }`

Two rules that matter for a correct client implementation:

1. **The refresh token is single-use.** Every call to `/auth/refresh` invalidates the token you sent and issues a new one in the response. You must overwrite your stored `refreshToken` with the one from *this* response — reusing the one you just spent will `401` on the next attempt. There is no grace window.
2. **`refreshToken` expiry is `refreshExpiresIn` seconds (30 days) from the most recent login or refresh**, not fixed to the original login. As long as your app refreshes at least once every 30 days (in practice: every time it's opened, or on a background timer), a user session never needs the password again. If a client goes unused for 30+ days, its refresh token has expired and it must call `/auth/login` again.

**Client implementation pattern** (same shape regardless of platform):

- Store `token`, `refreshToken`, and the access token's expiry time (compute it yourself: `now + expiresIn`) in your platform's secure/private storage — Flutter: `flutter_secure_storage`; React/browser: an in-memory store or `sessionStorage`, not `localStorage`, to limit exposure to XSS; plain JS/Node: wherever you'd keep any other secret. Never log these values.
- Before making an API call, check if the access token is expired (or about to expire — a small buffer, e.g. 30s, avoids a request landing right at the boundary). If so, call `/auth/refresh` first and update your stored `token`/`refreshToken`/expiry from the response, then proceed with the original call.
- As a backstop, also catch a bare `401` from any API call (covers clock drift or a token invalidated some other way): attempt one `/auth/refresh`, retry the original request once if it succeeds, and if the refresh itself fails, fall back to `/auth/login` with the app's stored credentials.
- Because refresh rotates the token, guard against concurrent refreshes racing each other (e.g. two API calls firing at once, both seeing an expired token): use a single in-flight refresh promise/lock that concurrent callers await, rather than each independently calling `/auth/refresh` and burning each other's rotated token.
- These apps have no backend of their own, so the app's `email`/`password` for `/auth/login` unavoidably ships inside the client (Flutter: `--dart-define`/build config, not committed to source; React/web: a bundled constant). That's a known, accepted tradeoff for this account, not an oversight — it's why every app gets its **own** dedicated account instead of one shared credential: if one app's build gets decompiled/inspected and its password extracted, only that one account needs disabling, not everyone's. Only use the password for the very first login or full backstop re-auth (previous bullet) — the refresh flow exists specifically so it's not called on every app open.

### Access control

Every event-scoped route checks the caller's organization membership server-side:

- `platform_admin` — access to everything.
- `org_admin` / `member` of the event's organization — access to that org's events.
- Anyone else — `403 Forbidden` (or `404` if you don't have access to know the resource exists, used for photo/session sub-resources to avoid leaking existence).

There's no separate "read-only" role for gallery viewing yet — org membership is currently all-or-nothing between `org_admin` and `member`. If the mobile app needs a lighter-weight "invited guest, view-only" role, that's a schema change, not something to work around client-side.

## 2. Discovering events

```
GET /events?organizationId=<uuid>   # or omit to get every event the caller can see
Authorization: Bearer <token>
```

Returns an array of event objects: `{ id, title, slug, timezone, coverPhotoId, organizationId, visibility, createdAt }`.

```
GET /events/:id
Authorization: Bearer <token>
```

Single event, `404` if not found or not accessible.

## 3. Fetching the gallery

```
GET /events/:id/photos?sort=captured_at&day=2026-07-15&sessionId=<uuid>&search=sunset&hasCaption=true&variants=thumb,medium&cursor=<opaque>&limit=50
Authorization: Bearer <token>
```

All query params are optional except the path `:id`.

| Param        | Values                                                      | Default       | Notes                                                                                                                                                                                                           |
| ------------ | ----------------------------------------------------------- | ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sort`       | `captured_at` \| `uploaded_at` \| `source_modified_at`      | `captured_at` | The three sort axes. `captured_at` comes from EXIF and can be null for screenshots/edited files — those sort last.                                                                                              |
| `day`        | `YYYY-MM-DD`                                                | —             | Filters to photos grouped into that day, computed in the **event's own timezone** (not the client's). Get the valid set from `GET /events/:id/days` below rather than guessing.                                 |
| `sessionId`  | uuid                                                        | —             | Filters to photos tagged with that session (see §4). Combine freely with `day` and `sort`.                                                                                                                      |
| `search`     | free text, 1–200 chars                                      | —             | Case-insensitive substring match against `caption`. No match against `altText` or anything else. `%`/`_`/`\` in your search text are escaped automatically, so they're matched literally, not as SQL wildcards. |
| `hasCaption` | `true` \| `false`                                           | —             | `true` returns only photos with a non-null caption; `false` only photos without one. Omit to not filter on this at all.                                                                                         |
| `variants`   | comma-separated subset of `thumb,small,medium,large,xlarge` | all five      | Only sign and return the requested variant labels — smaller payload and fewer signing calls if you only need e.g. `thumb` for a grid. `400` if any label isn't recognized.                                      |
| `cursor`     | opaque string from a previous response                      | —             | Keyset pagination — see below.                                                                                                                                                                                  |
| `limit`      | 1–200                                                       | 50            | Page size.                                                                                                                                                                                                      |

Only photos with `status: "ready"` are ever returned — still-processing or failed uploads are invisible to this endpoint. Soft-deleted photos are always excluded regardless of any filter above.

**Caching note**: only the plain first page — no `cursor`, no `search`, no `hasCaption`, no `variants` — is cached server-side (60s TTL, invalidated on every write). Any request using `search`/`hasCaption`/`variants` always hits the database fresh; expect it to be marginally slower than the plain gallery load, not a correctness difference.

Response:

```json
{
  "photos": [
    {
      "id": "uuid",
      "eventId": "uuid",
      "sessionId": "uuid | null",
      "contentType": "image/jpeg",
      "byteSize": 5893,
      "width": 1200,
      "height": 800,
      "capturedAt": "2026-07-15T09:03:00.000Z | null",
      "uploadedAt": "2026-07-15T12:38:08.863Z",
      "sourceModifiedAt": "string | null",
      "day": "2026-07-15",
      "position": null,
      "sourceProvider": "s3",
      "caption": "string | null",
      "altText": "string | null",
      "blurhash": "U8Bh]7tnfQtnyZj]fQj]fQfQfQfQyZj]fQj]",
      "status": "ready",
      "variants": [
        { "label": "thumb", "width": 240, "height": 160, "url": "https://..." },
        { "label": "small", "width": 640, "height": 427, "url": "https://..." },
        { "label": "medium", "width": 1280, "height": 800, "url": "https://..." },
        { "label": "large", "width": 2048, "height": 1365, "url": "https://..." },
        { "label": "xlarge", "width": 2880, "height": 1920, "url": "https://..." }
      ]
    }
  ],
  "nextCursor": "opaque-string-or-null"
}
```

**Variant selection**: use `blurhash` as a placeholder while loading, `thumb` for grid views, `medium`/`large` for a detail/lightbox view, `xlarge` only if you actually need near-full-resolution (e.g. pinch-zoom or share/export). Not every rung necessarily exists for very small source images (sharp skips upscaling), so treat the `variants` response array as "pick the closest label that exists," not "all 5 are always present." Use the `?variants=` **query param** (§3 table) to ask the server to only sign and return specific labels in the first place, rather than fetching all five and discarding the ones you don't render.

**Variant URLs are signed and expire in 1 hour.** Don't cache them past that — re-fetch the photo (or the whole page) to get a fresh URL. The underlying object storage key is stable; only the signature/expiry changes.

**Pagination**: keyset-based, not offset-based. Take `nextCursor` from a response and pass it back as `cursor` on the next request to get the following page, in the same `sort` order. `nextCursor` is `null` when there's nothing more. Cursors are only valid for the `sort` value they were issued under — don't reuse a `captured_at` cursor after switching to `uploaded_at`.

### Days list

```
GET /events/:id/days
Authorization: Bearer <token>
```

```json
[{ "day": "2026-07-14", "count": 42 }, { "day": "2026-07-15", "count": 118 }]
```

Use this to build a day picker/filter chip row without guessing valid dates. Ordered ascending, only counts `ready` photos.

## 4. Sessions ("special sessions")

A session is a named sub-block of time within an event (e.g. "Morning Keynote", "Evening Reception") that photos can optionally be tagged with, independent of the day grouping.

```
GET /events/:id/sessions
Authorization: Bearer <token>
```

```json
[{ "id": "uuid", "eventId": "uuid", "name": "Morning Keynote", "startsAt": "2026-07-15T09:00:00.000Z", "endsAt": "2026-07-15T11:00:00.000Z", "createdAt": "..." }]
```

Filter the gallery to a session with `GET /events/:id/photos?sessionId=<uuid>` (§3), combinable with `day` and `sort`. Sessions themselves are created/edited by organizers in the admin dashboard, not by consumer apps — this doc only covers listing them.

## Known gaps / follow-ups

- No "view-only guest" role — org membership is `org_admin` or `member` only. Public-facing consumer apps use a dedicated per-app member account instead (see §1) — that account technically has write access too (session/caption edits, uploads, bulk actions, reordering — see the API source under `apps/api/src/routes/` if you ever need that surface), enforced only by not documenting/using those routes here, not by the server refusing them.
- Refresh tokens aren't scoped or rate-limited beyond single-use rotation — a script that automates `/auth/refresh` in a tight loop isn't currently throttled.
- Variant URLs expire in 1 hour and there's no long-lived/CDN-backed URL option yet — every gallery re-render within the hour can reuse the same fetch, but a paused/backgrounded app coming back after an hour needs a re-fetch, not just a redraw.
