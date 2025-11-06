# Quick Testing Guide - November 6, 2025

## 🎯 In-Game Testing Commands

### Find Test NPCs
```lua
-- Open Database Browser (filter by current zone)
/av browser

-- Search for specific creature
/av browser search "Crazed Dragonhawk"

-- Check creature under mouse
/dump UnitName("mouseover")
/dump UnitGUID("mouseover")
```

### Check Addon Status
```lua
-- Reload UI after changes
/reload

-- Check addon loaded
/av help

-- Toggle debug mode
/av debug

-- Check settings
/av
```

## 📍 Easy Test Locations

### Starting Zones (Low-Level, Easy Access)

**Eversong Woods (Blood Elf starting zone)**
- Crazed Dragonhawk (ID 15650) - CONFIRMED FIXED (was 4015650)
- Springpaw Lynx
- Location: Near Sunstrider Isle

**Ghostlands**
- Mistbat (ID 16353) - CONFIRMED FIXED (was 4016353)
- Location: Throughout zone

**Tirisfal Glades (Undead starting zone)**
- Fellicent's Shade - CONFIRMED FIXED (added Tirisfal Glades zone)
- Various low-level creatures

### Multiple Items Test Cases
Look for creatures in database browser that show multiple drops

### Quest-Locked Test Cases
- Hand of Iruxos quest - Desolace (Horde only)
- Supplies to Auberdine - Darkshore (Alliance only)
- Challenge to the Black Flight - Dustwallow Marsh

## 🔍 What to Check

### ✅ Confirmed Working
- [x] Player companion pets don't show tooltips
- [x] Wild NPCs show tooltips correctly

### 🧪 Still Need Testing
- [ ] Multiple items per creature (overlap check)
- [ ] Quest warning display (spacing/formatting)
- [ ] Long item names (text wrapping)
- [ ] Tooltip positioning near screen edges
- [ ] Status icons (checkmark/cross) alignment

## 📊 Testing Checklist

### Visual Issues to Look For:
1. **Icon Overlap** - Do status icons (✓/✗) overlap with item icons?
2. **Text Spacing** - Is indentation consistent and readable?
3. **Quest Warnings** - Are quest warnings too tall/verbose?
4. **Tooltip Height** - Do tooltips exceed screen height?
5. **Color Coding** - Are colors distinct and readable?

### Take Screenshots Of:
- [ ] NPC with 2+ items (check spacing between items)
- [ ] Quest-locked NPC (check warning formatting)
- [ ] Learned vs unlearned items (check status icons)
- [ ] Tooltip near screen edge (check positioning)
- [ ] Any visual glitches or overlaps

## 🎨 UI Elements to Verify

### Header
- "Vanity Items:" in bright aqua color
- Clear separator line above

### Item Entry Format
```
[Status Icon] [Item Category Icon] Item Name
      Item ID: 12345 (if enabled)
      Location: Zone Name (if enabled)
      [Quest Warning] (if quest-locked)
```

### Expected Indentation
- Item name: 3 spaces (with status icon)
- Sub-info: 6 spaces (ID, location, quest)

### Status Icons
- ✓ Green checkmark = Learned
- ✗ Red cross = Unlearned
- No icon = Status unknown

### Quest Warning Colors
- 🔴 RED = Quest completed (too late!)
- 🟠 ORANGE = Quest not started (warning)
- 🟢 GREEN = Quest active (farm now!)

## 💡 Quick Fixes for Common Issues

### Tooltip Too Tall
- Disable Item IDs: `/av` → uncheck "Show Item IDs"
- Disable Regions: `/av` → uncheck "Show Regions"

### Text Overlap
- Try different resolution/UI scale
- Report specific creature name for fix

### Performance Issues
- Disable debug mode: `/av debug`
- Check addon memory: `/run UpdateAddOnMemoryUsage() print(GetAddOnMemoryUsage("AscensionVanity"))`

---

**Next Steps:**
1. Test multiple-item NPCs
2. Test quest-locked NPCs
3. Report any visual issues
4. Apply UI improvements based on findings
