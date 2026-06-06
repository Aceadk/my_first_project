# Web CI Upgrade Plan - 2026-06-05

**Purpose:** Add comprehensive CI coverage to `crush-web` to match `my_first_project` standards. Prevents regressions before web migration to backend callables (Phase 1).

**Status:** Ready for implementation. Estimated effort: 3-4 days.

---

## Current State: crush-web CI

### What Exists
- Lint checks (`pnpm lint`)
- Unit tests (`pnpm test`)

### What's Missing (P1 Blockers)
- **Build verification** — `pnpm build` never runs in CI
- **Type checking** — No `pnpm typecheck` in pipeline
- **E2E tests** — No Playwright smoke tests or user journey coverage
- **Contract tests** — No validation of REST/callable request/response shapes
- **Docs sync** — No guard like `my_first_project`'s mandatory docs updates

### Why This Matters
- **Build silently fails locally** → Deployed code breaks in production
- **Type errors slip through** → Runtime errors in production
- **E2E untested** → Chat, discovery, match flows may be broken without notice
- **Contract drift** — Web mutations to backend may have mismatched signatures
- **Docs stale** — Future agents don't know about decisions made in this PR

---

## Proposed CI Pipeline

### Stage 1: Fast Feedback (5 min)
```
1. Lint (pnpm lint)
2. Type check (pnpm typecheck)
3. Unit tests (pnpm test)
```

### Stage 2: Build Verification (8 min)
```
1. Build (pnpm build)
2. Verify bundle size (if threshold exceeded, warn)
3. Build static export for Vercel (if applicable)
```

### Stage 3: Integration Tests (15 min)
```
1. Start Firestore emulator
2. Start functions emulator
3. Run Playwright E2E tests (smoke + core journey)
4. Generate coverage report
```

### Stage 4: Contract Validation (5 min)
```
1. Validate REST endpoint signatures against backend contract matrix
2. Validate callable request/response shapes
3. Check for deprecated API usage
```

### Stage 5: Docs Sync Guard (1 min)
```
1. Ensure docs/Developer_agent_chat.md is included
2. Ensure docs/ai_workboard.md (if web team maintains) or
   link to centralized my_first_project docs
```

---

## Implementation Details

### Stage 1: Lint & Type Check & Unit Tests

#### File: `.github/workflows/lint-and-test.yml`
```yaml
name: Lint, Type Check, Unit Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    timeout-minutes: 15

    strategy:
      matrix:
        node-version: [20.x]

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'pnpm'

      - name: Install pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 9

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Lint
        run: pnpm lint

      - name: Type check
        run: pnpm typecheck

      - name: Unit tests
        run: pnpm test -- --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage-final.json
```

#### Checklist
- [ ] Verify `pnpm typecheck` command exists in `package.json`
- [ ] Verify `pnpm test -- --coverage` generates `coverage/coverage-final.json`
- [ ] Add codecov badge to `README.md`

---

### Stage 2: Build Verification

#### File: `.github/workflows/build.yml`
```yaml
name: Build & Bundle Size Check

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 20

    strategy:
      matrix:
        node-version: [20.x]

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'pnpm'

      - name: Install pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 9

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Build
        run: pnpm build
        env:
          # Use test/staging env values for build
          NEXT_PUBLIC_API_URL: ${{ secrets.NEXT_PUBLIC_API_URL_STAGING }}
          NEXT_PUBLIC_STRIPE_KEY: ${{ secrets.NEXT_PUBLIC_STRIPE_KEY_TEST }}

      - name: Check bundle size
        run: |
          # Calculate bundle size; warn if main bundle > 500KB
          if [ -f .next/static/chunks/main-*.js ]; then
            SIZE=$(wc -c < .next/static/chunks/main-*.js | tr -d ' ')
            SIZE_KB=$((SIZE / 1024))
            echo "Main bundle size: ${SIZE_KB}KB"
            if [ $SIZE_KB -gt 500 ]; then
              echo "::warning::Main bundle exceeds 500KB: ${SIZE_KB}KB"
            fi
          fi

      - name: Upload build artifacts
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: build-logs
          path: .next
```

#### Checklist
- [ ] Verify `pnpm build` succeeds locally
- [ ] Set bundle size thresholds (main, vendor, CSS)
- [ ] Configure staging API URL in GitHub secrets

---

### Stage 3: Playwright E2E Tests

#### File: `.github/workflows/e2e.yml`
```yaml
name: E2E Tests (Playwright)

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  e2e:
    runs-on: ubuntu-latest
    timeout-minutes: 30

    services:
      firestore:
        image: ovsdb/firestore-emulator:latest
        ports:
          - 8080:8080
        options: >-
          --health-cmd "curl -f http://localhost:8080/ || exit 1"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      functions:
        image: node:20-alpine
        options: >-
          npm install -g firebase-tools &&
          firebase emulators:start --project=crush-265f7-dev
        ports:
          - 5001:5001

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20.x
          cache: 'pnpm'

      - name: Install pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 9

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Install Playwright browsers
        run: pnpm exec playwright install --with-deps

      - name: Start dev server
        run: pnpm dev &
        env:
          NEXT_PUBLIC_API_URL: http://localhost:5001
          NEXT_PUBLIC_FIREBASE_PROJECT_ID: crush-265f7-dev

      - name: Wait for server
        run: |
          for i in {1..30}; do
            curl -f http://localhost:3000 && break
            sleep 1
          done

      - name: Run E2E tests
        run: pnpm test:e2e
        env:
          PLAYWRIGHT_TEST_BASE_URL: http://localhost:3000
          FIRESTORE_EMULATOR_HOST: localhost:8080
          FIREBASE_EMULATOR_HUB_HOST: localhost

      - name: Upload Playwright report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/

      - name: Comment with test results
        if: always()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('playwright-report/index.html', 'utf8');
            // Parse HTML and extract test count; post comment
```

#### E2E Test Suite Structure
**File:** `packages/e2e/tests/smoke.spec.ts`

```typescript
import { test, expect } from '@playwright/test';

test.describe('Smoke Tests', () => {
  test('Homepage loads', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/Crush/i);
  });

  test('Login page accessible', async ({ page }) => {
    await page.goto('/login');
    await expect(page.locator('input[type="email"]')).toBeVisible();
  });
});

test.describe('Discovery Flow', () => {
  test('Discovery deck loads and shows candidates', async ({ page, context }) => {
    // 1. Login with test user
    const token = await authenticateTestUser(context);
    
    // 2. Navigate to discovery
    await page.goto('/discovery', {
      waitUntil: 'networkidle',
    });
    
    // 3. Verify candidates load
    const candidateCards = page.locator('[data-testid="candidate-card"]');
    await expect(candidateCards.first()).toBeVisible();
  });

  test('Swipe right creates match', async ({ page, context }) => {
    const testUser = await authenticateTestUser(context);
    const testCandidate = await seedTestCandidate();
    
    // 1. Navigate to discovery
    await page.goto('/discovery');
    
    // 2. Swipe right on test candidate
    await page.click('[data-testid="swipe-right-button"]');
    
    // 3. Verify swipe was recorded
    const matches = await fetchUserMatches(testUser.uid);
    expect(matches).toContainEqual(
      expect.objectContaining({ otherUserId: testCandidate.uid })
    );
  });
});

test.describe('Chat Flow', () => {
  test('Send message in match', async ({ page, context }) => {
    const testUser = await authenticateTestUser(context);
    const testMatch = await seedTestMatch(testUser.uid);
    
    // 1. Navigate to chat
    await page.goto(`/messages/${testMatch.id}`);
    
    // 2. Send message
    await page.fill('[data-testid="message-input"]', 'Hello!');
    await page.click('[data-testid="send-button"]');
    
    // 3. Verify message appears in chat
    await expect(page.locator('text=Hello!')).toBeVisible();
    
    // 4. Verify message was saved to backend
    const messages = await fetchMatchMessages(testMatch.id);
    expect(messages).toContainEqual(
      expect.objectContaining({ content: 'Hello!' })
    );
  });

  test('Message read state updates', async ({ page, context, browser }) => {
    // Same match on two browser contexts
    const user1 = await authenticateTestUser(context);
    const user2 = await authenticateTestUser(await browser.newContext());
    const testMatch = await seedTestMatch(user1.uid, user2.uid);
    
    // 1. User 1 sends message
    await page.goto(`/messages/${testMatch.id}`);
    await page.fill('[data-testid="message-input"]', 'Test message');
    await page.click('[data-testid="send-button"]');
    
    // 2. User 2 receives and reads
    const otherPage = await context2.newPage();
    await otherPage.goto(`/messages/${testMatch.id}`);
    await expect(otherPage.locator('text=Test message')).toBeVisible();
    
    // 3. Verify read state synced
    const message = await fetchMessage(testMatch.id, messageId);
    expect(message.isRead).toBe(true);
  });
});
```

#### Checklist
- [ ] Create `packages/e2e/` directory with Playwright config
- [ ] Seed test users/candidates/matches via backend callables
- [ ] Set up Firestore emulator in GitHub Actions
- [ ] Verify dev server starts correctly
- [ ] Run tests locally before merging

---

### Stage 4: Contract Validation Tests

#### File: `packages/core/src/api/__tests__/contract.spec.ts`
```typescript
import { describe, it, expect } from '@jest/globals';

describe('Backend Contract Validation', () => {
  describe('REST Endpoints', () => {
    it('Discovery deck endpoint matches contract', () => {
      const endpoint = '/v1/discovery/deck';
      expect(endpoint).toMatch(/^\/v1\//);
      // Further validation: method, query params, response shape
    });

    it('Chat send message endpoint matches contract', () => {
      const endpoint = '/v1/chat/:conversationId/send';
      const request = {
        type: 'text',
        content: 'Hello',
        mediaUrl: undefined,
      };
      // Validate against schema from backend contract matrix
      validateRequestShape(request, SendMessageRequest);
    });
  });

  describe('Cloud Functions Callables', () => {
    it('sendMessage callable has correct signature', async () => {
      const request: SendMessageRequest = {
        matchId: 'match123',
        type: 'text',
        content: 'Hello',
      };
      
      // Mock callable response
      const response = {
        success: true,
        messageId: 'msg123',
        timestamp: Date.now(),
      };
      
      // Validate response shape
      expect(response).toMatchObject({
        success: expect.any(Boolean),
        messageId: expect.any(String),
        timestamp: expect.any(Number),
      });
    });

    it('swipeRight callable returns Match or null', async () => {
      const request: SwipeRequest = {
        candidateId: 'user456',
      };
      
      const response = {
        isMatch: false,
      };
      
      // or if match:
      const matchResponse = {
        isMatch: true,
        matchId: 'match123',
        match: {
          id: 'match123',
          userId: 'user123',
          otherUserId: 'user456',
          status: 'active',
        },
      };
      
      validateResponseShape(response, SwipeResponse);
    });
  });

  describe('Firestore Schema Compliance', () => {
    it('Message document has required fields', async () => {
      const message = {
        messageId: 'msg123',
        senderId: 'user123',
        type: 'text',
        content: 'Hello',
        visibleTo: ['user123', 'user456'],
        isRead: false,
        createdAt: new Date(),
      };
      
      expect(message).toHaveProperty('senderId');
      expect(message).toHaveProperty('type');
      expect(message).toHaveProperty('visibleTo');
      expect(Array.isArray(message.visibleTo)).toBe(true);
    });

    it('Match document has required fields', async () => {
      const match = {
        matchId: 'match123',
        userIds: ['user123', 'user456'],
        status: 'active',
        createdAt: new Date(),
      };
      
      expect(match).toHaveProperty('userIds');
      expect(Array.isArray(match.userIds)).toBe(true);
      expect(match.userIds.length).toBe(2);
    });
  });

  describe('Deprecated API Usage Check', () => {
    it('Code does not use old conversations/ collection', () => {
      // Lint check: grep for 'conversations/' in service code
      // Fail if found (except in archived migration files)
    });

    it('Code does not use old typing_indicators/ collection', () => {
      // Lint check: grep for 'typing_indicators/' in service code
    });
  });
});
```

#### Checklist
- [ ] Create schema validation utilities (zod, io-ts, or similar)
- [ ] Test against backend contract matrix values
- [ ] Add linting rules for deprecated API usage
- [ ] Run contract tests before PR merge

---

### Stage 5: Docs Sync Guard

#### File: `.github/workflows/docs-sync.yml`
```yaml
name: Docs Sync Guard

on:
  pull_request:
    branches: [main, develop]

jobs:
  docs-sync:
    runs-on: ubuntu-latest
    timeout-minutes: 5

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check if docs are included
        run: |
          # Get list of changed files
          CHANGED=$(git diff --name-only origin/main...HEAD)
          
          # Check if PR modifies any non-docs code
          HAS_CODE_CHANGES=$(echo "$CHANGED" | grep -E '\.(tsx?|jsx?)$' | grep -v '__tests__' | wc -l)
          
          if [ $HAS_CODE_CHANGES -gt 0 ]; then
            # Check for docs updates
            HAS_DOCS=$(echo "$CHANGED" | grep -E 'docs/(ai_workboard|Developer_agent_chat)\.md' | wc -l)
            
            if [ $HAS_DOCS -eq 0 ]; then
              echo "::error::Code changes require docs updates"
              echo "Please update:"
              echo "  - docs/ai_workboard.md (if this is crush-web work)"
              echo "  - docs/Developer_agent_chat.md (if centralized)"
              exit 1
            fi
          fi

      - name: Verify doc links are valid
        run: |
          # Check for broken markdown links in docs
          pnpm install -g markdownlint-cli
          markdownlint docs/*.md || echo "::warning::Fix markdown linting"
```

#### Checklist
- [ ] Decide: does crush-web maintain its own docs, or link to centralized my_first_project docs?
- [ ] Add docs sync enforcement to PR template
- [ ] Update CONTRIBUTING.md with docs requirement

---

## GitHub Actions Workflow Orchestration

### Main workflow file: `.github/workflows/ci.yml`
```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  lint-test:
    uses: ./.github/workflows/lint-and-test.yml

  build:
    uses: ./.github/workflows/build.yml
    needs: lint-test
    if: success()

  e2e:
    uses: ./.github/workflows/e2e.yml
    needs: lint-test
    if: success()

  contract:
    uses: ./.github/workflows/contract-tests.yml
    needs: lint-test
    if: success()

  docs:
    uses: ./.github/workflows/docs-sync.yml

  # Overall status
  ci-status:
    runs-on: ubuntu-latest
    needs: [lint-test, build, e2e, contract, docs]
    if: always()
    steps:
      - name: Check CI status
        run: |
          if [ "${{ needs.lint-test.result }}" != "success" ]; then
            echo "::error::Lint/Test stage failed"
            exit 1
          fi
          if [ "${{ needs.build.result }}" != "success" ]; then
            echo "::error::Build stage failed"
            exit 1
          fi
          if [ "${{ needs.e2e.result }}" != "success" ]; then
            echo "::error::E2E stage failed"
            exit 1
          fi
          if [ "${{ needs.contract.result }}" != "success" ]; then
            echo "::error::Contract tests failed"
            exit 1
          fi
          echo "✓ All CI checks passed"
```

---

## Implementation Checklist

### Week 1: Foundation
- [ ] Create `.github/workflows/lint-and-test.yml`
- [ ] Create `.github/workflows/build.yml`
- [ ] Verify `pnpm typecheck` and coverage are working locally
- [ ] Test workflows in PR (no need to merge yet)

### Week 2: E2E & Emulator Setup
- [ ] Create `packages/e2e/` and Playwright config
- [ ] Set up Firestore emulator in GitHub Actions
- [ ] Write smoke tests (homepage, login, discovery deck)
- [ ] Write core journey tests (swipe, match, send message)
- [ ] Verify tests run locally against emulator

### Week 3: Contract & Docs
- [ ] Create contract validation tests
- [ ] Add deprecated API usage linting
- [ ] Create `.github/workflows/docs-sync.yml`
- [ ] Decide on docs strategy (local vs. centralized)

### Week 4: Integration & Rollout
- [ ] Merge all workflow files to main
- [ ] Test against first PR; fix any issues
- [ ] Add badges to README (build, coverage, E2E)
- [ ] Update CONTRIBUTING.md with new CI requirements
- [ ] Document how to run tests locally

---

## Integration with Web Migration (Phase 1)

Once CI is in place, Phase 1 data migration work will:
1. **Pass all new contract tests** before merge
2. **Pass all E2E tests** against both old and new data models (during dual-write phase)
3. **Update docs** to reflect new service architecture
4. **Run canary deployment** with feature flags (leveraging new CI confidence)

---

## Success Criteria

- [ ] All 5 CI stages run and pass on every PR
- [ ] PR cannot merge if any stage fails
- [ ] E2E test coverage includes: onboarding, discovery, match, chat, settings
- [ ] Contract tests catch mismatched API signatures before deploy
- [ ] Build time < 10 min; E2E tests < 15 min
- [ ] Documentation is enforced and up-to-date
- [ ] Team confidence in CI results is high (low flakiness)

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|-----------|
| Emulator setup complexity | Medium | High | Use official Firebase images; document setup in README |
| E2E test flakiness | High | Medium | Implement retries, wait for network idle, use stable selectors |
| CI runtime exceeds 30 min | Medium | High | Parallelize stages; monitor and optimize slow tests |
| Secrets not configured | Low | Critical | Document all required GitHub secrets; pre-configure for team |
| Coverage requirements too strict | Medium | Medium | Set reasonable thresholds (80%); allow gradual improvement |

---

## Estimated Implementation Timeline

| Phase | Duration | Owner | Deliverable |
|-------|----------|-------|-------------|
| Week 1 | 2-3 days | Web DevOps | Lint/Test/Build workflows running |
| Week 2 | 2-3 days | Web QA/DevOps | E2E tests + Firestore emulator integration |
| Week 3 | 1-2 days | Web Tech Lead | Contract tests + docs sync guard |
| Week 4 | 1 day | Web DevOps | Integration, testing, rollout |
| **Total** | **~1 week** | — | Full CI/CD coverage matching my_first_project |

---

## Delivery status

| Lane | Status |
|------|--------|
| Lint | ✅ pre-existing |
| Unit tests | ✅ pre-existing |
| **Type check** (`pnpm typecheck`) | ✅ delivered (crush-web `a823696`) |
| **Build** (`pnpm build`) | ✅ delivered (crush-web `a823696`, placeholder env) |
| Playwright E2E + Firestore emulator | ⏳ follow-up (needs emulator/secret setup) |
| Contract validation tests | ⏳ follow-up |
| Docs-sync guard | ⏳ follow-up |

The four fast-feedback lanes (lint, typecheck, test, build) now run on every
push/PR to main. The remaining lanes are operational (emulator + secrets).

## Revision History

| Date | Changes |
|------|---------|
| 2026-06-05 | Initial CI upgrade plan. 5-stage pipeline (lint, build, E2E, contract, docs). Integrated with web migration Phase 1. |
| 2026-06-05 (rev 2) | Delivered typecheck + build lanes (crush-web `a823696`); both verified locally. E2E/contract/docs-sync remain as operational follow-ups. |
