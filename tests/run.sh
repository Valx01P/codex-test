#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIRS=()
PASS_COUNT=0
FAIL_COUNT=0

cleanup() {
  local dir
  for dir in "${TMP_DIRS[@]}"; do
    [[ -n "$dir" && -d "$dir" ]] && rm -rf "$dir"
  done
}
trap cleanup EXIT

make_temp_dir() {
  local dir
  dir="$(mktemp -d)"
  TMP_DIRS+=("$dir")
  printf '%s\n' "$dir"
}

fail() {
  printf '    %s\n' "$*" >&2
  return 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if ! grep -Fq -- "$needle" <<< "$haystack"; then
    fail "expected output to contain: $needle"
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if grep -Fq -- "$needle" <<< "$haystack"; then
    fail "expected output not to contain: $needle"
    return 1
  fi
}

assert_file_exists() {
  local path="$1"
  [[ -f "$path" ]] || fail "expected file to exist: $path"
}

assert_executable() {
  local path="$1"
  [[ -x "$path" ]] || fail "expected file to be executable: $path"
}

run_test() {
  local name="$1"
  local fn="$2"

  printf 'test: %s\n' "$name"
  if "$fn"; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok\n'
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  failed\n' >&2
  fi
}

test_analyze_detects_next_vitest_project() {
  local repo output
  repo="$(make_temp_dir)"

  mkdir -p "$repo/app" "$repo/lib" "$repo/utils" "$repo/tests"
  cat > "$repo/package.json" <<'JSON'
{
  "scripts": {
    "test": "vitest run",
    "test:unit": "vitest run --unit",
    "test:e2e": "playwright test"
  },
  "dependencies": {
    "next": "15.0.0",
    "react": "19.0.0"
  },
  "devDependencies": {
    "vitest": "2.0.0",
    "@testing-library/react": "16.0.0",
    "@playwright/test": "1.45.0"
  }
}
JSON
  printf 'export default function Page() { return null; }\n' > "$repo/app/page.tsx"
  printf 'export const total = 1;\n' > "$repo/lib/checkout.ts"
  printf 'export const format = String;\n' > "$repo/utils/format.ts"
  printf 'import { total } from "../lib/checkout";\n' > "$repo/tests/checkout.test.ts"

  output="$(bash "$ROOT_DIR/scripts/analyze.sh" "$repo")" || return 1

  assert_contains "$output" "LANGUAGE: javascript/typescript" || return 1
  assert_contains "$output" "PROJECT_TYPE: nextjs" || return 1
  assert_contains "$output" "FRAMEWORK: nextjs" || return 1
  assert_contains "$output" "PACKAGE_MANAGER: npm" || return 1
  assert_contains "$output" "TEST_RUNNER: vitest" || return 1
  assert_contains "$output" "TEST_COMMAND: npm run test" || return 1
  assert_contains "$output" "UNIT_TEST_COMMAND: npm run test:unit" || return 1
  assert_contains "$output" "E2E_TEST_COMMAND: npm run test:e2e" || return 1
  assert_contains "$output" "NEXTJS: yes" || return 1
  assert_contains "$output" "REACT: yes" || return 1
  assert_contains "$output" "TESTING_LIBRARY: yes" || return 1
  assert_contains "$output" "PLAYWRIGHT: yes" || return 1
  assert_contains "$output" "SOURCE_FILES: 3" || return 1
  assert_contains "$output" "TEST_FILES: 1" || return 1
  assert_contains "$output" "./app/page.tsx" || return 1
  assert_contains "$output" "./utils/format.ts" || return 1
}

test_analyze_uses_pnpm_script_commands() {
  local repo output
  repo="$(make_temp_dir)"

  mkdir -p "$repo/lib" "$repo/tests"
  cat > "$repo/package.json" <<'JSON'
{
  "scripts": {
    "test": "vitest run",
    "test:unit": "vitest run --unit",
    "test:ui": "vitest --ui",
    "test:e2e": "playwright test"
  },
  "devDependencies": {
    "vitest": "2.0.0",
    "@playwright/test": "1.45.0"
  }
}
JSON
  printf 'lockfileVersion: "9.0"\n' > "$repo/pnpm-lock.yaml"
  printf 'export const amount = 42;\n' > "$repo/lib/billing.ts"
  printf 'import { amount } from "../lib/billing";\n' > "$repo/tests/billing.test.ts"

  output="$(bash "$ROOT_DIR/scripts/analyze.sh" "$repo")" || return 1

  assert_contains "$output" "PACKAGE_MANAGER: pnpm" || return 1
  assert_contains "$output" "TEST_RUNNER: vitest" || return 1
  assert_contains "$output" "TEST_COMMAND: pnpm test" || return 1
  assert_contains "$output" "UNIT_TEST_COMMAND: pnpm test:unit" || return 1
  assert_contains "$output" "UI_TEST_COMMAND: pnpm test:ui" || return 1
  assert_contains "$output" "E2E_TEST_COMMAND: pnpm test:e2e" || return 1
}

test_analyze_detects_python_pytest_project() {
  local repo output
  repo="$(make_temp_dir)"

  mkdir -p "$repo/src/app" "$repo/tests"
  printf '[tool.pytest.ini_options]\npythonpath = ["src"]\n' > "$repo/pyproject.toml"
  printf 'def normalize(value):\n    return value.strip().lower()\n' > "$repo/src/app/normalize.py"
  printf 'from app.normalize import normalize\n' > "$repo/tests/test_normalize.py"

  output="$(bash "$ROOT_DIR/scripts/analyze.sh" "$repo")" || return 1

  assert_contains "$output" "LANGUAGE: python" || return 1
  assert_contains "$output" "PROJECT_TYPE: python" || return 1
  assert_contains "$output" "FRAMEWORK: pytest" || return 1
  assert_contains "$output" "TEST_RUNNER: pytest" || return 1
  assert_contains "$output" "TEST_COMMAND: python -m pytest" || return 1
  assert_contains "$output" "SOURCE_FILES: 1" || return 1
  assert_contains "$output" "TEST_FILES: 1" || return 1
}

test_analyze_handles_shell_only_repo_as_unknown() {
  local repo output
  repo="$(make_temp_dir)"

  printf '# sample\n' > "$repo/README.md"
  printf '#!/usr/bin/env bash\nprintf ok\\n\n' > "$repo/tool.sh"
  chmod +x "$repo/tool.sh"

  output="$(bash "$ROOT_DIR/scripts/analyze.sh" "$repo")" || return 1

  assert_contains "$output" "LANGUAGE: unknown" || return 1
  assert_contains "$output" "PROJECT_TYPE: unknown" || return 1
  assert_contains "$output" "TEST_RUNNER: unknown" || return 1
  assert_contains "$output" "SOURCE_FILES: 0" || return 1
  assert_contains "$output" "TEST_FILES: 0" || return 1
}

test_report_finalizer_is_idempotent() {
  local repo report first second marker_count
  repo="$(make_temp_dir)"
  report="$repo/CODEX-TEST-REPORT.md"

  cat > "$report" <<'MD'
# Summary

Generated tests passed.

## Generated

### `tests/example.test`

## Validation

Passing.

## Gaps

None.
MD

  first="$(bash "$ROOT_DIR/scripts/report.sh" "$repo")" || return 1
  second="$(bash "$ROOT_DIR/scripts/report.sh" "$repo")" || return 1
  marker_count="$(grep -c '^<!-- generated-by: codex-test -->' "$report")"

  assert_contains "$first" "Report finalized: $report" || return 1
  assert_contains "$second" "Report finalized: $report" || return 1
  [[ "$marker_count" == "1" ]] || fail "expected one generated-by marker, found $marker_count" || return 1
  assert_contains "$(sed -n '1,3p' "$report")" "<!-- generated-by: codex-test -->" || return 1
}

test_report_finalizer_supports_legacy_report_name() {
  local repo legacy output
  repo="$(make_temp_dir)"
  legacy="$repo/TEST-COVERAGE-REPORT.md"

  cat > "$legacy" <<'MD'
# Summary

Legacy report passed.

## Generated
## Validation
## Gaps
MD

  output="$(bash "$ROOT_DIR/scripts/report.sh" "$repo")" || return 1

  assert_contains "$output" "Report finalized: $legacy" || return 1
  assert_contains "$(sed -n '1p' "$legacy")" "<!-- generated-by: codex-test -->" || return 1
}

test_codex_test_version_does_not_require_codex_cli() {
  local output
  output="$(PATH="/usr/bin:/bin" bash "$ROOT_DIR/codex-test" --version)" || return 1
  [[ "$output" == "codex-test v0.2.0" ]] || fail "unexpected version output: $output"
}

test_codex_test_builds_default_prompt_without_optional_args() {
  local tmp fake_bin capture output line_count
  tmp="$(make_temp_dir)"
  fake_bin="$tmp/bin"
  capture="$tmp/codex-args.txt"
  mkdir -p "$fake_bin"

  cat > "$fake_bin/codex" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$CODEX_CAPTURE_FILE"
SH
  chmod +x "$fake_bin/codex"

  CODEX_CAPTURE_FILE="$capture" \
    PATH="$fake_bin:/usr/bin:/bin" \
    bash "$ROOT_DIR/codex-test" > "$tmp/stdout.txt" 2> "$tmp/stderr.txt"

  output="$(cat "$tmp/stderr.txt")"
  [[ -z "$output" ]] || fail "expected default invocation to avoid stderr, got: $output" || return 1
  assert_file_exists "$capture" || return 1
  output="$(cat "$capture")"
  line_count="$(wc -l < "$capture" | tr -d '[:space:]')"

  [[ "$line_count" == "1" ]] || fail "expected one codex argument, got $line_count: $output" || return 1
  assert_contains "$output" 'Use $codex-test. Inspect this repository for test gaps' || return 1
}

test_codex_test_builds_safe_exec_prompt_and_flags() {
  local tmp fake_bin capture output status stderr
  tmp="$(make_temp_dir)"
  fake_bin="$tmp/bin"
  capture="$tmp/codex-args.txt"
  mkdir -p "$fake_bin"

  cat > "$fake_bin/codex" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$CODEX_CAPTURE_FILE"
SH
  chmod +x "$fake_bin/codex"

  CODEX_CAPTURE_FILE="$capture" \
    PATH="$fake_bin:/usr/bin:/bin" \
    bash "$ROOT_DIR/codex-test" --exec --go-ham --plan-only --goal "focus on checkout form validation" \
    > "$tmp/stdout.txt" 2> "$tmp/stderr.txt"
  status=$?
  output="$(cat "$tmp/stdout.txt")"
  stderr="$(cat "$tmp/stderr.txt")"

  [[ "$status" == "0" ]] || fail "expected codex-test to invoke fake codex; exit $status; stderr: $stderr" || return 1

  [[ -z "$output" ]] || fail "expected fake codex invocation to be quiet, got: $output" || return 1
  assert_file_exists "$capture" || return 1
  output="$(cat "$capture")"

  assert_contains "$output" "exec" || return 1
  assert_contains "$output" "--ask-for-approval" || return 1
  assert_contains "$output" "never" || return 1
  assert_contains "$output" "--sandbox" || return 1
  assert_contains "$output" "workspace-write" || return 1
  assert_contains "$output" 'Use $codex-test in non-interactive mode.' || return 1
  assert_contains "$output" "Stop after writing the proposed plan in chat. Do not edit files." || return 1
  assert_contains "$output" "User testing goal: focus on checkout form validation" || return 1
}

test_codex_test_reports_missing_codex_cli() {
  local tmp stderr status
  tmp="$(make_temp_dir)"

  PATH="/usr/bin:/bin" bash "$ROOT_DIR/codex-test" --exec > "$tmp/stdout.txt" 2> "$tmp/stderr.txt"
  status=$?
  stderr="$(cat "$tmp/stderr.txt")"

  [[ "$status" == "1" ]] || fail "expected exit status 1, got $status" || return 1
  assert_contains "$stderr" "codex-test: Codex CLI not found." || return 1
  assert_contains "$stderr" "npm install -g @openai/codex" || return 1
}

test_codex_test_install_repo_copies_skill_without_shell_profile() {
  local tmp repo home output status stderr
  tmp="$(make_temp_dir)"
  repo="$tmp/repo"
  home="$tmp/home"
  mkdir -p "$repo" "$home"

  (
    cd "$repo" || exit 1
    HOME="$home" \
      SHELL="/bin/bash" \
      CODEX_TEST_NO_SHELL=1 \
      PATH="/usr/bin:/bin" \
      bash "$ROOT_DIR/codex-test" --install-repo
  ) > "$tmp/stdout.txt" 2> "$tmp/stderr.txt"
  status=$?
  output="$(cat "$tmp/stdout.txt")"
  stderr="$(cat "$tmp/stderr.txt")"

  [[ "$status" == "0" ]] || fail "expected --install-repo to complete; exit $status; stderr: $stderr" || return 1

  assert_contains "$output" "Installed repo-local skill to .agents/skills/codex-test" || return 1
  assert_contains "$output" "Commit this directory so teammates get the same Codex skill." || return 1
  assert_contains "$output" "Verified: codex-test --version" || return 1
  assert_not_contains "$output" "Shell integration installed" || return 1
  assert_file_exists "$repo/.agents/skills/codex-test/SKILL.md" || return 1
  assert_file_exists "$repo/.agents/skills/codex-test/scripts/analyze.sh" || return 1
  assert_file_exists "$repo/.agents/skills/codex-test/references/quality-rubric.md" || return 1
  [[ ! -f "$home/.bashrc" ]] || fail "expected CODEX_TEST_NO_SHELL=1 to avoid writing shell profile" || return 1
}

test_codex_test_check_reports_ready_with_fake_codex() {
  local tmp fake_bin skill output status stderr
  tmp="$(make_temp_dir)"
  fake_bin="$tmp/bin"
  skill="$tmp/skill"
  mkdir -p "$fake_bin" "$skill"
  printf '# fixture skill\n' > "$skill/SKILL.md"

  cat > "$fake_bin/codex" <<'SH'
#!/usr/bin/env bash
printf 'fake codex\n'
SH
  chmod +x "$fake_bin/codex"

  CODEX_TEST_SKILL_DIR="$skill" \
    PATH="$fake_bin:/usr/bin:/bin" \
    bash "$ROOT_DIR/codex-test" --check > "$tmp/stdout.txt" 2> "$tmp/stderr.txt"
  status=$?
  output="$(cat "$tmp/stdout.txt")"
  stderr="$(cat "$tmp/stderr.txt")"

  [[ "$status" == "0" ]] || fail "expected --check to report ready; exit $status; stderr: $stderr" || return 1

  assert_contains "$output" "codex-test check" || return 1
  assert_contains "$output" "[ok] Wrapper: $ROOT_DIR/codex-test" || return 1
  assert_contains "$output" "[ok] Skill: $skill" || return 1
  assert_contains "$output" "[ok] Codex CLI: $fake_bin/codex" || return 1
  assert_contains "$output" "[ok] Version: codex-test v0.2.0" || return 1
  assert_contains "$output" "Ready. Try: codex test" || return 1
}

test_codex_test_print_function_uses_path_wrapper() {
  local tmp fake_bin wrapper output
  tmp="$(make_temp_dir)"
  fake_bin="$tmp/bin"
  wrapper="$fake_bin/codex-test"
  mkdir -p "$fake_bin"
  printf '#!/usr/bin/env bash\nprintf wrapper\\n\n' > "$wrapper"
  chmod +x "$wrapper"

  output="$(PATH="$fake_bin:/usr/bin:/bin" bash "$ROOT_DIR/codex-test" --print-codex-function)" || return 1

  assert_contains "$output" "# It forwards \"codex test ...\" to codex-test" || return 1
  assert_contains "$output" "\"$wrapper\" \"\$@\"" || return 1
  assert_contains "$output" "command codex \"\$@\"" || return 1
}

test_install_sh_installs_from_stubbed_clone() {
  local tmp fake_bin git_stub output home bin profile status stderr
  tmp="$(make_temp_dir)"
  fake_bin="$tmp/fake-bin"
  home="$tmp/home"
  bin="$tmp/bin"
  profile="$tmp/profile"
  mkdir -p "$fake_bin" "$home" "$bin"
  git_stub="$fake_bin/git"

  cat > "$git_stub" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
dest="${@: -1}"
mkdir -p "$dest"
cp -R "$CODEX_TEST_FIXTURE_REPO"/. "$dest"
SH
  chmod +x "$git_stub"

  HOME="$home" \
    SHELL="/bin/bash" \
    CODEX_TEST_BIN_DIR="$bin" \
    CODEX_TEST_SHELL_PROFILE="$profile" \
    CODEX_TEST_FIXTURE_REPO="$ROOT_DIR" \
    PATH="$fake_bin:/usr/bin:/bin" \
    bash "$ROOT_DIR/install.sh" > "$tmp/stdout.txt" 2> "$tmp/stderr.txt"
  status=$?
  output="$(cat "$tmp/stdout.txt")"
  stderr="$(cat "$tmp/stderr.txt")"

  [[ "$status" == "0" ]] || fail "expected install.sh to complete; exit $status; stderr: $stderr" || return 1

  assert_contains "$output" "Downloading github.com/" || return 1
  assert_contains "$output" "codex-test installed." || return 1
  assert_contains "$output" "Skill:   $home/.agents/skills/codex-test" || return 1
  assert_contains "$output" "Command: $bin/codex-test" || return 1
  assert_file_exists "$home/.agents/skills/codex-test/SKILL.md" || return 1
  assert_file_exists "$home/.agents/skills/codex-test/scripts/analyze.sh" || return 1
  assert_file_exists "$home/.agents/skills/codex-test/references/quality-rubric.md" || return 1
  assert_executable "$bin/codex-test" || return 1
  assert_contains "$(cat "$profile")" "# >>> codex-test shell integration >>>" || return 1
  assert_contains "$(cat "$profile")" "\"$bin/codex-test\" \"\$@\"" || return 1
}

run_test "analyze.sh detects a Next.js Vitest project" test_analyze_detects_next_vitest_project
run_test "analyze.sh uses pnpm script commands" test_analyze_uses_pnpm_script_commands
run_test "analyze.sh detects a Python pytest project" test_analyze_detects_python_pytest_project
run_test "analyze.sh treats shell-only repos as unknown" test_analyze_handles_shell_only_repo_as_unknown
run_test "report.sh adds metadata once" test_report_finalizer_is_idempotent
run_test "report.sh supports legacy report fallback" test_report_finalizer_supports_legacy_report_name
run_test "codex-test --version works without Codex CLI" test_codex_test_version_does_not_require_codex_cli
run_test "codex-test builds default prompt without optional args" test_codex_test_builds_default_prompt_without_optional_args
run_test "codex-test builds safe exec prompt and flags" test_codex_test_builds_safe_exec_prompt_and_flags
run_test "codex-test reports missing Codex CLI" test_codex_test_reports_missing_codex_cli
run_test "codex-test --install-repo copies skill without shell profile" test_codex_test_install_repo_copies_skill_without_shell_profile
run_test "codex-test --check reports ready with fake Codex CLI" test_codex_test_check_reports_ready_with_fake_codex
run_test "codex-test --print-codex-function uses PATH wrapper" test_codex_test_print_function_uses_path_wrapper
run_test "install.sh installs from a stubbed clone" test_install_sh_installs_from_stubbed_clone

printf '\n%d passing, %d failing\n' "$PASS_COUNT" "$FAIL_COUNT"
if (( FAIL_COUNT > 0 )); then
  exit 1
fi
