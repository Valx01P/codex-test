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
  Invoke-WebRequest "$base/agents/openai.yaml" -OutFile "$Destination\agents\openai.yaml"
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
    Write-Host "Add this directory to PATH if codex-test.ps1 is not found:"
    Write-Host "  [Environment]::SetEnvironmentVariable('Path', `$env:Path + ';$BinDir', 'User')"
    Write-Host ""
  }

  Write-Host "Try it:"
  Write-Host "  codex-test.ps1 --help"
  Write-Host "  codex-test.ps1"
  Write-Host ""
  Write-Host "Uninstall:"
  Write-Host "  Remove-Item -Recurse -Force `"$SkillDir`" -ErrorAction SilentlyContinue"
  Write-Host "  Remove-Item -Force `"$WrapperPath`" -ErrorAction SilentlyContinue"
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
