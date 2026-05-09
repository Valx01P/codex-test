$ErrorActionPreference = "Stop"

$Repo = if ($env:CODEX_TEST_REPO) { $env:CODEX_TEST_REPO } else { "Valx01P/codex-test" }
$Branch = if ($env:CODEX_TEST_BRANCH) { $env:CODEX_TEST_BRANCH } else { "main" }
$SkillName = "codex-test"
$SkillDir = if ($env:CODEX_TEST_SKILL_DIR) {
  $env:CODEX_TEST_SKILL_DIR
} else {
  Join-Path $HOME ".agents\skills\$SkillName"
}
$BinDir = if ($env:CODEX_TEST_BIN_DIR) {
  $env:CODEX_TEST_BIN_DIR
} else {
  Join-Path $HOME "bin"
}
$ShellMarkerStart = "# >>> codex-test shell integration >>>"
$ShellMarkerEnd = "# <<< codex-test shell integration <<<"

function Write-Step($Message) {
  Write-Host $Message
}

function Copy-Skill($Source, $Destination) {
  if (-not (Test-Path (Join-Path $Source "SKILL.md"))) {
    throw "Downloaded repository is missing SKILL.md"
  }

  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  Copy-Item (Join-Path $Source "SKILL.md") $Destination -Force

  foreach ($dir in @("scripts", "references", "agents")) {
    $srcDir = Join-Path $Source $dir
    $destDir = Join-Path $Destination $dir
    if (Test-Path $destDir) {
      Remove-Item -Recurse -Force $destDir
    }
    Copy-Item $srcDir $destDir -Recurse -Force
  }
}

function Download-Repo($Destination) {
  if (Get-Command git -ErrorAction SilentlyContinue) {
    git clone --depth 1 --branch $Branch "https://github.com/$Repo.git" $Destination | Out-Null
    return
  }

  New-Item -ItemType Directory -Force -Path "$Destination\scripts", "$Destination\references", "$Destination\agents" | Out-Null
  $base = "https://raw.githubusercontent.com/$Repo/$Branch"
  Invoke-WebRequest "$base/SKILL.md" -OutFile "$Destination\SKILL.md"
  Invoke-WebRequest "$base/codex-test.ps1" -OutFile "$Destination\codex-test.ps1"
  Invoke-WebRequest "$base/codex-test" -OutFile "$Destination\codex-test"
  Invoke-WebRequest "$base/install.sh" -OutFile "$Destination\install.sh"
  Invoke-WebRequest "$base/scripts/analyze.sh" -OutFile "$Destination\scripts\analyze.sh"
  Invoke-WebRequest "$base/scripts/report.sh" -OutFile "$Destination\scripts\report.sh"
  Invoke-WebRequest "$base/references/quality-rubric.md" -OutFile "$Destination\references\quality-rubric.md"
  Invoke-WebRequest "$base/references/reporting-standard.md" -OutFile "$Destination\references\reporting-standard.md"
  Invoke-WebRequest "$base/agents/openai.yaml" -OutFile "$Destination\agents\openai.yaml"
}

function Remove-ShellBlock($ProfilePath) {
  if (-not (Test-Path $ProfilePath)) {
    return ""
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

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-test-" + [System.Guid]::NewGuid().ToString("N"))
try {
  Write-Step "Downloading github.com/$Repo..."
  Download-Repo $tmp

  Write-Step "Installing skill to $SkillDir..."
  Copy-Skill $tmp $SkillDir

  Write-Step "Installing wrapper to $BinDir..."
  New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
  $WrapperPath = Join-Path $BinDir "codex-test.ps1"
  Copy-Item (Join-Path $tmp "codex-test.ps1") $WrapperPath -Force
  Install-ShellIntegration $WrapperPath

  Write-Host ""
  Write-Host "codex-test installed."
  Write-Host ""
  Write-Host "Skill:   $SkillDir"
  Write-Host "Command: $WrapperPath"
  Write-Host ""

  if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    Write-Host "Codex CLI was not found. Install it first:"
    Write-Host "  npm install -g @openai/codex"
    Write-Host ""
  }

  $pathParts = ($env:PATH -split ";") | Where-Object { $_ }
  if ($pathParts -notcontains $BinDir) {
    Write-Host "Optional: add this directory to PATH if you want to run codex-test.ps1 directly:"
    Write-Host "  [Environment]::SetEnvironmentVariable('Path', `$env:Path + ';$BinDir', 'User')"
    Write-Host ""
  }

  Write-Host "Try it:"
  Write-Host "  codex test --help"
  Write-Host "  codex test"
  Write-Host ""
  Write-Host "If this terminal has not picked it up yet, restart PowerShell."
  Write-Host ""
  Write-Host "Uninstall:"
  Write-Host "  & `"$WrapperPath`" --uninstall"
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
