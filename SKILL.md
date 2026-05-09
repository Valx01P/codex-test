---
name: codex-test
description: >
  Agentic test discovery, planning, generation, validation, and reporting for
  Codex. Use when a user asks to choose a testing workflow, audit tests, improve
  test coverage to a target such as 80%+, generate unit, integration, UI, e2e,
  regression, or domain tests, harden a Next.js/frontend repo, find high-impact
  test targets, or invokes "$codex-test" or "codex-test".
---

# Codex Test

Run production-ready test work with a strict user-selected workflow.

## Entry Gate

Before commands, repo inspection, planning, or edits, always show this menu and
wait:

```text
Choose a testing workflow:

1. Recommended Test Scan: inspect the repo, find high-impact targets, propose a
   prioritized plan, then generate and validate approved tests.
2. Increase Test Coverage: measure or estimate coverage, target 80% by default
   unless you request another threshold, then cover meaningful lower-complexity
   gaps before harder gaps.
3. Specialized Test Development: build production-ready tests for a specific
   suite or risk area, such as e2e, regression, feature, API, contract,
   accessibility, performance, backend, or Next.js/frontend workflows.

Reply with `1`, `2`, or `3`.
```

Rules:

- Do not infer the workflow from goals like "80% coverage", "checkout e2e", or
  "audit tests"; treat that text only as scope after the user chooses.
- If the reply is not clearly `1`, `2`, or `3`, ask again for one of those
  numbers and do nothing else.
- In non-interactive mode, require explicit launcher mode:
  `--mode recommended`, `--mode coverage`, or `--mode specialized`.

## Analyze

Prefer the bundled analyzer:

```bash
bash .agents/skills/codex-test/scripts/analyze.sh .
```

If installed outside the repo, run the same script from the installed skill
path. If unavailable, inspect manifests/configs, source layout, existing tests,
test setup, fixtures/helpers, CI files, package/workspace boundaries, and test
commands manually.

Collect:

- stack, framework, package manager, monorepo/workspace signals
- test, coverage, lint, typecheck, build, and e2e commands
- existing test placement, imports, assertions, mocks, fixtures, factories,
  auth/session helpers, page objects, route helpers, and CI conventions
- dependency constraints, environment assumptions, secrets/data boundaries

Read `references/quality-rubric.md` before generating tests.

## Plan

Rank targets:

1. Critical behavior: auth, permissions, payments, validation, persistence, API
   contracts, business rules, parsers, security boundaries.
2. Shared code: utilities, hooks, services, adapters, state machines,
   validators, serializers.
3. User-facing frontend behavior: forms, loading/error/empty states,
   navigation, filtering, optimistic updates, accessibility-critical controls.
4. Regression risk: complex conditionals, recent changes, high-churn modules,
   brittle integrations.
5. Cheap meaningful coverage gaps.

Skip pure config/constants/types/barrels/generated files/stories/snapshots and
tests that only assert existence or implementation details.

For each proposed target include path, type, why, behaviors/edge cases,
mocks/fixtures, expected files, validation command, CI/runtime cost, flake risk.
In interactive runs, show the plan and wait for approval before writing tests
unless the user already explicitly authorized implementation after the menu.

## Modes

### 1. Recommended Test Scan

Use for general hardening. Produce a compact ranked plan and generate the
approved high-impact batch.

### 2. Increase Test Coverage

Use for coverage growth. Default target: 80% unless the user provides another
threshold.

Coverage ladder:

1. Baseline measured coverage when a real command exists; otherwise label
   analyzer results as estimates.
2. Low complexity first: pure utils, validators, parsers, formatters, reducers,
   simple hooks, route handlers, small services.
3. Medium next: stateful components, API boundaries, adapters, stores, server
   actions, mockable integrations.
4. High only for high targets or explicit scope: e2e flows, auth/payment,
   concurrency, realtime, migrations, fragile legacy code.

Do not add shallow tests or change coverage gates just to raise numbers.

### 3. Specialized Test Development

Use for a named suite or risk area: e2e, regression, feature, API/contract,
accessibility, backend integration, UI/component, upcoming feature work.

Define the risk model, reuse local helpers, add minimal infrastructure, document
why lower-level tests are or are not enough, and report setup/cleanup, flake
risk, runtime, and CI impact.

## Production Defaults

- Reuse repo conventions; do not invent a new testing style.
- Work in reviewable batches.
- Ask before adding dependencies, changing CI/coverage thresholds, editing
  product source, touching generated code, or adding long-running e2e suites.
- Never use production services, real secrets, live user data, payment
  credentials, or live third-party APIs.
- In monorepos, scope commands to touched packages/apps when possible and say
  when root validation was not run.
- Treat e2e/integration flake risk as a review blocker until selectors, seeded
  data, time, network, retries, and cleanup are deterministic.

## Frontend Defaults

For Next.js/React/frontends:

- Prefer existing Vitest/Jest/Testing Library; use Playwright/Cypress only when
  already present or explicitly justified.
- Test UI behavior through roles, labels, visible state, and user events; avoid
  snapshot-only coverage.
- Test route handlers/server actions/loaders through request/response behavior
  when practical; test pure logic directly.
- For forms, cover success, validation failure, disabled/loading states, and key
  accessibility labels.
- For regressions, encode the bug or planned behavior in the test name.

## Generate

For each target: read source and adjacent modules, read existing tests/setup,
create or append tests in the local pattern, mock only external boundaries,
keep tests deterministic and independent, use realistic synthetic fixtures.

Do not modify product source to make tests pass. If a real bug appears, document
it and ask before changing implementation.

## Validate

Run the narrowest useful command first, for example:

- Vitest/Jest: project script or `npx vitest run path` / `npx jest path`
- Playwright: `npx playwright test path`
- Pytest: `python -m pytest path -x --tb=short`
- Go/Rust: package-scoped `go test` / `cargo test`

If a generated test fails: read the failure, fix one clear test/setup issue,
rerun once, then stop and report if still failing.

Review-ready validation order when available and reasonably scoped:

1. Narrow generated tests.
2. Owning package/suite test command.
3. Typecheck.
4. Lint.
5. Coverage command for coverage mode.
6. Build/full CI-equivalent only when reasonable or requested.

## Report

Write `CODEX-TEST-REPORT.md`. For detailed structure, read
`references/reporting-standard.md` when available. Keep it concise and bounded:
target 300-800 lines for normal work, and do not create one long section per
test when many tests were generated. Prefer grouped summaries and detail only
for high-risk or representative files.

Include at minimum:

- timestamp, repo, selected mode, goal, stack, workspace/package context,
  commands detected/run
- overview table of changed files, impact, risk, validation
- plan summary and skipped targets
- grouped generated/updated-file summaries: purpose, behavior category, test
  count, key edge cases, validation result
- detailed callouts only for high-risk files, new infrastructure, failures,
  unusual mocks, or representative patterns
- coverage baseline/after-state or clearly labeled estimates
- CI/runtime impact, flake risk, data/secrets assumptions, dependencies avoided
  or proposed
- continuous-improvement next targets and human-review checklist

After writing, run if available:

```bash
bash .agents/skills/codex-test/scripts/report.sh .
```

## Final Response

Keep it short:

```text
Generated/updated N test files and CODEX-TEST-REPORT.md.
Mode: ...
Validation: N passing, N failing, N not run.
Key targets: ...
Review: CODEX-TEST-REPORT.md and git diff.
```

## Hard Rules

- Do not delete existing tests or overwrite unrelated user changes.
- Do not edit product source unless the user explicitly expands into bug fixing.
- Do not install network dependencies without approval.
- Do not call production services, use secrets, or rely on live user data.
- Do not use snapshots as a substitute for behavioral assertions.
- Do not report success unless tests ran, or clearly state validation was not
  possible.
