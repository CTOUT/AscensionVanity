# 📊 Data Model V2 - Web Scrape → API Transition

## 🔄 Field Mapping: Web Scrape → API Dump

### ❌ REMOVED Fields (Web Scrape Only)
```
creatureID   - Associated creature (REPLACED by creaturePreview)
sourcemore   - Acquisition code like "1-5.x" (REPLACED by description filtering)
```

### ✅ RETAINED Fields (Available in Both)
```
itemID       - Primary key identifier (API: itemid)
name         - Display name (API: name)
```

### ⭐ NEW Fields (API Only)
```
creaturePreview - Preview model ID (REPLACES creatureID, same purpose + 3D preview)
description     - Full text description (REPLACES sourcemore + adds region data)
icon            - Icon path (NEW capability, not available from web scrape)
```

## 📊 Net Change Summary

| Aspect | Web Scrape | API Dump | Change |
|--------|------------|----------|--------|
| **Total Fields** | 4 fields | 5 fields | +1 net |
| **Core Data** | itemID, creatureID, name | itemID, creaturePreview, name | ✓ Same |
| **Filtering** | sourcemore (implicit) | description (explicit) | ✓ Enhanced |
| **Visual** | None | icon | ⭐ NEW |
| **Region** | None | Parsed from description | ⭐ NEW |

---

## 📈 Size Impact

| Model | Per Item | Total (2,047 items) | Change |
|-------|----------|---------------------|--------|
| Web Scrape | ~51 bytes | ~104 KB | baseline |
| API Dump | ~205 bytes | ~420 KB | +304% |

**Verdict**: ✅ Acceptable trade-off for enhanced functionality

**Note**: Coverage increased from 1,857 items (web scrape) to 2,047 items (API dump) = +190 items

---

## 🎨 Feature Matrix

| Field | Feature Enabled | Priority |
|-------|----------------|----------|
| **description** | • Drop filtering<br>• Region extraction<br>• Source classification | 🔥 HIGH |
| **icon** | • Visual tooltips<br>• Icon-based grouping<br>• Actual item icons | 🔥 HIGH |
| **creaturePreview** | • Reverse lookups<br>• 3D model preview<br>• Visual validation | ⭐ MEDIUM |

---

## 🔄 Implementation Phases

### Phase 1: Core Enhancement (IMMEDIATE)
```
✓ Add description field
✓ Enable drop filtering
✓ Extract regions from descriptions
```

### Phase 2: Visual Enhancement (NEXT)
```
✓ Add icon field
✓ Display actual item icons in tooltips
✓ Implement icon-based filtering
```

### Phase 3: Advanced Features (FUTURE)
```
✓ Add creaturePreview field
✓ Build reverse lookup (creature → item)
✓ Implement 3D model preview on hover
```

---

## 💡 Use Case Examples

### 1. Smart Filtering with Description
```lua
-- Filter only dropped items
local dropped = FilterByDescription("Dropped by:")

-- Extract region
"Dropped by: Lord Kazzak in Tainted Scar, Blasted Lands"
-- Result: "Blasted Lands"
```

### 2. Visual Display with Icon
```lua
-- Show actual item icon in tooltip
GameTooltip:AddLine("|T" .. icon .. ":16|t " .. name)
-- Before: [Generic mount icon] Reins of the Tiger
-- After:  [Actual tiger icon] Reins of the Tiger
```

### 3. Reverse Lookup with creaturePreview
```lua
-- Find item from creature ID
local item = GetItemFromCreature(11021)
-- Returns: "Reins of the Winterspring Frostsaber"
```

---

## 🗂️ Data Structure Comparison

### Before (Web Scrape)
```lua
-- Simple mapping: creatureID = itemID
[18285] = 80533, -- Beastmaster's Whistle: "Count" Ungula
```

**Fields**: creatureID (key), itemID (value), name (comment only)

### After (API Dump)
```lua
-- Rich data structure with 5 pet item categories:
-- • Beastmaster's Whistles (Hunter)
-- • Blood Soaked Vellums (Death Knight)
-- • Summoner's Stones (Warlock)
-- • Draconic Warhorns (Mage)
-- • Elemental Lodestones (Shaman)

[80533] = {
    itemid = 80533,
    name = "Beastmaster's Whistle: \"Count\" Ungula",
    creaturePreview = 18285,
    description = "Has a chance to drop from \"Count\" Ungula within Zangarmarsh",
    icon = "Interface/Icons/Ability_Hunter_BeastCall"
}
```

**Fields**: itemid, name, creaturePreview, description, icon

---

## ✅ Validation Checklist

Before deployment, verify:

- [ ] All descriptions are non-empty
- [ ] All icons follow "Interface/Icons/" pattern
- [ ] creaturePreview matches creatureID (usually)
- [ ] No null/missing values in new fields
- [ ] Database version incremented
- [ ] Cache invalidation triggered

---

## 🚀 Next Actions

1. **Update ExtractDatabase.ps1**
   - Add description extraction
   - Add icon extraction
   - Add creaturePreview extraction

2. **Modify VanityDB.lua Schema**
   - Add new fields to database structure
   - Update version number

3. **Enhance Core.lua**
   - Display icons in tooltips
   - Implement filtering by description
   - Add reverse lookup functions

4. **Test & Validate**
   - Run validation queries
   - Verify all fields populated
   - Test new features in-game

---

**Status**: ✅ **APPROVED & DOCUMENTED**
**Created**: 2025-01-27
**Version**: V2 Enhanced Data Model
