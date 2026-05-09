param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $RemainingArgs
)

$Version = "0.2.0"
$SkillName = "codex-test"
$ReportFile = "CODEX-TEST-REPORT.md"
if ($env:CODEX_TEST_SKILL_DIR) {
  $UserSkillDir = $env:CODEX_TEST_SKILL_DIR
} else {
  $UserSkillDir = Join-Path $HOME ".agents\skills\$SkillName"
}

$DefaultPrompt = 'Use $codex-test. Inspect this repository for test gaps, propose a prioritized plan, generate the approved high-impact tests, validate them, and write CODEX-TEST-REPORT.md explaining every created or updated file.'
$ExecPrompt = 'Use $codex-test in non-interactive mode. Inspect this repository for test gaps, choose up to 5 high-impact targets, generate focused tests, validate them, and write CODEX-TEST-REPORT.md explaining every created or updated file. Do not install dependencies or edit product source unless they are already part of the repository setup.'

function Show-Usage {
  @"
codex-test v$Version

Usage:
  codex-test.ps1                    Open Codex with the codex-test workflow
  codex-test.ps1 --exec             Run non-interactively with a bounded plan
  codex-test.ps1 --exec --go-ham    Run with approval policy "never"
  codex-test.ps1 --plan-only        Inspect the repo and stop after the plan
  codex-test.ps1 --goal "..."       Add a testing goal or area to focus on
  codex-test.ps1 --install          Install this skill for the current user
  codex-test.ps1 --install-repo     Install into .agents\skills\codex-test
  codex-test.ps1 --uninstall        Remove the user skill
  codex-test.ps1 --help             Show this help

Report:
  $ReportFile

Notes:
  --exec uses workspace-write sandboxing so tests and the report can be written.
"@
}

function Find-SourceDir {
  $scriptDir = Split-Path -Parent $PSCommandPath
  if (Test-Path (Join-Path $scriptDir "SKILL.md")) {
    return $scriptDir
  }

  $parent = Split-Path -Parent $scriptDir
  if (Test-Path (Join-Path $parent "SKILL.md")) {
    return $parent
  }

  if (Test-Path (Join-Path $UserSkillDir "SKILL.md")) {
    return $UserSkillDir
  }

  throw "Cannot find SKILL.md. Run this from the codex-test repository."
}

function Copy-Skill($Source, $Destination) {
  if (-not (Test-Path (Join-Path $Source "SKILL.md"))) {
    throw "Cannot find SKILL.md in $Source"
  }

  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  Copy-Item (Join-Path $Source "SKILL.md") $Destination -Force

  foreach ($dir in @("scripts", "references", "agents")) {
    $srcDir = Join-Path $Source $dir
    $destDir = Join-Path $Destination $dir
    if (Test-Path $srcDir) {
      if (Test-Path $destDir) {
        Remove-Item -Recurse -Force $destDir
      }
      Copy-Item $srcDir $destDir -Recurse -Force
    }
  }
}

function Install-UserSkill {
  $src = Find-SourceDir
  Copy-Skill $src $UserSkillDir
  Write-Host "Installed $SkillName skill to $UserSkillDir"
  Write-Host "Use it in Codex as `$$SkillName, or run codex-test.ps1 from a repository."
}

function Install-RepoSkill {
  $src = Find-SourceDir
  $dest = ".agents\skills\$SkillName"
  Copy-Skill $src $dest
  Write-Host "Installed repo-local skill to $dest"
  Write-Host "Commit that directory so teammates get the same workflow."
}

function Uninstall-UserSkill {
  if (Test-Path $UserSkillDir) {
    Remove-Item -Recurse -Force $UserSkillDir
  }
  Write-Host "Removed skill $UserSkillDir"
}

$Mode = "interactive"
$JsonArg = @()
$GoHam = $false
$PlanOnly = $false
$Goal = ""
$ExtraArgs = @()

for ($i = 0; $i -lt $RemainingArgs.Count; $i++) {
  $arg = $RemainingArgs[$i]
  switch ($arg) {
    { $_ -in @("--exec", "-e") } { $Mode = "exec"; continue }
    "--json" { $JsonArg = @("--json"); continue }
    { $_ -in @("--go-ham", "--yes", "--auto") } { $GoHam = $true; continue }
    { $_ -in @("--plan-only", "--dry-run") } { $PlanOnly = $true; continue }
    { $_ -in @("--goal", "--focus", "--target") } {
      if ($i + 1 -ge $RemainingArgs.Count) {
        Write-Error "$arg requires a value"
        exit 2
      }
      $i++
      $Goal = $RemainingArgs[$i]
      continue
    }
    "--install" { Install-UserSkill; exit 0 }
    "--install-repo" { Install-RepoSkill; exit 0 }
    "--uninstall" { Uninstall-UserSkill; exit 0 }
    { $_ -in @("--help", "-h") } { Show-Usage; exit 0 }
    { $_ -in @("--version", "-v") } { Write-Host "codex-test v$Version"; exit 0 }
    default { $ExtraArgs += $arg }
  }
}

if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
  Write-Error "Codex CLI not found. Install it with: npm install -g @openai/codex"
  exit 1
}

if ($Mode -eq "exec") {
  $Prompt = $ExecPrompt
} else {
  $Prompt = $DefaultPrompt
}

if ($PlanOnly) {
  $Prompt = "$Prompt Stop after writing the proposed plan in chat. Do not edit files."
}

if ($Goal) {
  $Prompt = "$Prompt User testing goal: $Goal"
}

$CodexArgs = @()
if ($Mode -eq "exec") {
  $CodexArgs = @("--sandbox", "workspace-write")
}
if ($GoHam) {
  $CodexArgs = @("--ask-for-approval", "never", "--sandbox", "workspace-write")
}

if ($Mode -eq "exec") {
  & codex exec @CodexArgs @JsonArg @ExtraArgs $Prompt
  exit $LASTEXITCODE
}

& codex @CodexArgs @ExtraArgs $Prompt
exit $LASTEXITCODE
