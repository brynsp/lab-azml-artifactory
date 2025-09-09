## Minimal Windows jumpbox setup (offline-friendly)
$ErrorActionPreference = 'Stop'
$Log = 'C:\Windows\Temp\jumpbox-setup.log'
function Log($m){ $ts=(Get-Date).ToString('u'); $l="[$ts] $m"; Write-Host $l; Add-Content -Path $Log -Value $l }

if (Test-Path 'C:\Windows\Temp\jumpbox-setup.done') { Log 'Already completed earlier'; exit 0 }

Log '=== Jumpbox setup start ==='

Log 'Chocolatey bootstrap (if needed)'
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
  try {
    Set-ExecutionPolicy Bypass -Scope Process -Force | Out-Null
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Log 'Chocolatey installed'
  } catch { Log "Chocolatey install failed: $($_.Exception.Message)" }
} else { Log 'Chocolatey already present' }

function Ensure-Pkg($name) {
  if (choco list --local-only --limit-output | Select-String -SimpleMatch "^$name|") {
    Log "$name already installed"
  } else {
    try { choco install $name -y --no-progress; Log "$name installed" } catch { Log "$name failed: $($_.Exception.Message)" }
  }
}

Ensure-Pkg azure-cli
Ensure-Pkg git

# Sentinel marks completion so reruns are quick/idempotent
New-Item -ItemType File -Path 'C:\Windows\Temp\jumpbox-setup.done' -Force | Out-Null
Log '=== Jumpbox setup complete ==='
exit 0
