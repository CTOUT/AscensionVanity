# ExecuteCleanup.ps1
# Repository cleanup automation
# Run this to execute the cleanup plan

param(
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  AscensionVanity Repository Cleanup" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($WhatIf) {
    Write-Host "⚠️  RUNNING IN WHATIF MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

# Confirm before proceeding
if (-not $Force -and -not $WhatIf) {
    Write-Host "This script will:" -ForegroundColor Yellow
    Write-Host "  1. Archive 4 documentation files" -ForegroundColor Yellow
    Write-Host "  2. Delete 7 temporary/test files" -ForegroundColor Yellow
    Write-Host "  3. Move 3 utility scripts" -ForegroundColor Yellow
    Write-Host "  4. Remove 5 obsolete utility scripts" -ForegroundColor Yellow
    Write-Host "  5. Rename 1 versioned script" -ForegroundColor Yellow
    Write-Host "  6. Update .gitignore" -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "Continue? (y/n)"
    if ($confirm -ne 'y') {
        Write-Host "Cleanup cancelled." -ForegroundColor Red
        exit 0
    }
}

Write-Host ""
Write-Host "Starting cleanup..." -ForegroundColor Green
Write-Host ""

# Track changes
$changes = @{
    Archived = @()
    Deleted = @()
    Moved = @()
    Renamed = @()
    Failed = @()
}

# Helper function for operations
function Invoke-SafeOperation {
    param(
        [string]$Operation,
        [string]$Path,
        [string]$Destination = $null,
        [scriptblock]$Action
    )
    
    try {
        if ($WhatIf) {
            Write-Host "[WHATIF] $Operation : $Path" -ForegroundColor Cyan
            if ($Destination) {
                Write-Host "          → $Destination" -ForegroundColor Gray
            }
            return $true
        } else {
            & $Action
            Write-Host "[✓] $Operation : $Path" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "[✗] $Operation FAILED: $Path" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Red
        $script:changes.Failed += "$Operation : $Path - $_"
        return $false
    }
}

# ============================================================================
# STEP 1: Create archive directory
# ============================================================================
Write-Host "Step 1: Creating archive directory..." -ForegroundColor Cyan
$archiveDir = "docs\archive_20251027"

if (-not $WhatIf) {
    if (-not (Test-Path $archiveDir)) {
        New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
        Write-Host "[✓] Created: $archiveDir" -ForegroundColor Green
    } else {
        Write-Host "[✓] Archive directory already exists" -ForegroundColor Yellow
    }
}

# ============================================================================
# STEP 2: Archive documentation files
# ============================================================================
Write-Host ""
Write-Host "Step 2: Archiving documentation..." -ForegroundColor Cyan

$docsToArchive = @(
    "API_VALIDATION_COMPLETE.md",
    "NEXT_STEPS.md",
    "CLEANUP_CHECKLIST.md",
    "PROJECT_STRUCTURE.md"
)

foreach ($doc in $docsToArchive) {
    if (Test-Path $doc) {
        $result = Invoke-SafeOperation -Operation "Archive" -Path $doc -Destination $archiveDir -Action {
            Move-Item $doc $archiveDir -Force
        }
        if ($result) { $changes.Archived += $doc }
    }
}

# ============================================================================
# STEP 3: Delete temporary/test files
# ============================================================================
Write-Host ""
Write-Host "Step 3: Deleting temporary files..." -ForegroundColor Cyan

$filesToDelete = @(
    "npc_7045.html",
    "extracted_drops_data.txt",
    "test_item_page.html",
    "test_html_sample.txt",
    "DatabaseComparison_Report.txt",
    "MissingItems_Report.txt",
    "SkippedItems_Detailed.txt"
)

foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        $result = Invoke-SafeOperation -Operation "Delete" -Path $file -Action {
            Remove-Item $file -Force
        }
        if ($result) { $changes.Deleted += $file }
    }
}

# ============================================================================
# STEP 4: Move scripts to utilities
# ============================================================================
Write-Host ""
Write-Host "Step 4: Moving scripts to utilities..." -ForegroundColor Cyan

$scriptsToMove = @(
    "CompareDatabase.ps1",
    "ImportResults.ps1",
    "AnalyzeResults.ps1"
)

foreach ($script in $scriptsToMove) {
    if (Test-Path $script) {
        $result = Invoke-SafeOperation -Operation "Move" -Path $script -Destination "utilities\" -Action {
            Move-Item $script utilities\ -Force
        }
        if ($result) { $changes.Moved += $script }
    }
}

# ============================================================================
# STEP 5: Remove obsolete utility scripts
# ============================================================================
Write-Host ""
Write-Host "Step 5: Removing obsolete utilities..." -ForegroundColor Cyan

$obsoleteScripts = @(
    "utilities\CompareGameExportToVanityDB.ps1",
    "utilities\AnalyzeNPCDrops.ps1",
    "utilities\DiagnoseSourcemore.ps1",
    "utilities\ExtractDraconicWarhornIDs.ps1",
    "utilities\FetchNPCPage.ps1"
)

foreach ($script in $obsoleteScripts) {
    if (Test-Path $script) {
        $result = Invoke-SafeOperation -Operation "Delete" -Path $script -Action {
            Remove-Item $script -Force
        }
        if ($result) { $changes.Deleted += $script }
    }
}

# ============================================================================
# STEP 6: Rename versioned script
# ============================================================================
Write-Host ""
Write-Host "Step 6: Renaming versioned script..." -ForegroundColor Cyan

$oldName = "utilities\CompareGameExportToVanityDB_v2.ps1"
$newName = "utilities\CompareGameExportToVanityDB.ps1"

if (Test-Path $oldName) {
    $result = Invoke-SafeOperation -Operation "Rename" -Path $oldName -Destination $newName -Action {
        Rename-Item $oldName -NewName (Split-Path $newName -Leaf) -Force
    }
    if ($result) { $changes.Renamed += "$oldName → $newName" }
}

# ============================================================================
# STEP 7: Update .gitignore
# ============================================================================
Write-Host ""
Write-Host "Step 7: Updating .gitignore..." -ForegroundColor Cyan

$gitignoreAdditions = @"

# Analysis/comparison output files (added during cleanup)
DatabaseComparison_Report.txt
*_Report.txt
*Comparison*.txt
API_Analysis/

# Large test/extraction files (added during cleanup)
npc_*.html
extracted_*.txt

# Temporary extraction data (added during cleanup)
data/*.txt
data/*.json
"@

if (-not $WhatIf) {
    if (Test-Path ".gitignore") {
        $currentGitignore = Get-Content ".gitignore" -Raw
        if ($currentGitignore -notmatch "added during cleanup") {
            Add-Content ".gitignore" $gitignoreAdditions
            Write-Host "[✓] Updated .gitignore with new patterns" -ForegroundColor Green
        } else {
            Write-Host "[✓] .gitignore already updated" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "[WHATIF] Would update .gitignore with new patterns" -ForegroundColor Cyan
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Cleanup Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host ("Archived:  {0,2} files" -f $changes.Archived.Count) -ForegroundColor Green
Write-Host ("Deleted:   {0,2} files" -f $changes.Deleted.Count) -ForegroundColor Green
Write-Host ("Moved:     {0,2} files" -f $changes.Moved.Count) -ForegroundColor Green
Write-Host ("Renamed:   {0,2} files" -f $changes.Renamed.Count) -ForegroundColor Green

if ($changes.Failed.Count -gt 0) {
    Write-Host ""
    Write-Host ("Failed:    {0,2} operations" -f $changes.Failed.Count) -ForegroundColor Red
    foreach ($failure in $changes.Failed) {
        Write-Host "  ✗ $failure" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($WhatIf) {
    Write-Host ""
    Write-Host "No changes made (WhatIf mode)" -ForegroundColor Yellow
    Write-Host "Run without -WhatIf to execute cleanup" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "✅ Cleanup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Review changes with: git status" -ForegroundColor Yellow
    Write-Host "  2. Create utilities\README.md to document remaining scripts" -ForegroundColor Yellow
    Write-Host "  3. Delete CLEANUP_PLAN.md (reference completed)" -ForegroundColor Yellow
}
Write-Host ""
