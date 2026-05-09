#!/usr/bin/env bash
set -euo pipefail

REPO="${CODEX_TEST_REPO:-Valx01P/codex-test}"
BRANCH="${CODEX_TEST_BRANCH:-main}"
SKILL_NAME="codex-test"
SKILL_DIR="${CODEX_TEST_SKILL_DIR:-$HOME/.agents/skills/$SKILL_NAME}"

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'install.sh: %s\n' "$*" >&2
  exit 1
}

choose_bin_dir() {
  if [[ -n "${CODEX_TEST_BIN_DIR:-}" ]]; then
    printf '%s\n' "$CODEX_TEST_BIN_DIR"
    return 0
  fi

  local dir
  IFS=':' read -r -a path_dirs <<< "${PATH:-}"
  for dir in "${path_dirs[@]}"; do
    [[ -z "$dir" ]] && continue
    [[ "$dir" == "/bin" || "$dir" == "/usr/bin" || "$dir" == "/sbin" || "$dir" == "/usr/sbin" ]] && continue
    if [[ -d "$dir" && -w "$dir" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
  done

  if [[ -d "/usr/local/bin" && -w "/usr/local/bin" ]]; then
    printf '%s\n' "/usr/local/bin"
    return 0
  fi

  printf '%s\n' "$HOME/.local/bin"
}

copy_skill() {
  local src="$1"
  local dest="$2"

  [[ -f "$src/SKILL.md" ]] || die "downloaded repository is missing SKILL.md"

  mkdir -p "$dest"
  cp "$src/SKILL.md" "$dest/"

  rm -rf "$dest/scripts" "$dest/references" "$dest/agents"
  cp -R "$src/scripts" "$dest/scripts"
  cp -R "$src/references" "$dest/references"
  cp -R "$src/agents" "$dest/agents"
  chmod +x "$dest/scripts/"*.sh 2>/dev/null || true
}

download_repo() {
  local src="$1"

  if command -v git >/dev/null 2>&1; then
    git clone --depth 1 --branch "$BRANCH" "https://github.com/${REPO}.git" "$src" >/dev/null 2>&1 && return 0
  fi

  command -v curl >/dev/null 2>&1 || die "curl or git is required"

  mkdir -p "$src/scripts" "$src/references" "$src/agents"
  local base="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
  curl -fsSL "$base/SKILL.md" -o "$src/SKILL.md"
  curl -fsSL "$base/codex-test" -o "$src/codex-test"
  curl -fsSL "$base/codex-test.ps1" -o "$src/codex-test.ps1"
  curl -fsSL "$base/scripts/analyze.sh" -o "$src/scripts/analyze.sh"
  curl -fsSL "$base/scripts/report.sh" -o "$src/scripts/report.sh"
  curl -fsSL "$base/references/quality-rubric.md" -o "$src/references/quality-rubric.md"
  curl -fsSL "$base/agents/openai.yaml" -o "$src/agents/openai.yaml"
}

main() {
  local tmp src bin_dir wrapper
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  src="$tmp/codex-test"
  log "Downloading github.com/${REPO}..."
  download_repo "$src"

  log "Installing skill to $SKILL_DIR..."
  copy_skill "$src" "$SKILL_DIR"

  bin_dir="$(choose_bin_dir)"
  mkdir -p "$bin_dir"
  wrapper="$bin_dir/codex-test"
  cp "$src/codex-test" "$wrapper"
  chmod +x "$wrapper"

  log ""
  log "codex-test installed."
  log ""
  log "Skill:   $SKILL_DIR"
  log "Command: $wrapper"
  log ""

  if ! command -v codex >/dev/null 2>&1; then
    log "Codex CLI was not found. Install it first:"
    log "  npm install -g @openai/codex"
    log "  brew install --cask codex"
    log ""
  fi

  case ":${PATH:-}:" in
    *":$bin_dir:"*) ;;
    *)
      log "Add this directory to PATH if codex-test is not found:"
      log "  export PATH=\"$bin_dir:\$PATH\""
      log ""
      ;;
  esac

  log "Try it:"
  log "  codex-test --help"
  log "  codex-test"
  log ""
  log "Optional shell function for 'codex test':"
  log "  codex-test --print-codex-function"
  log ""
  log "Uninstall:"
  log "  rm -rf \"$SKILL_DIR\" \"$wrapper\""
}

main "$@"
