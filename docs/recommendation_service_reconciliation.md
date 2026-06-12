# Recommendation Service Reconciliation

_Investigated 2026-06-12. Not an emergency — architecture cleanup. Keep both implementations for now; this doc records what each is and proposes one owner._

## Current implementations

### 1. Firebase Admin standalone (`crushhour-recommendation-service/`)
- **Location:** `Crush/crushhour-recommendation-service/` (also vendored under `Crush App/crushhour-recommendation-service/`).
- **Purpose:** Standalone REST recommendation/discovery API.
- **Stack:** Express 5 + `firebase-admin` 13, Node 20, Dockerized (`PORT=8080`, Cloud Run-shaped). Includes a Firebase **DataConnect** generated client in `src/dataconnect-generated/`.
- **Inputs:** HTTP requests with a Firebase ID token (`Authorization: Bearer <idToken>`, verified via `admin.auth().verifyIdToken`).
- **Outputs:** JSON profile lists; proximity computed in-process via **Haversine distance**.
- **Data source:** Firestore (`admin.firestore()`).
- **How it's run:** `node index.js` in a container.
- **Deployment:** Not currently wired to production. It backs the app's `BackendMode.http` path (`HttpDiscoveryRepository`), which is **not** the default.
- **Secrets used:** `admin.credential.applicationDefault()` → ambient ADC / `GOOGLE_APPLICATION_CREDENTIALS` (no key file in code).
- **Pros:** Clean separation; independently scalable/deployable; can hold heavier ranking logic without bloating Cloud Functions.
- **Cons:** Lives partly outside the app repo (drift risk; duplicated copy); no tests; not deployed; reimplements auth/distance that Functions already have.
- **Current status:** Parallel/experimental. Not on the live path.

### 2. BigQuery/ML + Cloud Functions (in `Crush App/functions/`)
- **Location:** `Crush App/functions/src/index.ts` (BigQuery client + discovery/match logic); Flutter `lib/features/discovery/` repositories.
- **Purpose:** Production discovery serving + interaction-event capture for future ML.
- **Stack:** Firebase Cloud Functions (TypeScript) + Firestore + `@google-cloud/bigquery`.
- **Inputs:** Authenticated callable/REST discovery requests from the app (`FirebaseDiscoveryRepository`).
- **Outputs:** Discovery deck from Firestore; interaction events streamed to BigQuery.
- **Data source:** Firestore (serving) + BigQuery dataset **`crushhour_ml`**, table **`interaction_events`** (analytics/feature store).
- **How it's run:** Firebase Functions runtime (`admin.initializeApp()` — runtime SA, no key file).
- **Deployment:** Live production path (`BackendMode.firebase` is the default in `lib/core/di.dart`). Requires Blaze.
- **Secrets used:** Runtime service account (no committed key).
- **Pros:** Already the production path; BigQuery gives a scalable analytics/feature foundation; no extra service to operate.
- **Cons:** BigQuery is currently only an **event sink** (non-critical inserts) — no ranking/scoring model consumes it yet; `index.ts` is very large (14k+ lines) and mixes concerns.
- **Current status:** **Live.** Serving = Firestore via Functions; BigQuery = passive interaction logging.

## App wiring (how it's selected)
`lib/core/di.dart` switches on `BackendMode` (default `firebase`):
- `firebase` → `FirebaseDiscoveryRepository` (**live**)
- `http` → `HttpDiscoveryRepository` (would call the standalone service)
- `hybrid`/`stub` → debug/demo only (real + mock profiles; mock disabled in release)

So today the app serves recommendations from **Firestore/Functions**, logs interactions to **BigQuery**, and the standalone service is dormant behind the `http` mode.

## Decision needed
Which implementation is the source of truth?
1. Keep Firebase Admin standalone as a temporary production service.
2. Move fully to BigQuery/ML.
3. **Firebase Admin for realtime actions + BigQuery/ML for ranking/scoring.** ← recommended

### Recommendation (for Crush)
```
Flutter / Web app
      ↓
Recommendation API  (Cloud Functions — already live, owns realtime serving + auth)
      ↓
Firestore           (realtime user/match/profile data)
      ↓
BigQuery / ML       (crushhour_ml — heavier scoring, ranking, analytics, model training)
```
Make **Functions + Firestore** the serving/source-of-truth layer (it already is), and grow
**BigQuery `crushhour_ml`** from passive logging into the **ranking/scoring intelligence layer**
that feeds scores back to Functions. Fold the standalone service's useful bits (Haversine,
DataConnect queries) into Functions OR keep it only if you deliberately want a separate
scoring microservice — don't run two systems doing the same serving job.

## Migration plan
- **Phase 1 — Confirm live path:** Verified default `BackendMode.firebase`; standalone service unused in prod. (Done.)
- **Phase 2 — Standardize I/O model:** Define one discovery request/response contract shared by Functions and the standalone service (reuse `discovery_dto.dart` + the REST allowlist).
- **Phase 3 — Comparison tests:** Given identical inputs, compare standalone-service output vs Functions output to quantify divergence before retiring either.
- **Phase 4 — Choose one serving path:** Recommend Functions+Firestore for serving; design a BigQuery→Functions scoring hand-off (scheduled scoring job or Vertex endpoint writing scores Functions read).
- **Phase 5 — Archive the unused path:** Once parity is proven, archive `crushhour-recommendation-service` (or repurpose it explicitly as the scoring microservice) and remove the duplicated vendored copy under `Crush App/`.

## Cleanup nits found
- The standalone service is **duplicated** (top-level `Crush/crushhour-recommendation-service` and vendored inside `Crush App/`). Pick one home to avoid drift.
- BigQuery inserts are correctly **non-fatal**; before relying on `crushhour_ml` for ranking, add schema/retention docs for `interaction_events`.
