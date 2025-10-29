# In-Game Testing Guide - Learned Status Detection

## Current Status

✅ **Syntax Fixes**: All 3 items with quoted names are fixed and deployed
🧪 **Ready to Test**: API ownership detection for learned vanity items

---

## What We're Testing

The addon uses `C_VanityCollection.IsCollectionItemOwned(itemID)` API to detect if your character has already learned a vanity item. We need to verify this is working correctly.

---

## Prerequisites

1. **Addon Deployed**: You ran `.\DeployAddon.ps1` successfully
2. **In-Game Character**: You have a character with some learned vanity items
3. **Test Creatures**: Know at least one creature that drops a vanity item you **already own**

---

## Testing Procedure

### Step 1: Launch Game and Check Startup Messages

When you log in, you should see these messages in chat:

```
AscensionVanity v2.0.0 loaded!
Type /av help for commands
AscensionVanity: C_VanityCollection API detected ✓
```

**⚠️ If you see**: `C_VanityCollection API not available (learned status disabled)`
- This means the API doesn't exist on Ascension
- We'll need to investigate alternative detection methods

**✅ Expected**: You should see the "API detected ✓" message

---

### Step 2: Enable Debug Mode

Type in chat:
```
/av debug
```

You should see:
```
Debug mode enabled
```

---

### Step 3: Test on a Learned Vanity Item

**Find a creature** that drops a vanity item you **already have learned**.

**How to find one**:
1. Open your Vanity Collection (default: `Shift+P`)
2. Look for a pet/mount you already own
3. Find that creature in the world

**Target the creature** and hover over it (or use `/target CreatureName`)

---

### Step 4: Check Tooltip Output

When you hover over the creature, the tooltip should show:

```
[Creature Name]
Level XX Creature Type

🐾 Beastmaster's Whistle: [Item Name]
   Status: ✓ Learned
   Source: Drops from this creature in [Zone Name]
```

**AND** in chat, you should see debug output like:
```
[AV Debug] Item 2341 ( Beastmaster's Whistle: Count Ungula ) owned status: true
```

---

### Step 5: Test on an Unlearned Item

**Find a creature** that drops a vanity item you **DON'T have yet**.

**Target the creature** and check the tooltip:

```
[Creature Name]
Level XX Creature Type

🐾 Beastmaster's Whistle: [Item Name]
   Status: Not learned
   Source: Drops from this creature in [Zone Name]
```

**AND** in chat:
```
[AV Debug] Item 2342 ( Beastmaster's Whistle: Vicious Teromoth ) owned status: false
```

---

## What to Report Back

### ✅ If Working Correctly

Report:
- "API detected ✓" message appeared at login
- Debug messages show `owned status: true` for learned items
- Debug messages show `owned status: false` for unlearned items
- Tooltip correctly displays "✓ Learned" vs "Not learned"

**Result**: Issue is FIXED! 🎉

---

### ❌ If API Detected but Status Wrong

Report:
- "API detected ✓" message appeared
- BUT debug messages show **incorrect** owned status
- Example: You own the item, but debug says `owned status: false`

**Provide**:
```
1. Your character name
2. Item you tested (itemID from debug message)
3. Whether you actually own it (check Vanity Collection)
4. What the debug message said (owned status: true/false)
```

**Next Steps**: We'll investigate the API parameters or check if there's a character-specific issue

---

### ❌ If API Not Detected

Report:
- Saw message: "C_VanityCollection API not available"

**Next Steps**: We'll need to:
1. Research alternative APIs
2. Check if the API exists under a different namespace
3. Consider using saved variables to track learned items

---

### ❌ If No Debug Messages

Report:
- "API detected ✓" appeared
- Enabled debug mode
- BUT no debug messages when hovering over creatures

**Provide**:
```
1. Screenshot of tooltip
2. Creature name you targeted
3. Your /av config output
```

**Next Steps**: We'll check if the tooltip hook is working correctly

---

## Quick Test Examples

### Known Test Creatures (if available on Ascension)

These are common low-level areas for quick testing:

**Zangarmarsh (Outland)**:
- "Count" Ungula - Drops Beastmaster's Whistle (Item 2341)

**Check your quest log or Vanity Collection for creatures you can easily reach!**

---

## Additional Debug Commands

```
/av help          - Show all commands
/av debug         - Toggle debug mode on/off
/av config        - Show current configuration
/av version       - Show addon version
```

---

## What We're Looking For

The key diagnostic information:

1. **API Availability**: Does `C_VanityCollection.IsCollectionItemOwned` exist?
2. **API Accuracy**: Does it return correct true/false for owned items?
3. **Item ID Matching**: Is the itemID we're passing to the API correct?

---

## Common Issues & Solutions

### Issue: "API not available" message

**Possible Causes**:
- Ascension renamed or moved the API
- API requires specific addon or permission
- Different API on Ascension vs retail WoW

**Solution**: We'll research Ascension-specific APIs

---

### Issue: API exists but always returns false

**Possible Causes**:
- Wrong itemID format (expecting different parameter)
- Character-specific data not loaded yet
- API requires cache or collection to be opened first

**Solution**: We'll add more diagnostic logging and test API parameters

---

### Issue: Debug messages not appearing

**Possible Causes**:
- Tooltip hook not firing
- Creature not in database
- VanityDB not loading correctly

**Solution**: We'll verify database loading and hook functionality

---

## Expected Timeline

**If everything works**: 5 minutes of testing
**If issues found**: We'll iterate based on your feedback

---

## Success Criteria

- [ ] Addon loads without errors
- [ ] Startup message confirms API detected
- [ ] Debug mode shows owned status for learned items
- [ ] Debug mode shows owned status for unlearned items  
- [ ] Tooltip displays correct "✓ Learned" or "Not learned" status
- [ ] All three fixed items (2341, 2980, 2982) display proper names with quotes

---

## Notes

- **Debug mode only affects chat output**, not tooltip display
- Debug messages help us see what the API is returning
- The addon should work even without debug mode; debug just helps troubleshooting
- You can disable debug mode with `/av debug` again when done testing

---

## Ready to Test!

1. Launch the game
2. Log in and check for startup messages
3. Enable debug with `/av debug`
4. Target a creature with a vanity drop
5. Report back what you see!

Good luck! 🎮
