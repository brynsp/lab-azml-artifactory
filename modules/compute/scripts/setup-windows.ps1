# PowerShell script to set up Windows jumpbox with Docker Desktop and Azure CLI

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

# Install Chocolatey package manager
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Refresh environment variables
refreshenv

# Install Azure CLI
choco install azure-cli -y

# Install Git
choco install git -y

# Install Visual Studio Code (optional)
choco install vscode -y

# Install Windows Terminal (optional)
choco install microsoft-windows-terminal -y

# Install PowerShell 7
choco install powershell-core -y

# Create desktop shortcuts
$WshShell = New-Object -comObject WScript.Shell

# Docker Desktop shortcut
$DockerShortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\Docker Desktop.lnk")
$DockerShortcut.TargetPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
$DockerShortcut.Save()

# Azure CLI shortcut (Command Prompt)
$AzureShortcut = $WshShell.CreateShortcut("$env:PUBLIC\Desktop\Azure CLI.lnk")
$AzureShortcut.TargetPath = "$env:SystemRoot\System32\cmd.exe"
$AzureShortcut.Arguments = "/k az --version"
$AzureShortcut.Save()

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
Write-Host "Windows jumpbox setup completed!" -ForegroundColor Green
Write-Host "Installed: Azure CLI, Git, VS Code, Windows Terminal, PowerShell 7" -ForegroundColor Yellow
Write-Host "Lab scripts created in C:\LabScripts and desktop shortcuts added." -ForegroundColor Yellow
Write-Host "Docker image operations (build/pull/tag/push) must be performed on the Linux Artifactory VM (no Docker Desktop here)." -ForegroundColor Red