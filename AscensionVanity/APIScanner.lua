-- AscensionVanity - API Scanner Module
-- Scans all vanity items via Ascension API and exports to AscensionVanity_Dump.lua
--
-- HYBRID FILTERING APPROACH (v2.1+):
-- - In-Game: Minimal filtering (quality 6 only) - exports ~9,600+ items
-- - PowerShell: All category/group/exclusion filtering for flexibility
-- - Benefits: Complete data preservation, audit trail, no re-scans for filter changes

local AddonName = "AscensionVanity"

-- Saved variable for API dump (separate from main addon config)
AscensionVanityDump = AscensionVanityDump or {
    APIDump = {},
    LastScanDate = nil,           -- When the scan was performed
    ScanVersion = "2.1",           -- Scanner version
    TotalItems = 0,                -- Number of items in dump
    GameVersion = nil,             -- WoW client version (e.g., "3.3.5")
    GameBuild = nil,               -- Client build number (e.g., "12340")
    GameBuildDate = nil,           -- WoW build date (e.g., "Jun 24 2010")
    CustomVersion = nil,           -- Ascension custom version (if available via API)
    AddonVersion = nil,            -- AscensionVanity addon version at scan time
    ServerVersionNote = nil        -- Manual note: Paste /version output here if needed
}

-- Quality filter (6 = Artifact/Legendary - used for vanity items)
-- This is the ONLY filter applied in-game - all other filtering done in PowerShell
local VANITY_QUALITY = 6

-- Scanning state
local scanState = {
    isScanning = false,
    totalItems = 0,
    scannedItems = 0,
    startTime = nil
}

-- Utility: Print with addon prefix
local function Print(msg)
    print("|cFF00FF96[AscensionVanity]|r " .. msg)
end

-- Utility: Check if item should be exported
-- MINIMAL in-game filtering - only quality check
-- All category/group/exclusion filtering happens in PowerShell for flexibility
local function ShouldExportItem(itemData)
    if not itemData then
        return false
    end
    
    -- ONLY filter by quality (6 = Artifact/Legendary vanity items)
    -- This gets us ~9,679 items which includes ALL vanity items
    -- PowerShell will handle category/group filtering with full audit trail
    if itemData.quality ~= VANITY_QUALITY then
        return false
    end
    
    return true
end

-- Utility: Process raw item data from API
-- Extracts only essential fields with minimal filtering (quality only)
-- ALL category/group/exclusion filtering happens in PowerShell
local function ProcessItemData(itemData, itemID)
    if not itemData or type(itemData) ~= "table" then
        return nil
    end
    
    -- Minimal filter: ONLY check quality (exports ~9,679 vanity items)
    if not ShouldExportItem(itemData) then
        return nil
    end
    
    -- The API returns 'itemid' as the ACTUAL game item ID
    local gameItemId = itemData.itemid
    
    if not gameItemId or gameItemId == 0 then
        return nil
    end
    
    -- Return ONLY the 6 fields we need for PowerShell processing
    return {
        itemid = gameItemId,           -- Game item ID (what the API returns)
        name = itemData.name or "Unknown",
        description = itemData.description or "",
        icon = itemData.icon or "",
        creaturePreview = itemData.creaturePreview or 0,
        group = itemData.group or 0    -- Group ID for category filtering in PowerShell
    }
end

-- Get all vanity items (no category filtering - get everything)
local function GetAllVanityItems()
    local items = {}
    
    -- Use C_VanityCollection.GetAllItems to get all items (correct Ascension API)
    local allItems = C_VanityCollection.GetAllItems() or {}
    
    for idx, itemData in pairs(allItems) do
        if type(itemData) == "table" then
            -- Process the raw item data (extracts only 6 essential fields)
            local processedItem = ProcessItemData(itemData)
            
            if processedItem then
                table.insert(items, processedItem)
            end
        end
    end
    
    return items
end

-- Scan all vanity items and save to dump file
function AV_ScanAllItems()
    if scanState.isScanning then
        Print("Scan already in progress! Use /avanity scan cancel to abort.")
        return
    end
    
    Print("Starting vanity item scan (HYBRID MODE)...")
    Print("In-game filter: Quality 6 items only (~9,600+ items)")
    Print("Category/Group filtering: Handled by PowerShell utilities")
    Print("")
    Print("This exports ALL quality-6 vanity items for complete audit trail.")
    
    scanState.isScanning = true
    scanState.startTime = time()
    scanState.scannedItems = 0
    
    -- Clear previous dump data
    AscensionVanityDump.APIDump = {}
    
    -- Scan all items (filtering happens in ProcessItemData)
    Print("Scanning vanity collection...")
    
    local items = GetAllVanityItems()
    
    local totalScanned = 0
    
    for _, itemData in ipairs(items) do
        -- Store in dump using itemid as key
        AscensionVanityDump.APIDump[itemData.itemid] = itemData
        
        totalScanned = totalScanned + 1
    end
    
    Print("  → Found " .. totalScanned .. " items")
    
    -- Capture game client version info
    local version, build, buildDate, tocVersion = GetBuildInfo()
    
    -- Capture Ascension custom version using GetClientVersion()
    -- Returns: [1]=date, [2]=time, [3]=branch, [4]=boolean
    local customVersionDate = "Unknown"
    local customVersionTime = "Unknown"
    local customVersionFull = "Unknown"
    
    if GetClientVersion then
        local clientVer = GetClientVersion()
        if clientVer and type(clientVer) == "table" then
            customVersionDate = clientVer[1] or "Unknown"
            customVersionTime = clientVer[2] or "Unknown"
            
            -- Build the full version string like /version command shows
            if customVersionDate ~= "Unknown" and customVersionTime ~= "Unknown" then
                customVersionFull = customVersionDate .. " " .. customVersionTime
            end
        end
    end
    
    -- Update metadata
    AscensionVanityDump.LastScanDate = date("%Y-%m-%d %H:%M:%S")
    AscensionVanityDump.ScanVersion = "2.1"
    AscensionVanityDump.TotalItems = totalScanned
    AscensionVanityDump.GameVersion = version or "Unknown"
    AscensionVanityDump.GameBuild = build or "Unknown"
    AscensionVanityDump.GameBuildDate = buildDate or "Unknown"     -- Original WoW build date
    AscensionVanityDump.CustomVersion = customVersionFull          -- Ascension custom version (e.g., "2025-11-01 16:21:03 GMT")
    AscensionVanityDump.AddonVersion = GetAddOnMetadata(AddonName, "Version") or "2.1"
    
    scanState.isScanning = false
    scanState.scannedItems = totalScanned
    
    local elapsed = time() - scanState.startTime
    
    Print("========================================")
    Print("Scan Complete! (HYBRID MODE)")
    Print("  → Quality-6 vanity items exported: " .. totalScanned)
    Print("  → Time elapsed: " .. elapsed .. " seconds")
    Print("  → Scan Date: " .. (AscensionVanityDump.LastScanDate or "Unknown"))
    Print("  → Game Version: " .. (AscensionVanityDump.GameVersion or "Unknown") .. " (Build: " .. (AscensionVanityDump.GameBuild or "Unknown") .. ")")
    Print("  → Ascension Build: " .. (AscensionVanityDump.CustomVersion or "Unknown"))
    Print("  → Addon Version: " .. (AscensionVanityDump.AddonVersion or "Unknown"))
    Print("  → Data saved to: AscensionVanity_Dump.lua")
    Print("========================================")
    Print("Next Steps:")
    Print("  1. Exit WoW to save data")
    Print("  2. Run: .\\utilities\\MasterVanityDBPipeline.ps1")
    Print("")
    Print("PowerShell will filter by group ID for combat pets:")
    Print("  • 16777217 = Beastmaster's Whistle")
    Print("  • 16777220 = Blood Soaked Vellum")
    Print("  • 16777218 = Summoner's Stone")
    Print("  • 16777224 = Draconic Warhorn")
    Print("  • 16777232 = Elemental Lodestone")
    Print("========================================")
end

-- Clear the dump data
function AV_ClearDumpData()
    Print("Clearing API dump data...")
    
    AscensionVanityDump.APIDump = {}
    AscensionVanityDump.LastScanDate = nil
    AscensionVanityDump.TotalItems = 0
    
    Print("✓ Dump data cleared! Exit WoW to persist changes.")
end

-- Get scan statistics
function AV_GetScanStats()
    local itemCount = 0
    for _ in pairs(AscensionVanityDump.APIDump or {}) do
        itemCount = itemCount + 1
    end
    
    Print("========================================")
    Print("API Dump Statistics")
    Print("========================================")
    Print("Last Scan: " .. (AscensionVanityDump.LastScanDate or "Never"))
    Print("Items in Dump: " .. itemCount)
    Print("Scan Version: " .. (AscensionVanityDump.ScanVersion or "Unknown"))
    Print("Game Version: " .. (AscensionVanityDump.GameVersion or "Unknown") .. " (Build: " .. (AscensionVanityDump.GameBuild or "Unknown") .. ")")
    Print("Ascension Build: " .. (AscensionVanityDump.CustomVersion or "Unknown"))
    Print("Addon Version: " .. (AscensionVanityDump.AddonVersion or "Unknown"))
    
    if scanState.isScanning then
        Print("Status: SCANNING...")
    else
        Print("Status: Idle")
    end
    Print("========================================")
end

-- Cancel ongoing scan
function AV_CancelScan()
    if scanState.isScanning then
        scanState.isScanning = false
        Print("Scan cancelled.")
    else
        Print("No scan in progress.")
    end
end

-- Scanner commands are now integrated into main /avanity command
-- See Core.lua for command handlers

-- Confirmation dialog for clearing dump
StaticPopupDialogs["AV_CONFIRM_CLEAR_DUMP"] = {
    text = "Clear all API dump data?\n\nThis will delete all scanned item data. You will need to run a new scan.",
    button1 = "Yes, Clear",
    button2 = "Cancel",
    OnAccept = function()
        AV_ClearDumpData()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Startup message
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == AddonName then
        -- Check if we have dump data
        local itemCount = 0
        for _ in pairs(AscensionVanityDump.APIDump or {}) do
            itemCount = itemCount + 1
        end
        
        if itemCount > 0 then
            Print("API Scanner loaded. Last scan: " .. (AscensionVanityDump.LastScanDate or "Unknown"))
            Print("Type /avanity scan help for scanner commands.")
        end
    end
end)
