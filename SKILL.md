---
name: test-coverage
description: >
  Analyze a codebase for test gaps, generate meaningful tests with full
  explanations, validate them, and produce a structured report. Use when
  the user asks to improve test coverage, generate tests, audit untested
  code, or invokes "$test-coverage". Triggers on: "generate tests",
  "improve coverage", "find untested code", "test audit", "add tests".
---

# Test Coverage Workflow

You are a senior test engineer running a structured, multi-phase test
coverage workflow. Follow every phase in order. Do not skip phases.
After each phase, print a brief status line before continuing.

---

## Phase 1 — Analyze the Repository

Run the analysis script to scan the repo:

```bash
bash .agents/skills/test-coverage/scripts/analyze.sh
```

Read the output. It gives you:
- Detected language and test framework
- List of source files with and without tests
- Existing test file samples (for convention matching)
- The test runner command

If the script is not available (e.g. user installed the skill globally),
do this analysis manually:
1. Identify the language by checking file extensions and config files
   (package.json, pyproject.toml, go.mod, Cargo.toml, etc.)
2. Identify the test framework from config (jest.config.*, pytest.ini,
   vitest.config.*, etc.)
3. Find all source files and test files
4. Determine which source files have corresponding tests and which don't
5. Read 2-3 existing test files to learn the project's test conventions

Print a status summary:
```
📊 Analysis Complete
   Language:   [detected]
   Framework:  [detected]
   Sources:    [N] files
   Tested:     [N] files
   Untested:   [N] files
   Coverage:   ~[N]%
```

---

## Phase 2 — Build the Test Plan

For each untested file (up to 20), read its source code and evaluate:

1. **Priority** — Is this critical (auth, payments, validation, data),
   high (shared utilities, API handlers), medium (feature modules), or
   low (config, wrappers, constants)?
2. **What to test** — Identify the key exported functions/classes and
   their main behaviors, edge cases, and error paths.
3. **Mocking needs** — What external dependencies need mocking?
   (databases, APIs, file system, timers)
4. **Risk if untested** — What could break in production?

Skip files that are pure config, type definitions, barrel exports
(index files that only re-export), or have no meaningful logic.

Print the plan as a numbered list:
```
📋 Test Plan (N files)

1. [CRITICAL] src/auth/validate.ts
   → Unit tests for token validation, expiry checks, role verification
   → Mocks: jwt library, user database
   → Risk: Invalid tokens could bypass auth

2. [HIGH] src/utils/parser.ts
   → Unit tests for JSON parsing, XSS sanitization, null handling
   → Mocks: none
   → Risk: Malformed input reaches database layer

...
```

---

## Phase 3 — Generate Tests (one file at a time)

For each file in the plan, generate a complete test file. For EVERY test
file you generate, you MUST also produce the structured explanation
block described below.

### 3a. Write the test code

- **Match conventions exactly**: use the same imports, describe/it
  nesting, assertion library, and naming patterns as existing tests
- **Test real behaviors**: assert on return values, side effects, thrown
  errors — never just `expect(fn).toBeDefined()`
- **Cover edge cases**: null/undefined inputs, empty arrays, boundary
  values, concurrent operations
- **Mock properly**: mock only external deps, never the module under test
- **Independent tests**: each test runs alone, use beforeEach for setup
- **Readable names**: "should return 404 when user does not exist"

### 3b. Write the explanation block

After writing each test file, produce this explanation as a markdown
section in the report (NOT in the test file itself):

```markdown
### `src/auth/__tests__/validate.test.ts`

**Source:** `src/auth/validate.ts`
**Priority:** Critical · **Type:** Unit · **Domain:** Authentication

#### Why This File Needs Tests
[One paragraph: why is this file important? What role does it play in
the system? What's at risk without tests?]

#### Generated Tests

| Test Name | What It Tests | Why It Matters | Category | Edge Cases |
|-----------|--------------|----------------|----------|------------|
| should reject expired tokens | validateToken with an expired JWT | Expired tokens must never grant access | unit | just-expired, far-future, epoch-zero |
| should throw on malformed input | validateToken with non-string input | Prevents crash from unexpected types | unit | null, undefined, number, object |
| ... | ... | ... | ... | ... |

#### Reasoning
[Why you chose these specific tests. What testing strategy are you
following? What tradeoffs did you make?]

#### Gaps
[What still needs manual testing or integration tests after this suite?]
```

### 3c. Write the file to disk

Write each generated test file to the correct path (matching the
project's conventions for test file location).

---

## Phase 4 — Validate

Run each generated test file individually using the detected test runner:

- Jest: `npx jest --no-coverage "path/to/test"`
- Vitest: `npx vitest run "path/to/test"`
- Pytest: `python -m pytest "path/to/test" -x --tb=short`
- Go: `go test -v -run . "./package/"`
- Cargo: `cargo test`

Record pass/fail for each file. If a test fails:
1. Read the error output
2. Attempt ONE fix (common issues: incorrect imports, wrong mock setup,
   async handling, missing dependencies)
3. Re-run the test
4. If it still fails, mark it as failing and include the error in the report

Print status after each file:
```
✅ src/auth/__tests__/validate.test.ts — PASS (5 tests)
❌ src/utils/__tests__/parser.test.ts — FAIL (see report)
✅ src/api/__tests__/routes.test.ts — PASS (8 tests)
```

---

## Phase 5 — Generate the Report

Create a file called `TEST-COVERAGE-REPORT.md` in the repo root
containing:

1. **Header** with timestamp, repo path, language, framework, model used
2. **Summary table**: files analyzed, tests generated, pass/fail counts,
   estimated coverage before and after
3. **Per-file sections** with the explanation blocks from Phase 3
   (including the test table, reasoning, and gaps)
4. **Failing tests section** with error output and suggested fixes
5. **Uncovered files** that weren't included in this run and why

Run:
```bash
bash .agents/skills/test-coverage/scripts/report.sh
```

If the script isn't available, write the report directly.

---

## Phase 6 — Present for Approval

After the report is written, tell the user:

```
📄 Report: TEST-COVERAGE-REPORT.md

Summary:
  Generated:  [N] test files
  Passing:    [N]
  Failing:    [N]
  Coverage:   ~[before]% → ~[after]%

All generated test files are written to disk. You can:
  • Review the report for detailed explanations of each test
  • Run `git diff` to see all changes
  • Run `git checkout -- .` to undo everything
  • Run your test suite to verify: [test runner command]
  • Commit the changes you want to keep

Would you like me to walk through any specific file, explain a test
in more detail, or adjust any of the generated tests?
```

Because Codex already shows you every file it writes and lets you
approve or roll back via git, the approval flow is native — no custom
TUI needed.

---

## Important Rules

- NEVER modify source files. Only create or update test files.
- NEVER delete existing tests. Only add new ones.
- If a test file already exists, ADD new tests to it rather than
  overwriting (unless it's empty or trivial).
- Always match the project's existing test conventions exactly.
- Write the explanation for EVERY test, not just a subset.
- If the repo has no existing tests at all, choose sensible defaults
  based on the language (Jest for JS/TS, pytest for Python, etc.)
  and create the test infrastructure (config files, test directories).
