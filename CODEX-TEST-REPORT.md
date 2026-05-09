<!-- generated-by: codex-test -->
<!-- timestamp: 2026-05-09T23:26:31Z -->

# Summary

Timestamp: 2026-05-09T23:26:31Z

Repository: `/Users/pvaldes/Projects/codex-test`

Selected workflow mode: Specialized Test Development for the codex-test skill
itself. This pass reviewed the earlier changes from the perspective of a
developer using codex-test on a production app, then tightened the workflow,
prompts, analyzer output, CLI options, report standard, docs, and tests. A
follow-up pass aligned the interactive flow with the required behavior: plain
`codex test` always asks for `1`, `2`, or `3` and never infers the workflow.
A final compression/report-readability pass reduced the main AI-loaded
instructions while keeping the same behavior. `SKILL.md` is now 229 lines and
`references/reporting-standard.md` is now 59 lines. The report standard now
targets concise, grouped reports instead of exhaustive multi-thousand-line
per-test reports.

Detected stack: Bash and PowerShell wrappers/installers plus Markdown skill
instructions. The bundled analyzer still reports this repository as `unknown`
because it detects manifest-based JavaScript/TypeScript, Python, Go, Rust, Java,
and PHP projects, not shell-only skill repositories.

Test runner: custom dependency-free Bash harness at `tests/run.sh`.

Coverage target behavior: future target repos default to 80% only when users
select coverage mode without providing a threshold. The wrapper now accepts
targets like `85` and `85%`, normalizes them, and rejects invalid values.

Validation result: `bash tests/run.sh` passes with 18 passing tests and 0
failing tests.

# Overview

| File | Status | Type | Production value | Validation |
| --- | --- | --- | --- | --- |
| `SKILL.md` | Updated | Skill workflow | Compressed to a faster-loading 229-line instruction set while preserving strict menu flow, production rules, validation order, and bounded report requirements. | Skill validator passed. |
| `references/reporting-standard.md` | Created/updated | Report reference | Compressed to a 59-line report standard that targets 300-800 line normal reports and grouped summaries for large batches. | Installed by copy tests. |
| `codex-test` | Updated | Bash CLI wrapper | Adds validated workflow flags, normalized coverage targets, conflict checks, strict-menu prompt wording, shorter prompt payloads, and concise-report wording. | Harness and syntax checks passed. |
| `codex-test.ps1` | Updated | PowerShell CLI wrapper | Mirrors Bash workflow flags, validation logic, shorter prompt payloads, and concise-report wording for Windows users. | Not executed because `pwsh` is unavailable. |
| `scripts/analyze.sh` | Updated | Analyzer | Emits coverage, lint, typecheck, build, monorepo, and workspace signals for production planning. | Harness and syntax checks passed. |
| `scripts/report.sh` | Updated | Report finalizer | Warns when reports miss `Production Context` or `Human Review Packet`. | Harness and syntax checks passed. |
| `tests/run.sh` | Updated | Test harness | Covers strict interactive menu prompting, exec mode requirements, mode validation, conflicting options, coverage target normalization, CI command discovery, monorepo signals, and report headings. | `18 passing, 0 failing`. |
| `README.md` | Updated | User docs | Documents the three modes, coverage target syntax, and production app behavior. | Reviewed in diff. |
| `agents/openai.yaml` | Updated | Skill UI metadata | Default prompt now says to show the numbered menu and wait for the user's choice. | Skill validator passed. |
| `install.sh` | Updated | Bash installer | Includes the new report reference and avoids the prior shell-profile `pipefail` issue. | Harness and syntax checks passed. |
| `install.ps1` | Updated | PowerShell installer | Includes the new report reference in the web-download path. | Not executed because `pwsh` is unavailable. |
| `CODEX-TEST-REPORT.md` | Updated | Review artifact | Documents the current production-readiness pass. | Finalizer passed. |

# Production Context

| Area | Notes |
| --- | --- |
| Target user | Developers applying codex-test to large production apps, especially Next.js/frontends, backends, and monorepos. |
| Core production need | The tool should avoid vague "add tests" behavior and instead produce reviewable, deterministic, CI-aware test work. |
| Existing conventions | The skill now tells Codex to reuse repo-local fixtures, factories, mocks, auth helpers, page objects, route helpers, and CI scripts. |
| Human interaction | Interactive runs always start with numbered choices and wait for `1`, `2`, or `3`. Explicit mode flags are only allowed for non-interactive `--exec` runs. Approval gates are called out for dependencies, CI, coverage thresholds, product source edits, and long e2e suites. |
| CI impact | Analyzer now surfaces lint, typecheck, build, coverage, and workspace signals so the plan can include realistic review-ready commands. |
| Runtime/flake risk | Skill/report guidance now requires documenting e2e/integration runtime cost, flake risks, selectors, seeded data, time/network handling, and cleanup. |
| Data/secrets | Skill hard rules now forbid real production services, secrets, live user data, payment credentials, or live third-party APIs in generated tests. |
| Dependencies | Network-installed dependencies remain approval-gated. The skill prefers existing tools and proposes minimal setup when a repo lacks test infrastructure. |

# Plan

The review found the earlier implementation direction was useful, but production
developers would likely want four extra things before trusting it on a large app:

| Priority | Improvement | Why |
| --- | --- | --- |
| P0 | Validate and normalize CLI mode inputs. | Typos like `--mode covrage` should fail early instead of producing a vague prompt. |
| P0 | Normalize coverage targets and reject conflicts. | `--coverage-target 85%` should work, and `--mode recommended --coverage-target 80` should not silently conflict. |
| P1 | Surface CI and monorepo signals. | Production review usually depends on package-level test, typecheck, lint, build, and workspace scope. |
| P1 | Strengthen production prompt/report guidance. | Reports should explain CI/runtime impact, flake risk, secrets/data assumptions, and what is ready for human review. |
| P1 | Keep docs aligned. | Users should understand the behavior before running the tool on a real app. |
| P1 | Enforce the interactive menu contract. | `codex test` should always ask for `1`, `2`, or `3`; non-interactive runs must provide `--mode`. |

Skipped or deferred:

| Target | Reason |
| --- | --- |
| Full PowerShell runtime validation | `pwsh` is not installed in this environment. |
| Real coverage parsing | Analyzer discovers coverage commands but does not parse lcov/Cobertura/coverage JSON yet. |
| Shell-project classification | Useful for this repo itself, but less important than production app signals. |
| Forward test on a large app | Requires a target production-like app and approval to modify tests. |

# Generated

### `SKILL.md`

High-level overview: this is the core instruction file another Codex instance
will follow. It now behaves less like a generic test generator and more like a
production test engineer: choose a workflow first, inspect local conventions,
work in reviewable batches, preserve approval gates, and document readiness.

| Part | What it does | Why it matters | Review notes |
| --- | --- | --- | --- |
| Mode menu | Always offers Recommended Test Scan, Increase Test Coverage, and Specialized Test Development before analysis in interactive runs. | Gives users control before commands or edits. | Goals are scope context only; they never select the workflow. |
| Coverage workflow | Defaults to 80%, measures baseline when possible, then covers lower-complexity meaningful gaps before harder suites. | Avoids shallow coverage inflation and gives a practical route to higher thresholds. | Coverage gates are not changed without approval. |
| Specialized workflow | Handles e2e, regression, feature, API/contract, accessibility, backend, UI/component, and upcoming-feature tests. | Production teams often need focused suites, not just unit coverage. | Requires runtime, flake, data setup, and CI implications in the report. |
| Production Repo Defaults | Adds monorepo/package awareness, approval gates, batching, local helper reuse, secret/data rules, scoped commands, and flake-risk blockers. | These are the safeguards production developers expect. | This is the biggest production-usefulness improvement in this pass. |
| Validation phase | Adds a review-ready validation order: narrow tests, package suite, typecheck, lint, coverage, build/full CI when reasonable. | Prevents overclaiming readiness after only a narrow test run. | Still avoids expensive root commands unless available and appropriate. |
| Report phase | Requires workspace context, CI commands, runtime/flake risk, data/secrets assumptions, and review checklist. | Makes the generated report useful for code review. | Points to `references/reporting-standard.md`. |
| Hard rules | Adds no real production services, secrets, or live user data. | Protects teams from dangerous test behavior. | Complements existing no-dependency-install rule. |

Tests and validation:

| Command | Result | Notes |
| --- | --- | --- |
| `python3 /Users/pvaldes/.codex/skills/.system/skill-creator/scripts/quick_validate.py .` | Passed | Skill metadata and naming are valid. |

### `references/reporting-standard.md`

High-level overview: this reference defines what a production-grade
`CODEX-TEST-REPORT.md` should contain. It is intentionally separate from
`SKILL.md` so the main skill stays concise while detailed reporting rules remain
available.

| Part | What it does | Why it matters | Review notes |
| --- | --- | --- | --- |
| Required Structure | Defines `Summary`, `Overview`, `Production Context`, `Plan`, `Generated`, `Coverage`, `Validation`, `Gaps`, `Continuous Improvement`, and `Human Review Packet`. | Gives future agents a complete handoff structure. | `Coverage` remains conditional when relevant. |
| Production Context | Requires app/package scope, CI commands, dependency/infrastructure changes, external service assumptions, runtime, and flake risk. | This is what reviewers need before trusting tests in CI. | New in this production-readiness pass. |
| Validation detail | Separates narrow tests from package, lint, typecheck, coverage, build, and full-suite validation. | Avoids treating one command as full readiness. | Matches the updated skill validation order. |
| Human Review Packet | Requires exact changed files, rerun commands, first-review targets, blocked validation, and whether CI/deps/source changed. | Makes the report actionable for reviewers. | New in this pass. |
| Per-file template | Explains file purpose, important internals, sources covered, tests, and production context. | Developers can understand generated files without reverse-engineering them. | Keeps reports detailed but scan-friendly. |

Tests and validation:

| Command | Result | Notes |
| --- | --- | --- |
| `bash tests/run.sh` | Passed | Install tests confirm the reference is copied into installed skills. |

### `codex-test`

High-level overview: this Bash wrapper launches Codex with the skill prompt and
handles install/check/uninstall flows. It now rejects bad mode input, normalizes
coverage targets, and adds production-readiness language to the generated prompt.

| Part | What it does | Why it matters | Review notes |
| --- | --- | --- | --- |
| `normalize_test_mode` | Maps aliases like `1`, `scan`, `cover`, and `suite` to canonical modes. Rejects unknown modes. | Prevents typo-driven ambiguous behavior. | Covered by invalid-mode test. |
| `normalize_coverage_target` | Strips whitespace/percent signs and accepts numeric targets from 1 to 100. | Makes `85` and `85%` behave the same. | Covered by exec prompt test. |
| `--coverage-target` conflict check | Rejects coverage target when mode is not coverage. | Prevents contradictory prompts. | Covered by conflict test. |
| `--test-kind` conflict check | Requires specialized mode when a test kind is provided. | Keeps specialized suite requests clear. | Implemented in Bash and PowerShell. |
| Prompt wording | Requires showing exactly three numbered options, waiting for `1`, `2`, or `3`, and never inferring from goal text. It also adds production-ready plan language plus CI/runtime and flake-risk notes. | Future Codex runs follow the required menu flow and know what to document for reviewers. | Covered by default-prompt assertion. |
| Exec mode requirement | `--exec` exits unless `--mode recommended`, `--mode coverage`, or `--mode specialized` is provided. | Non-interactive runs cannot silently default to the wrong workflow. | Covered by exec-requires-mode test. |
| Interactive mode rejection | `--mode` is rejected unless `--exec` is present. | Plain `codex test` always asks the user to choose a number. | Covered by interactive-rejects-mode test. |
| `first_shell_profile` | Reads the first shell profile without `head` under `pipefail`. | Keeps installer flows from failing on macOS Bash profile detection. | Existing install-repo regression remains green. |

Tests and validation:

| Command | Result | Notes |
| --- | --- | --- |
| `bash tests/run.sh` | Passed | Covers wrapper prompts, mode validation, conflicts, version, install, check, and shell function output. |
| `bash -n codex-test` | Passed | Syntax check. |
| `/bin/bash -n codex-test` | Passed | macOS Bash syntax check. |

### `codex-test.ps1`

High-level overview: this PowerShell wrapper mirrors the Bash wrapper for
Windows users. It now has the same mode aliases, coverage target normalization,
conflict checks, and production-ready prompt wording.

| Part | What it does | Why it matters | Review notes |
| --- | --- | --- | --- |
| `Normalize-TestMode` | Maps mode aliases to `recommended`, `coverage`, or `specialized`; rejects unknown values. | Keeps Windows behavior aligned with Bash. | Not executed locally. |
| `Normalize-CoverageTarget` | Accepts values like `80` and `85%`, rejects non-numeric or out-of-range targets. | Prevents malformed prompts. | Not executed locally. |
| Parser conflict checks | Rejects coverage target outside coverage mode and test kind outside specialized mode. | Prevents contradictory user intent. | Mirrors Bash behavior. |
| Prompt wording | Requires numbered workflow selection in interactive runs and adds production-ready plan, CI/runtime, and flake-risk notes. | Keeps Windows launcher output aligned. | Requires future `pwsh` validation. |
| Exec/interactive checks | Requires `--mode` for `--exec` and rejects `--mode` in interactive mode. | Mirrors the strict Bash flow. | Requires future `pwsh` validation. |

Validation:

| Command | Result | Notes |
| --- | --- | --- |
| `command -v pwsh` | Not available | PowerShell runtime validation could not be run in this environment. |

### `scripts/analyze.sh`

High-level overview: this analyzer summarizes repository test signals. It now
surfaces the commands and workspace information a production developer would use
to decide whether generated tests are review-ready.

| Part | What it does | Why it matters | Review notes |
| --- | --- | --- | --- |
| `COVERAGE_COMMAND` | Detects package coverage scripts or runner fallbacks. | Coverage mode needs a real command when available. | Existing npm/pnpm coverage tests pass. |
| `LINT_COMMAND` | Detects package `lint` script. | Review-ready test changes often need lint. | Covered by Next.js fixture. |
| `TYPECHECK_COMMAND` | Detects `typecheck` or `type-check` script. | Type errors are common in generated TS tests. | Covered by Next.js fixture. |
| `BUILD_COMMAND` | Detects package `build` script. | Build readiness matters for CI. | Covered by Next.js fixture. |
| `MONOREPO` and workspace hints | Detects `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json`, `rush.json`, and `package.json` workspaces. | Large apps often require scoped package validation instead of root-wide assumptions. | Covered by `turbo.json` fixture. |
| Low-complexity candidates | Lists uncovered files of 120 lines or fewer. | Helps coverage mode start with easier meaningful targets. | Heuristic is labeled as such. |

Validation:

| Command | Result | Notes |
| --- | --- | --- |
| `bash tests/run.sh` | Passed | Covers coverage command, lint/typecheck/build command, and monorepo signal output. |
| `bash scripts/analyze.sh .` | Passed | This shell-only repo reports `unknown` commands and `MONOREPO: no`, expected. |
| `bash -n scripts/analyze.sh` | Passed | Syntax check. |
| `/bin/bash -n scripts/analyze.sh` | Passed | macOS Bash syntax check. |

### `scripts/report.sh`

High-level overview: this finalizer adds metadata and warns when expected report
sections are missing. It now enforces the new production report shape via
warnings.

| Part | What it does | Why it matters | Review notes |
| --- | --- | --- | --- |
| Heading checks | Adds `Production Context` and `Human Review Packet` to expected headings. | Future reports are nudged toward production review readiness. | Warnings remain non-blocking. |

Validation:

| Command | Result | Notes |
| --- | --- | --- |
| `bash tests/run.sh` | Passed | Report fixtures include the expanded headings. |
| `bash scripts/report.sh .` | Passed | Finalized this report. |
| `bash -n scripts/report.sh` | Passed | Syntax check. |
| `/bin/bash -n scripts/report.sh` | Passed | macOS Bash syntax check. |

### `tests/run.sh`

High-level overview: this harness validates the skill's deterministic shell
behavior without external dependencies. It now covers the production-readiness
changes.

| Test or fixture | Behavior covered | Why it matters |
| --- | --- | --- |
| Next.js/Vitest fixture | Coverage, lint, typecheck, build, and `turbo.json` monorepo output. | Production planning needs CI and workspace signals. |
| Exec prompt fixture | `--mode cover --coverage-target 85%` normalizes to coverage mode and `85%`. | Users commonly include percent signs. |
| Exec requires mode test | `--exec` without `--mode` exits 2. | Non-interactive runs cannot assume a workflow. |
| Interactive rejects mode test | `--mode coverage` without `--exec` exits 2. | Plain `codex test` always asks for `1`, `2`, or `3`. |
| Invalid mode test | `--mode covrage` exits 2 with a helpful error. | Prevents ambiguous typo-driven prompts. |
| Conflicting options test | `--mode recommended --coverage-target 80` exits 2. | Prevents contradictory instructions. |
| Report fixtures | Include `Production Context` and `Human Review Packet`. | Keeps finalizer expectations aligned. |
| Install fixtures | Confirm `reporting-standard.md` is installed. | Installed skill has the report reference. |

Validation:

| Command | Result | Notes |
| --- | --- | --- |
| `bash tests/run.sh` | Passed | 18 passing, 0 failing. |
| `bash -n tests/run.sh` | Passed | Syntax check. |
| `/bin/bash -n tests/run.sh` | Passed | macOS Bash syntax check. |

### `README.md`

High-level overview: the README now explains how production developers should
expect the tool to behave.

| Part | What it does | Why it matters |
| --- | --- | --- |
| Mode section | Documents Recommended Test Scan, Increase Test Coverage, and Specialized Test Development. | Users know what choice they will see before analysis. |
| Coverage examples | Shows `--exec --mode coverage --coverage-target 85` and notes `85%` is accepted. | Makes coverage workflow scriptable without weakening the interactive menu. |
| Specialized example | Shows `--exec --mode specialized --test-kind e2e`. | Makes non-coverage automation discoverable. |
| Production App Behavior | Describes convention reuse, command detection, approval gates, runtime/flake risk, skipped targets, and review steps. | Sets realistic expectations for large apps. |

Validation:

| Command | Result | Notes |
| --- | --- | --- |
| Manual diff review | Passed | Markdown only. |

### `agents/openai.yaml`

High-level overview: this UI metadata now describes codex-test as a numbered
testing workflow menu that waits for the user's choice.

| Part | What it does | Why it matters |
| --- | --- | --- |
| `default_prompt` | Says to show the numbered testing workflow menu and wait for the user's choice. | The UI prompt matches the strict interactive flow. |
| `short_description` | Keeps the concise "Choose, improve, validate, and explain tests" description. | Still fits the skill chip while covering the new menu behavior. |

Validation:

| Command | Result | Notes |
| --- | --- | --- |
| `python3 /Users/pvaldes/.codex/skills/.system/skill-creator/scripts/quick_validate.py .` | Passed | Skill metadata remains valid. |

### `install.sh`

High-level overview: this Unix installer remains responsible for downloading
and installing the skill, wrapper, references, and shell integration.

| Part | What it does | Why it matters |
| --- | --- | --- |
| `first_shell_profile` | Avoids the prior `shell_profiles | head -1` `pipefail` issue. | Install and repo-local install stay reliable on macOS Bash. |
| Curl fallback | Downloads `references/reporting-standard.md`. | Installs without git clone still include the report standard. |

Validation:

| Command | Result | Notes |
| --- | --- | --- |
| `bash tests/run.sh` | Passed | Stubbed clone install test confirms copied files. |
| `bash -n install.sh` | Passed | Syntax check. |
| `/bin/bash -n install.sh` | Passed | macOS Bash syntax check. |

### `install.ps1`

High-level overview: this Windows installer now downloads the new report
standard in the web-download fallback path.

| Part | What it does | Why it matters |
| --- | --- | --- |
| Download fallback | Fetches `references/reporting-standard.md`. | Windows installs are complete when clone is unavailable. |

Validation:

| Command | Result | Notes |
| --- | --- | --- |
| `command -v pwsh` | Not available | PowerShell validation remains a follow-up. |

### `CODEX-TEST-REPORT.md`

High-level overview: this report now reflects the production-readiness review
and the second round of improvements.

| Part | What it does | Why it matters |
| --- | --- | --- |
| Summary/Overview | Captures workflow, stack, changed files, and validation. | Fast review entry point. |
| Production Context | Explains user, CI, runtime, flake, data, and dependency assumptions. | Matches the new report standard. |
| Generated | Uses grouped details and representative callouts so developers can understand the diff without a huge report. |
| Gaps and Continuous Improvement | Records residual risk and next work. | Keeps the handoff honest. |
| Human Review Packet | Lists exact review steps and commands. | Makes review actionable. |

# Coverage

This implementation pass did not increase coverage for the codex-test repository
itself. It improved future target-repo coverage workflows.

Coverage-related behavior now includes:

| Area | Behavior |
| --- | --- |
| Skill workflow | Increase Test Coverage mode defaults to 80% only when no target is provided. |
| CLI | `--coverage-target` normalizes `85` and `85%`, rejects invalid values, and requires coverage mode. |
| Analyzer | Emits `COVERAGE_COMMAND` and low-complexity uncovered candidates. |
| Report standard | Requires measured before/after coverage when available and clear labeling when coverage is estimated. |
| Tests | Cover npm `test:coverage`, pnpm `coverage`, and normalized `85%` prompt output. |

For this repository, `bash scripts/analyze.sh .` reported:

| Field | Value |
| --- | --- |
| `LANGUAGE` | `unknown` |
| `TEST_RUNNER` | `unknown` |
| `COVERAGE_COMMAND` | `unknown` |
| `LINT_COMMAND` | `unknown` |
| `TYPECHECK_COMMAND` | `unknown` |
| `BUILD_COMMAND` | `unknown` |
| `MONOREPO` | `no` |
| `ESTIMATED_TEST_MAPPING` | `0%` |

# Validation

| Command | Result | Details |
| --- | --- | --- |
| `bash tests/run.sh` | Passed | 18 passing, 0 failing. |
| `bash scripts/analyze.sh .` | Passed | Reports expected shell-only unknown stack plus new command fields. |
| `python3 /Users/pvaldes/.codex/skills/.system/skill-creator/scripts/quick_validate.py .` | Passed | Skill is valid. |
| `git diff --check` | Passed | No whitespace errors. |
| `bash -n codex-test` | Passed | Bash wrapper syntax. |
| `bash -n install.sh` | Passed | Unix installer syntax. |
| `bash -n scripts/analyze.sh` | Passed | Analyzer syntax. |
| `bash -n scripts/report.sh` | Passed | Report finalizer syntax. |
| `bash -n tests/run.sh` | Passed | Harness syntax. |
| `/bin/bash -n codex-test` | Passed | macOS Bash wrapper syntax. |
| `/bin/bash -n install.sh` | Passed | macOS Bash installer syntax. |
| `/bin/bash -n scripts/analyze.sh` | Passed | macOS Bash analyzer syntax. |
| `/bin/bash -n scripts/report.sh` | Passed | macOS Bash report finalizer syntax. |
| `/bin/bash -n tests/run.sh` | Passed | macOS Bash harness syntax. |
| `command -v pwsh` | Not available | PowerShell wrapper and installer were not executed. |

No dependency installation was attempted.

# Gaps

| Gap | Reason | Risk |
| --- | --- | --- |
| PowerShell runtime validation | `pwsh` is not installed. | Windows wrapper/installer logic is reviewed but not executed here. |
| Real coverage parser support | Analyzer discovers commands but does not parse coverage artifacts. | Future coverage reports still need Codex to inspect tool output manually. |
| Shell project detection | Analyzer still reports this repo as `unknown`. | Self-analysis is less descriptive, but production app signals improved. |
| Large-app forward test | No production-scale target app was used. | Workflow is specified and wrapper/analyzer behavior is tested, but not field-tested on a real app in this pass. |
| PowerShell tests | No Pester or equivalent harness exists. | Windows parity could regress without a Windows-capable CI job. |

# Continuous Improvement

| Next target | Complexity | Expected value | Prerequisites | Suggested validation |
| --- | --- | --- | --- | --- |
| Add PowerShell test coverage. | Medium | Confirms Windows parity for mode validation and install behavior. | `pwsh` in local or CI. | `pwsh -NoProfile -File tests/run.ps1` or Pester. |
| Parse coverage artifacts. | Medium | Enables true before/after metrics across common tools. | Fixtures for lcov, coverage-summary.json, Cobertura, pytest-cov, Go cover. | Analyzer/parser tests. |
| Detect shell/custom harness repos. | Low | Makes codex-test self-analysis clearer. | Define shell project output fields. | Extend shell-only analyzer fixture. |
| Add CI workflow for this repo. | Low | Runs harness and syntax checks on every change. | Choose GitHub Actions or another CI. | CI job running `bash tests/run.sh` plus syntax checks. |
| Forward-test on a large Next.js app. | High | Validates report readability and workflow choices under realistic complexity. | Target app and approval to edit tests. | Run `$codex-test`, review report quality and generated tests. |

# Human Review Packet

Changed files:

| File |
| --- |
| `SKILL.md` |
| `references/reporting-standard.md` |
| `codex-test` |
| `codex-test.ps1` |
| `scripts/analyze.sh` |
| `scripts/report.sh` |
| `tests/run.sh` |
| `README.md` |
| `agents/openai.yaml` |
| `install.sh` |
| `install.ps1` |
| `CODEX-TEST-REPORT.md` |

Review first:

| Area | Why |
| --- | --- |
| `SKILL.md` mode and production sections | These define future agent behavior. |
| `codex-test` argument validation | This is the user-facing CLI contract. |
| `scripts/analyze.sh` output fields | These drive future coverage and production planning. |
| `references/reporting-standard.md` | This determines how detailed generated reports will be. |

Commands to rerun:

```bash
bash tests/run.sh
python3 /Users/pvaldes/.codex/skills/.system/skill-creator/scripts/quick_validate.py .
git diff --check
bash -n codex-test install.sh scripts/analyze.sh scripts/report.sh tests/run.sh
```

Known limitation: run PowerShell validation separately on a machine with `pwsh`.

CI config changed: no.

Coverage thresholds changed: no.

Dependencies added: no.

Product source edited: yes, for this repository's wrapper/analyzer/installer
source files. The codex-test workflow still tells future runs not to edit target
repo product source unless the user explicitly approves bug fixing.
