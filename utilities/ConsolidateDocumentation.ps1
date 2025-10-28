# Documentation Consolidation Script
# Consolidates redundant documentation following DRY/KISS principles

param(
    [switch]$WhatIf,  # Show what would happen without making changes
    [switch]$Force    # Skip confirmation prompts
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Documentation Consolidation Utility" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$repoRoot = Split-Path $PSScriptRoot -Parent
$docsPath = Join-Path $repoRoot "docs"

# Track changes
$filesArchived = 0
$filesDeleted = 0
$filesConsolidated = 0

#region Helper Functions

function Write-Action {
    param([string]$Message, [string]$Color = "Yellow")
    if ($WhatIf) {
        Write-Host "[WHATIF] $Message" -ForegroundColor $Color
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Move-ToArchive {
    param([string]$SourcePath, [string]$ArchiveSubfolder = "")
    
    $archivePath = Join-Path $docsPath "archive"
    if ($ArchiveSubfolder) {
        $archivePath = Join-Path $archivePath $ArchiveSubfolder
    }
    
    if (-not (Test-Path $archivePath)) {
        if (-not $WhatIf) {
            New-Item -Path $archivePath -ItemType Directory -Force | Out-Null
        }
        Write-Action "Created archive folder: $archivePath" "Green"
    }
    
    $fileName = Split-Path $SourcePath -Leaf
    $destPath = Join-Path $archivePath $fileName
    
    Write-Action "Archive: $fileName → archive/$ArchiveSubfolder"
    
    if (-not $WhatIf) {
        Move-Item -Path $SourcePath -Destination $destPath -Force
    }
    
    $script:filesArchived++
}

function Remove-RedundantFile {
    param([string]$FilePath, [string]$Reason)
    
    $fileName = Split-Path $FilePath -Leaf
    Write-Action "Delete: $fileName ($Reason)" "Red"
    
    if (-not $WhatIf) {
        Remove-Item -Path $FilePath -Force
    }
    
    $script:filesDeleted++
}

#endregion

#region Phase 1: Archive Session Notes

Write-Host "`n📝 Phase 1: Archiving Session Notes..." -ForegroundColor Cyan

$sessionNotes = @(
    "SESSION_NOTES_2025-01-26.md",
    "SESSION_NOTES_2025-10-27_API_VALIDATION.md",
    "SESSION_NOTES_2025-10-27_MULTIPLE_ITEMS.md",
    "TEST_RESULTS_2025-10-27.md"
)

foreach ($file in $sessionNotes) {
    $path = Join-Path $docsPath $file
    if (Test-Path $path) {
        Move-ToArchive $path "session_notes"
    }
}

#endregion

#region Phase 2: Remove Redundant API Scanner Docs

Write-Host "`n🔄 Phase 2: Removing Redundant API Scanner Documentation..." -ForegroundColor Cyan

$redundantAPIDocs = @(
    "API_SCANNER_REFINED_SUMMARY.md",
    "API_SCANNER_SIMPLIFICATION.md",
    "API_SCANNING_QUICKSTART.md",
    "IN_GAME_SCANNING_WORKFLOW.md",
    "FRESH_SCAN_WORKFLOW.md"
)

foreach ($file in $redundantAPIDocs) {
    $path = Join-Path $docsPath $file
    if (Test-Path $path) {
        Remove-RedundantFile $path "Consolidated into guides/API_SCANNING_GUIDE.md"
    }
}

# Keep API_SCANNER_REFINEMENTS.md - it's the most comprehensive

#endregion

#region Phase 3: Remove Redundant Quick Start Docs

Write-Host "`n📖 Phase 3: Removing Redundant Quick Start Guides..." -ForegroundColor Cyan

$redundantQuickStart = @(
    "QUICK_START_NEW_WORKFLOW.md"
)

foreach ($file in $redundantQuickStart) {
    $path = Join-Path $docsPath $file
    if (Test-Path $path) {
        Remove-RedundantFile $path "Consolidated into QUICK_START.md"
    }
}

# Archive V2_QUICK_REFERENCE.md as it's v2-specific
$v2QuickRef = Join-Path $docsPath "V2_QUICK_REFERENCE.md"
if (Test-Path $v2QuickRef) {
    Move-ToArchive $v2QuickRef "v2_migration"
}

#endregion

#region Phase 4: Remove Redundant Database Docs

Write-Host "`n💾 Phase 4: Removing Redundant Database Documentation..." -ForegroundColor Cyan

$redundantDatabaseDocs = @(
    "DATABASE_COMPARISON_EXPLANATION.md",
    "DATABASE_OPTIMIZATION_COMPLETE.md"
)

foreach ($file in $redundantDatabaseDocs) {
    $path = Join-Path $docsPath $file
    if (Test-Path $path) {
        Remove-RedundantFile $path "Consolidated into DATABASE_OPTIMIZATION_FINAL.md"
    }
}

#endregion

#region Phase 5: Remove Redundant Status Docs

Write-Host "`n📊 Phase 5: Archiving Redundant Status/Summary Documents..." -ForegroundColor Cyan

$redundantStatusDocs = @(
    "V2_BRANCH_SUMMARY.md",
    "V2_MIGRATION_COMPLETE.md",
    "V2_DATA_MODEL_SUMMARY.md"
)

foreach ($file in $redundantStatusDocs) {
    $path = Join-Path $docsPath $file
    if (Test-Path $path) {
        Move-ToArchive $path "v2_migration"
    }
}

# PROJECT_STATUS.md will be updated to be the single source of truth

#endregion

#region Phase 6: Remove Redundant Guide Files

Write-Host "`n📚 Phase 6: Removing Redundant Guide Files..." -ForegroundColor Cyan

$guidesPath = Join-Path $docsPath "guides"

# Developer Console consolidation
$redundantDevConsoleDocs = @(
    "DEVELOPER_CONSOLE_GUIDE.md",
    "DEV_CONSOLE_TESTING.md"
)

foreach ($file in $redundantDevConsoleDocs) {
    $path = Join-Path $guidesPath $file
    if (Test-Path $path) {
        Remove-RedundantFile $path "Consolidated into DEV_CONSOLE_REFERENCE.md"
    }
}

# API documentation consolidation
$redundantAPIDocs = @(
    "API_EXPORT_COMPARISON.md",
    "API_VALIDATION_GUIDE.md"
)

foreach ($file in $redundantAPIDocs) {
    $path = Join-Path $guidesPath $file
    if (Test-Path $path) {
        Remove-RedundantFile $path "Consolidated into API_QUICK_REFERENCE.md"
    }
}

# Remove temporary/obsolete files
$obsoleteFiles = @(
    "FILE_RENAME_SUMMARY.md",
    "TODO_FUTURE_INVESTIGATIONS.md"
)

foreach ($file in $obsoleteFiles) {
    $path = Join-Path $guidesPath $file
    if (Test-Path $path) {
        Remove-RedundantFile $path "One-time operation/move to GitHub issues"
    }
}

#endregion

#region Phase 7: Clean Up Root

Write-Host "`n🗑️ Phase 7: Cleaning Up Root Files..." -ForegroundColor Cyan

$rootCleanup = @(
    "API_VALIDATION_COMPLETE.md",
    "NEXT_STEPS.md"
)

foreach ($file in $rootCleanup) {
    $path = Join-Path $repoRoot $file
    if (Test-Path $path) {
        Move-ToArchive $path "root_cleanup"
    }
}

#endregion

#region Phase 8: Consolidate Archive Folders

Write-Host "`n📦 Phase 8: Consolidating Archive Folders..." -ForegroundColor Cyan

$archiveSource = Join-Path $docsPath "archive_20251027"
$changelogSource = Join-Path $docsPath "changelog"
$archiveDest = Join-Path $docsPath "archive"

if (Test-Path $archiveSource) {
    Write-Action "Merging archive_20251027/ into archive/"
    if (-not $WhatIf) {
        Get-ChildItem $archiveSource | Move-Item -Destination $archiveDest -Force
        Remove-Item $archiveSource -Force
    }
}

if (Test-Path $changelogSource) {
    Write-Action "Merging changelog/ into archive/"
    if (-not $WhatIf) {
        $changelogDest = Join-Path $archiveDest "changelog"
        if (-not (Test-Path $changelogDest)) {
            New-Item -Path $changelogDest -ItemType Directory -Force | Out-Null
        }
        Get-ChildItem $changelogSource | Move-Item -Destination $changelogDest -Force
        Remove-Item $changelogSource -Force
    }
}

#endregion

#region Summary

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Consolidation Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "Files archived:     $filesArchived" -ForegroundColor Green
Write-Host "Files deleted:      $filesDeleted" -ForegroundColor Red
Write-Host "Total cleaned:      $($filesArchived + $filesDeleted)" -ForegroundColor Yellow

if ($WhatIf) {
    Write-Host "`n⚠️  This was a dry run (WhatIf mode)" -ForegroundColor Yellow
    Write-Host "Run without -WhatIf to apply changes" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ Consolidation complete!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Review the changes" -ForegroundColor White
    Write-Host "2. Update PROJECT_STATUS.md with consolidated info" -ForegroundColor White
    Write-Host "3. Commit with: git commit -m 'docs: Consolidate documentation following DRY/KISS principles'" -ForegroundColor White
}

Write-Host ""

#endregion
