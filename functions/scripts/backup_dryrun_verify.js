/**
 * Backup/restore dry-run — verify phase (DB-003).
 * Reads the marker document seeded by backup_dryrun_seed.js. When run under
 * `firebase emulators:exec --import=<dir>`, success proves the export taken in
 * the seed phase was restored cleanly (top-level doc + subcollection). Not used
 * by production code.
 */
const admin = require("firebase-admin");

admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || "demo-crushhour" });
const db = admin.firestore();

async function main() {
  const doc = await db.collection("_backup_dryrun").doc("marker").get();
  if (!doc.exists) {
    throw new Error("marker doc missing after import — restore FAILED");
  }
  const data = doc.data();
  if (data.kind !== "backup-dryrun-marker") {
    throw new Error(`marker doc corrupted after import: ${JSON.stringify(data)}`);
  }
  const child = await db
    .collection("_backup_dryrun")
    .doc("marker")
    .collection("child")
    .doc("c1")
    .get();
  if (!child.exists || child.data().ok !== true) {
    throw new Error("subcollection doc missing after import — restore FAILED");
  }
  console.log("[verify] restore OK — marker + subcollection present:", data.note);
}

main().then(
  () => process.exit(0),
  (err) => {
    console.error("[verify]", err.message);
    process.exit(1);
  },
);
