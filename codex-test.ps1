param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $RemainingArgs
)

$Version = "0.3.0"
$SkillName = "codex-test"
$ReportFile = "CODEX-TEST-REPORT.md"
if ($env:CODEX_TEST_SKILL_DIR) {
  $UserSkillDir = $env:CODEX_TEST_SKILL_DIR
} else {
  $UserSkillDir = Join-Path $HOME ".agents\skills\$SkillName"
}
if ($env:CODEX_TEST_BIN_DIR) {
  $BinDir = $env:CODEX_TEST_BIN_DIR
} else {
  $BinDir = Join-Path $HOME "bin"
}
$ShellMarkerStart = "# >>> codex-test shell integration >>>"
$ShellMarkerEnd = "# <<< codex-test shell integration <<<"

$DefaultPrompt = 'Use $codex-test. Before running commands or editing files, offer the user three testing workflow options: Recommended Test Scan, Increase Test Coverage, and Specialized Test Development. If the user already provided a goal or mode, infer the mode and proceed. Then analyze the repository, propose a prioritized production-ready plan, generate approved tests, validate them, and write CODEX-TEST-REPORT.md with a high-level overview, detailed per-file descriptions, changes, impact, CI/runtime and flake-risk notes, and continuous-improvement next steps.'
$ExecPrompt = 'Use $codex-test in non-interactive mode. Select the workflow from the explicit mode or goal; otherwise use Recommended Test Scan. For Increase Test Coverage, target 80% unless another threshold is provided and cover lower-complexity meaningful gaps before more complex gaps. Generate focused production-ready tests, validate them, and write CODEX-TEST-REPORT.md with a high-level overview, detailed per-file descriptions, changes, impact, CI/runtime and flake-risk notes, and continuous-improvement next steps. Do not install dependencies or edit product source unless they are already part of the repository setup.'

function Show-Usage {
  @"
codex-test v$Version

Usage:
  codex-test.ps1                    Open Codex with the codex-test workflow
  codex-test.ps1 --exec             Run non-interactively with a bounded plan
  codex-test.ps1 --exec --go-ham    Run with approval policy "never"
  codex-test.ps1 --plan-only        Inspect the repo and stop after the plan
  codex-test.ps1 --goal "..."       Add a testing goal or area to focus on
  codex-test.ps1 --mode "..."       Preselect recommended, coverage, or specialized
  codex-test.ps1 --coverage-target N
                                    Set a coverage target for coverage mode
  codex-test.ps1 --test-kind "..."  Focus specialized tests, e.g. e2e or regression
  codex-test.ps1 --install          Install the skill, wrapper, and "codex test"
  codex-test.ps1 --install-repo     Install into .agents\skills\codex-test
  codex-test.ps1 --uninstall        Remove the user skill
  codex-test.ps1 --check            Check whether codex-test is installed
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

function Normalize-TestMode($Value) {
  $normalized = $Value.ToLowerInvariant().Replace("_", "-")
  switch ($normalized) {
    { $_ -in @("1", "recommended", "recommend", "scan", "recommended-scan", "recommended-test-scan") } {
      return "recommended"
    }
    { $_ -in @("2", "coverage", "cover", "increase-coverage", "test-coverage", "coverage-growth") } {
      return "coverage"
    }
    { $_ -in @("3", "specialized", "specialised", "suite", "custom", "test-suite", "test-development") } {
      return "specialized"
    }
    default {
      throw "invalid --mode `"$Value`". Use recommended, coverage, or specialized."
    }
  }
}

function Normalize-CoverageTarget($Value) {
  $normalized = ($Value -replace "[\s%]", "")
  if ($normalized -notmatch "^[0-9]+(\.[0-9]+)?$") {
    throw "invalid --coverage-target `"$Value`". Use a number from 1 to 100, such as 80 or 85%."
  }

  $number = [double]$normalized
  if ($number -le 0 -or $number -gt 100) {
    throw "invalid --coverage-target `"$Value`". Use a number from 1 to 100, such as 80 or 85%."
  }

  return $normalized
}

function Remove-ShellBlock($ProfilePath) {
  if (-not (Test-Path $ProfilePath)) {
    return
  }

  $lines = Get-Content $ProfilePath
  $out = New-Object System.Collections.Generic.List[string]
  $skip = $false
  $changed = $false
  foreach ($line in $lines) {
    if ($line -eq $ShellMarkerStart) {
      $skip = $true
      $changed = $true
      continue
    }
    if ($line -eq $ShellMarkerEnd) {
      $skip = $false
      continue
    }
    if (-not $skip) {
      $out.Add($line)
    }
  }

  if ($changed) {
    Set-Content -Path $ProfilePath -Value $out
  }
}

function Install-ShellIntegration($WrapperPath) {
  if ($env:CODEX_TEST_NO_SHELL -eq "1") {
    return
  }

  $ProfilePath = if ($env:CODEX_TEST_SHELL_PROFILE) {
    $env:CODEX_TEST_SHELL_PROFILE
  } else {
    $PROFILE.CurrentUserAllHosts
  }

  $profileDir = Split-Path -Parent $ProfilePath
  New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
  if (-not (Test-Path $ProfilePath)) {
    New-Item -ItemType File -Force -Path $ProfilePath | Out-Null
  }

  Remove-ShellBlock $ProfilePath
  $safeWrapper = $WrapperPath.Replace("'", "''")
  $block = @"
$ShellMarkerStart
function codex {
  param([Parameter(ValueFromRemainingArguments = `$true)][string[]] `$CodexArgs)
  if (`$CodexArgs.Count -gt 0 -and `$CodexArgs[0] -eq "test") {
    `$remaining = @()
    if (`$CodexArgs.Count -gt 1) {
      `$remaining = `$CodexArgs[1..(`$CodexArgs.Count - 1)]
    }
    & '$safeWrapper' @remaining
  } else {
    `$codexCommand = Get-Command codex.cmd -ErrorAction SilentlyContinue
    if (-not `$codexCommand) {
      `$codexCommand = Get-Command codex.exe -ErrorAction SilentlyContinue
    }
    if (-not `$codexCommand) {
      `$codexCommand = Get-Command codex -CommandType Application -ErrorAction SilentlyContinue
    }
    if (-not `$codexCommand) {
      throw "Codex CLI not found."
    }
    & `$codexCommand.Source @CodexArgs
  }
}
$ShellMarkerEnd
"@
  Add-Content -Path $ProfilePath -Value $block
  Write-Host "Shell integration installed for: $ProfilePath"
  Enable-CurrentSessionIntegration $WrapperPath
  try {
    codex test --version | Out-Null
    Write-Host "Verified: codex test --version"
  } catch {
    Write-Host "If codex test is not available in this terminal, restart PowerShell."
  }
}

function Enable-CurrentSessionIntegration($WrapperPath) {
  $safeWrapper = $WrapperPath.Replace("'", "''")
  $script = @"
function global:codex {
  param([Parameter(ValueFromRemainingArguments = `$true)][string[]] `$CodexArgs)
  if (`$CodexArgs.Count -gt 0 -and `$CodexArgs[0] -eq "test") {
    `$remaining = @()
    if (`$CodexArgs.Count -gt 1) {
      `$remaining = `$CodexArgs[1..(`$CodexArgs.Count - 1)]
    }
    & '$safeWrapper' @remaining
  } else {
    `$codexCommand = Get-Command codex.cmd -ErrorAction SilentlyContinue
    if (-not `$codexCommand) {
      `$codexCommand = Get-Command codex.exe -ErrorAction SilentlyContinue
    }
    if (-not `$codexCommand) {
      `$codexCommand = Get-Command codex -CommandType Application -ErrorAction SilentlyContinue
    }
    if (-not `$codexCommand) {
      throw "Codex CLI not found."
    }
    & `$codexCommand.Source @CodexArgs
  }
}
"@
  Invoke-Expression $script
}

function Install-UserSkill {
  $src = Find-SourceDir
  Copy-Skill $src $UserSkillDir
  New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
  $wrapper = Join-Path $BinDir "codex-test.ps1"
  $wrapperSource = Join-Path $src "codex-test.ps1"
  if (-not (Test-Path $wrapperSource)) {
    $wrapperSource = $PSCommandPath
  }
  Copy-Item $wrapperSource $wrapper -Force
  Install-ShellIntegration $wrapper
  Write-Host "Installed $SkillName skill to $UserSkillDir"
  Write-Host "Installed wrapper to $wrapper"
  Write-Host "Use: codex test"
  Write-Host "Inside Codex, use: `$$SkillName"
}

function Install-RepoSkill {
  $src = Find-SourceDir
  $dest = ".agents\skills\$SkillName"
  Copy-Skill $src $dest
  $wrapper = Join-Path (Split-Path -Parent $PSCommandPath) "codex-test.ps1"
  Install-ShellIntegration $wrapper
  Write-Host "Installed repo-local skill to $dest"
  Write-Host "Commit that directory so teammates get the same Codex skill."
  Write-Host "This machine can now use: codex test"
}

function Uninstall-UserSkill {
  if (Test-Path $UserSkillDir) {
    Remove-Item -Recurse -Force $UserSkillDir
  }
  if ($env:CODEX_TEST_SHELL_PROFILE) {
    Remove-ShellBlock $env:CODEX_TEST_SHELL_PROFILE
  }
  Remove-ShellBlock $PROFILE.CurrentUserAllHosts
  $wrapper = Join-Path $BinDir "codex-test.ps1"
  if (Test-Path $wrapper) {
    try {
      Remove-Item -Force $wrapper
      Write-Host "Removed wrapper $wrapper"
    } catch {
      Write-Host "Wrapper still exists at $wrapper. Remove it manually if desired."
    }
  }
  Write-Host "Removed skill $UserSkillDir"
}

function Check-Install {
  $status = 0
  Write-Host "codex-test check"
  Write-Host ""

  $wrapper = Get-Command codex-test.ps1 -ErrorAction SilentlyContinue
  if ($wrapper) {
    Write-Host "[ok] Wrapper: $($wrapper.Source)"
  } else {
    $localWrapper = Join-Path $BinDir "codex-test.ps1"
    if (Test-Path $localWrapper) {
      Write-Host "[ok] Wrapper: $localWrapper"
    } elseif (Test-Path $PSCommandPath) {
      Write-Host "[ok] Wrapper: $PSCommandPath"
    } else {
      Write-Host "[warn] Wrapper not found. Run the installer again."
      $status = 1
    }
  }

  if (Test-Path (Join-Path $UserSkillDir "SKILL.md")) {
    Write-Host "[ok] Skill: $UserSkillDir"
  } else {
    Write-Host "[warn] Skill not found at $UserSkillDir"
    $status = 1
  }

  $codex = Get-Command codex -ErrorAction SilentlyContinue
  if ($codex) {
    Write-Host "[ok] Codex CLI: $($codex.Source)"
  } else {
    Write-Host "[warn] Codex CLI not found. Install it with: npm install -g @openai/codex"
    $status = 1
  }

  Write-Host ""
  if ($status -eq 0) {
    Write-Host "Ready. Try: codex test"
  } else {
    Write-Host "Not fully ready. Re-run install, then run: codex test --check"
  }
  exit $status
}

$Mode = "interactive"
$JsonArg = @()
$GoHam = $false
$PlanOnly = $false
$Goal = ""
$TestMode = ""
$CoverageTarget = ""
$TestKind = ""
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
    { $_ -in @("--mode", "--workflow") } {
      if ($i + 1 -ge $RemainingArgs.Count) {
        Write-Error "$arg requires a value"
        exit 2
      }
      $i++
      try {
        $TestMode = Normalize-TestMode $RemainingArgs[$i]
      } catch {
        Write-Error $_
        exit 2
      }
      continue
    }
    { $_ -in @("--coverage-target", "--target-coverage") } {
      if ($i + 1 -ge $RemainingArgs.Count) {
        Write-Error "$arg requires a value"
        exit 2
      }
      $i++
      if ($TestMode -and $TestMode -ne "coverage") {
        Write-Error "--coverage-target requires --mode coverage"
        exit 2
      }
      try {
        $CoverageTarget = Normalize-CoverageTarget $RemainingArgs[$i]
      } catch {
        Write-Error $_
        exit 2
      }
      $TestMode = "coverage"
      continue
    }
    { $_ -in @("--test-kind", "--kind", "--suite") } {
      if ($i + 1 -ge $RemainingArgs.Count) {
        Write-Error "$arg requires a value"
        exit 2
      }
      $i++
      if ($TestMode -and $TestMode -ne "specialized") {
        Write-Error "--test-kind requires --mode specialized"
        exit 2
      }
      $TestKind = $RemainingArgs[$i]
      $TestMode = "specialized"
      continue
    }
    "--install" { Install-UserSkill; exit 0 }
    "--install-repo" { Install-RepoSkill; exit 0 }
    "--uninstall" { Uninstall-UserSkill; exit 0 }
    { $_ -in @("--check", "doctor") } { Check-Install }
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
if ($TestMode) {
  $Prompt = "$Prompt Requested testing workflow mode: $TestMode."
}
if ($CoverageTarget) {
  $Prompt = "$Prompt Requested coverage target: $CoverageTarget%."
}
if ($TestKind) {
  $Prompt = "$Prompt Requested specialized test kind: $TestKind."
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
