# codex-test

A Codex skill that generates tests, explains every one, validates them, and produces a structured report — all from a single command.

```bash
codex-test
```

Or inside Codex: `$test-coverage`

## What it does

1. **Scans** your repo — detects language, framework, finds untested files
2. **Plans** — prioritizes files by risk (critical → low), identifies what to test
3. **Generates** — writes complete test files matching your project's conventions
4. **Validates** — runs each generated test, attempts one auto-fix if it fails
5. **Reports** — produces `TEST-COVERAGE-REPORT.md` with per-test explanations:
   - What each test covers and why it matters
   - The testing strategy and reasoning
   - Edge cases covered
   - Gaps that still need manual testing
6. **Presents** — you review via Codex's native approval flow or `git diff`

## Install

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USER/codex-test/main/install.sh | bash
```

This installs the skill to `~/.agents/skills/test-coverage/` and puts the
`codex-test` wrapper on your PATH. That's it.

### From source

```bash
git clone https://github.com/YOUR_USER/codex-test
cd codex-test
./codex-test --install                # install skill globally
sudo cp codex-test /usr/local/bin/    # put wrapper on PATH
```

### Per-repo (teammates get it via git)

```bash
cd /path/to/your/project
/path/to/codex-test --install-repo
git add .agents/skills/test-coverage
git commit -m "add test-coverage skill"
```

Now every teammate with Codex can use `$test-coverage` in that repo.

### Uninstall

```bash
rm -rf ~/.agents/skills/test-coverage /usr/local/bin/codex-test
```

## Usage

```bash
# Interactive — opens Codex TUI with the test-coverage skill
codex-test

# Non-interactive — runs headless, prints report
codex-test --exec

# Non-interactive with JSON output (for CI pipelines)
codex-test --exec --json

# Inside Codex (interactive session or app)
$test-coverage

# Inside Codex (explicit prompt)
$test-coverage Focus on the src/auth/ directory only

# In CI via codex exec directly
codex exec --sandbox workspace-write '$test-coverage Generate tests for all untested files'
```

## How it works

This is a **Codex Skill** — a SKILL.md file plus helper scripts that Codex
reads and follows as structured instructions. When you invoke `$test-coverage`,
Codex:

1. Runs `scripts/analyze.sh` to get a deterministic scan of your repo
2. Reads the scan output and builds a prioritized test plan (AI)
3. For each file in the plan, generates tests + a structured explanation (AI)
4. Runs each test file to validate it passes (deterministic)
5. Writes `TEST-COVERAGE-REPORT.md` with everything (AI)
6. Shows you the results via Codex's native diff/approval UI

The deterministic parts (scanning, running tests) use shell scripts.
The intelligent parts (planning, generating, explaining) use Codex's model.
You approve changes through Codex's existing git-based approval flow.

## File structure

```
codex-test/
├── SKILL.md              # The skill — Codex's instructions
├── codex-test            # CLI wrapper script
├── agents/
│   └── openai.yaml       # Codex app UI metadata
├── scripts/
│   ├── analyze.sh        # Repo scanner (deterministic)
│   └── report.sh         # Report finalizer (deterministic)
└── references/
    └── quality-rubric.md  # Test quality checklist
```

When installed, this becomes:
```
~/.agents/skills/test-coverage/    # global
.agents/skills/test-coverage/      # per-repo
```

## Supported languages

The analyze script auto-detects:
- **JavaScript/TypeScript** — Jest, Vitest, Mocha
- **Python** — pytest
- **Go** — go test
- **Rust** — cargo test
- **Java** — JUnit (Gradle/Maven)
- **PHP** — PHPUnit

The AI-driven phases (plan, generate) work with any language Codex supports.

## The report

`TEST-COVERAGE-REPORT.md` contains a per-test breakdown:

| Test Name | What It Tests | Why It Matters | Category | Edge Cases |
|-----------|--------------|----------------|----------|------------|
| should reject expired tokens | validateToken with expired JWT | Expired tokens must never grant access | unit | just-expired, epoch-zero |

Plus reasoning for why each file was chosen, the testing strategy, and
gaps that still need manual attention.

## Extending

Create your own workflow skills using the same pattern:

```bash
# Use Codex's built-in skill creator
$skill-creator

# Or manually
mkdir -p .agents/skills/my-workflow
# Write a SKILL.md with instructions
# Add scripts/ for deterministic steps
# Add references/ for context docs
```

See [Codex Skills docs](https://developers.openai.com/codex/skills) for the full API.
