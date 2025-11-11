# Changelog

All notable changes to the AscensionVanity project will be documented in this file.

## [Unreleased] - v2.3-dev

### Added
- **Kill/Drop Statistics Tracking** 📊 (Phase 1 Complete - November 2025)
  - Lifetime and session kill counters per creature
  - Drop tracking with percentage calculations
  - Unlucky streak detection (kills since last drop)
  - Per-character stats via SavedVariablesPerCharacter
  - Real-time stats in creature tooltips
  - `/avanity stats` command suite for viewing statistics
  - Stats display toggle in Settings UI

- **Enhanced Creature Information** ⚔️ (Phase 2A Complete - November 11, 2025)
  - **Creature Stats Display**: Level, classification, type, family, attack speed, health, damage, armor
  - **Smart Filtering**: Show stats for "All Creatures", "Vanity Drop Creatures Only", "Tameable Beasts Only", or "Vanity + Tameable"
  - **Player Pet Support**: Always shows stats for your own summoned combat pets
  - **Auto-Caching System**: Stats cached when you mouse over creatures, persists between sessions
    - **Baseline Stats Only**: Only caches stats out of combat (Phase 1 - November 11, 2025)
    - Prevents skewed stats from combat buffs, debuffs, and temporary effects
    - Ensures fair comparison across all pets (apples to apples)
  - **Collection UI Integration**: Shows cached stats when previewing pets in Vanity Collection UI
    - Works with both small preview (left) and large preview (right)
    - Displays: "Baseline stats - out of combat"
    - Helpful message for uncached pets: "Summon out of combat to see baseline stats"
  - **New Module**: `CollectionUIEnhancer.lua` - Monitors and enhances Ascension's Vanity Collection interface
  - **Configurable**: Dropdown in Settings UI to control when stats appear

- **Drop Celebration System** 🎉
  - Custom celebration frame on vanity item drops
  - Dynamic item icon display with proper textures
  - Collection status indicator (learned/unlearned)
  - Auto-dismissing popup with visual feedback
  - Multiple design iterations for optimal UX

- **Enhanced Collection Messages** ✨
  - Clear "Already learned!" vs "New item!" messaging
  - Integrated with celebration and tooltip systems
  - Color-coded status indicators

### Changed
- **Tooltip Performance Optimization**: Removed `GetItemInfo()` server calls for instant display
  - No more "Loading..." delays when hovering over creatures
  - All data from local database only (99.95% coverage)
  - Graceful fallback: "Unknown Item (ID: xxx)" for edge cases
  - Significantly faster tooltip rendering
- **Player Pet Detection**: Optimized with faster unit checks (`UnitIsUnit` first, then fallbacks)
- **Removed Duplicate Features**: 
  - Removed custom "Show IDs in Tooltips" (now uses built-in WoW option: Interface → Display → Show IDs)
  - Prevents conflicts with native game feature

### In Progress
See `FEATURE_ROADMAP_V2.3.md` for remaining planned features:
- 🗺️ Minimap Button Integration - Quick access with LibDBIcon-1.0
- 📈 Farming Session Analytics - Kills/hour, time estimates, session summaries

**Development Status:** 🔨 Active Development - Phase 1 Complete  
**Timeline:** 4-5 week development cycle

## [2.2-beta] - 2025-11-08

### Fixed
- **Database Browser Zone Filtering**: Resolved bug where zone filter showed hundreds of creatures instead of ~11
  - Root cause: Was grouping by creature BEFORE filtering by zone (creature_0 contamination)
  - Solution: Implemented filter-then-group approach for accurate zone-specific results
  - User confirmed: "No, that issue appears to be resolved"
- **Settings UI Layout**: Fixed button overlap and text clipping issues
  - Changed bottom buttons from vertical to horizontal layout (3 buttons, 220px each with 10px spacing)
  - Moved "Color Code Items by Status" from 240px to 320px right to prevent text overlap
  - Extended Display Options background from 190px to 155px (then optimized based on content)

### Improved
- **Creature ID Display**: Now shows Creature IDs for ALL NPCs, not just those with database entries
  - Helps with research and identifying potentially missing items
  - User confirmed: "That's working!"
- **Collection Progress Button**: Changed from one-way open to toggle (open/close)
  - Clicking button now toggles progress frame on/off
  - Also accessible via `/avanity progress` slash command
- **UI Overlap Prevention**: Database Browser and Scanner buttons now close Settings panel when opened
  - Prevents overlapping modal windows for better user experience

### Removed
- **Obsolete Features Cleanup**:
  - Removed "Show Region Information" checkbox (feature never implemented, superseded by integrated zone/subzone data)
  - Removed redundant "Show Collection Progress Frame" checkbox (button provides better control)
  - Cleaned up dead code and unused functions

### Changed
- **Settings UI Polish**:
  - Display Options background now properly sized for 4 checkboxes (155px height)
  - Removed redundant "Settings are saved automatically" footer text
  - Optimized frame height to 720px for better content fit

## [2.2-dev] - 2025-11-04

### Added - Database Browser with Pagination (v2.2)
- **Database Browser / Regional Guide**: Comprehensive UI for exploring vanity database
  - **Pagination System**: 50 creatures per page for optimal performance
    - Previous/Next navigation buttons at bottom of frame
    - Page counter showing current page and total pages
    - Auto-reset to page 1 when filters change
    - Instant page navigation with smooth scrolling
  - **Multi-Filter System**:
    - Zone filter: Current Zone / All Zones
    - Category filter: All / Beast / Demon / Undead / Dragonkin / Elemental
    - Collection status: All Items / Unlearned Only / Learned Only
  - **Creature Listing**:
    - Alphabetically sorted creatures
    - Shows zone/subzone location
    - Lists all vanity items per creature
    - Visual checkmarks for learned items
    - Item icons from database
  - **Performance Optimizations**:
    - Renders only 50 creatures at a time (~40x faster than showing all 2,126)
    - Smooth interaction even with large databases
    - Efficient filtering and sorting
  - **Commands**: 
    - `/avanity browser` - Open full database browser
    - `/avanity guide` - Open regional guide (current zone)
  - **UI Features**:
    - Draggable frame with saved position
    - ESC key to close
    - Clean layout with no overlapping elements
    - Results counter showing total and current page range

### Added - Quest-Locked NPC Warnings (v2.2)
- **Quest Detection System**: Intelligent warnings for quest-spawned NPCs
  - Real-time quest status detection (not started/active/completed)
  - Color-coded warnings: 🔴 Red (too late), 🟢 Green (farm now!), 🟠 Orange (not started)
  - Quest information display (name, ID, faction requirement)
  - Summon methods and unlock instructions
  - Toggle in settings: "Show Quest-Locked NPC Warnings"
  
- **Collection Progress Frame**: Standalone moveable progress display
  - Draggable, resizable frame showing collection completion
  - Per-category progress bars (Beast, Demon, Undead, Dragonkin, Elemental)
  - Overall collection progress
  - Color-coded bars (Red → Orange → Yellow → Green based on completion)
  - Auto-updates every 5 seconds
  - Saves position and visibility state
  - Toggle: `/avanity progress` or checkbox in settings
  
- **Enhanced Constants System**: 
  - New quest warning color constants (AV_COLOR_RED, AV_COLOR_GOLD, etc.)
  - Category prefix constants (AV_CATEGORY_PREFIXES)
  - Short category names for UI (AV_CATEGORY_SHORT_NAMES)

### Added - Data & Configuration
- **Quest-Locked NPC Database**: `data/QuestLockedNPCs.json`
  - Demon Spirit (Horde, Hand of Iruxos quest)
  - Enraged Panther (Horde, Hypercapacitor Gizmo quest)
  - Structured format with quest details, warnings, and notes
  
- **New Files**:
  - `CollectionProgressFrame.lua` - Standalone progress UI
  - `data/QuestLockedNPCs.json` - Quest-locked NPC database

### Changed
- **Database Schema**: Updated to v2.2 with `questLock` field support
- **Generation Pipeline**: Enhanced to merge quest lock data during build
- **Settings UI**: Added checkboxes for quest warnings and progress frame
- **Code Quality**: Replaced hardcoded color codes with constants throughout

### Documentation
- Updated `docs/DATA_SCHEMAS.md` with questLock field structure
- Updated `docs/INNOVATIVE_FEATURES_ROADMAP.md` with completed features

## [2.1-beta] - 2025-10-29

### ⚠️ Breaking Changes - Clean Installation Required
**IMPORTANT:** This release adds new files (SettingsUI.lua) that require a clean installation.

**Upgrade Instructions:**
1. **Delete** your existing AscensionVanity folder completely
2. **Extract** the new version to your AddOns directory
3. **Restart** WoW or `/reload`
4. Your settings will be preserved (stored in SavedVariables)

**Why?** WoW doesn't automatically remove old files when updating addons. The new SettingsUI.lua file is essential for the modern UI system to work correctly.  Older files from previous versions are also orphaned.

### Release Highlights
- Modern standalone Settings and Scanner UIs
- Interface Options integration
- Real-time slash command synchronization
- Comprehensive test plan and documentation

See v2.0.0 release notes below for complete feature list.

## [2.0.0] - 2025-10-29

### Added - Modern UI System
- **Settings UI**: Professional standalone frame with DialogBox styling
  - Accessible via `/avanity` command or Interface Options
  - Configure tooltip display, learned status, and color coding
  - Quick access button to API Scanner
  - Real-time synchronization with slash commands
  - ESC key support for closing
  
- **API Scanner UI**: Developer tool for database generation
  - Accessible via `/avanity scanner` command or Settings UI button
  - Scan Ascension API for all vanity items
  - Export data for processing
  - Debug mode toggle moved here (developer-focused location)
  - Complete instructions and slash command reference
  
- **Interface Options Integration**: 
  - Clean launcher panel in addon list
  - Appears alphabetically as "AscensionVanity"
  - Quick access to both Settings and Scanner UIs

### Changed - UI Architecture
- **Frame Management**: 
  - Mutual exclusion - only one UI open at a time
  - Proper frame strata (DIALOG) prevents overlap
  - Bidirectional navigation between Settings and Scanner
  - Draggable, movable frames with position clamping
  
- **Real-Time Synchronization**:
  - Slash commands now update UI checkboxes immediately
  - UI updates even when already open
  - Settings sync: toggle, learned, color commands
  - Scanner sync: debug command
  
- **Developer Tools Reorganization**:
  - Debug Mode moved from Settings UI to Scanner UI
  - Cleaner separation: user settings vs developer tools
  - Settings UI reduced to user-facing features only

### Fixed
- UI overlapping issues resolved with proper frame strata
- Text overlap in Settings UI footer
- Scanner UI content cutoff (increased height)
- Checkbox state sync when using slash commands
- Mutual exclusion from all access points (commands, UI buttons, Interface Options)

## [Unreleased] - 2025-10-27

### Added
- **Improved Path Detection in AnalyzeAPIDump.ps1**:
  - Registry-based auto-detection of WoW installation path
  - Automatic discovery of SavedVariables file across all account folders
  - Integration with `local.config.ps1` for consistent path management
  - Fallback to manual path specification if auto-detection fails
  - No more hardcoded paths or incorrect default locations

- **PII Sanitization**:
  - Removed all personally identifiable information from tracked files
  - Replaced email addresses, usernames, and local paths with placeholders
  - Repository is now safe for public sharing

- **Multiple Items Per Creature Support**:
  - Updated VanityDB.lua to support multiple vanity items from a single creature
  - Database now uses arrays for creatures that drop multiple items: `[creatureID] = {item1, item2}`
  - Tooltip displays all items when multiple are available
  - Example: Creature 7045 (Scalding Drake) now shows both Warhorn variants

- **API Export & Comparison System**:
  - New `/av export` command: Exports API data in VanityDB.lua format for easy comparison
  - New `/av showexport` command: Displays exported data in chat (paginated)
  - Exports data to SavedVariables in the exact same format as static database
  - Enables trivial line-by-line comparison between API and database

- **PowerShell Comparison Tool**:
  - `CompareAPIExport.ps1`: Automated comparison of API export vs static database
  - Identifies exact matches, mismatches, API-only, and DB-only entries
  - Exports detailed results to CSV files for analysis
  - Shows summary statistics and sample discrepancies

- **Comprehensive Comparison Documentation**:
  - [API_EXPORT_COMPARISON.md](docs/guides/API_EXPORT_COMPARISON.md): Complete guide for export/comparison workflow
  - Step-by-step instructions for data synchronization
  - Data quality checks and verification procedures
  - Best practices for maintaining database accuracy

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
- **Enhanced Help Command**: Updated `/av help` to include new API export and validation commands
- **Removed Hardcoded Paths**: Fixed hardcoded OneDrive/user-specific paths in utility scripts
  - `AnalyzeAPIDump.ps1`: Now uses standard WoW SavedVariables path
  - `UpdateDatabaseFromAPI.ps1`: Now uses standard WoW SavedVariables path
  - `CompareAPIExport.ps1`: Uses environment variables for default paths

### Fixed
- **Creature 7045 Database Entry**: Updated to include both item drops {1180254, 1180256}
  - Previously only showed one of two available Draconic Warhorn variants
  - Both items now appear in tooltip when targeting Scalding Drake
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
  - Default path: `<YOUR_WOW_PATH>`
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
