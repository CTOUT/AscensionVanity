# API Validation Guide

**Purpose**: Validate and improve the AscensionVanity database using the official Ascension API as the source of truth.

**Goal**: Find missing items, fix incorrect mappings, and ensure our database matches the game's actual data.

---

## Overview

The Ascension game client has a built-in API (`C_VanityCollection`) that provides the complete, authoritative list of all vanity items and their drop sources. We can use this to:

1. **Find Missing Items** - Discover items in the API that aren't in our database
2. **Fix Incorrect Mappings** - Identify where we have wrong creature-to-item mappings
3. **Validate Data Quality** - Ensure our web scraping didn't introduce errors

---

## Step-by-Step Process

### Phase 1: Extract API Data

**In-Game Steps:**

1. Log into your character in Project Ascension
2. Open the chat window
3. Type: `/av apidump`
4. Wait for the dump to complete (you'll see progress messages)
5. Type: `/reload` to save the data to disk

**What This Does:**
- Extracts ALL vanity items from `C_VanityCollection.GetAllItems()`
- Organizes data by:
  - Item ID → Full item data
  - Creature ID → List of items that drop from it
  - Category → Item counts
- Saves everything to `SavedVariables/AscensionVanity.lua`

**Expected Output:**
```
Total items processed: 2000+
Items with creature sources: 1800+
Categories found:
  Beastmaster's Whistle: 600+ items
  Blood Soaked Vellum: 400+ items
  Summoner's Stone: 300+ items
  Draconic Warhorn: 300+ items
  Elemental Lodestone: 400+ items
```

---

### Phase 2: Validate Against Our Database

**In-Game Steps:**

1. After running `/av apidump` and `/reload`
2. Type: `/av validate`
3. Review the validation report

**What This Does:**
- Compares the API dump with our static database (`VanityDB.lua`)
- Identifies:
  - **Matches**: Creature IDs that have the correct item mapping
  - **API Only**: Items in the API but missing from our database (the 144 missing items!)
  - **Mismatches**: Creatures where we have a different item than the API shows

**Expected Output:**
```
=== DATABASE VALIDATION ===
API items: 2000+
Database items: 1857
Exact matches: 1700+
In API only: 144 (THESE ARE THE MISSING ITEMS!)
Mismatches: 13 (THESE ARE ERRORS IN OUR DATABASE!)
```

**Sample Missing Items:**
```
Items in API but missing from database:
  [18285] Item 80533: Beastmaster's Whistle: "Count" Ungula
  [3425] Item 79626: Beastmaster's Whistle: Savannah Prowler
  ...
```

**Sample Mismatches:**
```
Items with different mappings:
  Creature 12345: API has item 79999, DB has item 80000
    API name: Beastmaster's Whistle: Correct Name
```

---

### Phase 3: Analyze the Exported Data

**PowerShell Steps:**

1. Open PowerShell in the repository directory
2. Run: `.\utilities\AnalyzeAPIDump.ps1`
3. For detailed reports: `.\utilities\AnalyzeAPIDump.ps1 -Detailed`

**Path Auto-Detection:**
The script will automatically detect your SavedVariables path using:
1. `local.config.ps1` (if configured)
2. Windows Registry (WoW installation path)
3. Automatic search in detected WoW installation

**Manual Path (if needed):**
```powershell
.\utilities\AnalyzeAPIDump.ps1 -SavedVariablesPath "<YOUR_PATH>\AscensionVanity.lua"
```

**What This Does:**
- Reads the SavedVariables file
- Extracts validation statistics
- Generates summary reports
- Creates exportable data files for further analysis

**Output:**
```
═══════════════════════════════════════════
  Validation Summary
═══════════════════════════════════════════
  API Total Items:        2000
  Database Total Items:   1857
  Exact Matches:          1700
  Difference:             143

  → API has 143 more items than our database
    These might be the missing 144 items!
```

**With `-Detailed` flag:**
- Creates `API_Analysis/APIDump_Raw_[timestamp].lua` - Full API data export
- Creates `API_Analysis/Analysis_Report_[timestamp].md` - Markdown summary report

---

## Phase 4: Extract Missing Items from SavedVariables

**Manual Analysis Steps:**

1. Navigate to: `WTF\Account\[YourAccount]\SavedVariables\AscensionVanity.lua`
2. Open the file in a text editor (VS Code recommended)
3. Find the `APIDump` section
4. Find the `ValidationResults` section
5. Look for `apiOnly = {` - this contains the missing items!

**Example Structure:**
```lua
AscensionVanityDB = {
    APIDump = {
        timestamp = "2025-10-27 14:30:00",
        totalItems = 2000,
        items = {
            [79626] = {
                itemId = 79626,
                name = "Beastmaster's Whistle: Savannah Prowler",
                creaturePreview = 3425,
                rawData = { ... }
            },
            -- ... 2000+ more items
        },
        itemsByCreature = {
            [3425] = { 79626 },  -- Creature ID → Item IDs
            -- ... more mappings
        }
    },
    ValidationResults = {
        apiOnly = {
            {
                creatureID = 3425,
                itemID = 79626,
                name = "Beastmaster's Whistle: Savannah Prowler"
            },
            -- ... 144 more missing items
        },
        mismatches = {
            -- Items where our DB has wrong mapping
        }
    }
}
```

---

## Phase 5: Update the Database

**PowerShell Script (To Be Created):**

We'll create `.\utilities\UpdateDatabaseFromAPI.ps1` that:

1. Reads the SavedVariables file
2. Extracts all validated creature → item mappings
3. Compares with current `VanityDB.lua`
4. Generates a new `VanityDB.lua` with:
   - All missing items added
   - All mismatches corrected
   - Duplicate entries removed
   - Sorted by creature ID for easy lookup

**Manual Alternative:**

For now, you can manually add missing items to `VanityDB.lua`:

```lua
AV_VanityItems = {
    -- Add missing items from ValidationResults.apiOnly
    [3425] = 79626, -- Beastmaster's Whistle: Savannah Prowler
    [18285] = 80533, -- Beastmaster's Whistle: "Count" Ungula
    -- ... etc
}
```

---

## Troubleshooting

### "C_VanityCollection not available"
- You're not logged into Project Ascension
- The API was renamed or moved (check with `/av api`)

### "No API dump found"
- You haven't run `/av apidump` yet
- You forgot to `/reload` after running the dump
- The SavedVariables folder doesn't exist (enable addon first)

### "SavedVariables file not found" (PowerShell script)
- The script will auto-detect your path using registry or `local.config.ps1`
- If auto-detection fails, specify manually: `-SavedVariablesPath "<YOUR_PATH>"`
- Make sure you ran `/av apidump` and `/reload` in-game first

### Validation shows 0 matches
- Run `/av apidump` again
- Make sure you `/reload` after the dump
- Check that `VanityDB.lua` is loaded (type `/av debug` and check for database)

---

## Expected Results

After completing this process, you should:

1. **Identify the 144 missing items** from the `apiOnly` list
2. **Fix any incorrect mappings** from the `mismatches` list
3. **Have a complete, API-validated database** ready for v2.1 release
4. **Understand data quality issues** inherited from db.ascension.gg

---

## Next Steps

1. Run the full validation process in-game
2. Extract the missing items from SavedVariables
3. Create a script to auto-generate updated `VanityDB.lua`
4. Test the updated database in-game
5. Release v2.1 with complete coverage!

---

## Files Modified/Created

- **Core.lua** - Added `/av apidump` and `/av validate` commands
- **AnalyzeAPIDump.ps1** - PowerShell analysis tool
- **SavedVariables/AscensionVanity.lua** - Contains API dump and validation results
- **API_Analysis/** - Exported reports and data files

---

*Last Updated: October 27, 2025*
