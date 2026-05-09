#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Remote installer for codex-test
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_USER/codex-test/main/install.sh | bash
# ─────────────────────────────────────────────────────────────
set -euo pipefail

REPO="YOUR_USER/codex-test"   # ← update with your GitHub username
BRANCH="main"
SKILL_DIR="$HOME/.agents/skills/test-coverage"
BIN_DIR="/usr/local/bin"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║     codex-test · skill installer     ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"

# Check codex is installed
if ! command -v codex &>/dev/null; then
  echo "⚠  Codex CLI not found. Install it first:"
  echo "   npm i -g @openai/codex"
  echo "   or: brew install --cask codex"
  echo ""
  echo "   Installing the skill anyway..."
fi

# Download and install
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo -e "${DIM}Downloading from github.com/${REPO}...${NC}"

# Try git clone first, fall back to curl for individual files
if command -v git &>/dev/null; then
  git clone --depth 1 "https://github.com/${REPO}.git" "$TMPDIR/codex-test" 2>/dev/null
  SRC="$TMPDIR/codex-test"
else
  SRC="$TMPDIR/codex-test"
  mkdir -p "$SRC/scripts" "$SRC/agents" "$SRC/references"
  BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
  curl -fsSL "$BASE/SKILL.md"                     -o "$SRC/SKILL.md"
  curl -fsSL "$BASE/codex-test"                    -o "$SRC/codex-test"
  curl -fsSL "$BASE/scripts/analyze.sh"            -o "$SRC/scripts/analyze.sh"
  curl -fsSL "$BASE/scripts/report.sh"             -o "$SRC/scripts/report.sh"
  curl -fsSL "$BASE/agents/openai.yaml"            -o "$SRC/agents/openai.yaml"
  curl -fsSL "$BASE/references/quality-rubric.md"  -o "$SRC/references/quality-rubric.md"
fi

# Install skill
echo -e "${DIM}Installing skill to ${SKILL_DIR}...${NC}"
mkdir -p "$SKILL_DIR"
cp "$SRC/SKILL.md" "$SKILL_DIR/"
cp -r "$SRC/scripts" "$SKILL_DIR/"
cp -r "$SRC/agents" "$SKILL_DIR/"
cp -r "$SRC/references" "$SKILL_DIR/"
chmod +x "$SKILL_DIR/scripts/"*.sh 2>/dev/null || true

# Install CLI wrapper
echo -e "${DIM}Installing codex-test to ${BIN_DIR}...${NC}"
if [[ -w "$BIN_DIR" ]]; then
  cp "$SRC/codex-test" "$BIN_DIR/codex-test"
  chmod +x "$BIN_DIR/codex-test"
else
  sudo cp "$SRC/codex-test" "$BIN_DIR/codex-test"
  sudo chmod +x "$BIN_DIR/codex-test"
fi

echo ""
echo -e "${GREEN}${BOLD}✅ codex-test installed!${NC}"
echo ""
echo -e "  ${BOLD}Usage:${NC}"
echo -e "    ${CYAN}codex-test${NC}              Open Codex with the test-coverage skill"
echo -e "    ${CYAN}codex-test --exec${NC}       Run headless (for CI)"
echo -e "    ${CYAN}\$test-coverage${NC}          Invoke inside any Codex session"
echo ""
echo -e "  ${BOLD}Uninstall:${NC}"
echo -e "    rm -rf ${SKILL_DIR} ${BIN_DIR}/codex-test"
echo ""
