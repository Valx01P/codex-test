# CODEX-TEST-REPORT.md Reporting Standard

Use this reference when writing `CODEX-TEST-REPORT.md`. The report is a
developer handoff document: readable enough to scan, detailed enough to review
without reverse-engineering every generated file.

## Required Structure

1. `Summary`
   - timestamp
   - repository path
   - selected workflow mode
   - user goal
   - coverage target and baseline when applicable
   - detected stack, runner, package manager, workspace/monorepo context, and
     commands

2. `Overview`
   - table with each changed file
   - status: created, updated, unchanged, or blocked
   - test type
   - risk or behavior addressed
   - impact
   - validation result

3. `Production Context`
   - app/package/workspace affected
   - existing test conventions reused
   - CI commands discovered
   - dependency and infrastructure changes proposed or avoided
   - external services, secrets, data, and environment assumptions
   - expected runtime and flake risk

4. `Plan`
   - why the workflow mode was selected
   - priority order
   - coverage ladder or test-suite strategy when relevant
   - what was intentionally skipped

5. `Generated`
   - one section per generated or updated file
   - one short summary paragraph for the file
   - a detailed breakdown table for important sections, helpers, fixtures,
     mocks, test cases, assertions, and setup
   - source files covered
   - test names and behaviors
   - why each behavior matters
   - validation command and result
   - gaps, risk, and follow-up recommendations

6. `Coverage`
   - include for coverage mode or when coverage was measured
   - before/after metrics if available
   - command used
   - thresholds requested
   - files moved from uncovered to covered
   - files deferred by complexity or risk
   - clearly label estimates when measured coverage is unavailable

7. `Validation`
   - every command run
   - pass/fail/not-run status
   - concise failure details and likely cause
   - whether a retry was attempted
   - separate narrow test validation from package, lint, typecheck, coverage,
     build, and full-suite validation

8. `Gaps`
   - uncovered files or behaviors
   - reasons for skipping
   - residual risk
   - CI/runtime, flake, dependency, environment, and data risks

9. `Continuous Improvement`
   - next recommended test targets
   - complexity tier: low, medium, high
   - expected value
   - prerequisites
   - suggested validation command
   - clear "ready for human review" checklist

10. `Human Review Packet`
    - exact files changed
    - commands to rerun locally
    - what reviewers should inspect first
    - known limitations and blocked validation
    - whether CI config, coverage thresholds, dependencies, or product source
      were changed

## Tone and Detail

- Prefer tables for scanability, followed by short explanatory paragraphs.
- Avoid dumping raw logs. Quote only the failing command and the useful error.
- Explain test impact in product terms when possible: the behavior protected,
  regression prevented, or workflow made safer.
- Do not hide uncertainty. If coverage is estimated, say so in the summary and
  coverage section.
- Keep the report honest when tests fail. Passing syntax checks do not mean the
  test suite passed.
- Make review readiness explicit. A report should say whether the work is ready
  for human review, what remains blocked, and what would make the tests safer in
  CI.

## Per-File Detail Template

```markdown
### `path/to/file`

High-level overview: one paragraph explaining what the file does and why it was
created or changed.

| Part | What it does | Why it matters | Review notes |
| --- | --- | --- | --- |
| helper/setup/test case | description | impact | important caveats |

Source files covered:

| Source | Behavior covered | Risk addressed |
| --- | --- | --- |
| `src/example.ts` | input validation and edge cases | prevents invalid state |

Tests:

| Test name | Behavior | Assertion strategy | Edge cases |
| --- | --- | --- | --- |
| `rejects invalid input` | invalid form data | user-visible error | empty strings |

Validation:

| Command | Result | Notes |
| --- | --- | --- |
| `npm test -- example.test.ts` | Passed | narrow test run |

Production context:

| Area | Notes |
| --- | --- |
| CI impact | package-level test only; full build not run |
| Runtime/flake risk | deterministic unit tests; no browser required |
| Dependencies | none added |
| Data/secrets | synthetic fixtures only |
```
