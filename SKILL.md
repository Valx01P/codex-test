---
name: codex-test
description: >
  Agentic test discovery, planning, generation, validation, and reporting for
  Codex. Use when a user asks to audit tests, improve coverage, generate unit,
  integration, UI, e2e, regression, or domain tests, harden a Next.js/frontend
  repo, find high-impact test targets, or invokes "$codex-test" or "codex-test".
---

# Codex Test

Run a rigorous test-improvement workflow that keeps the human in the loop
without making them re-explain the process.

## Core Behavior

1. Inspect the repository before recommending tests.
2. Present a short testing brief and proposed plan before writing tests when the
   user is available.
3. Prefer high-signal tests over broad, shallow coverage.
4. Generate tests in small batches, validate them, and fix straightforward
   failures once.
5. Write `CODEX-TEST-REPORT.md` as a reviewable draft explaining every created
   or updated file, why it exists, what each test covers, validation results,
   remaining gaps, and follow-up recommendations.

If the user started Codex non-interactively and cannot approve a plan, proceed
with a conservative default plan: up to 5 high-impact targets, no dependency
installation unless already available, and no product source edits.

## Phase 0: Align Scope

Start by saying what will happen:

```text
I will inspect the repo, identify the best test targets, propose a prioritized
plan, then generate and validate the agreed tests with a report explaining every
file changed.
```

Ask for specificity only if the user did not provide it and the session is
interactive:

- "Do you want a broad coverage pass, or should I focus on a workflow, bug,
  component, route, or domain area?"
- "Should I stop after the plan, or proceed after the plan with the highest
  impact tests?"

Offer autonomy without hiding the risk:

```text
For fewer approval prompts in a trusted repo, run:
codex-test --exec --go-ham

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
   Expected files: paths to create or update
```

In an interactive session, wait for user confirmation or edits to the plan
before writing tests. If the user already asked you to proceed autonomously, make
the plan visible and continue.

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

## Phase 5: Write the Draft Report

Create or update `CODEX-TEST-REPORT.md` in the repo root. The report is the
human review artifact, not just a log. Include:

- timestamp, repo path, detected stack, test runner, and command(s) run
- testing goal and plan summary
- generated/updated file table
- per-file explanation:
  - source file
  - test file
  - priority and test type
  - why this target was chosen
  - table of test names, behavior covered, why it matters, category, edge cases
  - mocking/fixture strategy
  - validation command and result
  - gaps and recommended follow-ups
- skipped targets and why
- failing tests or blocked validation with exact command and concise error
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
- Do not use snapshots as a substitute for behavioral assertions.
- Do not report success unless generated tests were run, or clearly state that
  validation was not possible.
- Keep the report honest: include tradeoffs, uncovered areas, and residual risk.
