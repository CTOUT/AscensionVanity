# GitHub Release Creation Guide

## 📦 Release Package Ready!

Your first release package has been created:
- **File**: `AscensionVanity-v1.0.0.zip` (36 KB)
- **Release Notes**: `RELEASE_NOTES_v1.0.0.md`

---

## 🚀 Creating a GitHub Release

### Step 1: Go to GitHub Releases Page
1. Navigate to: https://github.com/CTOUT/AscensionVanity/releases
2. Click the **"Create a new release"** button (or go to: https://github.com/CTOUT/AscensionVanity/releases/new)

### Step 2: Configure Release Details

**Tag version:**
```
v1.0.0
```
- Click "Create new tag: v1.0.0 on publish"

**Release title:**
```
AscensionVanity v1.0.0 - Initial Release
```

**Release description:**
- Open `releases\RELEASE_NOTES_v1.0.0.md` in your editor
- Copy the entire contents
- Paste into the description field

### Step 3: Upload Release Package

1. In the "Attach binaries" section, drag and drop or click to upload:
   - `releases\AscensionVanity-v1.0.0.zip`

### Step 4: Publish

1. ✅ Check "Set as the latest release"
2. Click **"Publish release"**

---

## ✅ After Publishing

Your release will be available at:
```
https://github.com/CTOUT/AscensionVanity/releases/tag/v1.0.0
```

Users can download it directly from GitHub!

---

## 📝 Installation Test

To verify the release works correctly:

1. Download `AscensionVanity-v1.0.0.zip` from GitHub
2. Extract it to a test location
3. Verify structure:
   ```
   extracted_folder/
   └── AscensionVanity/
       ├── AscensionVanity.toc
       ├── Core.lua
       └── VanityDB.lua
   ```
4. The `AscensionVanity` folder should be ready to move to `Interface\AddOns\`

---

## 🔄 Future Releases

To create future releases:

1. Update version in `AscensionVanity\AscensionVanity.toc`
2. Update `CHANGELOG.md` with new changes
3. Run: `.\CreateRelease.ps1`
4. Follow this guide again with the new version number

---

## 🎉 Congratulations!

You've successfully created your first addon release package! 🚀
