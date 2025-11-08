<#
.SYNOPSIS
    Watches for file changes and auto-deploys to WoW directory
    
.DESCRIPTION
    Monitors AscensionVanity source files for changes and automatically
    copies them to the WoW AddOns folder. Press Ctrl+C to stop.
    
.EXAMPLE
    .\WatchAndDeploy.ps1 -WoWPath "D:\OneDrive\Warcraft\"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$WoWPath = "D:\OneDrive\Warcraft\"
)

$sourcePath = "$PSScriptRoot\AscensionVanity"
$destPath = Join-Path $WoWPath "AscensionVanity"

# Ensure destination exists
if (-not (Test-Path $destPath)) {
    Write-Host "Error: Destination path not found: $destPath" -ForegroundColor Red
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AscensionVanity Auto-Deploy Watcher  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Watching: $sourcePath" -ForegroundColor Yellow
Write-Host "Deploying to: $destPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop watching..." -ForegroundColor Gray
Write-Host ""

# Create file watcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $sourcePath
$watcher.Filter = "*.lua"
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

# Define action on file change
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $fileName = Split-Path $path -Leaf
    $changeType = $Event.SourceEventArgs.ChangeType
    $timeStamp = Get-Date -Format "HH:mm:ss"
    
    # Only process actual changes (not just opens)
    if ($changeType -eq 'Changed') {
        # Small delay to ensure file is fully written
        Start-Sleep -Milliseconds 100
        
        try {
            $destFile = Join-Path $using:destPath $fileName
            Copy-Item -Path $path -Destination $destFile -Force -ErrorAction Stop
            Write-Host "[$timeStamp] " -NoNewline -ForegroundColor Gray
            Write-Host "✓ " -NoNewline -ForegroundColor Green
            Write-Host "$fileName deployed" -ForegroundColor White
            Write-Host "         → Type /reload in-game to see changes" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "[$timeStamp] " -NoNewline -ForegroundColor Gray
            Write-Host "✗ " -NoNewline -ForegroundColor Red
            Write-Host "Failed to deploy $fileName" -ForegroundColor Red
            Write-Host "         Error: $($_.Exception.Message)" -ForegroundColor DarkRed
        }
    }
}

# Register events
$handlers = @()
$handlers += Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action

# Keep script running
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
}
finally {
    # Cleanup on exit
    Write-Host "`nStopping watcher..." -ForegroundColor Yellow
    $handlers | ForEach-Object { Unregister-Event -SourceIdentifier $_.Name }
    $watcher.Dispose()
    Write-Host "Watcher stopped." -ForegroundColor Green
}
