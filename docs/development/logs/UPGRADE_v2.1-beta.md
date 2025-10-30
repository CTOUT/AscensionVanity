# AscensionVanity v2.1-beta - Upgrade Instructions

## ⚠️ IMPORTANT: Clean Installation Required

**This release requires deleting your old addon files before installing.**

---

## Why Clean Installation?

World of Warcraft does **not** automatically delete old files when you update addons. This release adds critical new files:

- ✅ **NEW:** `SettingsUI.lua` - Standalone Settings UI (required)
- ✅ **NEW:** Test plans and documentation

Without a clean installation, the old file structure will conflict with the new UI system.

---

## Upgrade Instructions

### Step 1: Backup Your Settings (Optional)

Your settings are stored in `SavedVariables` and will **NOT** be deleted:

```
WTF\Account\<account-name>\SavedVariables\AscensionVanity.lua
```

These settings will automatically load after upgrading. No backup needed unless you want extra safety.

### Step 2: Delete Old Addon Files

**Navigate to your AddOns folder:**

```
World of Warcraft\_retail_\Interface\AddOns\
```

**Delete the entire AscensionVanity folder:**

```
📁 AddOns\
  └─ 🗑️ AscensionVanity\  ← DELETE THIS ENTIRE FOLDER
```

### Step 3: Install New Version

**Extract the new version:**

1. Download AscensionVanity-v2.1-beta.zip
2. Extract the `AscensionVanity` folder to `Interface\AddOns\`
3. Verify the folder structure:

```
📁 AddOns\
  └─ 📁 AscensionVanity\
      ├─ AscensionVanity.toc (Version: 2.1-beta)
      ├─ Core.lua
      ├─ SettingsUI.lua       ← NEW FILE
      ├─ ScannerUI.lua
      ├─ VanityDB.lua
      └─ ... (other files)
```

### Step 4: Restart WoW

- **If WoW is running:** Type `/reload` or restart the game
- **If WoW is closed:** Start the game normally

### Step 5: Verify Installation

**Check addon loaded:**

```
/avanity help
```

**Expected output:** Help text with all commands listed

**Open new UIs:**

```
/avanity          → Opens Settings UI
/avanity scanner  → Opens Scanner UI
```

**Check Interface Options:**

```
ESC → Interface → AddOns → Look for "AscensionVanity"
```

---

## What's New in v2.1-beta?

### Modern UI System

**Settings UI** (`/avanity`)
- Standalone frame with professional DialogBox styling
- Configure tooltip display, learned status, color coding
- Quick access to Scanner UI
- Automatic save on change

**Scanner UI** (`/avanity scanner`)
- Developer tools for API scanning
- Debug mode toggle
- Complete instructions and command reference
- Enhanced layout (no more cutoff content)

**Interface Options Integration**
- Clean launcher panel in addon list
- Quick access to both Settings and Scanner
- Appears as "AscensionVanity" in alphabetical order

### Enhanced Features

- **Mutual Exclusion:** Only one UI open at a time (no overlap)
- **Real-Time Sync:** Slash commands update UI checkboxes immediately
- **Draggable Frames:** Move UIs anywhere on screen
- **ESC Key Support:** Close UIs with ESC key
- **Proper Frame Strata:** UIs always render above game world

### Testing & Documentation

- Comprehensive UI test plan (300+ test cases)
- Testing options guide for WoW addons
- Quick test checklist for rapid validation
- Updated README with complete UI documentation

---

## Troubleshooting

### Issue: "SettingsUI.lua not found" Error

**Cause:** Old addon files not deleted before upgrading

**Solution:**
1. Delete entire AscensionVanity folder
2. Extract fresh copy
3. `/reload` or restart WoW

### Issue: Settings UI Doesn't Open

**Solution:**
1. Check for Lua errors (enable Lua errors in settings)
2. Verify SettingsUI.lua exists in addon folder
3. Check TOC file shows Version: 2.1-beta
4. Try `/reload` to reload all addons

### Issue: Old UI Still Showing

**Cause:** Cached UI files from previous version

**Solution:**
1. Delete WoW cache: `Cache\` folder
2. Delete AscensionVanity folder completely
3. Reinstall fresh copy
4. Restart WoW (not just `/reload`)

### Issue: Settings Not Saved

**Check SavedVariables:**

```
WTF\Account\<account-name>\SavedVariables\AscensionVanity.lua
```

This file should contain:

```lua
AscensionVanityDB = {
    ["enabled"] = true,
    ["colorCode"] = true,
    ["showLearnedStatus"] = true,
    ["debug"] = false,
}
```

If missing or corrupted, delete it and let addon recreate defaults.

---

## Rollback Instructions

If you need to revert to v2.0.0:

1. Delete AscensionVanity folder
2. Download v2.0.0 release
3. Extract to AddOns folder
4. `/reload` or restart WoW

Your settings will remain intact.

---

## Support

**Issues?** Report on GitHub:  
https://github.com/CTOUT/AscensionVanity/issues

**Questions?** Check documentation:
- README.md - Complete feature guide
- UI_TEST_PLAN.md - Testing guide
- TESTING_OPTIONS.md - Testing strategy

---

## Release Files

**Required:**
- `AscensionVanity-v2.1-beta.zip` - Complete addon (install this)

**Optional:**
- Source code - For developers
- Test plans - For testing/validation

---

## Post-Installation Checklist

After upgrading, verify everything works:

- [ ] `/avanity help` shows all commands
- [ ] `/avanity` opens Settings UI
- [ ] `/avanity scanner` opens Scanner UI
- [ ] Interface Options shows AscensionVanity launcher
- [ ] Creature tooltips show vanity items
- [ ] Settings persist after `/reload`
- [ ] No Lua errors

**All checked?** You're good to go! 🎉

---

## What's Next?

**v2.1 Stable Release:**
- Additional testing and feedback
- Bug fixes if any found
- Final polish and optimization

**Future Plans:**
- Region information display (Coming Soon feature)
- Enhanced learned status detection
- Performance optimizations
- More comprehensive data validation

---

**Thank you for using AscensionVanity!**

**Version:** 2.1-beta  
**Release Date:** October 29, 2025  
**Branch:** v2.0-dev  
**Commit:** c41a91f
