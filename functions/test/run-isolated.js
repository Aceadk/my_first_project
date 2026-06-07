#!/usr/bin/env node
/**
 * Per-file test runner (Phase 9 release-gate fix).
 *
 * Several integration suites stub the shared `firebase-admin` singleton at
 * module scope (admin.auth/firestore/storage). Under a single `mocha` process
 * the LAST-loaded stub wins for the whole run, so earlier suites (chatAuthz,
 * chatRestPagination, callRestRateLimit, profileRestEndpoints) ran against the
 * wrong mock and failed with "Invalid token" → 401. Running each test file in
 * its OWN process gives each file a fresh module registry, eliminating the
 * cross-file pollution. Mirrors what CI should do; deterministic (unlike
 * mocha --parallel, which may co-locate polluting files in one worker).
 */

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const TEST_DIR = path.join(__dirname);
// Kept in sync with the previous `--ignore` flag.
const EXCLUDED = new Set(['securityAbuseLanes.test.js']);

function findTestFiles(dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      out.push(...findTestFiles(full));
    } else if (entry.name.endsWith('.test.js') && !EXCLUDED.has(entry.name)) {
      out.push(full);
    }
  }
  return out;
}

const files = findTestFiles(TEST_DIR).sort();
const mochaBin = path.join(__dirname, '..', 'node_modules', '.bin', 'mocha');

let failedFiles = 0;
for (const file of files) {
  const rel = path.relative(path.join(__dirname, '..'), file);
  const res = spawnSync(mochaBin, ['--exit', '--timeout', '30000', file], {
    stdio: 'inherit',
  });
  if (res.status !== 0) {
    failedFiles += 1;
    console.error(`\n✗ FILE FAILED: ${rel} (exit ${res.status})\n`);
  }
}

console.log(
  `\n=== isolated run: ${files.length} files, ${failedFiles} with failures ===`
);
process.exit(failedFiles === 0 ? 0 : 1);
