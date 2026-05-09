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

Run a rigorous test-improvement workflow that keeps the human in the loop
without making them re-explain the process.

## Core Behavior

1. Offer the testing workflow options before running commands, inspecting the
   repository, or changing files, then wait for the user to reply with `1`, `2`,
   or `3`.
2. Inspect the repository before recommending tests.
3. Present a short testing brief and proposed plan before writing tests when the
   user is available.
4. Prefer high-signal tests over broad, shallow coverage.
5. Generate tests in small batches, validate them, and fix straightforward
   failures once.
6. Write `CODEX-TEST-REPORT.md` as a reviewable draft explaining every created
   or updated file, why it exists, what each part does, what changed, impact,
   validation results, remaining gaps, and continuous-improvement follow-ups.

Never infer a workflow choice from the user's goal text in an interactive
session. A focus such as "checkout e2e", "80% coverage", or "audit tests" is
context for the eventual workflow, but the workflow does not start until the
user chooses `1`, `2`, or `3`.

If Codex is running non-interactively, require an explicit workflow mode from
the launcher. If no explicit mode is present, stop and report that `--mode
recommended`, `--mode coverage`, or `--mode specialized` is required.

## Phase 0: Align Scope

Start with a concise mode menu before analysis:

```text
Choose a testing workflow:

1. Recommended Test Scan (recommended): inspect the repo, identify the best
   high-impact targets, propose a prioritized plan, then generate and validate
   the approved tests.
2. Increase Test Coverage: measure or estimate current coverage, target 80% by
   default unless you request another threshold, and add meaningful tests from
   lower-complexity coverage gaps toward more complex gaps as the target rises.
3. Specialized Test Development: build production-ready tests for a specific
   suite or risk area, such as e2e, regression, feature, API, contract,
   accessibility, performance, backend, or Next.js/frontend workflows.

Reply with `1`, `2`, or `3`.
```

If the user replies with anything other than a clear `1`, `2`, or `3`, ask them
to choose one of those numbers. Do not inspect the repo, run commands, propose a
plan, or edit files until a valid number is received.

After a valid number is received, restate the selected workflow and use any
previously provided goal text as scope details. Ask for more specificity only if
the selected workflow cannot proceed safely without it.

Offer autonomy without hiding the risk:

```text
For fewer approval prompts in a trusted repo, run:
codex-test --exec --mode recommended --go-ham

This keeps Codex in workspace-write sandboxing but uses approval policy
"never", so it can edit tests and run local commands without repeated prompts.
Network installs, destructive actions, and writes outside the repo are still
not part of this workflow unless the user explicitly asks.
```

## Phase 1: Repository Analysis

Prefer the bundled analyzer when available:

```bash
bash .agents/skills/codex-test/scripts/analyze.sh .
```

If the skill is installed for the user rather than checked into the repo, locate
the skill folder from the path shown in the available skills list, then run:

```bash
bash /path/to/codex-test/scripts/analyze.sh .
```

If the script is unavailable, manually inspect:

- package or language files: `package.json`, `pnpm-lock.yaml`, `pyproject.toml`,
  `go.mod`, `Cargo.toml`, `pom.xml`, `pytest.ini`, `vitest.config.*`,
  `jest.config.*`, `playwright.config.*`, `cypress.config.*`
- source layout: `app`, `pages`, `src`, `components`, `lib`, `utils`, `hooks`,
  `server`, `api`, `tests`, `__tests__`, `e2e`
- existing test conventions: imports, runner, assertion style, mocks, file
  placement, setup files, factories, fixtures, and helpers

Read `references/quality-rubric.md` before generating tests.

Capture the detected test commands, coverage commands, lint/typecheck/build
commands, package manager, framework, monorepo/workspace signals, existing test
styles, and dependency constraints. Inspect CI config when present so the plan
matches how developers review and merge code. In coverage mode, run the
project's existing coverage command when it is available and reasonably scoped.
If no real coverage command exists, use analyzer output as a rough map only and
state that the report contains an estimate, not measured line/branch coverage.

## Phase 2: Prioritize Targets

Build a ranked plan using this order:

1. Critical domain behavior: auth, permissions, payments, data validation,
   persistence, API contracts, business rules, parsing, security boundaries.
2. Shared code with many callers: utilities, hooks, services, adapters, state
   machines, form validators, formatters, serializers.
3. Frontend behavior users rely on: forms, loading/error/empty states,
   navigation, filtering, optimistic updates, accessibility-critical controls.
4. Regression risk: complex conditionals, recent changes, bug-prone files,
   high-churn modules, brittle integration points.
5. Coverage gaps that are cheap and meaningful.

Skip or defer:

- pure config, constants, generated files, type-only files, barrel exports,
  stories, snapshots, and wrappers with no behavior
- tests that only assert existence or implementation details
- broad e2e infrastructure when unit/component tests would catch the risk faster

For each proposed target include:

```markdown
1. [priority] `path/to/source`
   Type: unit | component | integration | e2e | domain
   Why: risk and role in the app
   Tests: concrete behaviors and edge cases
   Mocks/fixtures: required dependencies
   Validation: narrow command plus any relevant lint/typecheck/build command
   CI/runtime risk: expected cost, flake risk, and external dependencies
   Expected files: paths to create or update
```

In an interactive session, wait for user confirmation or edits to the plan
before writing tests. If the user already asked you to proceed autonomously, make
the plan visible and continue.

## Workflow Modes

### Recommended Test Scan

Use this for general hardening and for users who want testing analysis like the
standard workflow. Produce a compact ranked plan, then generate the approved
small batch of high-impact tests.

### Increase Test Coverage

Use this when the user asks for coverage growth or a percentage target. Default
to 80% only when the user does not provide a target. If they ask for more than
80%, keep raising the bar but preserve test quality.

Coverage work must be staged:

1. Establish the current baseline from the existing coverage command whenever
   possible.
2. Prefer meaningful low-complexity gaps first: pure utilities, validators,
   parsers, formatters, reducers, hooks with clear boundaries, route handlers,
   and small services.
3. Move to medium-complexity code after cheap meaningful gaps are covered:
   components with state, API boundaries, adapters, stores, server actions, and
   integrations with mockable external dependencies.
4. Reserve high-complexity suites for higher targets or explicit user requests:
   e2e flows, cross-service behavior, concurrency, auth/payment workflows,
   realtime features, data migrations, and fragile legacy modules.
5. Stop before adding shallow tests that inflate numbers without protecting
   behavior. Record those skipped files and why.

When coverage tooling supports it, report before/after lines, branches,
functions, and statements. When it does not, report estimated mapping progress
and tell the user how to add real coverage measurement.

### Specialized Test Development

Use this when the user asks for a specific kind of testing: e2e, regression,
feature coverage, API/contract tests, accessibility tests, backend integration
tests, UI/component tests, or a suite for upcoming work. Treat this as a
production test design task:

- identify the risk model and the target users or systems affected
- reuse the repo's existing runner, fixtures, factories, mocks, auth helpers,
  route helpers, page objects, and CI conventions
- add only the minimum infrastructure needed for the requested test type
- document when a lower-level test would catch the same risk faster
- include data setup, cleanup, flake risks, and CI/runtime implications in the
  report

## Production Repo Defaults

Use these defaults for large production apps and teams:

- Identify repository shape first: monorepo packages, application boundaries,
  shared libraries, CI jobs, package scripts, environment files, fixtures,
  factories, seeded data, and existing test ownership.
- Keep human approval gates explicit. Ask before adding dependencies, creating
  new test infrastructure, changing CI or coverage thresholds, editing product
  source, touching generated code, or adding long-running e2e suites.
- Work in reviewable batches. Prefer a small set of tests that can be understood
  and validated over a large unreviewable coverage dump.
- Prefer repo-local conventions over generic patterns: factories, page objects,
  mock servers, test database helpers, auth/session helpers, route helpers,
  MSW/Nock patterns, Playwright fixtures, and CI script names.
- Do not use real production services, secrets, user data, payment credentials,
  or live third-party APIs. Stub external boundaries or use existing sandbox
  helpers.
- For monorepos, scope commands to the touched package or app when possible, and
  record when only a package-level validation was run instead of the full root
  suite.
- Treat flake risk as a review blocker for e2e/integration tests. Stabilize
  selectors, seeded data, time, network boundaries, retries, and cleanup before
  calling the work ready.
- Do not change coverage gates just to make the report look better. If a
  threshold should change, propose it separately with before/after metrics and
  CI impact.

## Next.js and Modern Frontend Defaults

For Next.js, React, or similar frontend repos:

- Prefer existing test tools. Use Vitest/Jest and Testing Library if present.
- Add component tests for UI state and user behavior, not snapshots as the main
  assertion.
- Add route handler, server action, loader, or API tests when business logic
  sits at the boundary.
- Add Playwright/Cypress tests only when an e2e tool already exists or the plan
  explicitly justifies adding one.
- Do not install test infrastructure by default. If the repo has no test setup,
  propose the smallest viable setup and wait for approval unless running
  non-interactively.
- For app-router code, test pure logic directly and route handlers through
  request/response behavior where practical.
- For forms and interactive components, cover submit success, validation
  failure, disabled/loading states, and the most important accessibility labels.
- For e2e tests, prefer existing Playwright/Cypress setup, stable user-visible
  selectors, deterministic seeded data, and one strong workflow per spec before
  expanding breadth.
- For regression tests, encode the bug or planned behavior as the test name,
  reproduce the failing condition first when practical, and avoid broad snapshots.

## Phase 3: Generate Tests

Work one target at a time:

1. Read the source and adjacent modules.
2. Read relevant existing tests and setup files.
3. Create or update the test file in the project's existing location pattern.
4. Mock only external boundaries: network, database, filesystem, time, browser
   APIs, auth/session providers, feature flags.
5. Keep tests independent and deterministic.
6. Use realistic fixtures and user-visible assertions.

Do not modify product source to make tests pass. If a real bug appears, document
it in the report and ask before changing implementation.

If an existing test file exists, append focused tests instead of replacing it.
If the file is empty or trivial, preserve any useful setup and improve it.

## Phase 4: Validate

Run the narrowest useful command first:

- Vitest: `npx vitest run path/to/test`
- Jest: `npx jest path/to/test`
- Testing Library through project script: package manager test script plus a
  path filter when supported
- Playwright: `npx playwright test path/to/spec`
- Pytest: `python -m pytest path/to/test -x --tb=short`
- Go: `go test ./package`
- Rust: `cargo test`

If a generated test fails:

1. Read the failure.
2. Fix one clear issue in the test or setup.
3. Re-run the same command.
4. If it still fails, stop fixing that file and record the failure, likely
   cause, and suggested next step in the report.

Run broader test or typecheck commands only when they are already available and
reasonably scoped, or when the user requested a full validation pass.

Before marking work ready for human review, prefer this validation order when
the commands exist and are reasonably scoped:

1. Narrow tests for each generated/updated test file.
2. The package or suite test command that owns the touched files.
3. Typecheck for the touched package/app.
4. Lint for the touched package/app.
5. Coverage command when coverage mode is selected.
6. Build or full CI-equivalent command only when it is already available and
   reasonable for the repo size, or when the user requested it.

## Phase 5: Write the Draft Report

Create or update `CODEX-TEST-REPORT.md` in the repo root. The report is the
human review artifact, not just a log. Before writing it, read
`references/reporting-standard.md` when available. Include:

- timestamp, repo path, selected workflow mode, coverage target when applicable,
  detected stack, package/workspace context, test runner, coverage command,
  lint/typecheck/build commands, and command(s) run
- a high-level overview table summarizing changes, impact, risk addressed, and
  validation status
- testing goal and plan summary, including why the selected workflow was used
- generated/updated file table with status and developer-readable purpose
- per-file explanation:
  - source file
  - test file
  - priority and test type
  - why this target was chosen
  - high-level file overview
  - detailed description of the important sections, helpers, fixtures, test
    cases, mocks, setup, and assertions inside the file
  - change and impact summary
  - table of test names, behavior covered, why it matters, category, edge cases
  - mocking/fixture strategy
  - validation command and result
  - gaps and recommended follow-ups
- coverage baseline and after-state when coverage mode is selected, or an
  honest explanation that only estimated mapping was possible
- skipped targets and why
- failing tests or blocked validation with exact command and concise error
- CI/runtime impact, flake risks, data/secrets assumptions, and whether new
  dependencies or infrastructure were avoided or proposed
- continuous-improvement plan: next coverage/test targets, complexity tier,
  expected value, prerequisites, and when it is ready for human review
- user review checklist: `git diff`, generated tests, report, and test commands

After writing the report, run the bundled report finalizer if available:

```bash
bash .agents/skills/codex-test/scripts/report.sh .
```

## Phase 6: Final Response

Keep the final response short and concrete:

```text
Generated/updated N test files and CODEX-TEST-REPORT.md.
Validation: N passing, N failing, N not run.
Mode: Recommended Test Scan | Increase Test Coverage | Specialized Test Development.
Key targets: ...
Review: CODEX-TEST-REPORT.md and git diff.
```

Mention any commands that could not be run and why.

## Hard Rules

- Do not delete existing tests.
- Do not overwrite unrelated user changes.
- Do not edit product source unless the user explicitly expands the task from
  test generation into bug fixing.
- Do not add network-installed dependencies without approval.
- Do not call real production services, use real secrets, or rely on live user
  data in generated tests.
- Do not use snapshots as a substitute for behavioral assertions.
- Do not report success unless generated tests were run, or clearly state that
  validation was not possible.
- Keep the report honest: include tradeoffs, uncovered areas, and residual risk.
