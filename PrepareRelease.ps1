<#
.SYNOPSIS
    Prepares the AscensionVanity repository for v2.0 stable release.

.DESCRIPTION
    This script performs repository cleanup by:
    - Creating archive directory structure
    - Moving development logs to docs/development/logs/
    - Moving guides to docs/guides/
    - Deleting temporary test files
    - Organizing the repository for release

.EXAMPLE
    .\PrepareRelease.ps1
    Performs all cleanup operations

.EXAMPLE
    .\PrepareRelease.ps1 -WhatIf
    Shows what would be done without making changes
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'

Write-Host "🧹 AscensionVanity v2.0 Release Preparation" -ForegroundColor Cyan
Write-Host "=" * 60

# Ensure we're in the repo root
$repoRoot = $PSScriptRoot
Set-Location $repoRoot

# Create archive directory structure
Write-Host "`n📁 Creating archive directory structure..." -ForegroundColor Yellow

$directories = @(
    'docs\development\logs',
    'docs\guides',
    'docs\development\api-analysis'
)

foreach ($dir in $directories) {
    $fullPath = Join-Path $repoRoot $dir
    if (-not (Test-Path $fullPath)) {
        if ($PSCmdlet.ShouldProcess($fullPath, "Create directory")) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Host "  ✓ Created: $dir" -ForegroundColor Green
        }
    } else {
        Write-Host "  • Exists: $dir" -ForegroundColor Gray
    }
}

# Files to archive (move to docs/development/logs/)
Write-Host "`n📦 Archiving development logs..." -ForegroundColor Yellow

$logsToArchive = @(
    'ACTION_PLAN_2025-10-29.md',
    'APPEARANCE_COLLECTED_DISCOVERY.md',
    'APPEARANCE_COLLECTED_TEST_PLAN.md',
    'BUG_FIXES_2025-10-28.md',
    'CACHE_IMPLEMENTATION_SUMMARY.md',
    'CACHE_OPTIMIZATION_FALLBACK_FIX.md',
    'CACHE_STRATEGY_FINAL.md',
    'CACHE_STRATEGY_REALITY_CHECK.md',
    'CACHE_STRATEGY_UPDATED.md',
    'CACHE_UPDATE_OCT30.md',
    'DESCRIPTION_ENRICHMENT_COMPLETE.md',
    'DESCRIPTION_ENRICHMENT_FINAL_REPORT.md',
    'EMPTY_DESCRIPTION_ISSUE.md',
    'EVENT_VALIDATION_RESULTS.md',
    'EVENT_VALIDATION_TEST.md',
    'FRESH_SCAN_CLARIFICATION.md',
    'FRESH_SCAN_READY.md',
    'IN_GAME_SCANNING_COMPLETE.md',
    'MANUAL_ENRICHMENT_COMPLETE.md',
    'QUOTE_ESCAPING_FIX_COMPLETE.md',
    'QUOTE_ESCAPING_FIX_TEST_PLAN.md',
    'REPOSITORY_ORGANIZATION_COMPLETE.md',
    'SCRIPT_CONSOLIDATION_SUMMARY.md',
    'TOOLTIP_ICON_FIX.md',
    'VANITYDB_GENERATION_COMPLETE.md',
    'VANITYDB_GENERATION_FINAL.md',
    'UPGRADE_v2.1-beta.md'
)

$archiveDir = 'docs\development\logs'
foreach ($file in $logsToArchive) {
    $sourcePath = Join-Path $repoRoot $file
    $destPath = Join-Path $repoRoot "$archiveDir\$file"
    
    if (Test-Path $sourcePath) {
        if ($PSCmdlet.ShouldProcess($file, "Move to $archiveDir")) {
            Move-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "  ✓ Archived: $file" -ForegroundColor Green
        }
    } else {
        Write-Host "  • Not found: $file" -ForegroundColor Gray
    }
}

# Files to move to guides
Write-Host "`n📚 Moving guides to docs/guides/..." -ForegroundColor Yellow

$guidesToMove = @(
    'CACHE_QUICK_REFERENCE.md',
    'CACHE_TESTING_GUIDE.md',
    'IN_GAME_TESTING_GUIDE.md',
    'QUICK_TEST_CHECKLIST.md',
    'TESTING_OPTIONS.md',
    'UI_TEST_PLAN.md'
)

$guidesDir = 'docs\guides'
foreach ($file in $guidesToMove) {
    $sourcePath = Join-Path $repoRoot $file
    $destPath = Join-Path $repoRoot "$guidesDir\$file"
    
    if (Test-Path $sourcePath) {
        if ($PSCmdlet.ShouldProcess($file, "Move to $guidesDir")) {
            Move-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "  ✓ Moved: $file" -ForegroundColor Green
        }
    } else {
        Write-Host "  • Not found: $file" -ForegroundColor Gray
    }
}

# Move API Analysis to docs/development/api-analysis/
Write-Host "`n🔍 Moving API Analysis..." -ForegroundColor Yellow

$apiAnalysisSource = Join-Path $repoRoot 'API_Analysis'
$apiAnalysisDest = Join-Path $repoRoot 'docs\development\api-analysis'

if (Test-Path $apiAnalysisSource) {
    if ($PSCmdlet.ShouldProcess('API_Analysis', "Move to docs/development/api-analysis")) {
        # Move contents, not the folder itself
        Get-ChildItem $apiAnalysisSource | ForEach-Object {
            Move-Item -Path $_.FullName -Destination $apiAnalysisDest -Force
        }
        Remove-Item $apiAnalysisSource -Force
        Write-Host "  ✓ Moved API_Analysis contents" -ForegroundColor Green
    }
} else {
    Write-Host "  • API_Analysis not found" -ForegroundColor Gray
}

# Delete temporary files
Write-Host "`n🗑️  Deleting temporary files..." -ForegroundColor Yellow

$tempFiles = @(
    '100',
    'strigid_owl_page.html',
    'temp_drops.txt',
    'temp_listview.txt',
    'validation_log.txt'
)

foreach ($file in $tempFiles) {
    $filePath = Join-Path $repoRoot $file
    if (Test-Path $filePath) {
        if ($PSCmdlet.ShouldProcess($file, "Delete")) {
            Remove-Item -Path $filePath -Force
            Write-Host "  ✓ Deleted: $file" -ForegroundColor Green
        }
    } else {
        Write-Host "  • Not found: $file" -ForegroundColor Gray
    }
}

Write-Host "`n✅ Repository cleanup complete!" -ForegroundColor Green
Write-Host "`n📋 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review changes with: git status" -ForegroundColor White
Write-Host "  2. Stage changes with: git add ." -ForegroundColor White
Write-Host "  3. Commit with: git commit -m 'chore: prepare repository for v2.0 release'" -ForegroundColor White
Write-Host "  4. Review RELEASE_2.0_PLAN.md for next phases" -ForegroundColor White
