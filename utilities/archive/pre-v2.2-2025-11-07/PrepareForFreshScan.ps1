# PrepareForFreshScan.ps1
# Prepares for a fresh in-game vanity item scan by backing up and clearing SavedVariables
# This ensures you get a complete, clean scan of all items currently available in-game

param(
    [string]$SavedVarsFile = "data\AscensionVanity_SavedVariables.lua",
    [string]$BackupDir = "data\backups",
    [switch]$NoBackup,
    [switch]$Force
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Prepare for Fresh Vanity Item Scan" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if SavedVariables file exists
if (-not (Test-Path $SavedVarsFile)) {
    Write-Host "✓ No existing SavedVariables file found - ready for fresh scan!" -ForegroundColor Green
    Write-Host "`nNext Steps:" -ForegroundColor Green
    Write-Host "1. Launch WoW and log in to your character" -ForegroundColor White
    Write-Host "2. Run the AscensionVanity addon scan command" -ForegroundColor White
    Write-Host "3. Exit WoW to save the new data" -ForegroundColor White
    Write-Host "4. Run the database generation pipeline`n" -ForegroundColor White
    exit 0
}

Write-Host "Current SavedVariables file:" -ForegroundColor Cyan
Write-Host "  → Path: $SavedVarsFile" -ForegroundColor Gray
$fileInfo = Get-Item $SavedVarsFile
Write-Host "  → Size: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor Gray
Write-Host "  → Last Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
Write-Host ""

# Count current items in SavedVariables
$content = Get-Content $SavedVarsFile
$validationCount = ($content | Select-String -Pattern '\["ValidationResults"\]' -Context 0,1000 | Select-String -Pattern '\["apiItem"\]').Count
Write-Host "  → Contains validation data for $validationCount items" -ForegroundColor Yellow
Write-Host ""

# Confirm action unless Force flag is used
if (-not $Force) {
    Write-Host "⚠️  WARNING: This will prepare for a FRESH scan by:" -ForegroundColor Yellow
    Write-Host "   1. Backing up current SavedVariables (unless -NoBackup)" -ForegroundColor White
    Write-Host "   2. Deleting the current SavedVariables file" -ForegroundColor White
    Write-Host "   3. Preparing for a complete rescan in-game" -ForegroundColor White
    Write-Host ""
    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Create backup unless NoBackup flag is used
if (-not $NoBackup) {
    Write-Host "`nStep 1: Creating backup..." -ForegroundColor Green
    
    # Ensure backup directory exists
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        Write-Host "  → Created backup directory: $BackupDir" -ForegroundColor Gray
    }
    
    # Create timestamped backup
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path $BackupDir "AscensionVanity_SavedVariables_$timestamp.lua"
    
    Copy-Item $SavedVarsFile -Destination $backupFile
    Write-Host "  ✓ Backup created: $backupFile" -ForegroundColor Green
    
    # Show backup size
    $backupInfo = Get-Item $backupFile
    Write-Host "  → Backup size: $([math]::Round($backupInfo.Length / 1KB, 2)) KB" -ForegroundColor Gray
} else {
    Write-Host "`nStep 1: Skipping backup (NoBackup flag specified)" -ForegroundColor Yellow
}

# Delete the current SavedVariables file
Write-Host "`nStep 2: Removing current SavedVariables..." -ForegroundColor Green

try {
    Remove-Item $SavedVarsFile -Force
    Write-Host "  ✓ SavedVariables file removed successfully" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Error removing file: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPlease ensure the file is not in use and try again." -ForegroundColor Yellow
    exit 1
}

# Success summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✓ Ready for Fresh Scan!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

if (-not $NoBackup) {
    Write-Host "Backup Location:" -ForegroundColor Cyan
    Write-Host "  → $backupFile" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Next Steps:" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Launch World of Warcraft (Ascension)" -ForegroundColor White
Write-Host "2. Log in to your character" -ForegroundColor White
Write-Host "3. Open chat and run the vanity scan command:" -ForegroundColor White
Write-Host "   /run AscensionVanity:ScanAllItems()" -ForegroundColor Yellow
Write-Host "4. Wait for the scan to complete (watch for completion message)" -ForegroundColor White
Write-Host "5. Exit WoW completely to save the new data" -ForegroundColor White
Write-Host "6. Run the database generation pipeline:" -ForegroundColor White
Write-Host "   .\utilities\GenerateVanityDB_V2.ps1" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "💡 Tips:" -ForegroundColor Cyan
Write-Host "  • The fresh scan will capture ALL vanity items currently in-game" -ForegroundColor Gray
Write-Host "  • This will include items that were missing from previous scans" -ForegroundColor Gray
Write-Host "  • The scan may take a few minutes depending on server response" -ForegroundColor Gray
Write-Host "  • You can restore from backup if needed: $backupFile`n" -ForegroundColor Gray
