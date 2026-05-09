# codex-test

`codex-test` gives Codex a simple testing workflow:

1. Look through your repo.
2. Pick useful tests to add.
3. Explain the plan before changing files.
4. Write the tests.
5. Run the tests.
6. Create `CODEX-TEST-REPORT.md` so you can review what happened.

It works best for modern frontend and Next.js apps, and also supports common
JavaScript/TypeScript, Python, Go, Rust, Java, and PHP projects.

## 1. Install Codex

If you already have Codex installed, skip this.

```bash
npm install -g @openai/codex
```

On macOS, this also works:

```bash
brew install --cask codex
```

## 2. Install codex-test

macOS or Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/Valx01P/codex-test/main/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/Valx01P/codex-test/main/install.ps1 | iex
```

The installer prints the exact setup line to run next. It looks like this:

```bash
source "$HOME/.zshrc"
```

You can also just open a new terminal.

## 3. Check It Worked

Run:

```bash
codex test --version
```

Expected output:

```text
codex-test v0.3.0
```

If anything seems off, run:

```bash
codex test --check
```

## 4. Use It

From the project you want to test:

```bash
codex test
```

Codex will offer three numbered options before it starts. It waits for you to
reply with `1`, `2`, or `3`; it does not infer the workflow from your goal text.

1. **Recommended Test Scan**: inspect the repo, find the best high-impact test
   targets, propose a plan, then generate and validate the approved tests.
2. **Increase Test Coverage**: measure or estimate coverage, target 80% by
   default unless you request another threshold, and add meaningful tests from
   simpler uncovered code toward more complex areas.
3. **Specialized Test Development**: build production-ready tests for a specific
   suite or risk area, such as e2e, regression, feature, API, accessibility,
   backend, or Next.js/frontend workflows.

To focus on one area:

```bash
codex test --goal "focus on checkout form validation"
```

This still shows the numbered menu first. The goal is used as context after you
choose `1`, `2`, or `3`.

For non-interactive coverage mode:

```bash
codex test --exec --mode coverage --coverage-target 85
```

`--coverage-target` also accepts a percent sign, for example `85%`.

For a non-interactive specialized test suite:

```bash
codex test --exec --mode specialized --test-kind e2e --goal "checkout smoke flow"
```

To let it run without stopping for small approvals:

```bash
codex test --exec --mode recommended --go-ham
```

Use `--go-ham` only in a repo you trust. It still avoids dependency installs,
destructive actions, and product source edits unless you explicitly ask.

Inside an existing Codex session, you can also type:

```text
$codex-test
```

## What You Get

- New or updated test files.
- A `CODEX-TEST-REPORT.md` report.
- A high-level overview table, per-file explanations, change and impact notes,
  validation results, coverage details when applicable, remaining gaps, and a
  continuous-improvement plan for the next testing work.

The report is there so you do not have to blindly trust generated tests.

## Production App Behavior

For larger production repos, `codex-test` is designed to:

- reuse the repo's existing test runners, fixtures, mocks, page objects, and CI
  scripts instead of inventing a new testing style
- detect coverage, lint, typecheck, build, and monorepo/workspace signals when
  possible
- keep dependency installs, CI changes, coverage threshold changes, and product
  source edits behind explicit approval
- call out runtime cost, flake risk, skipped targets, environment assumptions,
  and remaining review steps in `CODEX-TEST-REPORT.md`

## Team Setup

One person can add the skill to a repo:

```bash
codex test --install-repo
git add .agents/skills/codex-test
git commit -m "add codex-test skill"
```

Each teammate should still run the installer once on their own machine so the
`codex test` command works in their terminal.

## Uninstall

macOS, Linux, or Windows:

```bash
codex test --uninstall
```

If your terminal has not loaded `codex test`, use:

```bash
codex-test --uninstall
```

## Notes

`codex test` is a shell shortcut installed by this package. Codex does not yet
let external projects register built-in subcommands, so the installer adds and
manages a small profile block for you. Re-running install updates the block
instead of duplicating it.
