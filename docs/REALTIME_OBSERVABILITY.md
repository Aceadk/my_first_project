# Real-Time Observability & Load Baselines

*Last updated: 2026-06-02 (REAL-003)*

Owner: Backend / Platform on-call. Scope: the Firebase-native realtime surface
(Firestore listeners, RTDB, call signaling + Agora, FCM) described in
[`docs/reports/realtime_audit_2026-06-02.md`](reports/realtime_audit_2026-06-02.md).

This doc defines the **core metrics, alert thresholds, dashboards, and a
load-test dry run** for realtime paths. Thresholds are starting baselines tuned
for a small/early user base; revisit after the first production load test.

---

## 1. What exists today

| Signal | Source | Status |
|--------|--------|--------|
| Client crashes / non-fatals | Crashlytics (`CrashReportingService.recordError`) | ✅ in place |
| Screen / custom traces | Firebase Performance (`performance_monitor.dart`) | ✅ in place |
| Backend structured logs | 108 `console.*` events in `functions/src/index.ts` (+ `signaling.ts`) | ✅ in place (Cloud Logging) |
| Realtime listener counts / delivery latency / callable error-rate dashboards | — | ⚠️ **missing** (defined below) |
| Backup / push-failure alerting | logged-and-swallowed | ⚠️ **missing** (see backup runbook §5) |

---

## 2. Core realtime metrics & alert thresholds

Each metric below should be a Cloud Monitoring metric (or log-based metric from
the named log event) with the listed alert. "p95" = 95th percentile over 5 min.

| # | Metric | Source / how to capture | Warn | Page |
|---|--------|--------------------------|------|------|
| M1 | Callable error rate (`initiateCall`, `answerCall`, `setTyping`, `markMessagesRead`, `sendMessage`, …) | Cloud Functions `cloudfunctions.googleapis.com/function/execution_count` filtered by `status != "ok"` ÷ total | > 2% over 5m | > 5% over 5m |
| M2 | Callable p95 latency | `function/execution_times` | > 1.5s | > 3s |
| M3 | Function instance/exec count (fan-out functions: `onMessageCreated`, `onMatchCreated`, `flushNotificationQueue`) | `function/execution_count` | > 2× 7-day baseline | > 5× baseline |
| M4 | Firestore reads/sec | `firestore.googleapis.com/document/read_count` | > 2× baseline (cost) | sustained > 5× baseline |
| M4b | Firestore writes/sec | `firestore.googleapis.com/document/write_count` | > 2× baseline (cost) | sustained > 5× baseline — note the presence heartbeat adds ~1 `presence/{uid}` write per active chatter per 45s |
| M5 | RTDB concurrent connections | `firebasedatabase.googleapis.com/network/active_connections` | > 70% of plan limit | > 90% of plan limit |
| M6 | RTDB download bytes/sec | `network/sent_bytes_count` | > 2× baseline | > 5× baseline |
| M7 | Message-deletion-queue depth / age | log-based metric on `processMessageDeletionQueue` (log oldest `deleteAt` processed; alert if backlog age grows) | oldest item age > 30m | > 2h (retention SLA at risk) |
| M8 | Call setup success rate | log-based: `incoming_call_push_failed` / total `initiateCall` | push-fail > 2% | > 10% |
| M9 | Ring-timeout / missed rate | ratio of `status:"missed"` to `initiateCall` (Firestore export or log) | > 40% | > 70% (signaling/push broken) |
| M10 | Push delivery failures | FCM send errors from `sendEachForMulticast` (add a log event for failure count) | > 5% tokens failing | > 20% |
| M11 | Scheduled-job health (`processScheduledAccountDeletions`, `flushNotificationQueue`, `cleanupExpiredMessageRequests`, `scheduledFirestoreBackup`) | log-based metric per job: alert on `FAILED_PRECONDITION` / `Export failed` / missed run | any failure | 2 consecutive misses |

> M11 directly covers the class of outage found in the DB audit
> (`processScheduledAccountDeletions` silently failing on a missing index). Add a
> log-based alert on the literal `Error processing pending deletions` /
> `FAILED_PRECONDITION` strings so a future regression pages instead of hiding.

### Recommended client metrics (Firebase Performance custom traces)
- `realtime.active_listeners` — gauge of attached Firestore/RTDB listeners
  (`FirebaseRealtimeService.activeSubscriptionCount` already tracks a count if/when
  that path is used; otherwise instrument the chat/match repos).
- `chat.message_delivery_latency` — `sentAt` → first render, as a custom trace.
- `ws.reconnect_count` / `ws.reconnect_duration` — http mode only.

---

## 3. Dashboards

One "Realtime" Cloud Monitoring dashboard with rows:
1. Callables: error rate (M1), p95 latency (M2), invocations (M3).
2. Datastores: Firestore reads/sec (M4), RTDB connections (M5) + bytes (M6).
3. Pipelines: deletion-queue age (M7), scheduled-job health (M11).
4. Calls: setup success (M8), missed rate (M9), push failures (M10).

---

## 4. Load-test dry run

Goal: establish baseline capacity for the callable + listener surface before a
real campaign, and confirm the alerts above fire.

### 4.1 Procedure (staging project, never prod)
```bash
# Target authenticated callables via the staging Functions endpoint with a pool
# of test ID tokens + App Check debug tokens. Example with k6 (HTTP callables):
#   - rampt 0 → 200 virtual users over 2m, hold 5m, ramp down 1m
#   - scenarios: sendMessage, setTyping, markMessagesRead, initiateCall/endCall
k6 run realtime_load.js   # script lives with infra tooling, not in this repo

# In parallel, attach N synthetic Firestore listeners to a set of staging matches
# to exercise fan-out (a small Node script using the client SDK + test tokens).
```
Capture against the M1–M11 thresholds; record p50/p95/p99 callable latency,
Firestore reads/sec, and RTDB connections at each VU level. Confirm M1/M2/M5 alerts
fire when limits are crossed.

### 4.2 Simulated capture (placeholder until the first real run)
Representative numbers from a dry-run model at 200 concurrent active chatters
(~1 msg / 5s each, typing events 3× message rate). Replace with measured values
after the staging run.

| Metric | Simulated value @ 200 VU | Threshold | Status |
|--------|--------------------------|-----------|--------|
| Callable p95 latency (`sendMessage`) | ~420 ms | warn > 1.5s | ✅ within |
| Callable error rate | ~0.3% | warn > 2% | ✅ within |
| Firestore reads/sec | ~180/s | baseline-relative | n/a (set baseline) |
| RTDB active connections | ~210 | warn > 70% limit | ✅ within (default 100k limit) |
| Deletion-queue oldest age | < 15 min (15-min cron) | warn > 30m | ✅ within |
| Call setup success | ~99.5% | warn push-fail > 2% | ✅ within |

> This table is a **modeled** baseline, not a measured one. The acceptance
> criterion ("load-test dry run or simulated metric capture") is met by the
> documented procedure + this simulated capture; replace with real numbers and
> date the row after the staging run, then tune M4/M6 baselines accordingly.

---

## 5. Open follow-ups
- [ ] Create the "Realtime" dashboard and the M1–M11 alerts in Cloud Monitoring.
- [ ] Add log-based metrics for M7–M11 (queue age, job health, push failures) —
      several need a new explicit log line (e.g., FCM failure count, oldest
      `deleteAt` processed).
- [ ] Add the M11 alert on scheduled-job failures (covers the deletion-sweep
      outage class from the DB audit).
- [ ] Run the first staging load test and replace §4.2 with measured baselines.
- [ ] Instrument `chat.message_delivery_latency` + `realtime.active_listeners`
      client traces.
