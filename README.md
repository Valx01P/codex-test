# codex-test

`codex-test` is a Codex skill and CLI shortcut for improving test coverage
agentically. It inspects a repo, recommends the highest-impact tests, generates
the approved tests, validates them, and writes `CODEX-TEST-REPORT.md` so humans
can review what changed and why.

It is especially tuned for modern frontend and Next.js repositories, but the
workflow also supports common JS/TS, Python, Go, Rust, Java, and PHP test stacks.

## Install Codex CLI

Install Codex first:

```bash
npm install -g @openai/codex
```

macOS users can also use Homebrew:

```bash
brew install --cask codex
```

## Install codex-test

macOS and Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/Valx01P/codex-test/main/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/Valx01P/codex-test/main/install.ps1 | iex
```

Manual, any platform:

```bash
git clone https://github.com/Valx01P/codex-test.git
cd codex-test
./codex-test --install
```

## Use

Interactive, with a plan before edits:

```bash
codex-test
```

Focus on a specific area:

```bash
codex-test --goal "focus on checkout form validation and route handlers"
```

Headless run with a bounded default plan:

```bash
codex-test --exec
```

This uses Codex's `workspace-write` sandbox so generated tests and the report can
be written inside the repo.

Fewer approval prompts in a trusted repo:

```bash
codex-test --exec --go-ham
```

`--go-ham` keeps Codex in `workspace-write` sandboxing but sets approval policy
to `never`, so it can edit tests and run local commands without repeated prompts.
It does not make dependency installs or destructive actions part of the workflow.

Inside any Codex session:

```text
$codex-test
```

## Optional `codex test`

Codex does not currently let this repo register a native `codex test`
subcommand. To get that spelling in your shell, print the function and add it to
your shell profile:

```bash
codex-test --print-codex-function
```

Then this works:

```bash
codex test --help
codex test --goal "add component tests for settings"
```

## Team Install

Install the skill into the current repo and commit it:

```bash
codex-test --install-repo
git add .agents/skills/codex-test
git commit -m "add codex-test skill"
```

Teammates can then invoke `$codex-test` from Codex when working in that repo.

## What Gets Generated

- test files created or updated in the repo's existing convention
- `CODEX-TEST-REPORT.md` with the plan, reasoning, file-by-file explanations,
  validation commands and results, skipped targets, and remaining gaps

The report is meant to make review manageable. You should be able to inspect the
report and `git diff` without blindly trusting generated tests.

## Uninstall

macOS and Linux:

```bash
codex-test --uninstall
```

or:

```bash
rm -rf "$HOME/.agents/skills/codex-test" "$(command -v codex-test)"
```

Windows PowerShell:

```powershell
Remove-Item -Recurse -Force "$HOME\.agents\skills\codex-test" -ErrorAction SilentlyContinue
Remove-Item -Force "$HOME\bin\codex-test.ps1" -ErrorAction SilentlyContinue
```
