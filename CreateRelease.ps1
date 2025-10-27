# CreateRelease.ps1
# Creates a release package for AscensionVanity addon

param(
    [Parameter(Mandatory=$false)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\releases"
)

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  AscensionVanity - Release Package Creator" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Get version from TOC file if not specified
if (-not $Version) {
    $tocFile = ".\AscensionVanity\AscensionVanity.toc"
    if (Test-Path $tocFile) {
        $tocContent = Get-Content $tocFile
        $versionLine = $tocContent | Where-Object { $_ -match "## Version: (.+)" }
        if ($versionLine -match "## Version: (.+)") {
            $Version = $Matches[1].Trim()
            Write-Host "Detected version from TOC: $Version" -ForegroundColor Green
        }
    }
    
    if (-not $Version) {
        Write-Host "ERROR: Could not detect version from TOC file" -ForegroundColor Red
        Write-Host "Please specify version: .\CreateRelease.ps1 -Version '1.0.0'" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Creating release package for version: $Version" -ForegroundColor Cyan
Write-Host ""

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

# Define release filename
$releaseFileName = "AscensionVanity-v$Version.zip"
$releaseFilePath = Join-Path $OutputPath $releaseFileName

# Remove existing release file if it exists
if (Test-Path $releaseFilePath) {
    Write-Host "Removing existing release file..." -ForegroundColor Yellow
    Remove-Item $releaseFilePath -Force
}

# Create temporary staging directory
$tempDir = Join-Path $env:TEMP "AscensionVanity_Release_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $tempDir | Out-Null

try {
    Write-Host "Staging files..." -ForegroundColor Cyan
    
    # Copy addon folder to temp with proper structure
    $addonSource = ".\AscensionVanity"
    $addonDest = Join-Path $tempDir "AscensionVanity"
    
    Copy-Item -Path $addonSource -Destination $addonDest -Recurse -Force
    
    # Verify files
    $copiedFiles = Get-ChildItem -Path $addonDest -File -Recurse
    Write-Host "  ✓ Copied $($copiedFiles.Count) files" -ForegroundColor Green
    
    foreach ($file in $copiedFiles) {
        $relativePath = $file.FullName.Substring($tempDir.Length + 1)
        Write-Host "    - $relativePath" -ForegroundColor Gray
    }
    
    # Create ZIP archive
    Write-Host ""
    Write-Host "Creating ZIP archive..." -ForegroundColor Cyan
    
    Compress-Archive -Path "$addonDest" -DestinationPath $releaseFilePath -Force
    
    if (Test-Path $releaseFilePath) {
        $zipSize = (Get-Item $releaseFilePath).Length / 1KB
        Write-Host "  ✓ Created: $releaseFileName ($([math]::Round($zipSize, 2)) KB)" -ForegroundColor Green
    }
    
    # Generate release notes
    Write-Host ""
    Write-Host "Generating release notes..." -ForegroundColor Cyan
    
    $releaseNotesPath = Join-Path $OutputPath "RELEASE_NOTES_v$Version.md"
    
    $releaseNotes = @"
# AscensionVanity v$Version Release Notes

**Release Date**: $(Get-Date -Format "MMMM dd, yyyy")

## 📦 Installation Instructions

1. Download ``AscensionVanity-v$Version.zip``
2. Extract the ZIP file
3. Move the ``AscensionVanity`` folder to your WoW AddOns directory:
   - Default: ``<WoW_Installation>\Interface\AddOns\``
   - Example: ``D:\Program Files\Ascension Launcher\resources\client\Interface\AddOns\``
4. Restart World of Warcraft (or ``/reload`` if already in-game)

## ✨ Features

- **Tooltip Integration**: Automatically shows vanity item information when hovering over creatures
- **Comprehensive Database**: Tracks vanity items including:
  - Whistles (battle pets)
  - Vellums (cosmetic spells)
  - Stones (cosmetic effects)
  - Warhorms (sound effects)
  - Lodestones (various cosmetics)
- **Source Information**: Shows where each item comes from (Drop, Quest, Vendor, etc.)
- **Performance Optimized**: Minimal memory footprint and fast tooltip updates

## 🎮 Usage

Once installed, simply hover your mouse over any creature in the game. If that creature drops vanity items, you'll see them listed in the tooltip with:
- Item name and ID
- Item type (Whistle, Vellum, Stone, etc.)
- Source type (Drop, Quest, Vendor, etc.)

## 📊 Database Statistics

- **Total Items**: $(
    $dbPath = ".\AscensionVanity\VanityDB.lua"
    if (Test-Path $dbPath) {
        $dbContent = Get-Content $dbPath -Raw
        $matches = [regex]::Matches($dbContent, '\[(\d+)\]\s*=')
        $matches.Count
    } else {
        "N/A"
    }
)+ vanity items tracked
- **Categories**: Whistle, Vellum, Stone, Warhorn, Lodestone
- **Sources**: Drop, Quest, Vendor, Achievement, World Event

## 🔧 Commands

Currently, this addon works automatically and requires no commands. Future versions may add:
- Configuration options
- Search functionality
- Custom filtering

## 🐛 Known Issues

None at this time. Please report any issues on GitHub!

## 📝 Changelog

See [CHANGELOG.md](https://github.com/CTOUT/AscensionVanity/blob/main/CHANGELOG.md) for full version history.

## 🔗 Links

- **GitHub Repository**: https://github.com/CTOUT/AscensionVanity
- **Issue Tracker**: https://github.com/CTOUT/AscensionVanity/issues
- **Latest Releases**: https://github.com/CTOUT/AscensionVanity/releases

## 📄 License

This addon is released under the MIT License. See LICENSE file for details.

---

**Thank you for using AscensionVanity!** ✨

If you encounter any issues or have suggestions, please open an issue on GitHub.
"@
    
    $releaseNotes | Out-File -FilePath $releaseNotesPath -Encoding UTF8
    Write-Host "  ✓ Created: RELEASE_NOTES_v$Version.md" -ForegroundColor Green
    
} finally {
    # Cleanup temporary directory
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Release Package Complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Release Files:" -ForegroundColor Yellow
Write-Host "  📦 $releaseFilePath" -ForegroundColor Cyan
Write-Host "  📄 $releaseNotesPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test the ZIP file by extracting it" -ForegroundColor Yellow
Write-Host "  2. Review the release notes" -ForegroundColor Yellow
Write-Host "  3. Create a GitHub release:" -ForegroundColor Yellow
Write-Host "     - Go to: https://github.com/CTOUT/AscensionVanity/releases/new" -ForegroundColor Gray
Write-Host "     - Tag: v$Version" -ForegroundColor Gray
Write-Host "     - Title: AscensionVanity v$Version" -ForegroundColor Gray
Write-Host "     - Upload: $releaseFileName" -ForegroundColor Gray
Write-Host "     - Copy release notes from RELEASE_NOTES_v$Version.md" -ForegroundColor Gray
Write-Host ""
