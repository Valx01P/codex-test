#!/usr/bin/env bash
set -euo pipefail

REPO="${CODEX_TEST_REPO:-Valx01P/codex-test}"
BRANCH="${CODEX_TEST_BRANCH:-main}"
SKILL_NAME="codex-test"
SKILL_DIR="${CODEX_TEST_SKILL_DIR:-$HOME/.agents/skills/$SKILL_NAME}"
SHELL_MARKER_START="# >>> codex-test shell integration >>>"
SHELL_MARKER_END="# <<< codex-test shell integration <<<"
INSTALL_TMP=""

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

escape_double_quotes() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\$/\\$/g; s/`/\\`/g'
}

shell_profiles() {
  if [[ -n "${CODEX_TEST_SHELL_PROFILE:-}" ]]; then
    printf '%s\n' "$CODEX_TEST_SHELL_PROFILE"
    return 0
  fi

  case "$(basename "${SHELL:-}")" in
    zsh)
      printf '%s\n' "$HOME/.zshrc"
      ;;
    bash)
      printf '%s\n' "$HOME/.bashrc"
      if [[ "$(uname -s 2>/dev/null || true)" == "Darwin" ]]; then
        printf '%s\n' "$HOME/.bash_profile"
      fi
      ;;
    fish)
      printf '%s\n' "$HOME/.config/fish/config.fish"
      ;;
    *)
      printf '%s\n' "$HOME/.profile"
      ;;
  esac
}

write_shell_block() {
  local profile="$1"
  local wrapper="$2"
  local tmp
  local escaped_wrapper

  mkdir -p "$(dirname "$profile")"
  tmp="$(mktemp)"
  if [[ -f "$profile" ]]; then
    awk -v start="$SHELL_MARKER_START" -v end="$SHELL_MARKER_END" '
      $0 == start { skip = 1; next }
      $0 == end { skip = 0; next }
      !skip { print }
    ' "$profile" > "$tmp"
  else
    : > "$tmp"
  fi

  escaped_wrapper="$(escape_double_quotes "$wrapper")"
  {
    cat "$tmp"
    printf '\n%s\n' "$SHELL_MARKER_START"
    printf '# Enables: codex test ...\n'
    if [[ "$(basename "$profile")" == "config.fish" ]]; then
      printf 'function codex\n'
      printf '  if test (count $argv) -gt 0; and test $argv[1] = test\n'
      printf '    set -e argv[1]\n'
      printf '    "%s" $argv\n' "$escaped_wrapper"
      printf '  else\n'
      printf '    command codex $argv\n'
      printf '  end\n'
      printf 'end\n'
    else
      printf 'codex() {\n'
      printf '  if [ "$#" -gt 0 ] && [ "$1" = "test" ]; then\n'
      printf '    shift\n'
      printf '    "%s" "$@"\n' "$escaped_wrapper"
      printf '  else\n'
      printf '    command codex "$@"\n'
      printf '  fi\n'
      printf '}\n'
    fi
    printf '%s\n' "$SHELL_MARKER_END"
  } > "$profile"
  rm -f "$tmp"
}

install_shell_integration() {
  local wrapper="$1"
  local profile
  local installed=""

  if [[ "${CODEX_TEST_NO_SHELL:-}" == "1" ]]; then
    return 0
  fi

  while IFS= read -r profile; do
    [[ -z "$profile" ]] && continue
    write_shell_block "$profile" "$wrapper"
    installed="${installed}${profile}"$'\n'
  done < <(shell_profiles)

  if [[ -n "$installed" ]]; then
    log "Shell integration installed for:"
    printf '%s' "$installed" | sed '/^$/d; s/^/  /'
  fi
}

shell_reload_command() {
  if [[ -n "${CODEX_TEST_SHELL_PROFILE:-}" ]]; then
    printf 'source "%s"\n' "$CODEX_TEST_SHELL_PROFILE"
    return 0
  fi

  case "$(basename "${SHELL:-}")" in
    zsh)
      printf 'source "%s"\n' "$HOME/.zshrc"
      ;;
    bash)
      printf 'source "%s"\n' "$HOME/.bashrc"
      ;;
    fish)
      printf 'source "%s"\n' "$HOME/.config/fish/config.fish"
      ;;
    *)
      printf 'restart your terminal\n'
      ;;
  esac
}

verify_shell_integration() {
  local profile="$1"
  local shell_name
  shell_name="$(basename "${SHELL:-}")"

  case "$shell_name" in
    zsh)
      command -v zsh >/dev/null 2>&1 && zsh -lc "source '$profile' >/dev/null 2>&1; codex test --version" >/dev/null 2>&1
      ;;
    bash)
      command -v bash >/dev/null 2>&1 && bash -lc "source '$profile' >/dev/null 2>&1; codex test --version" >/dev/null 2>&1
      ;;
    fish)
      command -v fish >/dev/null 2>&1 && fish -c "source '$profile' >/dev/null 2>&1; codex test --version" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

finish_setup_message() {
  local wrapper="$1"
  local profile="$2"
  local reload_cmd

  reload_cmd="$(shell_reload_command)"
  if "$wrapper" --version >/dev/null 2>&1; then
    log "Verified: codex-test --version"
  fi
  if [[ -n "$profile" ]] && verify_shell_integration "$profile"; then
    log "Verified in a fresh shell: codex test --version"
  fi

  log ""
  log "Use it now:"
  log "  $reload_cmd"
  log "  codex test --version"
  log ""
  log "Or open a new terminal and run:"
  log "  codex test"
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

cleanup_tmp() {
  if [[ -n "${INSTALL_TMP:-}" && -d "$INSTALL_TMP" ]]; then
    rm -rf "$INSTALL_TMP"
  fi
}

main() {
  local src bin_dir wrapper primary_profile
  INSTALL_TMP="$(mktemp -d)"
  trap cleanup_tmp EXIT

  src="$INSTALL_TMP/codex-test"
  log "Downloading github.com/${REPO}..."
  download_repo "$src"

  log "Installing skill to $SKILL_DIR..."
  copy_skill "$src" "$SKILL_DIR"

  bin_dir="$(choose_bin_dir)"
  mkdir -p "$bin_dir"
  wrapper="$bin_dir/codex-test"
  cp "$src/codex-test" "$wrapper"
  chmod +x "$wrapper"
  install_shell_integration "$wrapper"
  primary_profile="$(shell_profiles | head -1)"

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
      log "Optional: add this directory to PATH if you want to run codex-test directly:"
      log "  export PATH=\"$bin_dir:\$PATH\""
      log ""
      ;;
  esac

  log "Native command:"
  log "  codex test --help"
  log "  codex test"
  finish_setup_message "$wrapper" "$primary_profile"
  log "Uninstall:"
  log "  \"$wrapper\" --uninstall"
}

main "$@"
