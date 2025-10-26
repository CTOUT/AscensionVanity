# Changelog

All notable changes to the AscensionVanity project will be documented in this file.

## [Unreleased] - 2025-10-26

### Changed
- **BREAKING**: Renamed `VanityData_Generated.lua` to `VanityDB.lua` for better clarity and consistency
  - Updated all script references (ExtractDatabase.ps1, utilities/*)
  - Updated all documentation files
  - Updated AscensionVanity.toc manifest

### Added
- **Cache Versioning System**: Added intelligent cache change detection
  - Content hashing (SHA256) to detect database changes
  - Metadata files (`.meta.json`) track content hash and timestamp
  - `Test-CacheChanged()` function validates if cached content has changed
  - Cache statistics report shows efficiency and metadata file count
  - Even if cache hasn't expired (24 hours), content changes are detected

### Improved
- Enhanced `Set-CachedContent()` to save metadata alongside cached pages
- Cache statistics now displayed after extraction showing:
  - Category pages cached
  - Item pages cached  
  - Metadata files created
  - Web requests made vs cache hits
  - Cache efficiency percentage

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
