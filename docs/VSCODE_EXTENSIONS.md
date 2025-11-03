# VS Code Extensions for WoW Addon Development

**Last Updated:** November 3, 2025  
**Target:** World of Warcraft WOTLK 3.3.5 (Project Ascension)

---

## 🎯 Required Extensions

Install these 4 extensions for optimal WoW addon development:

### 1. **Lua Language Server** (sumneko.lua)
```
code --install-extension sumneko.lua
```
- **Best Lua IntelliSense available**
- Type checking and diagnostics
- Function signatures
- Real-time error detection
- 1.9M installs, 4.7★ rating

### 2. **WoW API** (ketho.wow-api)
```
code --install-extension ketho.wow-api
```
- **WoW API annotations for IntelliSense**
- WOTLK 3.3.5 API documentation
- Function signatures for WoW functions
- Parameter hints
- 26K installs, 5★ rating

### 3. **WoW Bundle** (septh.wow-bundle)
```
code --install-extension septh.wow-bundle
```
- **WoW-specific toolset**
- FrameXML syntax support
- Lua snippets for WoW
- TOC file support
- Color themes
- 45K installs, 5★ rating

### 4. **WoW TOC** (stanzilla.vscode-wow-toc)
```
code --install-extension stanzilla.vscode-wow-toc
```
- **TOC file language support**
- Syntax highlighting
- Metadata snippets
- 17K installs, 5★ rating

---

## 🚀 Quick Install (All at Once)

```powershell
# Install all 4 extensions
code --install-extension sumneko.lua
code --install-extension ketho.wow-api
code --install-extension septh.wow-bundle
code --install-extension stanzilla.vscode-wow-toc
```

---

## ⚙️ Configuration

The workspace is pre-configured in `.vscode/settings.json`:

- **Lua 5.1 runtime** (WOTLK era)
- **WoW API annotations** from ketho.wow-api
- **All AscensionVanity globals** declared
- **Project Ascension APIs** (C_VanityCollection, GetClientVersion)
- **No false warnings** on WoW functions

---

## ✅ What This Fixes

### Before (Without Extensions):
- ❌ "Undefined global 'GetItemInfo'" warnings
- ❌ No IntelliSense for WoW functions
- ❌ No autocomplete for addon globals
- ❌ False positives on valid code

### After (With Extensions):
- ✅ Clean code with no false warnings
- ✅ IntelliSense for all WoW API functions
- ✅ Autocomplete for AscensionVanity globals
- ✅ Real error detection only
- ✅ Parameter hints for functions
- ✅ TOC file syntax highlighting

---

## 🎓 Using IntelliSense

### WoW API Functions
Type any WoW function and get:
```lua
GetItemInfo(itemID)  -- Shows parameters and return types
                     -- Hover for documentation
```

### Our Addon Globals
Autocomplete for all AV_ globals:
```lua
AV_Get...  -- Press Ctrl+Space for suggestions
           -- Shows: AV_GetVanityItemsForCreature, AV_GetItemData, etc.
```

### Function Signatures
Hover over any function call to see:
- Parameter names and types
- Return value types
- Documentation (if available)

---

## 🐛 Troubleshooting

### "Undefined global" warnings still appear

**Solution:** Reload VS Code window
1. Press `Ctrl+Shift+P`
2. Type "Reload Window"
3. Press Enter

### WoW API functions not recognized

**Solution:** Check WoW API extension loaded
1. Open any `.lua` file
2. Look for WoW annotations in IntelliSense
3. If missing, reinstall `ketho.wow-api`

### TOC file not syntax highlighted

**Solution:** Check file association
1. Open `.toc` file
2. Bottom right corner should say "WoW TOC"
3. If not, click and select "WoW TOC" language

---

## 📚 Additional Resources

**WoW API Documentation:**
- [WoWpedia API](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API)
- [WoWWiki (Classic)](https://wowwiki-archive.fandom.com/wiki/World_of_Warcraft_API)

**Lua 5.1 Reference:**
- [Official Lua 5.1 Manual](https://www.lua.org/manual/5.1/)

**Project Ascension:**
- [db.ascension.gg](https://db.ascension.gg/) - Item/NPC database
- Custom APIs: C_VanityCollection, GetClientVersion

---

## 🔄 Optional Extensions

These are nice to have but not required:

**WoW Lua Error Loader** (sapu94.wow-lua-error-loader)
- Load in-game Lua errors into VS Code
- Click error to jump to line
- Great for debugging

```powershell
code --install-extension sapu94.wow-lua-error-loader
```

**WoW Spell Tooltips** (elvador.wow-spell-tooltips)
- Display spell data in tooltips
- Useful if working with spell IDs

```powershell
code --install-extension elvador.wow-spell-tooltips
```

---

## ❌ What We DON'T Need

**AddOn Studio** - Too heavy, VS Code is better
**Visual Studio** - Not needed for Lua development
**Eclipse LDT** - Outdated, sumneko.lua is better
**Lua for Windows** - WoW uses embedded Lua 5.1

---

## 🎯 Summary

With these 4 extensions, VS Code becomes a **professional WoW addon IDE** with:
- ✅ Full IntelliSense for WoW APIs
- ✅ Lua 5.1 support
- ✅ TOC file editing
- ✅ Addon-specific autocomplete
- ✅ Real-time error detection
- ✅ FrameXML support

**No need for AddOn Studio or other heavy IDEs!** 🚀

---

**Questions?** Check `.vscode/settings.json` for the full configuration.
