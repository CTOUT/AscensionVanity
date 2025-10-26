# AscensionVanity Deployment Script
# Mirrors the addon folder to WoW AddOns directory for testing
#
# Usage:
#   .\DeployAddon.ps1 -WoWPath "C:\Path\To\WoW\Interface\AddOns"  # Specify your WoW path
#   .\DeployAddon.ps1 -Watch    # Deploy and watch for changes (auto-deploy on file change)

param(
    [Parameter(Mandatory=$true)]
    [string]$WoWPath,
    [switch]$Watch,
    [switch]$Force
)

# Configuration
$sourceFolder = Join-Path $PSScriptRoot "AscensionVanity"
$destinationFolder = Join-Path $WoWPath "AscensionVanity"

# Colors for output
$colorInfo = "Cyan"
$colorSuccess = "Green"
$colorWarning = "Yellow"
$colorError = "Red"

# Header
Write-Host "`nAscensionVanity Deployment Tool" -ForegroundColor $colorInfo
Write-Host "================================" -ForegroundColor $colorInfo
Write-Host "Source:      $sourceFolder" -ForegroundColor Gray
Write-Host "Destination: $destinationFolder" -ForegroundColor Gray
Write-Host ""

# Validate source folder exists
if (-not (Test-Path $sourceFolder)) {
    Write-Host "ERROR: Source folder not found: $sourceFolder" -ForegroundColor $colorError
    exit 1
}

# Check if destination parent directory exists
$wowAddOnsPath = Split-Path $destinationFolder -Parent
if (-not (Test-Path $wowAddOnsPath)) {
    Write-Host "ERROR: WoW AddOns directory not found: $wowAddOnsPath" -ForegroundColor $colorError
    Write-Host "Please verify your WoW installation path." -ForegroundColor $colorWarning
    exit 1
}

# Function to perform the deployment
function Deploy-Addon {
    param([bool]$IsWatchMode = $false)
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    if (-not $IsWatchMode) {
        Write-Host "[$timestamp] Deploying addon..." -ForegroundColor $colorInfo
    }
    
    try {
        # Create destination folder if it doesn't exist
        if (-not (Test-Path $destinationFolder)) {
            New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
            Write-Host "[$timestamp] Created destination folder" -ForegroundColor $colorSuccess
        }
        
        # Get all files to copy
        $filesToCopy = Get-ChildItem -Path $sourceFolder -File -Recurse
        $copiedCount = 0
        $skippedCount = 0
        
        foreach ($file in $filesToCopy) {
            $relativePath = $file.FullName.Substring($sourceFolder.Length + 1)
            $destPath = Join-Path $destinationFolder $relativePath
            $destDir = Split-Path $destPath -Parent
            
            # Create destination directory if needed
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            
            # Copy if file doesn't exist or is newer or Force flag is set
            $shouldCopy = $Force
            if (-not $shouldCopy) {
                if (-not (Test-Path $destPath)) {
                    $shouldCopy = $true
                } else {
                    $sourceTime = $file.LastWriteTime
                    $destTime = (Get-Item $destPath).LastWriteTime
                    $shouldCopy = $sourceTime -gt $destTime
                }
            }
            
            if ($shouldCopy) {
                Copy-Item -Path $file.FullName -Destination $destPath -Force
                $copiedCount++
                
                if (-not $IsWatchMode) {
                    Write-Host "  Copied: $relativePath" -ForegroundColor Gray
                }
            } else {
                $skippedCount++
            }
        }
        
        # Summary
        if ($IsWatchMode) {
            if ($copiedCount -gt 0) {
                Write-Host "[$timestamp] Updated $copiedCount file(s)" -ForegroundColor $colorSuccess
            }
        } else {
            Write-Host "`n[$timestamp] Deployment complete!" -ForegroundColor $colorSuccess
            Write-Host "  Files copied: $copiedCount" -ForegroundColor $colorSuccess
            Write-Host "  Files skipped (up-to-date): $skippedCount" -ForegroundColor Gray
            Write-Host ""
        }
        
        return $true
        
    } catch {
        Write-Host "[$timestamp] ERROR: Deployment failed" -ForegroundColor $colorError
        Write-Host $_.Exception.Message -ForegroundColor $colorError
        return $false
    }
}

# Initial deployment
$deploySuccess = Deploy-Addon -IsWatchMode $false

if (-not $deploySuccess) {
    exit 1
}

# Watch mode
if ($Watch) {
    Write-Host "Watch mode enabled - monitoring for changes..." -ForegroundColor $colorInfo
    Write-Host "Press Ctrl+C to stop watching" -ForegroundColor $colorWarning
    Write-Host ""
    
    # Create file system watcher
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $sourceFolder
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true
    
    # Track last deployment time to debounce multiple rapid changes
    $lastDeployTime = Get-Date
    $debounceSeconds = 2
    
    # Define the action to take when a file changes
    $action = {
        $currentTime = Get-Date
        $timeSinceLastDeploy = ($currentTime - $script:lastDeployTime).TotalSeconds
        
        if ($timeSinceLastDeploy -gt $script:debounceSeconds) {
            $script:lastDeployTime = $currentTime
            Deploy-Addon -IsWatchMode $true
        }
    }
    
    # Register event handlers
    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action | Out-Null
    
    # Keep script running
    try {
        while ($true) {
            Start-Sleep -Seconds 1
        }
    } finally {
        # Cleanup on exit
        $watcher.Dispose()
        Get-EventSubscriber | Unregister-Event
        Write-Host "`nWatch mode stopped" -ForegroundColor $colorWarning
    }
}

Write-Host "Deployment script finished" -ForegroundColor $colorInfo
Write-Host ""
Write-Host "To test in-game:" -ForegroundColor $colorInfo
Write-Host "  1. Launch World of Warcraft" -ForegroundColor Gray
Write-Host "  2. Type /reload to reload UI" -ForegroundColor Gray
Write-Host "  3. Type /av help to verify addon loaded" -ForegroundColor Gray
Write-Host ""
