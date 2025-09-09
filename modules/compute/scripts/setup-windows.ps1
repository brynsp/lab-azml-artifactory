<#
	Hardened Windows jumpbox setup script
	- Adds logging & retries
	- Removes Docker Desktop references (Linux VM handles Docker work)
	- Non‑interactive installs
	- Safe to re-run (idempotent where practical)
	NOTE: Extension runs as SYSTEM; shortcuts appear for all users via PUBLIC desktop.
#>

$ErrorActionPreference = 'Stop'
$LogFile = 'C:\Windows\Temp\jumpbox-setup.log'
function Write-Log {
	param([string]$Message,[string]$Level='INFO')
	$ts = (Get-Date).ToString('u')
	$line = "[$ts][$Level] $Message"
	Write-Host $line
	Add-Content -Path $LogFile -Value $line
}

Write-Log 'Starting jumpbox setup'

function Test-Network {
	try { (Invoke-WebRequest -Uri 'https://aka.ms' -UseBasicParsing -TimeoutSec 15) | Out-Null; return $true } catch { return $false }
}
if (-not (Test-Network)) {
	Write-Log 'WARNING: Initial network reachability test failed; retrying in 30s'
	Start-Sleep 30
	if (-not (Test-Network)) { Write-Log 'ERROR: No outbound network connectivity; aborting.' 'ERROR'; exit 1 }
}

Write-Log 'Setting execution policy (local machine)'
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force | Out-Null

function Invoke-Retry {
	param(
		[scriptblock]$Script,
		[int]$MaxAttempts = 5,
		[int]$DelaySeconds = 10,
		[string]$Description = 'operation'
	)
	for ($i=1; $i -le $MaxAttempts; $i++) {
		try { & $Script; Write-Log "$Description success (attempt $i)"; return }
		catch {
			# Format string avoids parser confusion with "$i:" pattern under extension execution context
			Write-Log ("{0} failed attempt {1}: {2}" -f $Description, $i, $_.Exception.Message) 'WARN'
			if ($i -eq $MaxAttempts) { Write-Log "$Description exhausted retries" 'ERROR'; throw }
			Start-Sleep $DelaySeconds
		}
	}
}

# Install Chocolatey if missing
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
	Write-Log 'Installing Chocolatey'
	Set-ExecutionPolicy Bypass -Scope Process -Force | Out-Null
	[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
	Invoke-Retry -Description 'Chocolatey bootstrap' -Script { Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) }
} else {
	Write-Log 'Chocolatey already installed; skipping'
}

# Refresh env for current session if function is available
if (Get-Command refreshenv -ErrorAction SilentlyContinue) { refreshenv }

function Install-ChocoPackage {
	param(
		[string]$Name
	)
	if (choco list --local-only --limit-output | Select-String -SimpleMatch "^$Name|") {
		Write-Log "$Name already installed"
		return
	}
	try {
		Invoke-Retry -Description "choco install $Name" -Script { choco install $Name -y --no-progress }
	} catch {
		Write-Log "Package $Name failed to install after retries: $($_.Exception.Message)" 'WARN'
	}
}

# Core packages (omit Windows Terminal to avoid failures on Server)
$Packages = @('azure-cli','git','vscode','powershell-core')
foreach ($p in $Packages) { Install-ChocoPackage $p }

# Create desktop shortcuts
$WshShell = New-Object -ComObject WScript.Shell
$AzureShortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\Azure CLI.lnk")
$AzureShortcut.TargetPath = "$env:SystemRoot\System32\cmd.exe"
$AzureShortcut.Arguments = "/k az --version"
$AzureShortcut.Save()
Write-Log 'Created Azure CLI shortcut'

# Create sample scripts directory
New-Item -ItemType Directory -Path "C:\LabScripts" -Force

# Create PAT generation script
$PATScript = @'
@echo off
echo Azure ML Artifactory Lab - PAT Generation Script
echo.
echo This script helps generate a Personal Access Token (PAT) for Artifactory authentication
echo.

set /p ARTIFACTORY_IP="Enter Artifactory VM IP address: "
set /p USERNAME="Enter Artifactory username (default: admin): "
if "%USERNAME%"=="" set USERNAME=admin
set /p PASSWORD="Enter Artifactory password: "

echo.
echo Generating PAT for Artifactory at http://%ARTIFACTORY_IP%:8082...
echo.

curl -u %USERNAME%:%PASSWORD% -X POST "http://%ARTIFACTORY_IP%:8082/artifactory/api/security/token" ^
-d "username=%USERNAME%" ^
-d "scope=member-of-groups:readers"

echo.
echo.
echo Save the access_token value from the response above.
echo You will use this token for Azure ML authentication to Artifactory.
echo.
pause
'@

$PATScript | Out-File -FilePath "C:\LabScripts\generate-artifactory-pat.cmd" -Encoding ASCII

# Create image sync script
$SyncScript = @'
@echo off
echo Azure ML Artifactory Lab - Image Sync Script
echo.
echo This script syncs container images from Artifactory to Azure Container Registry
echo.

set /p ARTIFACTORY_IP="Enter Artifactory VM IP address: "
set /p ACR_NAME="Enter Azure Container Registry name: "
set /p IMAGE_NAME="Enter image name (e.g., contoso-lab/sample-ml-model): "
set /p IMAGE_TAG="Enter image tag (default: latest): "
if "%IMAGE_TAG%"=="" set IMAGE_TAG=latest

echo.
echo Logging into Azure...
az login

echo.
echo Logging into ACR...
az acr login --name %ACR_NAME%

echo.
echo Pulling image from Artifactory...
docker pull %ARTIFACTORY_IP%:8082/%IMAGE_NAME%:%IMAGE_TAG%

echo.
echo Tagging image for ACR...
docker tag %ARTIFACTORY_IP%:8082/%IMAGE_NAME%:%IMAGE_TAG% %ACR_NAME%.azurecr.io/%IMAGE_NAME%:%IMAGE_TAG%

echo.
echo Pushing image to ACR...
docker push %ACR_NAME%.azurecr.io/%IMAGE_NAME%:%IMAGE_TAG%

echo.
echo Image sync completed successfully!
echo Image is now available at: %ACR_NAME%.azurecr.io/%IMAGE_NAME%:%IMAGE_TAG%
echo.
pause
'@

$SyncScript | Out-File -FilePath "C:\LabScripts\sync-image-to-acr.cmd" -Encoding ASCII

# Create shortcuts for lab scripts
$PATScriptShortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\Generate Artifactory PAT.lnk")
$PATScriptShortcut.TargetPath = "C:\LabScripts\generate-artifactory-pat.cmd"
$PATScriptShortcut.Save()

$SyncScriptShortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\Sync Image to ACR.lnk")
$SyncScriptShortcut.TargetPath = "C:\LabScripts\sync-image-to-acr.cmd"
$SyncScriptShortcut.Save()

# Output completion message
Write-Log 'Windows jumpbox setup completed successfully'
Write-Log 'Installed (best-effort): Azure CLI, Git, VS Code, PowerShell 7'
Write-Log 'Lab scripts created in C:\LabScripts and desktop shortcuts added.'
Write-Log 'Reminder: Docker operations happen on the Linux Artifactory VM.'

exit 0