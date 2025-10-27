# Changelog

All notable changes to the AscensionVanity project will be documented in this file.

## [Unreleased] - 2025-10-27

### Added
- **API Validation System**: Complete database validation using Ascension's official API
  - New `/av apidump` command: Extracts complete vanity collection data from C_VanityCollection
  - New `/av validate` command: Compares API data vs static database to find discrepancies
  - Exports full API data to SavedVariables for offline analysis
  - Identifies missing items (in API but not in database)
  - Detects incorrect mappings (mismatches between API and database)
  - Organizes data by creature ID, item ID, and category
  - Tracks validation metrics: total items, matches, missing, mismatches

- **PowerShell Analysis Tools**:
  - `AnalyzeAPIDump.ps1`: Analyzes SavedVariables and generates validation reports
  - `UpdateDatabaseFromAPI.ps1`: Auto-generates updated VanityDB.lua from API data
  - Both tools support detailed reporting and backup functionality
  - Exports data to `API_Analysis/` folder with timestamped reports

- **Comprehensive Documentation**:
  - [API_VALIDATION_GUIDE.md](docs/guides/API_VALIDATION_GUIDE.md): Complete step-by-step validation process
  - [API_QUICK_REFERENCE.md](docs/guides/API_QUICK_REFERENCE.md): Quick reference card for all commands
  - Troubleshooting guide for common issues
  - Workflow summaries for quick validation, full analysis, and database updates

### Changed
- **Enhanced Help Command**: Updated `/av help` to include new API validation commands
  - Organized into sections: Basic Commands, Database Validation, Debug Commands
  - Improved formatting and clarity
  - Added examples for complex commands

### Technical Details
- API dump structure includes:
  - `items`: Complete item data with names, creature sources, and raw API data
  - `itemsByCreature`: Reverse lookup mapping creatures to their item drops
  - `categories`: Item counts by category (Whistles, Vellums, Stones, etc.)
  - `errors`: Tracks any parsing errors during extraction
- Validation results track:
  - Exact matches between API and database
  - Items present in API but missing from database (the 144 missing items!)
  - Mismatched mappings (incorrect creature → item associations)
- SavedVariables integration allows offline analysis and automated database updates

### Purpose
This update enables complete validation of the static database against Ascension's official API, helping to:
1. Find the 144 missing items identified in earlier analysis
2. Fix any incorrect mappings inherited from web scraping
3. Ensure 100% database accuracy and completeness
4. Provide automated tools for future database maintenance

---

## [2025-10-26]

### Added
- **Deployment System**: Created `DeployAddon.ps1` script for easy testing
  - Automatically copies addon files to WoW AddOns directory
  - Smart copying: only updates changed files (compares timestamps)
  - Watch mode: auto-deploy on file save (`-Watch` parameter)
  - Force mode: re-deploy all files regardless of state (`-Force` parameter)
  - Configurable WoW path with `-WoWPath` parameter
  - Default path: `D:\OneDrive\Warcraft`
  - Debounce protection: prevents multiple rapid deployments
  - Comprehensive error handling and user feedback
  - Documentation: Added [DEPLOYMENT_GUIDE.md](docs/guides/DEPLOYMENT_GUIDE.md)

- **Cache Versioning System**: Added intelligent cache change detection
  - Content hashing (SHA256) to detect database changes
  - Metadata files (`.meta.json`) track content hash and timestamp
  - `Test-CacheChanged()` function validates if cached content has changed
  - Cache statistics report shows efficiency and metadata file count
  - Even if cache hasn't expired (24 hours), content changes are detected

### Changed
- **BREAKING**: Renamed `VanityData_Generated.lua` to `VanityDB.lua` for better clarity and consistency
  - Updated all script references (ExtractDatabase.ps1, utilities/*)
  - Updated all documentation files
  - Updated AscensionVanity.toc manifest

### Improved
- Enhanced `Set-CachedContent()` to save metadata alongside cached pages
- Cache statistics now displayed after extraction showing:
  - Category pages cached
  - Item pages cached  
  - Metadata files created
  - Web requests made vs cache hits
  - Cache efficiency percentage
- Updated README.md with deployment workflow and testing instructions
- Updated PROJECT_STRUCTURE.md to include deployment script

### Technical Details
- Cache metadata stored as JSON with structure:
  ```json
  {
    "CachedDate": "ISO 8601 timestamp",
    "ContentHash": "SHA256 hash",
    "Url": "source URL"
  }
  ```
- Metadata files automatically excluded from git via .gitignore
- Cache change detection enables smart invalidation beyond time-based expiration

### Benefits
- **Database Change Detection**: Automatically detect when Ascension updates the vanity database
- **Intelligent Caching**: Know when to re-fetch even if cache is fresh
- **Audit Trail**: Track when content was cached and what its hash was
- **Performance**: Avoid unnecessary web requests while staying current

---

## [1.0.0] - Previous Release

### Initial Features
- Database extraction from Ascension DB
- 96.7% coverage (2,032/2,101 items)
- Intelligent NPC validation
- Generic drop categorization by creature type
- Category-based extraction (Beastmaster's Whistles, Necrotic Runes, etc.)
- Time-based caching (24-hour expiration)
