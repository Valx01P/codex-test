# CODEX-TEST-REPORT.md Standard

Purpose: concise developer handoff. Optimize for skim value, not exhaustiveness.
Normal target: 300-800 lines. For large batches, group details; do not write a
multi-thousand-line report.

## Required Sections

1. `Summary`: timestamp, repo, mode, goal, coverage target/baseline when
   relevant, stack, runner, package/workspace context, commands.
2. `Overview`: changed-file table with status, test type, risk, impact,
   validation.
3. `Production Context`: affected app/package, conventions reused, CI commands,
   dependency/infrastructure changes, external services, secrets/data
   assumptions, runtime/flake risk.
4. `Plan`: why this mode, priority order, coverage ladder or suite strategy,
   skipped work.
5. `Generated`: grouped summaries, not one exhaustive section per test. Include
   file/group, purpose, test count, key behaviors, notable edge cases, validation
   result. Add detailed callouts only for high-risk files, new infrastructure,
   failures, unusual mocks, or representative patterns.
6. `Coverage`: include for coverage mode/measured coverage; before/after
   metrics, command, target, files improved/deferred, estimated labels.
7. `Validation`: commands with pass/fail/not-run status; separate narrow,
   package, lint, typecheck, coverage, build, full-suite validation.
8. `Gaps`: uncovered behavior and residual CI/runtime/flake/dependency/env/data
   risks.
9. `Continuous Improvement`: next targets, complexity, value, prerequisites,
   suggested validation.
10. `Human Review Packet`: changed files, rerun commands, first review targets,
    blocked validation, whether CI/coverage/deps/product source changed.

## Batching Rules

- If <=5 files changed, per-file notes are fine.
- If >5 files or >15 tests changed, group by feature/package/test type.
- For large batches, include a "Representative Details" table with 3-7 rows.
- Do not list every assertion unless the file failed, is high risk, or adds new
  infrastructure.
- Keep raw errors short: command plus useful excerpt only.
- Mark estimates as estimates; distinguish syntax, narrow tests, package tests,
  and full CI.
- State if ready for human review and what remains blocked.

## Compact Generated Template

```markdown
## Generated

| Group/File | Purpose | Tests | Key behaviors | Validation |
| --- | --- | ---: | --- | --- |
| `src/auth/*` | auth guard coverage | 6 | allow/deny/session expiry | Passed |

### Representative Details

| File | Why detail matters | Important setup/mocks | Review notes |
| --- | --- | --- | --- |
| `auth.test.ts` | high-risk permission logic | session factory, fake clock | inspect role matrix |
```
