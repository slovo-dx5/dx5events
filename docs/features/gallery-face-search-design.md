# Gallery Face Search — "Find My Photos"

**Status:** Design / proposal
**Author:** (drafted with Claude Code)
**Date:** 2026-07-10
**Feature:** Let an attendee take a selfie and have the event gallery filter to
only the photos they appear in, at a scale of 1,000+ (growing) photos per event.

---

## 1. Goal & scope

- User opens the gallery, taps **"Find my photos"**, grants consent, takes a
  selfie.
- The app returns the subset of gallery photos in which that person appears.
- Must scale to **1,000–10,000+ photos** per event without doing heavy work on
  the phone at search time.
- Privacy-first: per the product decision, **the selfie image never leaves the
  device** — only a numeric face embedding (a vector of ~128–512 floats) is
  sent to the backend.

Non-goals (for v1): tagging people by name, clustering "all unique faces",
recognising the same person across multiple events, or building an attendee
face directory.

---

## 2. How face recognition actually works

Three distinct steps — do not conflate them:

1. **Detection** — find the faces in an image and their bounding boxes. A photo
   can contain 0..N faces.
2. **Embedding (a.k.a. encoding / face template)** — run each detected face
   through a neural net that outputs a fixed-length vector. The same person's
   face produces vectors that are *close together* in vector space; different
   people are far apart.
3. **Matching** — compare the user's selfie embedding against stored gallery
   embeddings using **cosine similarity** (or Euclidean distance). Anything
   above a similarity threshold is a match.

### The scaling insight: index once, search many

Running detection+embedding on 1,000 photos *per search* is infeasible on a
phone. Instead:

- **Ingest phase (once per photo, server-side):** when a photo is added to the
  gallery, detect every face and store one embedding row per face, linked to
  the `photo_id`. 1,000 photos might yield ~5,000 face vectors — computed a
  single time.
- **Search phase (per user):** embed the *one* selfie, run a nearest-neighbour
  search over the stored vectors, return matching `photo_id`s. This is
  milliseconds even at 100k+ faces.

---

## 3. The constraint that decides the architecture

> **Embeddings are model-specific. A vector from model A cannot be compared to a
> vector from model B. And AWS Rekognition will not accept an externally
> computed embedding — its `SearchFacesByImage` requires the raw image, which it
> embeds internally with its own private model.**

Consequences:

| If the selfie is embedded… | Then the gallery must be embedded with… | Matching engine |
|---|---|---|
| **On-device** (our privacy choice) | the **same model**, server-side | **We run the vector search ourselves** (self-hosted) |
| By uploading the image to AWS | AWS Rekognition's model | AWS Rekognition |

Because product chose **on-device selfie embedding**, the consistent design is a
**self-hosted, single-matched-model pipeline**. Rekognition is documented in
§6 as the alternative should the on-device requirement ever be relaxed.

---

## 4. Recommended architecture (self-hosted, matched model)

```
                    ┌────────────────────────── INGEST (server, once per photo) ─────────────────────────┐
  New gallery photo │  Directus upload ──▶ webhook/flow ──▶ Face service (Python)                          │
  ───────────────▶  │        │                                   │  detect faces (RetinaFace/MTCNN)       │
                    │        │                                   │  embed each face (MobileFaceNet TFLite) │
                    │        ▼                                   ▼                                          │
                    │   event_photos                        photo_faces (embedding[512], bbox, photo_id)   │
                    └───────────────────────────────────────────────────────────────────────────────────-─┘

                    ┌────────────────────────── SEARCH (per user) ──────────────────────────────────────-─┐
  Selfie on phone   │  ML Kit detect face ──▶ crop ──▶ MobileFaceNet TFLite embed ──▶ 512-float vector     │
  ───────────────▶  │                                                     │  (selfie image discarded)      │
                    │                                                     ▼                                │
                    │   POST /photo-search {eventId, vector, threshold}                                    │
                    │                                                     │                                │
                    │        cosine ANN over photo_faces (pgvector) ──────┘                                │
                    │        return [photo_id...] ──▶ gallery filters to those photos                      │
                    └──────────────────────────────────────────────────────────────────────────────────-─┘
```

### 4.1 The matched model

Both ends **must run the identical model** so the vectors live in the same
space. Recommended: **MobileFaceNet (ArcFace-trained)** exported to:
- **TFLite** for the Flutter on-device selfie embedding, and
- the same weights (TFLite/ONNX) on the server for gallery ingest.

MobileFaceNet is small (~4 MB), mobile-friendly, and accurate enough for a
"find my photos" use case. (A heavier server-only model like InsightFace
`buffalo_l` is *more* accurate but can't be paired with a phone — see the
alternative in §4.5.)

### 4.2 Ingest pipeline

A small **Python microservice** (or containerised job) triggered by a Directus
**Flow / webhook** on new `event_photos`:
1. Download the image.
2. Detect faces (RetinaFace or MTCNN).
3. For each face ≥ a minimum size / detection confidence, compute the
   MobileFaceNet embedding.
4. Insert a `photo_faces` row per face.
Batch-runnable to backfill the existing gallery in one pass (1,000 photos on CPU
is minutes–tens of minutes; trivial on a GPU).

### 4.3 Storage / vector search

Use **PostgreSQL + `pgvector`** (Directus already runs on Postgres, so this is
the lowest-friction option):
- `photo_faces.embedding vector(512)` with an IVFFlat/HNSW index.
- Query: `SELECT photo_id, 1 - (embedding <=> :selfie) AS score
  FROM photo_faces WHERE event_id = :e ORDER BY embedding <=> :selfie LIMIT 200;`
  then keep rows with `score >= threshold`, dedupe by `photo_id`.

If pgvector isn't available, at 1,000 photos you *can* brute-force cosine in the
service over the event's vectors in memory (~5k dot products = sub-millisecond),
but pgvector is the clean long-term answer.

### 4.4 On-device selfie flow (Flutter)

- **Camera + consent screen** (see §7).
- **google_mlkit_face_detection** to detect and crop the largest face.
- **tflite_flutter** running MobileFaceNet on the crop → 512-float vector,
  L2-normalised.
- `POST /photo-search` with `{ eventId, vector, threshold }`.
- Discard the selfie bytes immediately (never persist, never upload).
- Filter the existing gallery grid to the returned `photo_id`s; offer a "show
  all / clear filter" toggle.

### 4.5 Accuracy alternative (if on-device is relaxed later)

If uploading the selfie *to our own backend* (not a third party) becomes
acceptable, do **all** embedding server-side with a stronger model
(InsightFace `buffalo_l`, ArcFace-R100). Better accuracy, no model-matching
constraint, simpler app. The only thing lost is "selfie never leaves the
device" — it would leave the device but go only to our infra and be deleted
immediately after search. Worth revisiting after v1.

---

## 5. Data model (Directus)

**`event_photos`** (already planned per gallery_repository TODO)
- `id`, `event_id`, `image` (file), `caption`, `taken_at`, `faces_indexed` (bool)

**`photo_faces`** (new)
- `id`
- `photo_id` → event_photos
- `event_id` (denormalised for fast filtering)
- `embedding` `vector(512)`
- `bbox` (json: x,y,w,h — for future "highlight the face" UX)
- `det_score` (float)
- `created_at`

**No selfie / attendee face is ever stored.** The search vector is used
transiently in one request and dropped.

---

## 6. Engine comparison & cost at your scale ("advise me")

Assumed scale: an event of ~5,000 photos (~25,000 faces) and ~2,000 attendee
searches. Multiple such events per year.

| | **Self-hosted (recommended for on-device)** | **AWS Rekognition** |
|---|---|---|
| Compatible with on-device selfie embedding? | ✅ Yes (same model both ends) | ❌ No (needs the selfie image) |
| Accuracy | Good (MobileFaceNet) | Excellent |
| **Ingest cost** | Compute only (a batch job on a CPU/GPU box) | ~$0.001/image → ~**$5** per 5k-photo event* |
| **Search cost** | Compute only | ~$0.001/search → ~**$2** per 2k searches* |
| **Face storage** | In your Postgres (negligible) | ~$0.01 per 1k faces/mo → cents* |
| **Ops / infra** | You run a Python service + pgvector | Fully managed |
| **Data residency** | 100% in your infra | Face data indexed in AWS |
| **Build effort (v1)** | Higher (~1.5–3 wk) | Lower (~3–5 days) — *but incompatible with the chosen privacy model* |

\* Verify current AWS pricing before quoting to stakeholders; figures are
order-of-magnitude.

**Verdict:** At your scale, Rekognition's *cost* is negligible (single-digit
dollars per event) — the reason to prefer self-hosting here is **not cost, it's
the on-device / data-residency requirement you chose.** Self-hosting only also
wins decisively on cost at very large scale (millions of faces) where
per-image fees compound. Given the privacy stance, **go self-hosted with a
matched MobileFaceNet model.** Keep Rekognition in your back pocket as the
faster-to-ship fallback if the on-device constraint is ever dropped.

---

## 7. Privacy, consent & legal (must-do, not optional)

Face templates are **biometric / special-category data** (GDPR Art. 9, Kenya
DPA 2019, Illinois BIPA, etc.). Requirements:

- **Explicit opt-in** screen before the camera opens, in plain language:
  what's captured, that it's processed on-device, that only a math vector is
  sent, that it's used solely to find their photos, and that it's deleted right
  after.
- **No retention** of the selfie or its embedding beyond the single search
  request.
- **Gallery photos** should already be covered by the event's photography /
  media consent — confirm this with the organiser.
- Provide a way for a user to **request removal** of a photo they appear in.
- Secure the `photo_faces` table (it *is* biometric data) and document a
  retention/deletion policy for it tied to event lifecycle.

Building the consent screen is part of v1 scope, not a follow-up.

---

## 8. Accuracy, thresholds & edge cases

- **Threshold tuning:** start with cosine similarity ≈ 0.5–0.6 for MobileFaceNet
  and calibrate against a labelled test set of your real event photos. Expose
  it as a server config so you can tune without an app release.
- **Group / crowd photos:** many small faces → lower detection confidence. Set a
  minimum face size and `det_score` at ingest to avoid junk vectors.
- **False positives** are the main UX risk (someone else's photos shown). Prefer
  a *stricter* threshold and let users "load more / loosen" than over-return.
- **Sunglasses, masks, profiles, poor lighting** reduce recall — acceptable for
  v1; document as known limitation.
- **Multiple faces of the searcher** across photos is fine — dedupe results by
  `photo_id`, rank by best face score.
- **No face in selfie / multiple faces in selfie:** validate on-device and
  prompt to retake.

---

## 9. Phased rollout / task breakdown

**Phase 0 — Backend foundation for real photos** (prereq, already flagged in
`gallery_repository.dart` TODO)
- Move gallery from bundled assets to Directus `event_photos` fetched by
  `event_id`; paginate; cache thumbnails.

**Phase 1 — Ingest pipeline**
- Stand up the Python face service (detect + MobileFaceNet embed).
- Add `photo_faces` collection + pgvector column & index.
- Directus Flow/webhook on new photo → index faces; backfill job for existing.

**Phase 2 — Search API**
- `POST /photo-search {eventId, vector, threshold}` → deduped `[photo_id...]`.
- Threshold as server config.

**Phase 3 — Flutter feature**
- Consent screen + camera capture.
- ML Kit face detect + crop + MobileFaceNet TFLite embed on-device.
- Wire to `/photo-search`; filter gallery grid; "clear filter" toggle; empty/
  error/no-face states.

**Phase 4 — Hardening**
- Threshold calibration on real photos; false-positive review.
- Analytics (opt-in rate, match counts) — no biometric data in analytics.
- Retention/deletion policy for `photo_faces`.

---

## 10. Open questions / decisions needed

1. **Model choice confirmed?** MobileFaceNet TFLite on both ends — or revisit
   §4.5 (server-only, stronger model, selfie uploaded to *our* backend)?
2. **Where does the Python face service live?** Alongside Directus, a separate
   container, or a serverless GPU function?
3. **Is pgvector available** on the current Postgres, or do we brute-force in
   the service for v1?
4. **Photography consent** for gallery subjects — confirmed by organisers per
   event?
5. **Retention policy** for `photo_faces` — delete N days after event end?
```