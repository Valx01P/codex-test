#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

count_lines() {
  local value="${1:-}"
  if [[ -z "$value" ]]; then
    printf '0\n'
  else
    printf '%s\n' "$value" | grep -c . || true
  fi
}

has_file() {
  local pattern="$1"
  compgen -G "$pattern" >/dev/null 2>&1
}

has_package_text() {
  local pattern="$1"
  [[ -f package.json ]] && grep -Eqi "$pattern" package.json
}

package_manager() {
  if [[ -f pnpm-lock.yaml ]]; then
    printf 'pnpm\n'
  elif [[ -f yarn.lock ]]; then
    printf 'yarn\n'
  elif [[ -f bun.lockb || -f bun.lock ]]; then
    printf 'bun\n'
  elif [[ -f package-lock.json || -f npm-shrinkwrap.json || -f package.json ]]; then
    printf 'npm\n'
  else
    printf 'unknown\n'
  fi
}

script_command() {
  local name="$1"
  local pm="$2"

  [[ -f package.json ]] || return 1
  grep -Eq "\"$name\"[[:space:]]*:" package.json || return 1

  case "$pm" in
    pnpm) printf 'pnpm %s\n' "$name" ;;
    yarn) printf 'yarn %s\n' "$name" ;;
    bun) printf 'bun run %s\n' "$name" ;;
    *) printf 'npm run %s\n' "$name" ;;
  esac
}

find_code_files() {
  find . \
    \( -path './.git' \
    -o -path './node_modules' \
    -o -path './.next' \
    -o -path './dist' \
    -o -path './build' \
    -o -path './coverage' \
    -o -path './vendor' \
    -o -path './target' \
    -o -path './__pycache__' \
    -o -path './venv' \
    -o -path './env' \
    -o -path './.venv' \) -prune \
    -o -type f "$@" -print 2>/dev/null | sort
}

LANGUAGE="unknown"
PROJECT_TYPE="unknown"
FRAMEWORK="unknown"
TEST_RUNNER="unknown"
PM="$(package_manager)"
TEST_COMMAND="unknown"
UNIT_TEST_COMMAND="unknown"
UI_TEST_COMMAND="unknown"
E2E_TEST_COMMAND="unknown"

NEXTJS="no"
REACT="no"
TESTING_LIBRARY="no"
PLAYWRIGHT="no"
CYPRESS="no"

if [[ -f package.json ]]; then
  LANGUAGE="javascript/typescript"
  PROJECT_TYPE="node"

  if has_package_text '"next"[[:space:]]*:' || [[ -f next.config.js || -f next.config.mjs || -f next.config.ts ]]; then
    PROJECT_TYPE="nextjs"
    FRAMEWORK="nextjs"
    NEXTJS="yes"
  elif has_package_text '"react"[[:space:]]*:'; then
    PROJECT_TYPE="react"
    FRAMEWORK="react"
    REACT="yes"
  fi

  has_package_text '"react"[[:space:]]*:' && REACT="yes"
  has_package_text '@testing-library/(react|user-event|jest-dom)' && TESTING_LIBRARY="yes"
  has_package_text '"@playwright/test"[[:space:]]*:' || has_file 'playwright.config.*' && PLAYWRIGHT="yes"
  has_package_text '"cypress"[[:space:]]*:' || has_file 'cypress.config.*' && CYPRESS="yes"

  if has_file 'vitest.config.*' || has_package_text '"vitest"[[:space:]]*:'; then
    TEST_RUNNER="vitest"
    UNIT_TEST_COMMAND="npx vitest run"
  elif has_file 'jest.config.*' || has_package_text '"jest"[[:space:]]*:'; then
    TEST_RUNNER="jest"
    UNIT_TEST_COMMAND="npx jest"
  elif has_package_text '"mocha"[[:space:]]*:' || has_file '.mocharc.*'; then
    TEST_RUNNER="mocha"
    UNIT_TEST_COMMAND="npx mocha"
  fi

  if script_command test "$PM" >/dev/null 2>&1; then
    TEST_COMMAND="$(script_command test "$PM")"
  elif [[ "$TEST_RUNNER" == "vitest" ]]; then
    TEST_COMMAND="npx vitest run"
  elif [[ "$TEST_RUNNER" == "jest" ]]; then
    TEST_COMMAND="npx jest"
  fi

  if script_command test:unit "$PM" >/dev/null 2>&1; then
    UNIT_TEST_COMMAND="$(script_command test:unit "$PM")"
  fi
  if script_command test:ui "$PM" >/dev/null 2>&1; then
    UI_TEST_COMMAND="$(script_command test:ui "$PM")"
  fi
  if script_command test:e2e "$PM" >/dev/null 2>&1; then
    E2E_TEST_COMMAND="$(script_command test:e2e "$PM")"
  elif [[ "$PLAYWRIGHT" == "yes" ]]; then
    E2E_TEST_COMMAND="npx playwright test"
  elif [[ "$CYPRESS" == "yes" ]]; then
    E2E_TEST_COMMAND="npx cypress run"
  fi
elif [[ -f pyproject.toml || -f setup.py || -f setup.cfg || -f pytest.ini ]]; then
  LANGUAGE="python"
  PROJECT_TYPE="python"
  FRAMEWORK="pytest"
  TEST_RUNNER="pytest"
  TEST_COMMAND="python -m pytest"
elif [[ -f go.mod ]]; then
  LANGUAGE="go"
  PROJECT_TYPE="go"
  FRAMEWORK="go"
  TEST_RUNNER="go test"
  TEST_COMMAND="go test ./..."
elif [[ -f Cargo.toml ]]; then
  LANGUAGE="rust"
  PROJECT_TYPE="rust"
  FRAMEWORK="cargo"
  TEST_RUNNER="cargo test"
  TEST_COMMAND="cargo test"
elif [[ -f build.gradle || -f build.gradle.kts || -f pom.xml ]]; then
  LANGUAGE="java"
  PROJECT_TYPE="java"
  FRAMEWORK="junit"
  TEST_RUNNER="junit"
  if [[ -f build.gradle || -f build.gradle.kts ]]; then
    TEST_COMMAND="./gradlew test"
  else
    TEST_COMMAND="mvn test"
  fi
elif [[ -f phpunit.xml || -f phpunit.xml.dist ]]; then
  LANGUAGE="php"
  PROJECT_TYPE="php"
  FRAMEWORK="phpunit"
  TEST_RUNNER="phpunit"
  TEST_COMMAND="./vendor/bin/phpunit"
fi

case "$LANGUAGE" in
  javascript/typescript)
    ALL_FILES="$(find_code_files \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' \))"
    TEST_PATTERN='(\.test\.|\.spec\.|/__tests__/|/tests?/|/e2e/|\.stories\.)'
    ;;
  python)
    ALL_FILES="$(find_code_files -name '*.py')"
    TEST_PATTERN='(^|/)test_|_test\.py$|/tests?/'
    ;;
  go)
    ALL_FILES="$(find_code_files -name '*.go')"
    TEST_PATTERN='_test\.go$'
    ;;
  rust)
    ALL_FILES="$(find_code_files -name '*.rs')"
    TEST_PATTERN='(^|/)tests?/'
    ;;
  java)
    ALL_FILES="$(find_code_files -name '*.java')"
    TEST_PATTERN='Test\.java$|/src/test/'
    ;;
  php)
    ALL_FILES="$(find_code_files -name '*.php')"
    TEST_PATTERN='Test\.php$|/tests?/'
    ;;
  *)
    ALL_FILES="$(find_code_files \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.java' -o -name '*.php' \))"
    TEST_PATTERN='test|spec|__tests__'
    ;;
esac

TEST_FILES="$(printf '%s\n' "$ALL_FILES" | grep -Ei "$TEST_PATTERN" || true)"
SOURCE_FILES="$(printf '%s\n' "$ALL_FILES" | grep -Eiv "$TEST_PATTERN" || true)"

SOURCE_FILES="$(printf '%s\n' "$SOURCE_FILES" | grep -Ev '(\.d\.ts$|next-env\.d\.ts$|\.config\.|/types?/|/constants?/|/generated/|\.stories\.)' || true)"

SRC_COUNT="$(count_lines "$SOURCE_FILES")"
TEST_COUNT="$(count_lines "$TEST_FILES")"

TESTED=0
UNTESTED_LIST=""

while IFS= read -r src; do
  [[ -z "$src" ]] && continue

  base="$(basename "$src")"
  stem="${base%.*}"
  dir="$(dirname "$src" | sed 's#^\./##')"
  stem_lc="$(printf '%s' "$stem" | tr '[:upper:]' '[:lower:]')"
  dir_lc="$(printf '%s' "$dir" | tr '[:upper:]' '[:lower:]')"

  has_match=false
  while IFS= read -r test_file; do
    [[ -z "$test_file" ]] && continue
    test_base="$(basename "$test_file")"
    test_lc="$(printf '%s' "$test_file" | tr '[:upper:]' '[:lower:]')"
    test_base_lc="$(printf '%s' "$test_base" | tr '[:upper:]' '[:lower:]')"

    if [[ "$test_base_lc" == *"$stem_lc"* ]] || [[ "$test_lc" == *"$dir_lc"* && "$test_lc" == *"$stem_lc"* ]]; then
      has_match=true
      break
    fi
  done <<< "$TEST_FILES"

  if [[ "$has_match" == true ]]; then
    TESTED=$((TESTED + 1))
  else
    UNTESTED_LIST="${UNTESTED_LIST}${src}"$'\n'
  fi
done <<< "$SOURCE_FILES"

UNTESTED=$((SRC_COUNT - TESTED))
if (( SRC_COUNT > 0 )); then
  COVERAGE=$((TESTED * 100 / SRC_COUNT))
else
  COVERAGE=0
fi

HIGH_VALUE="$(printf '%s\n' "$UNTESTED_LIST" | grep -Ei '(/app/|/pages/|/api/|/routes?/|/server/|/services?/|/lib/|/utils?/|/hooks?/|/components?/|auth|session|permission|payment|checkout|billing|validation|schema|parser|serializer|form|route|action|loader|mutation)' | head -40 || true)"

printf '=== CODEX TEST ANALYSIS ===\n'
printf 'ROOT: %s\n' "$(pwd)"
printf 'LANGUAGE: %s\n' "$LANGUAGE"
printf 'PROJECT_TYPE: %s\n' "$PROJECT_TYPE"
printf 'FRAMEWORK: %s\n' "$FRAMEWORK"
printf 'PACKAGE_MANAGER: %s\n' "$PM"
printf 'TEST_RUNNER: %s\n' "$TEST_RUNNER"
printf 'TEST_COMMAND: %s\n' "$TEST_COMMAND"
printf 'UNIT_TEST_COMMAND: %s\n' "$UNIT_TEST_COMMAND"
printf 'UI_TEST_COMMAND: %s\n' "$UI_TEST_COMMAND"
printf 'E2E_TEST_COMMAND: %s\n' "$E2E_TEST_COMMAND"
printf '\n'

printf '=== FRONTEND SIGNALS ===\n'
printf 'NEXTJS: %s\n' "$NEXTJS"
printf 'REACT: %s\n' "$REACT"
printf 'TESTING_LIBRARY: %s\n' "$TESTING_LIBRARY"
printf 'PLAYWRIGHT: %s\n' "$PLAYWRIGHT"
printf 'CYPRESS: %s\n' "$CYPRESS"
printf '\n'

printf '=== FILE COUNTS ===\n'
printf 'SOURCE_FILES: %s\n' "$SRC_COUNT"
printf 'TEST_FILES: %s\n' "$TEST_COUNT"
printf 'TESTED_SOURCES: %s\n' "$TESTED"
printf 'UNTESTED_SOURCES: %s\n' "$UNTESTED"
printf 'ESTIMATED_TEST_MAPPING: %s%%\n' "$COVERAGE"
printf '\n'

printf '=== HIGH VALUE CANDIDATES ===\n'
if [[ -n "$HIGH_VALUE" ]]; then
  printf '%s\n' "$HIGH_VALUE"
else
  printf '(none detected by path heuristic)\n'
fi
printf '\n'

printf '=== UNTESTED FILES (TOP 60) ===\n'
printf '%s\n' "$UNTESTED_LIST" | head -60
printf '\n'

printf '=== EXISTING TEST FILES (TOP 40) ===\n'
printf '%s\n' "$TEST_FILES" | head -40
printf '\n'

printf '=== EXISTING TEST SAMPLES ===\n'
sample_count=0
while IFS= read -r test_file; do
  [[ -z "$test_file" ]] && continue
  (( sample_count >= 2 )) && break
  printf -- '--- SAMPLE: %s ---\n' "$test_file"
  sed -n '1,80p' "$test_file" 2>/dev/null || true
  printf '\n'
  sample_count=$((sample_count + 1))
done <<< "$TEST_FILES"

if (( sample_count == 0 )); then
  printf '(no existing test samples found)\n'
fi

printf '=== END CODEX TEST ANALYSIS ===\n'
