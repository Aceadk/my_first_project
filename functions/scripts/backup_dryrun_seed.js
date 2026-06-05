/**
 * Backup/restore dry-run — seed phase (DB-003).
 * Writes a known marker document into the Firestore emulator. Paired with
 * backup_dryrun_verify.js: run under `firebase emulators:exec --export-on-exit`,
 * then re-run the verify script under `--import` to prove an export→import
 * round-trip restores data. Not used by production code.
 */
const admin = require("firebase-admin");

admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || "demo-crushhour" });
const db = admin.firestore();

async function main() {
  const marker = {
    kind: "backup-dryrun-marker",
    note: "Written by backup_dryrun_seed.js to validate export/import.",
    writtenAt: admin.firestore.Timestamp.now(),
  };
  await db.collection("_backup_dryrun").doc("marker").set(marker);
  // A nested subcollection doc, to confirm the export captures subcollections.
  await db
    .collection("_backup_dryrun")
    .doc("marker")
    .collection("child")
    .doc("c1")
    .set({ ok: true });
  console.log("[seed] wrote _backup_dryrun/marker (+child/c1)");
}

main().then(
  () => process.exit(0),
  (err) => {
    console.error("[seed] failed:", err);
    process.exit(1);
  },
);
