# manage-willitrain.ps1

<#
.SYNOPSIS
A script to manage the 'willitrain-backend' Docker container lifecycle.

.DESCRIPTION
This script provides two main actions:
- nuke: Asks for confirmation, then stops, removes, and deletes the container and image before automatically rebuilding and starting it.
- start: Builds a fresh image and starts a new container with hot-reloading for development.

.PARAMETER Action
The action to perform. Can be 'nuke' or 'start'. If not provided, the script will prompt for it.

.EXAMPLE
# To run interactively and be prompted for an action
.\manage-willitrain.ps1

# To specify the action directly
.\manage-willitrain.ps1 -Action nuke
#>

param(
    # Parameter is no longer mandatory to allow the script to prompt the user.
    [ValidateSet('nuke', 'start')]
    [string]$Action
)

# --- Configuration ---
$imageName = "willitrain-backend"
$containerName = "willitrain-container" # Using a consistent name for stability

# --- Functions ---
function Invoke-Nuke {
    Write-Host "---------------------------------------------------------" -ForegroundColor Red
    Write-Host "WARNING: You are about to NUKE the '$imageName' environment." -ForegroundColor Yellow
    Write-Host "This will permanently delete the container and the image." -ForegroundColor Yellow
    Write-Host "After deletion, the application will be rebuilt and started automatically." -ForegroundColor Yellow
    Write-Host "---------------------------------------------------------" -ForegroundColor Red
    
    Read-Host -Prompt "Press ENTER to proceed, or CTRL+C to cancel"

    Write-Host "`n--- Tearing down the '$imageName' environment ---" -ForegroundColor Yellow
    Write-Host "1. Stopping container '$containerName'..."
    docker stop $containerName 2>$null
    Write-Host "2. Removing container '$containerName'..."
    docker rm $containerName 2>$null
    Write-Host "3. Removing image '$imageName'..."
    docker rmi $imageName -f
    Write-Host "--- Nuke complete. Proceeding to start... ---" -ForegroundColor Green
}

function Invoke-Start {
    Write-Host "`n--- Starting the '$imageName' environment ---" -ForegroundColor Cyan
    Write-Host "1. Building image '$imageName' from Dockerfile..."
    docker build -t $imageName $PSScriptRoot

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Docker build failed. Aborting." -ForegroundColor Red
        return
    }

    Write-Host "2. Starting container '$containerName' with live reload..."
    
    # Check if .env file exists
    if (Test-Path "${PSScriptRoot}\.env") {
        Write-Host "   ✅ Found .env file, passing environment variables..." -ForegroundColor Green
        docker run -d -p 8000:8000 --name $containerName `
            -v "${PSScriptRoot}:/app" `
            --env-file "${PSScriptRoot}\.env" `
            $imageName
    } else {
        Write-Host "   ⚠️ No .env file found, starting without environment variables..." -ForegroundColor Yellow
        docker run -d -p 8000:8000 --name $containerName -v "${PSScriptRoot}:/app" $imageName
    }

    Write-Host "--- Start complete. Container is running. ---" -ForegroundColor Green
    Write-Host "Access the application at http://localhost:8000"
    Write-Host "View logs with: docker logs -f $containerName" -ForegroundColor Cyan
}

# --- Main Logic ---

# 1. Check if the user provided an action. If not, display the message and ask for one.
if (-not $Action) {
    Write-Host "--- Script for managing the '$imageName' environment ---" -ForegroundColor Blue
    $Action = Read-Host -Prompt "Enter action ('nuke' to reset and restart, 'start' for a fresh start)"
}

# 2. Execute the chosen action.
switch ($Action) {
    "nuke" {
        Invoke-Nuke
        Invoke-Start # Automatically calls the start function after nuking
    }
    "start" {
        Invoke-Start
    }
    default {
        Write-Host "Invalid action: '$Action'. Please run the script again and choose 'nuke' or 'start'." -ForegroundColor Red
    }
}