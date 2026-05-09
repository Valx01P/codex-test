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
codex-test v0.2.0
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

To focus on one area:

```bash
codex test --goal "focus on checkout form validation"
```

To let it run without stopping for small approvals:

```bash
codex test --exec --go-ham
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
- A summary of what was tested, why it was chosen, what passed, what failed, and
  what still needs review.

The report is there so you do not have to blindly trust generated tests.

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
