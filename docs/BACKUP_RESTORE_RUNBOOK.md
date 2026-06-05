# Firestore Backup & Restore Runbook

*Last updated: 2026-06-02 (DB-003)*

Owner: Backend / Platform on-call. Escalation: project owner (`crush-265f7`).

This runbook covers the managed Firestore database `(default)` in project
`crush-265f7` (location `nam5`, see [`firebase.json`](../firebase.json)). It
documents backup cadence, restore steps, and the validated dry run required
before relying on these procedures in an incident.

---

## 1. Backup cadence & ownership

| Item | Value |
|------|-------|
| Mechanism | `scheduledFirestoreBackup` Cloud Function ([`functions/src/index.ts`](../functions/src/index.ts)) using `FirestoreAdminClient.exportDocuments` |
| Schedule | Every 24h, `UTC` |
| Scope | All collections (`collectionIds: []`) |
| Destination | `gs://crush-265f7-firestore-backups/<YYYY-MM-DD>/` |
| Retention | 30 days, enforced by **bucket lifecycle** (must be set manually — see §2) |
| Owner | Backend / Platform on-call |

The function logs the export operation name on success and swallows errors
(returns `null`). See the open follow-ups in §5 — failure alerting and bucket
lifecycle are **not yet automated** and must be configured manually.

---

## 2. One-time infrastructure setup (prerequisites)

These must exist for the scheduled backup to succeed and for retention to apply.
Run once per environment with an account that has `roles/datastore.importExportAdmin`
and `roles/storage.admin`.

```bash
PROJECT=crush-265f7
BUCKET=gs://${PROJECT}-firestore-backups

# 1. Create the backup bucket (same region as Firestore: nam5 → us multi-region)
gsutil mb -p "$PROJECT" -l us "$BUCKET"

# 2. Apply 30-day deletion lifecycle (matches the documented retention window)
echo '{"rule":[{"action":{"type":"Delete"},"condition":{"age":30}}]}' > /tmp/lifecycle.json
gsutil lifecycle set /tmp/lifecycle.json "$BUCKET"

# 3. Grant the Cloud Functions runtime service account export permission
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${PROJECT}@appspot.gserviceaccount.com" \
  --role="roles/datastore.importExportAdmin"
```

> **Strongly recommended:** also enable Firestore Point-in-Time Recovery (PITR)
> for protection against logical corruption between daily exports:
> `gcloud firestore databases update --database='(default)' --enable-pitr`
> (7-day continuous recovery window). PITR complements, not replaces, exports.

---

## 3. Restore procedure (production)

> Importing **overwrites** documents with matching paths and does not delete
> documents created after the backup. For a clean restore after data loss,
> import into a **fresh / staging database** first, validate, then decide on a
> targeted re-import. Never import an unvalidated backup straight over prod.

```bash
PROJECT=crush-265f7
BUCKET=gs://${PROJECT}-firestore-backups
BACKUP_DATE=2026-06-01        # pick the snapshot to restore

# 1. Identify the export prefix to restore
gsutil ls "${BUCKET}/${BACKUP_DATE}/"

# 2. (Safer) Restore into a staging database to validate first
gcloud firestore import "${BUCKET}/${BACKUP_DATE}" \
  --database='staging-restore'

# 3. Validate in staging (spot-check key collections: users, matches, messages)

# 4. Restore into the live database once validated
gcloud firestore import "${BUCKET}/${BACKUP_DATE}" \
  --database='(default)'

# Optional: restore only specific collections
gcloud firestore import "${BUCKET}/${BACKUP_DATE}" \
  --database='(default)' \
  --collection-ids='users,matches'
```

Post-restore checklist:
- Re-deploy security rules and indexes if they changed since the snapshot
  (`firebase deploy --only firestore:rules,firestore:indexes`).
- Confirm scheduled functions resume (account-deletion sweep, retention queue).
- Spot-check `users`, `matches/{id}/messages`, and subscription state.

---

## 4. Validated dry run (local, repeatable)

The restore **mechanics** (Firestore export format → import) are validated
locally against the emulator on every run of the two scripts below. This proves
the export→import round trip restores top-level documents and subcollections
cleanly. Last validated: **2026-06-02** (passed).

```bash
# Phase A — seed a marker doc and export on exit
firebase emulators:exec --only firestore --project demo-crushhour \
  --export-on-exit=./tmp_backup_dryrun \
  "node functions/scripts/backup_dryrun_seed.js"

# Phase B — start a fresh emulator importing that export, then verify
firebase emulators:exec --only firestore --project demo-crushhour \
  --import=./tmp_backup_dryrun \
  "node functions/scripts/backup_dryrun_verify.js"

rm -rf ./tmp_backup_dryrun   # cleanup
```

Phase B prints `[verify] restore OK …` and exits `0` when the round trip
succeeds. The emulator export format is the same format produced by
`gcloud firestore export` and consumed by `gcloud firestore import`, so a green
dry run exercises the same import path used in §3.

> Scope note: the local dry run validates restore *mechanics*. A full
> production restore drill (export bucket → `gcloud firestore import` into a
> staging database) should be exercised at least once per release train; record
> the date and snapshot used in the table below.

| Drill date | Type | Snapshot | Result |
|------------|------|----------|--------|
| 2026-06-02 | Local emulator export→import round trip | seeded marker | Pass |
| _TBD_ | Production export → staging import drill | _TBD_ | _pending_ |

---

## 5. Open follow-ups

- [ ] Create `gs://crush-265f7-firestore-backups` and apply the 30-day lifecycle (§2) — confirm in each environment.
- [ ] Add failure alerting: `scheduledFirestoreBackup` currently logs and swallows errors. Add a Cloud Monitoring log-based alert on `FirestoreBackup: Export failed` and/or check export operation completion.
- [ ] Enable PITR on the `(default)` database (§2).
- [ ] Schedule and record the first production export → staging import drill (§4 table).
