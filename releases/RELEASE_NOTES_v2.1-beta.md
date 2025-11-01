# AscensionVanity v2.1-beta

## ⚠️ IMPORTANT: Clean Installation Required

**This release requires deleting your old addon files before installing.**

WoW doesn't automatically remove old files when updating addons. This release adds new critical files (SettingsUI.lua) that won't work correctly with old file structures.

### Quick Upgrade Steps:

1. **Delete** your existing `AscensionVanity` folder completely
2. **Extract** the new version to your AddOns directory
3. **Restart** WoW or `/reload`
4. Your settings will be preserved (stored in SavedVariables)

**See UPGRADE_v2.1-beta.md for detailed upgrade instructions and troubleshooting.**

---

## 🎨 What's New

### Modern UI System

**Standalone Settings UI**
- Access via `/avanity` command or Interface Options
- Professional DialogBox styling (600×430)
- Configure tooltip display, learned status, and color coding
- Quick access button to Scanner UI
- Automatic save on change
- Dependency management (e.g., color coding requires learned status)

**Standalone Scanner UI**
- Access via `/avanity scanner` command or Settings UI button
- Enhanced layout (650×680) with no content cutoff
- Developer tools: Scan, Clear, Refresh, Export
- Debug Mode checkbox (relocated from Settings UI)
- Complete instructions and slash command reference
- Status display with scan metrics

**Interface Options Integration**
- Clean launcher panel in WoW addon list
- Appears as "AscensionVanity" alphabetically
- Quick access to both Settings and Scanner UIs
- Professional presentation

### Enhanced User Experience

**Mutual Exclusion**
- Only one UI can be open at a time
- Prevents UI overlap and z-fighting
- Works from all access points (commands, buttons, launcher)
- Automatic closure when switching between UIs

**Real-Time Synchronization**
- Slash commands now update UI checkboxes immediately
- Works even when UI is already open
- Bidirectional sync (UI ↔ slash commands)
- No need to close and reopen UIs to see changes

**Improved Usability**
- Draggable frames (click and drag title bar)
- ESC key support for closing UIs
- Proper frame strata (always renders above game world)
- Position clamping (stays within screen bounds)

### Developer Tools

**Debug Mode Relocation**
- Moved from Settings UI to Scanner UI
- Better separation: user settings vs developer tools
- Syncs with `/avanity debug` command in real-time

### Testing & Documentation

**Comprehensive Test Plan** (UI_TEST_PLAN.md)
- 300+ test cases covering all functionality
- 9 organized test suites
- Pass/fail criteria for each test
- Professional sign-off section

**Testing Strategy Guide** (TESTING_OPTIONS.md)
- Overview of testing approaches for WoW addons
- Why traditional unit testing doesn't work for WoW
- Practical alternatives (Luacheck, manual testing, smoke tests)
- Luacheck setup guide with CI/CD integration
- Recommended 3-tier testing strategy

**Quick Test Checklist** (QUICK_TEST_CHECKLIST.md)
- 5-minute critical path tests for rapid validation
- 1-minute smoke tests for quick checks
- Pre-push validation checklist
- Lua test scripts for automated checks

---

## 📋 Complete Feature List

### UI Features
- ✅ Standalone Settings UI with professional styling
- ✅ Standalone Scanner UI with enhanced layout
- ✅ Interface Options launcher panel
- ✅ Mutual exclusion between UIs
- ✅ Real-time slash command synchronization
- ✅ Draggable, movable frames
- ✅ ESC key support
- ✅ Proper frame strata (DIALOG level)
- ✅ Debug Mode in Scanner UI

### Core Features (Existing)
- ✅ Creature tooltip enhancement
- ✅ 2,174 combat pets database (99.95% coverage)
- ✅ Smart NPC ID detection
- ✅ Location descriptions
- ✅ Visual indicators with icons
- ✅ Color coding (green/yellow)
- ✅ Learned status display
- ✅ Slash command controls
- ✅ Settings persistence

### Documentation
- ✅ Comprehensive README with UI guide
- ✅ Complete test plan (300+ cases)
- ✅ Testing strategy guide
- ✅ Quick test checklist
- ✅ Upgrade instructions
- ✅ CHANGELOG with full history

---

## 🔧 Technical Details

### Files Changed
- **AscensionVanity.toc** - Bumped to v2.1-beta
- **Core.lua** - Added sync function calls to slash commands
- **SettingsUI.lua** - Complete standalone Settings UI (NEW FILE)
- **ScannerUI.lua** - Enhanced with debug checkbox and sync
- **CHANGELOG.md** - v2.1-beta release notes
- **UPGRADE_v2.1-beta.md** - Complete upgrade guide (NEW FILE)

### New Dependencies
- None! Still pure Lua with WoW API

### Compatibility
- **WoW Version**: 3.3.5 (WOTLK)
- **Project**: Ascension
- **Interface**: 30300

---

## 🐛 Known Issues

None currently reported. This is a pre-release (beta) for testing and feedback.

---

## 📊 Statistics

- **Total Commits**: 2 in this release
- **Files Changed**: 6 files
- **Lines Added**: ~800 (including documentation)
- **New Features**: 8 major UI features
- **Test Cases**: 300+ documented tests

---

## 💬 Feedback & Support

**Found a bug?** Report it on GitHub Issues:  
https://github.com/CTOUT/AscensionVanity/issues

**Questions?** Check the documentation:
- `README.md` - Complete feature guide
- `UPGRADE_v2.1-beta.md` - Upgrade instructions
- `UI_TEST_PLAN.md` - Testing guide
- `TESTING_OPTIONS.md` - Testing strategy

**Discord/Community:** (Add your community links here)

---

## 🎯 What's Next?

### v2.1 Stable Release
- Additional testing and user feedback
- Bug fixes if any found
- Performance optimization
- Final polish

### Future Features (v2.2+)
- Region information display (Coming Soon)
- Enhanced learned status detection  
- Performance optimizations
- More comprehensive data validation
- Additional creature types support

---

## 👥 Contributors

**Developer:** CMTout  
**Testing:** Community feedback welcome!  
**Documentation:** Comprehensive guides included

---

## 📜 License

See LICENSE file in repository.

---

## 🙏 Acknowledgments

- Project Ascension team for the amazing server
- WoW addon community for inspiration and best practices
- All users who provide feedback and testing

---

**Version:** 2.1-beta  
**Release Date:** October 29, 2025  
**Branch:** v2.0-dev  
**Commit:** ba4b4df  
**Tag:** v2.1-beta

**Download:** See Assets section below ⬇️
