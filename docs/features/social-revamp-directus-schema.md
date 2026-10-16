# Social Revamp — Directus Schema Spec

This is the **backend prerequisite** for the revamped social feature. Create these
collections/fields in the Directus admin at `https://subscriptions.cioafrica.co`
(the exact names/keys below are what the Flutter app expects). Nothing in the app
works end-to-end until this exists.

> The app authenticates every request with the shared admin bearer token in
> `lib/dioServices/dioClient.dart`, so no per-collection public permissions are
> strictly required — but if you later add per-user Directus auth, grant
> create/read on these collections accordingly.

---

## 1. `Social` (existing — add fields)

Keep existing fields (`id`, `date_created`, `user_id`, `user_name`,
`post_description`, `picture_link`). **Add:**

| Field | Type | Notes |
|---|---|---|
| `status` | string (dropdown) | `published` \| `hidden` \| `removed`. Default `published`. Feed shows only `published`. |
| `is_pinned` | boolean | Default `false`. Replaces the hard-coded pinned-UUID logic. |
| `reaction_count` | integer | Default `0`. Denormalized for cheap display. |
| `comment_count` | integer | Default `0`. Denormalized. |
| `hashtags` | json (array of string) | Lowercased tags parsed from the post text, for `#tag` filtering. |

**Stop writing** the old embedded `likes` / `Comments` JSON fields (leave the
columns for backfill, but the app no longer reads/writes them).

## 2. `post_reactions` (new)

One row per (post, user). Changing reaction updates `type`; un-reacting deletes the row.

| Field | Type | Notes |
|---|---|---|
| `id` | auto PK | |
| `post_id` | M2O → `Social` | |
| `user_id` | integer | |
| `user_name` | string | |
| `type` | string | `like` \| `love` \| `laugh` \| `celebrate` \| `insightful` |
| `date_created` | timestamp | Directus "date created" special |

## 3. `post_comments` (new)

| Field | Type | Notes |
|---|---|---|
| `id` | auto PK | |
| `post_id` | M2O → `Social` | |
| `parent_comment_id` | M2O → `post_comments` (self) | `null` = top-level; set = reply (threading) |
| `user_id` | integer | |
| `user_name` | string | |
| `comment` | text | |
| `status` | string | `published` \| `hidden` \| `removed`. Default `published`. |
| `date_created` | timestamp | |

## 4. `post_reports` (new)

| Field | Type | Notes |
|---|---|---|
| `id` | auto PK | |
| `target_type` | string | `post` \| `comment` |
| `target_id` | integer | id of the reported post/comment |
| `reporter_id` | integer | |
| `reason` | string | |
| `resolved` | boolean | Default `false` |
| `date_created` | timestamp | |

## 5. `user_blocks` (new)

| Field | Type | Notes |
|---|---|---|
| `id` | auto PK | |
| `blocker_id` | integer | the user doing the blocking |
| `blocked_id` | integer | the user being blocked |
| `date_created` | timestamp | |

## 6. `social_profiles` (new)

| Field | Type | Notes |
|---|---|---|
| `id` | auto PK | |
| `user_id` | integer (unique) | one profile per user |
| `avatar` | uuid (M2O → directus_files) | nullable; app falls back to colored initials |
| `headline` | string | nullable |
| `bio` | text | nullable |

---

## Optional but recommended: Directus Flows (counters + moderation)

- **Reaction/comment counters:** a Flow on create/delete of `post_reactions` /
  `post_comments` that recomputes `Social.reaction_count` / `comment_count`.
  (If skipped, the app increments optimistically and can recompute on fetch.)
- **Realtime:** for live updates, the server needs `WEBSOCKETS_ENABLED=true`
  (env). If it stays off, the app uses its polling fallback — no schema impact.

## Backfill (one-time)

Migrate existing embedded data from `Social` rows into the new tables:
- each element of old `likes` → a `post_reactions` row (`type = like`)
- each element of old `Comments` → a `post_comments` row (top-level, `status = published`)
- set `Social.reaction_count` / `comment_count` from the counts
- set `Social.status = published`, `is_pinned = false` (except the currently
  pinned post → `true`).
