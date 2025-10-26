# Database Extraction Guide

## Overview

This guide explains the intelligent extraction process for AscensionVanity database with built-in validation to ensure data quality.

---

## Vanity Item Categories

Project Ascension organizes vanity items into **5 main categories**:

| Category | URL | Description |
|----------|-----|-------------|
| **Beastmaster's Whistle** | `https://db.ascension.gg/?items=101.1` | Beast companions |
| **Blood Soaked Vellum** | `https://db.ascension.gg/?items=101.2` | Undead companions |
| **Summoner's Stones** | `https://db.ascension.gg/?items=101.3` | Demon companions |
| **Draconic Warhorns** | `https://db.ascension.gg/?items=101.4` | Dragonkin companions |
| **Elemental Lodestones** | `https://db.ascension.gg/?items=101.5` | Elemental companions |

---

## Data Quality Rules

### ✅ Include These Items

**1. Specific Creature Sources**

Items with a **specific NPC name** as the source:
- Example: `Beastmaster's Whistle: Savannah Patriarch` dropped by `Savannah Patriarch`
- These become **specific creature entries** in `AV_VanityItems`

**2. Generic "Drop" Sources (with validation)**

Items with source showing `"Drop"`:
- Click the item link
- Navigate to **"Dropped by"** tab
- Verify NPC names **match** the item name
- Only include NPCs whose names match the expected creature

### ❌ Exclude These Items

**1. Database Errors**

NPCs that **don't match** the expected creature name:
- Example: `Beastmaster's Whistle: Savannah Prowler` showing `Felstalker` as drop source
- `Felstalker` ≠ `Savannah Prowler` → **SKIP**

**2. Quest Rewards, Vendors, etc.**

Items with sources other than creature drops:
- Quest rewards
- Vendor purchases  
- Crafted items
- Achievement rewards

---

## Validation Logic

### Name Matching Algorithm

The extraction script uses intelligent name matching:

```
Expected creature: "Savannah Prowler"
NPC candidates:
  - "Savannah Prowler" → ✓ EXACT MATCH
  - "Elder Savannah Prowler" → ✓ PARTIAL MATCH (contains "Savannah Prowler")
  - "Felstalker" → ✗ NO MATCH (different creature)
```

**Matching Rules**:
1. **Exact match**: NPC name equals expected creature name
2. **Word match**: At least 50% of words overlap
   - "Savannah Prowler" vs "Elder Savannah Prowler" = 2/2 words match = ✓
   - "Savannah Prowler" vs "Felstalker" = 0/2 words match = ✗

---

## Extraction Examples

### Example 1: Specific Creature Drop

**Item**: `Beastmaster's Whistle: Savannah Patriarch`  
**Source**: `Savannah Patriarch (NPC ID: 3241)`

**Result**: Added to `AV_VanityItems`
```lua
["Savannah Patriarch"] = {
    itemID = 79625,
    itemName = "Beastmaster's Whistle: Savannah Patriarch",
    type = "Beast",
    npcID = 3241
}
```

### Example 2: Generic Drop (Valid)

**Item**: `Beastmaster's Whistle: Savannah Prowler`  
**Source**: `Drop`

**Dropped by tab shows**:
- ✓ `Savannah Prowler (NPC ID: 3425)` - **VALID** (name matches)
- ✗ `Felstalker (NPC ID: 5278)` - **INVALID** (name doesn't match)

**Result**: Only Savannah Prowler added
```lua
["Savannah Prowler"] = {
    itemID = 79626,
    itemName = "Beastmaster's Whistle: Savannah Prowler",
    type = "Beast",
    npcID = 3425
}
```

### Example 3: Multiple Valid NPCs

**Item**: `Summoner's Stone: Terrorfiend`  
**Source**: `Drop`

**Dropped by tab shows**:
- ✓ `Terrorfiend (Multiple spawns)`
- ✓ `Elder Terrorfiend`
- ✓ `Raging Terrorfiend`

All NPCs contain "Terrorfiend" → **Multiple matches**

**Result**: Treated as generic drop by creature type
```lua
AV_GenericDropsByType["Demon"] = {
    "Summoner's Stone: Terrorfiend",
    ...
}
```

---

## Automated Extraction Process

### PowerShell Script Flow

```
1. For each category (101.1 - 101.5):
   ├─ Fetch category page
   ├─ Extract all item links
   └─ For each item:
      ├─ Extract expected creature name from item name
      ├─ Fetch item detail page
      ├─ Navigate to "Dropped by" tab
      ├─ Extract all NPC names and IDs
      ├─ Validate each NPC against expected creature
      ├─ Filter out invalid matches
      └─ Categorize:
         ├─ Single NPC → Specific creature
         └─ Multiple NPCs → Generic drop

2. Generate VanityData.lua with validated data

3. Report statistics:
   - Total items processed
   - Specific creatures found
   - Generic drops categorized
   - Invalid entries skipped
```

### Running the Script

```powershell
# Basic execution
.\ExtractDatabase.ps1

# With verbose logging
.\ExtractDatabase.ps1 -Verbose

# Review output
notepad VanityDB.lua

# Backup and replace
Copy-Item VanityData.lua VanityData.lua.backup
Move-Item VanityDB.lua VanityData.lua -Force
```

---

## Manual Extraction Process

If automated extraction fails or for spot-checking:

### Step-by-Step Manual Process

**1. Navigate to Category**
```
https://db.ascension.gg/?items=101.1
```

**2. For Each Item in List**

**Option A: Specific Source**
- If source shows specific creature name:
  - Record: Item Name, Item ID, Creature Name, NPC ID
  - Add to `AV_VanityItems` table

**Option B: "Drop" Source**
1. Click item link (e.g., `https://db.ascension.gg/?item=79626`)
2. Click **"Dropped by"** tab
3. Review NPC list:
   - For each NPC, check if name contains expected creature
   - Extract creature name from item name
   - Compare NPC name to expected creature
4. Record only **matching NPCs**
5. Categorize:
   - **1 match** → Specific creature entry
   - **2+ matches** → Generic drop entry

**3. Format Data**

Specific creature:
```lua
["Creature Name"] = {
    itemID = 12345,
    itemName = "Full Item Name",
    type = "CreatureType",
    npcID = 67890
}
```

Generic drop:
```lua
AV_GenericDropsByType["CreatureType"] = {
    "Item Name 1",
    "Item Name 2",
}
```

---

## Validation Checklist

Before finalizing extracted data:

### Data Quality Checks

- [ ] All item names follow pattern: `"Category: Creature Name"`
- [ ] NPC names match expected creature names
- [ ] No obvious database errors included (mismatched names)
- [ ] Item IDs are numeric (not `nil`)
- [ ] Creature types are consistent
- [ ] Generic drops don't duplicate specific creatures

### Coverage Checks

- [ ] All 5 categories processed (101.1 - 101.5)
- [ ] Item counts match expected totals
- [ ] No major gaps in creature types
- [ ] Both specific and generic drops included

### Technical Checks

- [ ] Lua syntax is valid (no missing commas, brackets)
- [ ] Hash table keys are properly quoted
- [ ] No duplicate entries
- [ ] File encoding is UTF-8

---

## Database Structure

### AV_VanityItems (Specific Creatures)

```lua
AV_VanityItems = {
    -- Key: Exact creature name that drops the item
    ["Creature Name"] = {
        itemID = 12345,           -- Numeric item ID from database
        itemName = "Full Name",   -- Complete item name with category prefix
        type = "CreatureType",    -- Creature classification
        npcID = 67890            -- NPC ID for validation
    },
}
```

### AV_GenericDropsByType (Type-Based Drops)

```lua
AV_GenericDropsByType = {
    -- Key: Creature type (Beast, Demon, Undead, etc.)
    ["CreatureType"] = {
        "Item Name 1",
        "Item Name 2",
        -- Items that drop from multiple NPCs of this type
    },
}
```

---

## Troubleshooting

### Common Issues

**Issue**: Script fails with "Invalid URL"
- **Solution**: Check internet connection, verify database is accessible

**Issue**: No items extracted
- **Solution**: HTML structure may have changed, review parsing patterns

**Issue**: Too many items skipped
- **Solution**: Check validation logic, may be too strict

**Issue**: Duplicate creatures in database
- **Solution**: Review for items with multiple sources, ensure proper categorization

### Debug Commands

```powershell
# Test single category
$items = Get-VanityItemsFromPage -categoryUrl "https://db.ascension.gg/?items=101.1" -categoryName "Beastmaster's Whistle"

# Test single item
Process-VanityItem -item @{ID="79625"; Name="Beastmaster's Whistle: Savannah Patriarch"; URL="https://db.ascension.gg/?item=79625"} -categoryName "Beastmaster's Whistle"

# Check validation logic
Test-NPCMatchesItem -npcName "Savannah Prowler" -expectedName "Savannah Prowler"
Test-NPCMatchesItem -npcName "Felstalker" -expectedName "Savannah Prowler"
```

---

## Performance Considerations

### Extraction Speed

- **Categories**: 5 total
- **Estimated items**: 400-600 per category (2000-3000 total)
- **Network requests**: 
  - 5 category pages
  - ~2500 item detail pages
  - ~500ms delay between requests
- **Total time**: 20-40 minutes

### Server-Friendly Practices

- 300-500ms delay between requests
- Graceful error handling
- Progress reporting
- Resumable on failure (TODO: implement checkpoint system)

---

## Future Enhancements

### Planned Features

1. **Checkpoint System**
   - Save progress after each category
   - Resume from last checkpoint on failure

2. **Creature Type Detection**
   - Fetch NPC pages to determine creature type
   - More accurate type classification

3. **Parallel Processing**
   - Process multiple categories simultaneously
   - Reduce total extraction time

4. **Data Export Options**
   - Generate CSV for analysis
   - Create backup formats (JSON, XML)

5. **Incremental Updates**
   - Detect new items since last extraction
   - Update only changed entries

---

## Summary

The intelligent extraction system ensures high-quality data by:

✅ **Validating** NPC names match expected creatures  
✅ **Filtering** database errors and mismatches  
✅ **Categorizing** specific vs generic drops automatically  
✅ **Reporting** detailed statistics and warnings  
✅ **Generating** clean, validated Lua database code

**Result**: Production-ready database with minimal manual correction needed!
