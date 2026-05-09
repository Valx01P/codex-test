# codex-test

A [Codex](https://github.com/openai/codex) skill that automatically generates tests for your codebase, explains every one, validates they pass, and produces a full report — in a single command.

```
codex-test
```

## Install

You need [Codex CLI](https://github.com/openai/codex) installed first.

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/Valx01P/codex-test/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
git clone https://github.com/Valx01P/codex-test.git "$env:TEMP\codex-test"
$dest = "$HOME\.agents\skills\test-coverage"
New-Item -ItemType Directory -Force -Path $dest, "$dest\scripts", "$dest\agents", "$dest\references" | Out-Null
Copy-Item "$env:TEMP\codex-test\SKILL.md" $dest
Copy-Item "$env:TEMP\codex-test\scripts\*" "$dest\scripts\"
Copy-Item "$env:TEMP\codex-test\agents\*" "$dest\agents\"
Copy-Item "$env:TEMP\codex-test\references\*" "$dest\references\"
Remove-Item -Recurse -Force "$env:TEMP\codex-test"
Write-Host "Installed to $dest"
```

### Manual (any platform)

```bash
git clone https://github.com/Valx01P/codex-test.git
cd codex-test
./codex-test --install
```

## Usage

Once installed, use it however you use Codex:

```bash
# From your terminal (opens Codex with the skill)
codex-test

# Inside any Codex session (CLI, IDE, or App)
$test-coverage

# Non-interactive (CI, scripts)
codex-test --exec
```

That's it. Codex scans your repo, generates tests, runs them, and writes a `TEST-COVERAGE-REPORT.md` explaining what every test does, why it exists, and what it covers. You review the changes through Codex's normal approval flow or `git diff`.

## Supported Languages

JavaScript/TypeScript (Jest, Vitest, Mocha) · Python (pytest) · Go · Rust · Java (JUnit) · PHP (PHPUnit)

## Team Install

Want your whole team to have it without each person installing?

```bash
cd your-project
codex-test --install-repo
git add .agents/skills/test-coverage && git commit -m "add test-coverage skill"
```

Now anyone on the repo can use `$test-coverage` in Codex.

## Uninstall

```bash
rm -rf ~/.agents/skills/test-coverage /usr/local/bin/codex-test
```
