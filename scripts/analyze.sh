#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# test-coverage skill: analyze.sh
# Scans the repo and outputs structured info for Codex to consume.
# Codex calls this in Phase 1 of the test-coverage workflow.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

echo "=== REPO ANALYSIS ==="
echo ""

# ── Detect language and framework ────────────────────────────
LANG="unknown"
FRAMEWORK="unknown"
TEST_CMD="unknown"

if [[ -f "package.json" ]]; then
  LANG="javascript"
  if [[ -f jest.config.js || -f jest.config.ts || -f jest.config.mjs || -f jest.config.cjs ]]; then
    FRAMEWORK="jest"
    TEST_CMD="npx jest"
  elif grep -q '"jest"' package.json 2>/dev/null; then
    FRAMEWORK="jest"
    TEST_CMD="npx jest"
  elif [[ -f vitest.config.ts || -f vitest.config.js || -f vitest.config.mts ]]; then
    FRAMEWORK="vitest"
    TEST_CMD="npx vitest run"
  elif [[ -f mocha.opts || -f .mocharc.yml || -f .mocharc.json ]]; then
    FRAMEWORK="mocha"
    TEST_CMD="npx mocha"
  else
    # Check package.json scripts
    if grep -q '"test"' package.json 2>/dev/null; then
      TEST_CMD="npm test"
      FRAMEWORK="npm-test-script"
    fi
  fi
elif [[ -f "pyproject.toml" || -f "setup.py" || -f "setup.cfg" || -f "pytest.ini" ]]; then
  LANG="python"
  FRAMEWORK="pytest"
  TEST_CMD="python -m pytest"
elif [[ -f "go.mod" ]]; then
  LANG="go"
  FRAMEWORK="go-test"
  TEST_CMD="go test ./..."
elif [[ -f "Cargo.toml" ]]; then
  LANG="rust"
  FRAMEWORK="cargo-test"
  TEST_CMD="cargo test"
elif [[ -f "build.gradle" || -f "build.gradle.kts" || -f "pom.xml" ]]; then
  LANG="java"
  FRAMEWORK="junit"
  if [[ -f "build.gradle" || -f "build.gradle.kts" ]]; then
    TEST_CMD="./gradlew test"
  else
    TEST_CMD="mvn test"
  fi
elif [[ -f "phpunit.xml" || -f "phpunit.xml.dist" ]]; then
  LANG="php"
  FRAMEWORK="phpunit"
  TEST_CMD="./vendor/bin/phpunit"
fi

echo "LANGUAGE: $LANG"
echo "FRAMEWORK: $FRAMEWORK"
echo "TEST_COMMAND: $TEST_CMD"
echo ""

# ── Find source and test files ───────────────────────────────
EXCLUDE="-not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/vendor/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/__pycache__/*' -not -path '*/target/*' -not -path '*/.next/*' -not -path '*/venv/*' -not -path '*/env/*' -not -path '*/coverage/*'"

case "$LANG" in
  javascript)
    ALL_FILES=$(eval "find . -type f \( -name '*.js' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx' \) $EXCLUDE" 2>/dev/null | sort)
    TEST_PATTERN='\.test\.\|\.spec\.\|__tests__'
    ;;
  python)
    ALL_FILES=$(eval "find . -type f -name '*.py' $EXCLUDE" 2>/dev/null | sort)
    TEST_PATTERN='test_\|_test\.py\|/tests/'
    ;;
  go)
    ALL_FILES=$(eval "find . -type f -name '*.go' $EXCLUDE" 2>/dev/null | sort)
    TEST_PATTERN='_test\.go'
    ;;
  rust)
    ALL_FILES=$(eval "find . -type f -name '*.rs' $EXCLUDE" 2>/dev/null | sort)
    TEST_PATTERN='/tests/\|#\[cfg(test)\]'
    ;;
  java)
    ALL_FILES=$(eval "find . -type f -name '*.java' $EXCLUDE" 2>/dev/null | sort)
    TEST_PATTERN='Test\.java\|/test/'
    ;;
  php)
    ALL_FILES=$(eval "find . -type f -name '*.php' $EXCLUDE" 2>/dev/null | sort)
    TEST_PATTERN='Test\.php\|/tests/'
    ;;
  *)
    ALL_FILES=$(eval "find . -type f \( -name '*.js' -o -name '*.ts' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.java' \) $EXCLUDE" 2>/dev/null | sort)
    TEST_PATTERN='test\|spec\|__tests__'
    ;;
esac

TEST_FILES=$(echo "$ALL_FILES" | grep -i "$TEST_PATTERN" 2>/dev/null || true)
SOURCE_FILES=$(echo "$ALL_FILES" | grep -iv "$TEST_PATTERN" 2>/dev/null || true)

# Also exclude config-like files from source
SOURCE_FILES=$(echo "$SOURCE_FILES" | grep -v -E '(\.config\.|\.d\.ts$|/types/|/constants/)' 2>/dev/null || echo "$SOURCE_FILES")

SRC_COUNT=$(echo "$SOURCE_FILES" | grep -c '.' 2>/dev/null || echo "0")
TEST_COUNT=$(echo "$TEST_FILES" | grep -c '.' 2>/dev/null || echo "0")

# ── Determine which source files are tested ──────────────────
TESTED=0
UNTESTED_LIST=""

while IFS= read -r src; do
  [[ -z "$src" ]] && continue
  basename_src=$(basename "$src")
  name_no_ext="${basename_src%.*}"

  # Check if any test file references this source file
  has_test=false
  while IFS= read -r tf; do
    [[ -z "$tf" ]] && continue
    tf_base=$(basename "$tf")
    if echo "$tf_base" | grep -qi "$name_no_ext"; then
      has_test=true
      break
    fi
  done <<< "$TEST_FILES"

  if $has_test; then
    TESTED=$((TESTED + 1))
  else
    UNTESTED_LIST="${UNTESTED_LIST}${src}\n"
  fi
done <<< "$SOURCE_FILES"

UNTESTED=$((SRC_COUNT - TESTED))
if (( SRC_COUNT > 0 )); then
  COVERAGE=$((TESTED * 100 / SRC_COUNT))
else
  COVERAGE=0
fi

echo "=== FILE COUNTS ==="
echo "SOURCE_FILES: $SRC_COUNT"
echo "TEST_FILES: $TEST_COUNT"
echo "TESTED_SOURCES: $TESTED"
echo "UNTESTED_SOURCES: $UNTESTED"
echo "ESTIMATED_COVERAGE: ${COVERAGE}%"
echo ""

echo "=== UNTESTED FILES ==="
echo -e "$UNTESTED_LIST" | head -30
echo ""

echo "=== EXISTING TEST SAMPLES (for convention matching) ==="
# Show first 2 test files (truncated) so Codex learns the style
SAMPLE_COUNT=0
while IFS= read -r tf; do
  [[ -z "$tf" ]] && continue
  (( SAMPLE_COUNT >= 2 )) && break
  echo "--- SAMPLE: $tf ---"
  head -60 "$tf" 2>/dev/null || true
  echo ""
  SAMPLE_COUNT=$((SAMPLE_COUNT + 1))
done <<< "$TEST_FILES"

echo "=== END ANALYSIS ==="
