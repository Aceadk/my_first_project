# AGENTS.md - Fast, Reliable AI Workflow for CRUSH

Purpose:
- Help the developer ship faster with safe, highest-quality changes.
- Keep agent behavior clear, concise, and token-efficient.
- Preserve architecture, reliability, and collaboration history.

## 1) Non-negotiable Rules

1. Read collaboration docs before coding (latest relevant sections only):
   - `/docs/ai_workboard.md`
   - `/docs/risk_notes.md`
   - `/docs/Developer_agent_chat.md`

2. Log every developer task in `/docs/Developer_agent_chat.md`:
   - original request
   - refined prompt (goal, scope, constraints, expected outcome)
   - status updates (Received -> In Progress -> Completed)
   - outcome (files changed + verification)

3. After finishing a task, update:
   - `/docs/ai_workboard.md`
   - `/docs/risk_notes.md` (only if risk changed)

4. If architecture, flow, or data models changed, also update:
   - `/docs/project_flowchart.md`
   - `/docs/project_dfd.md`
   - `/docs/project_er_diagram.md`

5. A task is not complete until verification and required docs are updated.

6. Deprecated docs are removed and must not be recreated:
   - `/docs/ai_change_log.md`
   - `/docs/ai_tasks_board.md`
   - `/docs/ai_collab_chat.md`

7. Docs sync guard is mandatory:
   - `scripts/check_ai_docs_sync.sh` must pass before task closeout.
   - Any task change set must include both:
     - `/docs/ai_workboard.md`
     - `/docs/Developer_agent_chat.md`

## 2) Default Workflow (Fast + Low Token Use)

1. Intake:
   - restate goal and constraints in 1-3 bullets.

2. Context scan:
   - read only files needed for this task.

3. Plan:
   - max 6 bullets: steps, touched files, risks.

4. Execute:
   - small, focused edits; avoid broad rewrites.

5. Verify:
   - run targeted checks first (build/tests/lint for changed area).
   - run docs workflow guard: `scripts/check_ai_docs_sync.sh --files <changed files>`

6. Closeout:
   - update required docs with short entries.
   - report what changed, why, and how to verify.

## 3) Engineering Guardrails

- Keep clean layering:
  - Presentation -> State (BLoC/Cubit) -> Domain -> Data
- Avoid API calls directly from UI unless existing architecture already does this.
- Treat these areas as high-risk:
  - routing/navigation
  - auth/session
  - dependency injection
  - BLoC lifecycle/disposal
- Prefer incremental refactors over large rewrites.
- Prefer extended, end-to-end implementations that cover the full impacted area over overly simplified code with avoidable limitations.
- Before deleting or moving code:
  - verify references (imports, routes, DI, tests, scripts)
  - if uncertain, deprecate first and log follow-up

## 4) Product Priorities (CRUSH)

Prioritize:
- trust and safety
- performance and responsiveness
- clear onboarding and core flows
- accessibility and readable UX
- stable, predictable behavior over flashy complexity

## 5) Collaboration Model (No Overload)

- Default: one agent executes end-to-end for speed.
- Ask for second-opinion review only for high-risk changes:
  - routes/auth/session/DI changes
  - data model or API contract changes
  - file deletions/moves across modules
  - security/privacy/performance-critical logic
- Record high-risk decisions briefly in `/docs/ai_workboard.md` under the relevant task entry.

## 6) Testing and Verification

Minimum for each task:
- project builds for the changed target
- changed tests pass (or new tests added for new logic)
- impacted flow works in manual check

For high-risk changes, manually verify relevant path segments:
- onboarding -> auth -> home/discovery -> match/chat -> profile/settings

If verification cannot run, state the limitation and provide manual steps.

## 7) Documentation Format (Short)

`/docs/Developer_agent_chat.md`:
- Task ID + date
- Original request
- Refined prompt
- Status
- Outcome (files + verification + next step)

`/docs/ai_workboard.md`:
- Task ID, date, owner, status
- Goal + scope
- Key changes (files/modules)
- Decisions/handoffs (if any)
- Risks/mitigation (if any)
- Verification + next step

## 8) Token and Time Efficiency Rules

- Avoid repeated full-repo scans.
- Reuse existing patterns/utilities.
- Keep plans and status updates short and actionable.
- Ask questions only when blocked by missing decisions.
- Do not over-document trivial edits.
- Prefer targeted commands/tests over full-suite runs unless needed.

## 9) Definition of Done

- requested change implemented within scope
- verification completed (or limitation clearly stated)
- required docs updated
- risks captured if applicable
- final report includes:
  - what changed
  - why
  - how to verify

If anything is unclear, choose the safest reasonable assumption, document it briefly, and proceed.
