# Web Enrichment Workflow

**Last Updated:** 2025-11-15  
**Version:** 2.3

## Overview

All external web scraping has been consolidated into a single master script: **`MasterWebEnrichment.ps1`**

This replaces the previous multi-script workflow and provides a unified, cacheable, resumable enrichment system.

---

## Data Sources

All enrichment data comes from **db.ascension.gg**:

1. **Pet Family Pages** (`db.ascension.gg/?pets` and `db.ascension.gg/?pet={familyId}`)
   - 155 pet families with metadata
   - 9,292 tameable creatures mapped to families
   - Family abilities and spell IDs

2. **Individual Item Pages** (`db.ascension.gg/?item={itemId}`)
   - Pet family data for non-tameable sources
   - Item descriptions
   - Drop information

3. **Zone/Location Data**
   - Extracted from description text (no web scraping)
   - Validated against `data/ZoneMappings.json`

---

## Workflow Phases

### Phase 1: Pet Family Enrichment

**Goal:** Achieve 100% pet family coverage for all combat pets

**Steps:**

1. **Scrape Pet Family Pages** (`ScrapePetFamilies.ps1`)
   - Fetches all 155 pet families from `db.ascension.gg/?pets`
   - For each family, scrapes:
     - Vanity items (182 items from family pages)
     - Tameable creatures (9,292 creature → family mappings)
     - Abilities with spell IDs (444 abilities)
   - Output: `data/PetFamilyMapping.json`
   - Cache TTL: 7 days (configurable)

2. **Enrich Missing Items** (`EnrichMissingPetFamilies.ps1`)
   - Identifies combat pets without family data (~359 items)
   - Scrapes individual item pages for pet family info
   - Targets items from non-tameable sources (bosses, demons, etc.)
   - Output: `data/MissingPetFamilies_Enriched.json`
   - Rate limit: 2 seconds between requests

**Coverage:**
- Before: 85.1% (2,004 / 2,355 items)
- After: 100% (2,355 / 2,355 items)

---

### Phase 2: Description Enrichment

**Goal:** Fill empty descriptions for items missing drop information

**Steps:**

1. **Identify Empty Descriptions**
   - Scans `MasterFullValidated.json` for items with empty/missing descriptions
   - Filters to only items that need enrichment

2. **Scrape Item Pages**
   - Fetches description from `db.ascension.gg/?item={itemId}`
   - Extracts drop location and source creature
   - Saves enriched descriptions

**Script:** `MasterDescriptionEnrichment.ps1`  
**Rate Limit:** 2 seconds (configurable)

---

### Phase 3: Zone/Location Extraction

**Goal:** Extract zone and subzone data from descriptions

**Steps:**

1. **Parse Descriptions**
   - Regex patterns match "within {zone}" and "in {subzone}"
   - Extracts primary zone and specific location

2. **Validate Against Mappings**
   - Uses `data/ZoneMappings.json` for subzone → zone relationships
   - Promotes subzones to parent zones when needed

3. **Populate Fields**
   - Adds `zone` and `subzone` fields to items
   - Output: `data/MasterFullValidated_ZoneEnriched.json`

**Script:** `EnrichZoneData.ps1`  
**Note:** No web scraping (text parsing only)

---

## Usage

### Single Command (Recommended)

```powershell
.\utilities\MasterWebEnrichment.ps1
```

Runs all three phases with default settings:
- Rate limit: 2 seconds
- Cache TTL: 7 days
- Resumable (skips cached data)

### Options

```powershell
# Force refresh (ignore cache)
.\utilities\MasterWebEnrichment.ps1 -Force

# Skip specific phases
.\utilities\MasterWebEnrichment.ps1 -SkipDescriptions -SkipZones

# Adjust rate limiting
.\utilities\MasterWebEnrichment.ps1 -RateLimit 3

# Longer cache TTL
.\utilities\MasterWebEnrichment.ps1 -CacheDays 30
```

### Individual Scripts (Legacy)

Still available for targeted enrichment:

```powershell
# Pet families only
.\utilities\ScrapePetFamilies.ps1

# Missing pet families only
.\utilities\EnrichMissingPetFamilies.ps1

# Descriptions only
.\utilities\MasterDescriptionEnrichment.ps1

# Zones only
.\utilities\EnrichZoneData.ps1
```

---

## Output Files

| File | Description | Size | Cache |
|------|-------------|------|-------|
| `data/PetFamilyMapping.json` | 155 families + 9,292 creatures | ~2 MB | 7 days |
| `data/MissingPetFamilies_Enriched.json` | 359 item-based families | ~100 KB | N/A |
| `data/MasterFullValidated_ZoneEnriched.json` | Items with zone data | ~4 MB | N/A |

---

## Integration with Database Generation

After enrichment, regenerate the database:

```powershell
# Step 1: Copy zone-enriched JSON as master source
Copy-Item 'data\MasterFullValidated_ZoneEnriched.json' 'data\MasterFullValidated.json' -Force

# Step 2: Regenerate VanityDB.lua with all enrichments
.\utilities\GenerateVanityDB_Master.ps1
```

The generator automatically loads and merges:
- Pet family data (creature-based + item-based)
- Quest-locked NPC data
- Zone/subzone information

---

## Performance & Timing

**Estimated Duration (Full Run):**

- Phase 1 (Pet Families):
  - Family scraping: ~10 minutes (155 families × 2 sec)
  - Missing items: ~12 minutes (359 items × 2 sec)
  - **Total: ~22 minutes**

- Phase 2 (Descriptions):
  - Variable based on empty items (~5-10 minutes typical)

- Phase 3 (Zones):
  - No web scraping (~30 seconds for parsing)

**Full Pipeline: ~30-40 minutes** (first run)  
**Subsequent Runs: <1 minute** (cached data)

---

## Rate Limiting & Etiquette

**Default Settings:**
- 2 seconds between requests
- Respects db.ascension.gg server load
- Batch saves every 50 items
- Resumable if interrupted

**Recommendations:**
- Run during off-peak hours for large refreshes
- Use default 2-second rate limit
- Don't run multiple instances simultaneously
- Cache data for 7-30 days typical

---

## Troubleshooting

### Cache Not Being Used

```powershell
# Check cache age
$file = Get-Item "data\PetFamilyMapping.json"
$age = (Get-Date) - $file.LastWriteTime
Write-Host "Cache age: $($age.TotalDays) days"
```

### Rate Limit Too Aggressive

Increase delay if seeing HTTP errors:

```powershell
.\utilities\MasterWebEnrichment.ps1 -RateLimit 3
```

### Partial Completion

Script saves progress every 50 items. Re-run to resume:

```powershell
# Resumes from where it left off
.\utilities\EnrichMissingPetFamilies.ps1
```

---

## Future Enhancements

Potential additions to the enrichment system:

- [ ] Creature combat stats (armor, damage, health, speed)
- [ ] Drop rates from community data
- [ ] Alternative sources (vendor prices, quest rewards)
- [ ] Item rarity and quality metadata
- [ ] Profession requirements for crafted items

---

## Maintenance

**When to Re-run:**

- After major game patches/updates
- When new items are added to the game
- If descriptions or zone data changes
- Cache expired (default 7 days)

**Validation:**

After enrichment, check coverage:

```powershell
# Check pet family coverage
$db = Get-Content "AscensionVanity\VanityDB.lua" -Raw
$withFamily = ([regex]::Matches($db, 'petFamily\s*=\s*\{')).Count
$total = ([regex]::Matches($db, '"Beastmaster''s Whistle"')).Count
Write-Host "Coverage: $withFamily / $total ($([math]::Round($withFamily/$total*100,1))%)"
```

---

## Migration Notes

**For users upgrading from multi-script workflow:**

Old workflow files can be kept as fallbacks, but the master script is now preferred:

```powershell
# Old (still works)
.\utilities\ScrapePetFamilies.ps1
.\utilities\EnrichMissingPetFamilies.ps1
.\utilities\MasterDescriptionEnrichment.ps1
.\utilities\EnrichZoneData.ps1

# New (recommended)
.\utilities\MasterWebEnrichment.ps1
```

The master script calls individual scripts internally, so no functionality is lost.
