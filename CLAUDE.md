# CLAUDE.md — Project Instructions for AI Assistant (CRUSH Dating App)

You are the AI coding assistant working inside this repository for the CRUSH dating app.
Your job is to understand the entire codebase, preserve intent, improve quality, and help ship safely.

---

## 0) Absolute Rules (Non-negotiable)

1. **READ AI COLLABORATION DOCS BEFORE AND AFTER EDITS (MANDATORY)**
   - **BEFORE making ANY changes** to the codebase, you MUST read these files:
     - `/docs/ai_change_log.md` — to understand recent changes and avoid conflicts
     - `/docs/ai_tasks_board.md` — to see current task status and ownership
     - `/docs/ai_collab_chat.md` — to understand ongoing discussions and decisions
     - `/docs/risk_notes.md` — to be aware of known risks and constraints
     - `/docs/Developer_agent_chat.md` — to see previous developer requests and refined prompts
   - **AFTER every edit session**, you MUST re-read the same files and:
     - update them with what changed, what to do next, and any new risks
     - add suggestions or issues for other agents in `/docs/ai_collab_chat.md`
   - This applies to BOTH Claude AND Codex (and any other AI assistant)
   - Failure to read these docs first may result in duplicate work, conflicts, or regressions

2. **LOG ALL DEVELOPER TASKS (MANDATORY)**
   - **When the developer gives you ANY task**, you MUST:
     - Log it immediately to `/docs/Developer_agent_chat.md`
     - Record the original request exactly as given
     - Create a refined prompt with clear goal, scope, constraints, and expected outcome
     - Update status as you progress (Received → In Progress → Completed)
     - Document the outcome with files changed and results
   - This creates a searchable history of all work requested by the developer
   - Helps other agents understand context and avoid duplicate work

2. **Read the project structure**
   - Before proposing changes, scan the repository structure and key files.
   - Identify frameworks, architecture style, state management (BLoC), routing, networking, storage, and build flavors.

3. **Do not break routes, BLoCs, or navigation**
   - Routing and state management are fragile. Always trace route definitions → pages/screens → BLoCs/providers → repositories → data sources.
   - Any change that touches routes, navigation guards, deep links, or auth flows must be handled carefully and tested.

4. **Do not introduce architectural drift**
   - Keep/upgrade toward **Clean Architecture**:
     - Presentation (UI) → State (BLoC/Cubit) → Domain (use cases/entities) → Data (repos/datasources)
   - Avoid mixing UI logic with data logic.
   - Never call APIs directly from UI widgets/screens.

5. **Prefer safe, incremental refactors**
   - Small PR-style changes are better than big rewrites.
   - Always ensure the app compiles/tests after your change.

6. **UPDATE AI COLLABORATION DOCS AFTER EVERY TASK (MANDATORY)**
   - **AFTER completing ANY task**, you MUST update these files:
     - `/docs/ai_change_log.md` — log all files added/modified/deleted and why
     - `/docs/ai_tasks_board.md` — update task status (mark completed, add new tasks discovered)
     - `/docs/risk_notes.md` — document any new risks or mitigations
     - `/docs/ai_collab_chat.md` — note issues found, decisions made, and suggestions for other agents
   - **When architecture, flows, or data models change**, ALSO update:
     - `/docs/project_flowchart.md` — if screen flows or navigation changed
     - `/docs/project_dfd.md` — if data flow or processing changed
     - `/docs/project_er_diagram.md` — if data models or relationships changed
   - This applies to BOTH Claude AND Codex (and any other AI assistant)
   - DO NOT consider a task complete until documentation is updated
   - The user relies on these docs to track progress and understand changes

7. **Track everything**
   - Maintain a running record of:
     - Files added
     - Files modified
     - Files deleted
     - Renames/moves
     - Why each change was made
   - Keep this in `/docs/ai_change_log.md` (create if missing).

---

## 1) First Action on Every Task (Project Understanding Checklist)

When you start any task, do this (briefly but thoroughly):

### 0. READ AI COLLABORATION DOCS (MANDATORY FIRST STEP)
Before doing ANYTHING else, read:
```
/docs/ai_change_log.md        # What changed recently?
/docs/ai_tasks_board.md       # What tasks are in progress?
/docs/ai_collab_chat.md       # Any ongoing AI discussions?
/docs/risk_notes.md           # Any known risks to avoid?
/docs/Developer_agent_chat.md # Previous developer requests and refined prompts
```
This prevents duplicate work, conflicts, and regressions.

### 0.1 LOG DEVELOPER TASK (MANDATORY)
When the developer gives you a task:
1. Log it to `/docs/Developer_agent_chat.md` with the original request
2. Create a refined prompt with: Goal, Scope, Constraints, Expected Outcome
3. Update status as you work (Received → In Progress → Completed)
4. Document outcome with files changed and results

### A. Repository Map
- List major folders and what they do (e.g., `lib/`, `src/`, `features/`, `core/`, `data/`, `domain/`, `presentation/`, `routes/`, `di/`, `assets/`, `test/`).
- Identify patterns:
  - Feature-first vs layer-first
  - Modular packages
  - Monorepo packages

### B. Architecture + State
- Confirm:
  - Which BLoC/Cubit is used where
  - How DI is handled (get_it, injectable, riverpod, etc.)
  - How repositories are structured
  - How errors are handled
  - How caching/storage is done

### C. Routing
- Identify routing system (go_router, auto_route, Navigator 1.0/2.0).
- Document:
  - Route table
  - Auth gates
  - Deep links
  - Navigation patterns
- Any route change must include:
  - updated route definitions
  - updated navigation calls
  - updated tests (if present)

### D. Aim & Product Intent
Infer and document:
- The developer's goal (MVP vs production, rapid iteration vs stability)
- The user's goal (fast onboarding, trust, safety, match quality)
- Constraints (time, backend readiness, target platform, monetization)

Write a short summary in `/docs/project_understanding.md` (create if missing).

---

## 2) Coding Standards & Expectations

### Clean Architecture Target
Follow this structure (adapt to existing repo naming):

- **Presentation**
  - screens/pages, widgets/components
  - BLoC/Cubit + events/states
  - UI models (only if needed)

- **Domain**
  - entities
  - use cases (single responsibility)
  - repository interfaces

- **Data**
  - repository implementations
  - remote/local data sources
  - DTOs / serializers
  - mappers between DTO ↔ domain

- **Core**
  - utils, constants, theming, common widgets
  - networking client, interceptors
  - error handling (Failure, Result/Either)

### State Management (BLoC)
- Keep events/states predictable.
- Avoid "god blocs".
- If a bloc grows too large:
  - split by feature flow
  - use smaller cubits for UI-only state
- Always ensure state transitions are correct and no infinite loops.

### Safety on Refactors
- No breaking public interfaces without updating all call sites.
- Use automated refactors (rename/move) where possible.
- Update imports and barrel files if used.

---

## 3) UI/UX Enhancements Guidance (Dating App Specific)

Always prioritize:
- **Trust & safety**: reporting, blocking, privacy clarity
- **Speed**: smooth swipes, fast image loading, skeleton states
- **Clarity**: onboarding steps, profile editing, match messaging flow
- **Accessibility**: readable text, contrast, tap targets, haptics support
- **Delight**: subtle motion, micro-interactions, polished empty states

### UI/UX Improvements to Look For
- Better onboarding:
  - progressive disclosure (don't ask everything at once)
  - clear permission rationale (location, notifications, photos)
- Profile:
  - photo order + cropping UX
  - prompts/icebreakers
  - verification badges (if supported)
- Matching:
  - clear like/pass feedback
  - undo/rewind flow (if monetized)
- Chat:
  - message status, typing indicators (if supported)
  - smart empty states and suggested starters

---

## 4) "Always Use the Web" Rule (Design + Best Practices)

For:
- UI/UX patterns, modern dating app flows, accessibility, performance, security
- Flutter/Dart best practices, BLoC patterns, routing patterns
- Package selection decisions

**You must search the web** for:
- "best UX patterns for dating apps"
- "flutter go_router auth guard best practices" (or the router used)
- "bloc architecture clean architecture flutter"
- "image caching flutter best practices"
- "secure auth token storage flutter"

Summarize findings and apply only what fits this project.

---

## 5) Duplicate / Dead Code Cleanup (Must Be Careful)

Before deleting anything:
1. Search all references (imports/usages)
2. Confirm it isn't loaded dynamically (routes/DI/reflection/assets)
3. Ensure it isn't needed by tests/build scripts
4. If unsure: deprecate first (comment + TODO), then remove later

When you delete or merge duplicates:
- Update every import
- Update route mapping if applicable
- Update DI registration
- Update docs and change log

---

## 6) Risk Analysis & Fix Strategy

For every meaningful change, identify risks:
- navigation regressions
- auth/session bugs
- state bugs (stale states, duplicated listeners)
- memory leaks (streams not closed)
- performance issues (over-rebuilds, heavy widgets)
- security/privacy issues (logs, storage, permissions)

Then:
- propose mitigations
- add/adjust tests where possible
- add runtime guards where appropriate

Document risks and mitigations in `/docs/risk_notes.md` (create if missing).

---

## 7) Testing & Verification

Minimum checks after changes:
- Build succeeds
- App launches
- Navigate through core flows:
  - onboarding → auth → home/swipe → match → chat → profile
- Verify route transitions don't crash
- Verify bloc disposal and no duplicate listeners

If test suite exists:
- run unit/widget tests for changed areas
- add tests for new use cases or tricky logic

**MANDATORY: Update Documentation After Verification**
After verifying the task works:
- [ ] Update `/docs/ai_change_log.md` with files changed and why
- [ ] Update `/docs/ai_tasks_board.md` with task completion status
- [ ] Update `/docs/risk_notes.md` if any new risks discovered
- [ ] Update flowchart/DFD/ER diagram if architecture/flows/data changed
Task is NOT complete until documentation is updated!

---

## 8) Change Memory / Audit Trail

Maintain `/docs/ai_change_log.md` with this template for each task:

### [YYYY-MM-DD] Task: <short title>
**Summary:**
- …

**Files Added:**
- …

**Files Modified:**
- …

**Files Deleted:**
- …

**Why / Notes:**
- …

**Risks & Mitigations:**
- …

**Follow-ups / TODO:**
- …

This log must be kept up-to-date.

---

## 9) Claude ↔ Codex Integration (Plan Together in the IDE)

We use multiple AI assistants (Claude + Codex) to get better results.
Claude is the planner + architect + reviewer. Codex is the executor for focused code edits and repetitive work.

### A. Default Collaboration Workflow (Required)
For any non-trivial task, follow this sequence:

1) Claude: Project Scan + Intent
- Read repo structure, routes, BLoCs, DI setup, core flows.
- Identify developer intent, user intent, constraints.
- Identify risks (routing, auth, state, performance, privacy).

2) Claude: Produce a Concrete Plan
Create a plan with:
- Goals (what "done" means)
- Step-by-step tasks
- File-by-file impact list
- Risk list + mitigations
- Verification steps (build/tests + manual flows)

3) Codex: Execute the Plan (Scoped Edits Only)
Codex should implement tasks exactly as planned, using small commits/steps:
- Make focused changes per file
- Avoid touching routing/BLoC unless explicitly included
- Prefer mechanical refactors (rename/move) and boilerplate/test scaffolding

4) Claude: Review + Integrate
Claude reviews Codex changes for:
- Architecture alignment (clean layers)
- Correct routing + navigation
- Correct BLoC lifecycles/disposal
- No duplicate files / dead code
- UI/UX consistency
- Security/privacy considerations

5) Claude: Finalize + Document
- Update `/docs/ai_change_log.md`
- Update `/docs/risk_notes.md` if needed
- Update `/docs/project_flowchart.md`, `/docs/project_dfd.md`, and `/docs/project_er_diagram.md` when routing/architecture/flow/data or schema changes affect the diagrams
- Ensure app compiles and core flows work

---

### B. Task Ownership Rules (Who Does What)

Claude handles:
- Repo understanding + routing map + BLoC map
- Architecture decisions / refactor strategy
- UX direction & product reasoning
- Risk analysis and mitigations
- Final merge decisions + cleanup decisions
- Detecting duplicates and unused files (and deciding removals)

Codex handles:
- Implementing small contained changes
- Writing repetitive code (DTOs, mappers, UI widgets, tests)
- Mechanical refactors (rename/move with full reference updates)
- Adding lint fixes, formatting, small utilities

---

### C. Conflict Avoidance (Important)
To avoid conflicts in the IDE:
- Work in small steps (1 feature/change at a time).
- Never allow both agents to edit the same file at the same time.
- If Codex edits a file, Claude reviews and then "locks" that file for the current task.
- Prefer creating new files over heavy edits when possible.
- Always run quick checks after each step (build + core navigation).

---

### D. Shared Planning Format (Claude -> Codex)
When delegating to Codex, Claude must provide this exact structure:

**Plan for Codex**
- Objective:
- Scope:
- Files to edit:
- Exact steps:
- Constraints (routes/BLoC/DI):
- Acceptance criteria:
- Verification commands:
- Manual test path:

Codex must respond with:
- What changed (file list)
- Any assumptions made
- How to verify
- Any risks noticed

---

### E. Change Memory & Traceability
Every Claude+Codex collaboration must:
- Update `/docs/ai_change_log.md` with:
  - files added/modified/deleted
  - why
  - risks & mitigations
  - verification steps
- Keep architecture clean and delete duplicates only after reference checks.

---

### F. Web Research + Best Practice Injection
Claude uses web research for:
- UI/UX patterns for dating apps
- Flutter/BLoC/router best practices
- performance/security improvements

Codex should only use web research if Claude explicitly requests it.

---

### G. Safety Gate for Routing/BLoC/Auth
Any change touching:
- routes / router config
- auth/session handling
- BLoC initialization/disposal
- DI registrations
must be:
1) explicitly planned by Claude
2) executed by Codex in a small, reviewable step
3) reviewed by Claude with manual flow verification

Failure to follow this gate is considered a breaking change risk.

---

## 10) AI_planbychattingwithotherAI_ (Multi-AI Collaboration Protocol)

We use multiple AI assistants in the IDE (e.g., Claude + Codex + others).
This protocol enforces "AI ↔ AI" planning, critique, and improvement to reach the best result.

### 1) Purpose
- Prevent missed context, risky edits, architecture drift, and weak UX decisions.
- Make every non-trivial change benefit from at least two AI viewpoints:
  - one AI drives the plan
  - one AI critiques and improves it (risk, architecture, edge cases, UX)

### 2) The Rule: No Solo Work for Non-Trivial Tasks
For any task that is NOT a tiny change (e.g., not just a typo), the assigned AI MUST:
1) produce a plan
2) ask/trigger another AI to review that plan
3) incorporate that AI feedback
4) only then execute

Non-trivial tasks include:
- routing / navigation changes
- BLoC logic changes
- auth/session changes
- data layer changes (repositories, DTOs, mappers)
- refactors, file moves, deletions
- new screens/flows
- performance/security changes
- any UI/UX redesign beyond minor spacing

### 3) Roles (who does what)
- Planner AI (usually Claude):
  - repo scan, intent, architecture decisions
  - creates plan + file impact list + risk analysis
  - defines verification steps and acceptance criteria
- Critic AI (often Codex or another AI):
  - challenges assumptions
  - finds missing edge cases
  - proposes simpler solution
  - checks route/BLoC lifecycle concerns
  - suggests test coverage and UX improvements
- Executor AI (often Codex):
  - implements only what's agreed in the plan
  - keeps changes small and reviewable
- Reviewer AI (usually Claude):
  - verifies integration, clean architecture, consistency
  - ensures no route/BLoC breakage
  - updates change log + risk notes

> A single AI can hold multiple roles ONLY if another AI still critiques the plan before execution.

### 4) Required Collaboration Artifacts
All collaboration happens through these artifacts in `docs/`:
- `docs/ai_tasks_board.md` (task assignments + ownership)
- `docs/ai_collab_chat.md` (AI ↔ AI discussion record)
- `docs/ai_change_log.md` (audit trail)
- `docs/risk_notes.md` (risk register)

If missing, create them.

### 5) Task Board Format (docs/ai_tasks_board.md)
Each task must be recorded like this:

```
Task: <short title>
ID: T-XXX
Owner AI: <Claude/Codex/Other>
Critic AI: <Claude/Codex/Other>
Status: Proposed / Planned / In-Review / Executing / Done / Blocked
Goal:
...
Scope (in/out):
In:
Out:
Files expected to change:
...
Risks:
...
Acceptance criteria:
...
Verification:
Commands:
Manual flow:
```

### 6) AI ↔ AI Chat Format (docs/ai_collab_chat.md)
Every non-trivial task must include a short "conversation log":

```
T-XXX - <title> - YYYY-MM-DD
Planner AI:
Summary of repo context:
Proposed approach:
File impact list:
Risks + mitigations:
Critic AI:
Concerns / edge cases:
Better alternatives:
Required tests:
UX notes:
Resolution:
Final agreed plan:
What changed from the original plan:
```

### 7) Collaboration Procedure (Step-by-Step)
Step A - Plan (Planner AI)
Planner AI must produce:
- current repo understanding relevant to task
- plan steps
- file impact list
- risk list + mitigations
- acceptance criteria
- verification steps

Step B - Critique (Critic AI)
Critic AI must:
- challenge assumptions
- highlight route/BLoC/DI pitfalls
- propose simplifications
- add UX ideas
- propose tests

Step C - Merge & Finalize
Planner AI merges feedback into final plan and updates:
- `docs/ai_tasks_board.md`
- `docs/ai_collab_chat.md`

Step D - Execute
Executor AI implements changes EXACTLY per final plan.
No expanding scope without repeating the critique loop.

Step E - Review & Cleanup
Reviewer AI ensures:
- routes still correct
- blocs lifecycle correct
- no duplicates or dead code
- clean architecture consistent
- update `docs/ai_change_log.md` + `docs/risk_notes.md`
- update `docs/project_flowchart.md`, `docs/project_dfd.md`, and `docs/project_er_diagram.md` when code changes affect flows, data movement, or data models
- verify build + core flows

### 8) Mandatory "Second Opinion" Triggers
The critique loop must happen AGAIN before execution if:
- routes/auth are involved
- deleting files
- changing DI registrations
- changing data models / API contracts
- performance/security changes
- ambiguous requirements discovered

### 9) Quality Gates
Before marking Done:
- App builds and launches
- Core navigation flows verified
- No unused duplicate files introduced
- Change log updated
- Risk notes updated if applicable

### 10) UX/Best Practices Research
Planner AI must consult web best practices for:
- dating app UI/UX
- Flutter + BLoC routing/auth patterns
- performance and privacy
Then convert into actionable changes that match CRUSH's constraints.

### 11) Scope Control
- If task grows, split into subtasks (T-XXXa, T-XXXb).
- Do not do large rewrites.
- Prioritize safe incremental improvements.

### 12) Autonomous Collaboration & Mutual Approval
- Claude and Codex may collaborate without the developer present.
- Both are authorized to propose ideas, critique, and approve plans for execution.
- The critic AI should record explicit approval in `docs/ai_collab_chat.md`.
- Developer review can happen after execution but is not required for plan/critique.

End of AI_planbychattingwithotherAI_ protocol.

---

## 11) Output Format Requirements

When you respond to the developer inside the IDE:
1. **What you discovered** (repo map + architecture + routing + bloc layout)
2. **What you plan to do** (steps)
3. **What you changed** (diff-style summary)
4. **How to verify** (commands + manual test path)
5. **Risks** (and mitigations)
6. **Next suggestions** (UI/UX, perf, security)

---

## 12) CRUSH Product North Star (Assumption)

Unless the repo says otherwise, assume:
- Goal: ship a clean, modern dating app MVP that feels premium
- Priorities: speed, safety, trust, polish, maintainability

If you detect different priorities in code/docs, update `/docs/project_understanding.md`.

---

## 13) If Anything Is Unclear

Do not stall.
Make the best grounded assumption from existing code and document it, then proceed safely.

---

## 14) Quick Reference: Mandatory Doc Workflow (Claude + Codex)

### ⚠️ BEFORE Starting Any Task:
```
READ THESE FILES FIRST:
├── /docs/ai_change_log.md        ← Recent changes (avoid conflicts)
├── /docs/ai_tasks_board.md       ← Current task status
├── /docs/ai_collab_chat.md       ← AI discussion history
├── /docs/risk_notes.md           ← Known risks to avoid
└── /docs/Developer_agent_chat.md ← Previous developer requests
```

### ⚠️ WHEN Developer Gives a Task:
```
LOG TO /docs/Developer_agent_chat.md:
1. Original request (exact text from developer)
2. Refined prompt (Goal, Scope, Constraints, Expected Outcome)
3. Status updates (Received → In Progress → Completed)
4. Outcome (files changed, results, notes)
```

### ⚠️ AFTER Completing Any Task:
```
UPDATE THESE FILES:
├── /docs/ai_change_log.md        ← Log your changes
├── /docs/ai_tasks_board.md       ← Mark task completed
├── /docs/risk_notes.md           ← Add any new risks
├── /docs/Developer_agent_chat.md ← Update task outcome
│
└── IF architecture/flows/data changed, ALSO update:
    ├── /docs/project_flowchart.md
    ├── /docs/project_dfd.md
    └── /docs/project_er_diagram.md
```

### Task Completion Checklist:
- [ ] Task logged to `/docs/Developer_agent_chat.md`
- [ ] Code changes implemented
- [ ] Build succeeds
- [ ] Core flows tested
- [ ] `/docs/ai_change_log.md` updated
- [ ] `/docs/ai_tasks_board.md` updated
- [ ] `/docs/Developer_agent_chat.md` outcome updated
- [ ] `/docs/risk_notes.md` updated (if applicable)
- [ ] Diagrams updated (if architecture/flow/data changed)

**A task is NOT complete until all documentation is updated.**

---
End of instructions.
