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

# Create lab scripts and shortcuts
try {
  $labDir = 'C:\LabScripts'
  New-Item -ItemType Directory -Path $labDir -Force | Out-Null
  Log 'Created/verified C:\LabScripts'

  $patScript = @'
@echo off
echo Azure ML Artifactory Lab - PAT Generation Script
echo.
set /p ARTIFACTORY_IP="Enter Artifactory VM IP address: "
set /p USERNAME="Enter Artifactory username (default: admin): "
if "%USERNAME%"=="" set USERNAME=admin
set /p PASSWORD="Enter Artifactory password: "
echo.
echo Generating PAT...
curl -u %USERNAME%:%PASSWORD% -X POST "http://%ARTIFACTORY_IP%:8082/artifactory/api/security/token" -d "username=%USERNAME%" -d "scope=member-of-groups:readers"
echo.
echo Save the access_token value above for subsequent operations.
pause
'@
  $patScript | Out-File -FilePath "$labDir\generate-artifactory-pat.cmd" -Encoding ASCII -Force

  $syncScript = @'
@echo off
echo Azure ML Artifactory Lab - Image Sync Script
echo.
set /p ARTIFACTORY_IP="Enter Artifactory VM IP address: "
set /p ACR_NAME="Enter Azure Container Registry name: "
set /p IMAGE_NAME="Enter image name (e.g., contoso-lab/sample-ml-model): "
set /p IMAGE_TAG="Enter image tag (default: latest): "
if "%IMAGE_TAG%"=="" set IMAGE_TAG=latest
echo Logging into Azure...
az login
echo Logging into ACR...
az acr login --name %ACR_NAME%
echo Pulling image from Artifactory...
docker pull %ARTIFACTORY_IP%:8082/%IMAGE_NAME%:%IMAGE_TAG%
echo Tagging image for ACR...
docker tag %ARTIFACTORY_IP%:8082/%IMAGE_NAME%:%IMAGE_TAG% %ACR_NAME%.azurecr.io/%IMAGE_NAME%:%IMAGE_TAG%
echo Pushing image to ACR...
docker push %ACR_NAME%.azurecr.io/%IMAGE_NAME%:%IMAGE_TAG%
echo Done.
pause
'@
  $syncScript | Out-File -FilePath "$labDir\sync-image-to-acr.cmd" -Encoding ASCII -Force
  Log 'Lab scripts written'

  $publicDesktop = "$env:PUBLIC\Desktop"
  $wsh = New-Object -ComObject WScript.Shell
  $shortcut1 = $wsh.CreateShortcut("$publicDesktop\Generate Artifactory PAT.lnk"); $shortcut1.TargetPath = "$labDir\generate-artifactory-pat.cmd"; $shortcut1.Save()
  $shortcut2 = $wsh.CreateShortcut("$publicDesktop\Sync Image to ACR.lnk"); $shortcut2.TargetPath = "$labDir\sync-image-to-acr.cmd"; $shortcut2.Save()
  $azureShortcut = $wsh.CreateShortcut("$publicDesktop\Azure CLI.lnk"); $azureShortcut.TargetPath = "$env:SystemRoot\System32\cmd.exe"; $azureShortcut.Arguments = "/k az --version"; $azureShortcut.Save()
  Log 'Desktop shortcuts created'
} catch {
  Log "Lab script/shortcut creation issue: $($_.Exception.Message)"
}

# Sentinel marks completion so reruns are quick/idempotent
New-Item -ItemType File -Path 'C:\Windows\Temp\jumpbox-setup.done' -Force | Out-Null
Log '=== Jumpbox setup complete ==='
exit 0
