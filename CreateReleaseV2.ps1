<#
.SYNOPSIS
    Creates AscensionVanity v2.0 release package and archives previous releases.

.DESCRIPTION
    This script:
    - Archives previous release packages to releases/archive/
    - Creates a clean v2.0 release package from main branch
    - Includes only necessary addon files
    - Generates release package ready for distribution

.EXAMPLE
    .\CreateReleaseV2.ps1
    Creates v2.0 release package and archives old releases
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "📦 AscensionVanity v2.0 Release Package Creation" -ForegroundColor Cyan
Write-Host "=" * 60

# Get repository root
$repoRoot = $PSScriptRoot
Set-Location $repoRoot

# Ensure we're looking at main branch content
Write-Host "`n🔍 Checking current branch..." -ForegroundColor Yellow
$currentBranch = git branch --show-current
if ($currentBranch -ne "main") {
    Write-Host "⚠️  Currently on branch: $currentBranch" -ForegroundColor Yellow
    Write-Host "   Switching to main to create release from stable code..." -ForegroundColor Yellow
    git checkout main
}

# Define paths
$releasesDir = Join-Path $repoRoot "releases"
$archiveDir = Join-Path $releasesDir "archive"
$tempDir = Join-Path $env:TEMP "AscensionVanity_Release"
$addonSourceDir = Join-Path $repoRoot "AscensionVanity"

# Create archive directory
Write-Host "`n📁 Creating archive directory..." -ForegroundColor Yellow
if (-not (Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    Write-Host "  ✓ Created: releases/archive/" -ForegroundColor Green
} else {
    Write-Host "  • Archive directory exists" -ForegroundColor Gray
}

# Archive old releases
Write-Host "`n📦 Archiving previous releases..." -ForegroundColor Yellow
$oldReleases = @(
    "AscensionVanity-v1.0.0.zip",
    "AscensionVanity-v2.0.0-beta.zip"
)

foreach ($release in $oldReleases) {
    $sourcePath = Join-Path $releasesDir $release
    $destPath = Join-Path $archiveDir $release
    
    if (Test-Path $sourcePath) {
        Move-Item -Path $sourcePath -Destination $destPath -Force
        Write-Host "  ✓ Archived: $release" -ForegroundColor Green
    } else {
        Write-Host "  • Not found: $release" -ForegroundColor Gray
    }
}

# Archive old release notes
$oldNotes = @(
    "RELEASE_NOTES_v1.0.0.md",
    "RELEASE_NOTES_v2.0.0-beta.md"
)

foreach ($note in $oldNotes) {
    $sourcePath = Join-Path $releasesDir $note
    $destPath = Join-Path $archiveDir $note
    
    if (Test-Path $sourcePath) {
        Move-Item -Path $sourcePath -Destination $destPath -Force
        Write-Host "  ✓ Archived: $note" -ForegroundColor Green
    } else {
        Write-Host "  • Not found: $note" -ForegroundColor Gray
    }
}

# Clean temp directory
Write-Host "`n🧹 Preparing temporary directory..." -ForegroundColor Yellow
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Create addon directory structure
$addonTempDir = Join-Path $tempDir "AscensionVanity"
New-Item -ItemType Directory -Path $addonTempDir -Force | Out-Null

# Copy addon files (only necessary files)
Write-Host "`n📋 Copying addon files..." -ForegroundColor Yellow

$filesToInclude = @(
    "AscensionVanity.toc",
    "Core.lua",
    "VanityDB.lua",
    "VanityDB_Loader.lua",
    "AscensionVanityConfig.lua",
    "SettingsUI.lua",
    "APIScanner.lua",
    "ScannerUI.lua"
)

$filesCopied = 0
foreach ($file in $filesToInclude) {
    $sourcePath = Join-Path $addonSourceDir $file
    $destPath = Join-Path $addonTempDir $file
    
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $destPath -Force
        $filesCopied++
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Missing: $file" -ForegroundColor Red
    }
}

Write-Host "`n  Total files: $filesCopied" -ForegroundColor Cyan

# Create release package
Write-Host "`n📦 Creating release package..." -ForegroundColor Yellow
$releaseZipPath = Join-Path $releasesDir "AscensionVanity-v2.0.zip"

# Remove old v2.0 zip if it exists
if (Test-Path $releaseZipPath) {
    Remove-Item -Path $releaseZipPath -Force
    Write-Host "  • Removed old v2.0 package" -ForegroundColor Gray
}

# Create zip
Compress-Archive -Path $addonTempDir -DestinationPath $releaseZipPath -Force
Write-Host "  ✓ Created: AscensionVanity-v2.0.zip" -ForegroundColor Green

# Get file size
$zipSize = (Get-Item $releaseZipPath).Length / 1KB
Write-Host "  • Size: $([math]::Round($zipSize, 2)) KB" -ForegroundColor Cyan

# Create release notes
Write-Host "`n📝 Creating release notes..." -ForegroundColor Yellow
$releaseNotesPath = Join-Path $releasesDir "RELEASE_NOTES_v2.0.md"

$releaseNotes = @"
# AscensionVanity v2.0 - Stable Release

**Release Date:** $(Get-Date -Format "MMMM dd, yyyy")  
**Version:** 2.0  
**Package:** AscensionVanity-v2.0.zip

---

## 🎉 What's New in v2.0

### Database Excellence
- **2,174 Combat Pets** tracked across all Ascension content
- **99.95% Description Coverage** (2,173/2,174 items with descriptions)
- **Comprehensive Location Data** for efficient farming
- **1 Correctly Empty Entry** (Captain Claws - creature doesn't exist)

### Performance & Optimization
- **Smart Caching System** for instant tooltip updates
- **Lazy Loading** for optimized memory usage
- **Consolidated Icon System** (15 unique icons)
- **Event-Driven Architecture** for minimal performance impact

### User Interface
- **Enhanced Tooltips** with better formatting and color coding
- **Settings Panel** for configuration (`/av settings`)
- **In-Game API Scanner** for data collection
- **Slash Commands** for quick access (`/av`)

### Developer Tools
- **95% Automated Workflow** for description enrichment
- **Master Enrichment Script** handles end-to-end processing
- **Database Generation** fully automated
- **Comprehensive Documentation** and guides

---

## 📥 Installation

### Fresh Installation
1. Download ``AscensionVanity-v2.0.zip``
2. Extract to ``World of Warcraft\_retail_\Interface\AddOns\``
3. You should have: ``...\Interface\AddOns\AscensionVanity\``
4. Restart WoW or type ``/reload``

### Upgrading from Previous Versions
1. **Delete** the old ``AscensionVanity`` folder
2. Follow fresh installation steps above
3. All learned items and settings will be preserved automatically

---

## 🎮 Usage

### Basic Commands
- ``/av`` or ``/ascensionvanity`` - Show help
- ``/av toggle`` - Enable/disable tooltips
- ``/av settings`` - Open settings panel

### Tooltip Display
Mouse over any creature to see:
- Combat pet items they can drop
- Item icons and names  
- Location/region information
- Collection status (learned/not learned)

---

## 📊 Statistics

| Metric | Value |
|--------|-------|
| Total Combat Pets | 2,174 |
| With Descriptions | 2,173 (99.95%) |
| Correctly Empty | 1 (0.05%) |
| Unique Icons | 15 |
| Automation Rate | 95% |

---

## 🔧 Technical Details

### Files Included
- ``AscensionVanity.toc`` - Addon manifest
- ``Core.lua`` - Main tooltip logic
- ``VanityDB.lua`` - Combat pets database (2,174 items)
- ``VanityDB_Loader.lua`` - Database loading & caching
- ``AscensionVanityConfig.lua`` - Configuration system
- ``SettingsUI.lua`` - In-game settings panel
- ``APIScanner.lua`` - API scanning functionality
- ``ScannerUI.lua`` - Scanner UI components

### Requirements
- World of Warcraft: Wrath of the Lich King (3.3.5)
- Project Ascension server

---

## 🐛 Known Issues

None reported. Please submit issues on GitHub if you encounter problems.

---

## 🙏 Acknowledgments

- **Data Sources:** db.ascension.gg, Wowhead WotLK
- **Project Ascension Team** for the amazing server
- **Community Members** who helped validate data
- **Beta Testers** who provided valuable feedback

---

## 🔗 Links

- **GitHub Repository:** https://github.com/CTOUT/AscensionVanity
- **Issue Tracker:** https://github.com/CTOUT/AscensionVanity/issues
- **Feature Roadmap:** See FEATURE_ROADMAP_V2.1.md in repository

---

## 📜 Changelog

See [CHANGELOG.md](https://github.com/CTOUT/AscensionVanity/blob/main/CHANGELOG.md) for detailed version history.

---

**Thank you for using AscensionVanity!** 🐾

For questions, suggestions, or issues, please visit our GitHub repository.
"@

Set-Content -Path $releaseNotesPath -Value $releaseNotes -Force
Write-Host "  ✓ Created: RELEASE_NOTES_v2.0.md" -ForegroundColor Green

# Clean up temp directory
Write-Host "`n🧹 Cleaning up..." -ForegroundColor Yellow
Remove-Item -Path $tempDir -Recurse -Force
Write-Host "  ✓ Temporary files removed" -ForegroundColor Green

# Summary
Write-Host "`n✅ Release package creation complete!" -ForegroundColor Green
Write-Host "`n📦 Release Package Details:" -ForegroundColor Cyan
Write-Host "  • Location: releases/AscensionVanity-v2.0.zip" -ForegroundColor White
Write-Host "  • Size: $([math]::Round($zipSize, 2)) KB" -ForegroundColor White
Write-Host "  • Files: $filesCopied addon files" -ForegroundColor White
Write-Host "  • Notes: releases/RELEASE_NOTES_v2.0.md" -ForegroundColor White

Write-Host "`n📁 Archived Releases:" -ForegroundColor Cyan
Write-Host "  • Location: releases/archive/" -ForegroundColor White
Write-Host "  • v1.0.0 package and notes" -ForegroundColor White
Write-Host "  • v2.0.0-beta package and notes" -ForegroundColor White

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Test the release package locally" -ForegroundColor White
Write-Host "  2. Review RELEASE_NOTES_v2.0.md" -ForegroundColor White
Write-Host "  3. Commit the changes: git add releases/ && git commit -m 'release: v2.0 package'" -ForegroundColor White
Write-Host "  4. Create GitHub release with the zip file" -ForegroundColor White

# Return to original branch if needed
if ($currentBranch -ne "main") {
    Write-Host "`n🔄 Returning to branch: $currentBranch" -ForegroundColor Yellow
    git checkout $currentBranch
}
