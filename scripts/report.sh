#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# test-coverage skill: report.sh
# Post-processes the TEST-COVERAGE-REPORT.md that Codex wrote.
# Adds timestamp header and validates structure.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

ROOT="${1:-.}"
REPORT="$ROOT/TEST-COVERAGE-REPORT.md"

if [[ ! -f "$REPORT" ]]; then
  echo "⚠  No report found at $REPORT"
  echo "   Codex should write the report before calling this script."
  exit 1
fi

# Add generation metadata if not already present
if ! grep -q "^<!-- generated-by: test-coverage -->" "$REPORT" 2>/dev/null; then
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  {
    echo "<!-- generated-by: test-coverage -->"
    echo "<!-- timestamp: $TIMESTAMP -->"
    echo ""
    cat "$REPORT"
  } > "${REPORT}.tmp" && mv "${REPORT}.tmp" "$REPORT"
fi

# Count sections for a quick validation
TOTAL_SECTIONS=$(grep -c '^### ' "$REPORT" 2>/dev/null || echo "0")
PASS_COUNT=$(grep -c '✅' "$REPORT" 2>/dev/null || echo "0")
FAIL_COUNT=$(grep -c '❌' "$REPORT" 2>/dev/null || echo "0")

echo "📄 Report finalized: $REPORT"
echo "   Sections:  $TOTAL_SECTIONS"
echo "   Passing:   $PASS_COUNT"
echo "   Failing:   $FAIL_COUNT"
echo "   Size:      $(wc -c < "$REPORT" | xargs) bytes"
