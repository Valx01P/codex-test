# Test Quality Rubric

When generating tests, evaluate each against these criteria.
A test that fails 2+ criteria should be rewritten.

## Must Pass (deal-breakers)

- [ ] **Compiles/parses** — The test file has no syntax errors
- [ ] **Runs independently** — No test depends on another test's state
- [ ] **Tests behavior, not implementation** — Asserts on outputs/effects, not internal calls
- [ ] **Meaningful assertions** — No `toBeDefined()` or `toBeTruthy()` as sole assertion

## Should Pass (quality bar)

- [ ] **Tests error paths** — At least one test covers invalid/null/error input
- [ ] **Tests edge cases** — Boundary values, empty collections, concurrent ops
- [ ] **Readable test names** — Each name describes expected behavior as a sentence
- [ ] **Proper mocking** — Only mocks external deps; uses project's mock patterns
- [ ] **Matches conventions** — Same imports, nesting, assertion lib as existing tests
- [ ] **User-visible UI assertions** — Component/UI tests assert rendered behavior, roles, labels, and state changes instead of implementation details
- [ ] **Boundary coverage** — API/route/server tests cover status codes, bad input, and auth/permission branches

## Nice to Have (excellence)

- [ ] **Tests async behavior** — Proper await/promise handling, timeout coverage
- [ ] **Parameterized cases** — Uses test.each or equivalent for data-driven tests
- [ ] **Comments on non-obvious setup** — Complex arrangements are explained
- [ ] **Covers the "why"** — Test name or comment explains the business reason
- [ ] **Accessible queries** — Testing Library uses roles, labels, and user-event where practical
- [ ] **Realistic fixtures** — Fixtures resemble production data without leaking secrets

## Anti-Patterns (auto-fail)

- Snapshot tests for non-UI logic
- Snapshot-only tests for UI logic
- Testing console.log was called (unless it's a logging module)
- Mocking the module under test
- Asserting on exact error message strings instead of error types
- Testing third-party library behavior instead of your code's use of it
- Only happy-path tests with zero error handling coverage
- Adding e2e infrastructure for a behavior that a unit or component test would cover clearly
