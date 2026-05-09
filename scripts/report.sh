#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
REPORT="${2:-$ROOT/CODEX-TEST-REPORT.md}"
LEGACY_REPORT="$ROOT/TEST-COVERAGE-REPORT.md"

if [[ ! -f "$REPORT" && -f "$LEGACY_REPORT" ]]; then
  REPORT="$LEGACY_REPORT"
fi

if [[ ! -f "$REPORT" ]]; then
  printf 'No report found. Expected %s\n' "$REPORT" >&2
  exit 1
fi

if ! grep -q '^<!-- generated-by: codex-test -->' "$REPORT" 2>/dev/null; then
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  tmp="${REPORT}.tmp"
  {
    printf '<!-- generated-by: codex-test -->\n'
    printf '<!-- timestamp: %s -->\n' "$timestamp"
    printf '\n'
    cat "$REPORT"
  } > "$tmp"
  mv "$tmp" "$REPORT"
fi

section_count="$(grep -c '^### ' "$REPORT" 2>/dev/null || true)"
file_section_count="$(grep -Ec '^### `[^`]+`' "$REPORT" 2>/dev/null || true)"
pass_count="$(grep -Eci '\b(pass|passing|passed)\b|PASS' "$REPORT" 2>/dev/null || true)"
fail_count="$(grep -Eci '\b(fail|failing|failed)\b|FAIL' "$REPORT" 2>/dev/null || true)"
size_bytes="$(wc -c < "$REPORT" | tr -d '[:space:]')"

printf 'Report finalized: %s\n' "$REPORT"
printf 'Sections: %s\n' "$section_count"
printf 'File sections: %s\n' "$file_section_count"
printf 'Pass markers: %s\n' "$pass_count"
printf 'Fail markers: %s\n' "$fail_count"
printf 'Size: %s bytes\n' "$size_bytes"

missing=0
for heading in "Summary" "Generated" "Validation" "Gaps"; do
  if ! grep -Eiq "^#+[[:space:]].*$heading" "$REPORT"; then
    printf 'Warning: report may be missing a %s section\n' "$heading" >&2
    missing=$((missing + 1))
  fi
done

exit 0
