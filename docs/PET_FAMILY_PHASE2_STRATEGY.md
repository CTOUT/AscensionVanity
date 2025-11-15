# Pet Family Enrichment - Phase 2 Strategy

**Date:** November 15, 2025  
**Status:** Enhanced with tooltip species extraction and skills database scraping

## Phase 1 Results (Current)

- **Total Combat Pets:** 2,355
- **With Family Data:** 2,278 (96.7%)
- **Missing:** 77 (3.3%)

## Phase 2 Discoveries

### 1. Hidden Pet Families in Skills Database

**Source:** https://db.ascension.gg/?skills#0+2+1

- **392 "Pet - " skills** exist (e.g., "Pet - Dreadwood Treant")
- These families do NOT appear in the tameable pets list (?pets)
- Each skill links to abilities (e.g., https://db.ascension.gg/?skill=1038)

**Example:**
- **Ironwood Stomper** → Family: "Dreadwood Treant" (not in tameable list)
- Skill ID: 1038
- Has abilities but no tameable creatures

### 2. Species in Item Tooltips

**Discovery:** Combat pet item tooltips contain the species name!

**Example Pattern:**
```html
<b class="q6">Summoner's Stone: Prince Malchezaar</b><br />
<span class="q2">Man'ari Eredar</span><br />
Binds when used
```

**Confirmed Examples:**
- **Prince Malchezaar** (138255) → "Man'ari Eredar" (Demon family)
- **Aflicted Treemouth** (97743) → Likely "Ancient Protector" (Elemental family)

### 3. Spell Database Links

Some items without direct family data link to spells:
- **spell=944444** for Afflicted Treemouth
- Could scrape spell tooltips as fallback

## Enhanced Enrichment Strategy

### Three-Tier Lookup System

**Tier 1: Pet Family Listview (Existing)**
- Source: Item page → `new Listview({"template":"pet","id":"pet-family"...`
- Provides: familyId, familyName, familyType, icon, abilities, isExotic
- Coverage: ~96% (2,278 / 2,355 items)

**Tier 2: Item Tooltip Species (NEW)**
- Source: Item page → `<span class=\"q2\">SPECIES</span>`
- Provides: familyName (species), heuristic familyType
- Coverage: Expected +50-70 items
- Status: ✅ Implemented in EnrichMissingPetFamilies.ps1

**Tier 3: Skills Database Families (NEW)**
- Source: Skills page → 392 "Pet - " entries
- Provides: familyName, abilities, heuristic familyType
- Coverage: Fills gaps for non-tameable sources
- Status: ✅ Script created: ScrapePetSkills.ps1

### Heuristic Family Type Mapping

Since skills and tooltips don't provide explicit types, use pattern matching:

```powershell
if ($name -match 'Demon|Doomguard|Fel|Satyr|Eredar|Shivarra') { "Demon" }
elseif ($name -match 'Undead|Skeleton|Ghoul|Zombie') { "Undead" }
elseif ($name -match 'Elemental|Revenant|Golem|Treant') { "Elemental" }
elseif ($name -match 'Dragon|Drake|Whelp|Wyrm') { "Dragonkin" }
else { "Unknown" }
```

## Implementation Status

### ✅ Completed

1. **Enhanced EnrichMissingPetFamilies.ps1**
   - Strategy 1: Pet family listview (existing)
   - Strategy 2: Tooltip species extraction (NEW)
   - Strategy 3: Spell link detection (noted for future)
   - Heuristic type mapping added

2. **Created ScrapePetSkills.ps1**
   - Scrapes 392 "Pet - " skills
   - Extracts abilities for each family
   - Maps to family types heuristically
   - Output: `data/PetSkillsMapping.json`

### 🔄 Next Steps

1. **Run Enhanced Enrichment**
   ```powershell
   cd "D:\Repos\World of Warcraft\AscensionVanity"
   .\utilities\EnrichMissingPetFamilies.ps1
   ```
   - Expected: +50-70 items via tooltip species
   - Missing items CSV will shrink to ~7-27 items

2. **Scrape Pet Skills Database**
   ```powershell
   .\utilities\ScrapePetSkills.ps1
   ```
   - Expected: 392 pet families (many duplicates with existing)
   - Identify unique families not in PetFamilyMapping.json

3. **Merge and Validate**
   - Compare PetSkillsMapping.json vs PetFamilyMapping.json
   - Find families in skills but not in tameable list
   - Create master family lookup

4. **Regenerate Database**
   ```powershell
   .\utilities\GenerateVanityDB_Master.ps1
   ```
   - Merge all three sources
   - Fallback order: Listview → Tooltip → Skills

## Expected Final Coverage

**Optimistic:** 99.5% (2,343 / 2,355)
- Tier 1 (Listview): 2,278 items
- Tier 2 (Tooltip): +60 items
- Tier 3 (Skills): +5 items (fill remaining gaps)
- Truly missing: ~12 items (vendor purchases, seasonal rewards without data)

**Conservative:** 98.5% (2,320 / 2,355)
- Some items may lack data in all three sources
- Vendor/seasonal items may need manual mapping

## Manual Verification Needed

For items still missing after all three tiers:
1. **In-game creature preview** (confirm creature type visually)
2. **Community knowledge** (Discord, forums)
3. **Manual mapping** to closest known family

---

## Key Files

| File | Purpose |
|------|---------|
| `ScrapePetFamilies.ps1` | Tameable families (155 families, 9,292 creatures) |
| `ScrapePetSkills.ps1` | Skills database (392 "Pet - " families) |
| `EnrichMissingPetFamilies.ps1` | Three-tier enrichment (listview → tooltip → skills) |
| `PetFamilyMapping.json` | Tameable families data |
| `PetSkillsMapping.json` | Skills families data (NEW) |
| `MissingPetFamilies_Enriched.json` | Enriched items (will expand) |
| `MissingPetFamilies_NoData.csv` | Truly missing items (will shrink) |

## Community Contribution Potential

This multi-source enrichment system creates the most comprehensive Ascension pet family database:
- 155 tameable families
- 392 skill families
- 2,355 combat pets mapped
- Abilities and icons included

Could be shared as a community resource on:
- Ascension Discord
- Ascension Forums
- GitHub as standalone JSON dataset
