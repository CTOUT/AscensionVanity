-- AscensionVanity - API Scanner Module
-- Scans all vanity items via Ascension API and exports to AscensionVanity_Dump.lua

local AddonName = "AscensionVanity"

-- Saved variable for API dump (separate from main addon config)
AscensionVanityDump = AscensionVanityDump or {
    APIDump = {},
    LastScanDate = nil,
    ScanVersion = "2.0",
    TotalItems = 0
}

-- Combat Pet Vanity Categories (for filtering)
local COMBAT_PET_PREFIXES = {
    "Beastmaster's Whistle:",
    "Blood Soaked Vellum:",
    "Summoner's Stone:",
    "Draconic Warhorn:",
    "Elemental Lodestone:"
}

-- Exclusion filters - items to EXCLUDE even if they match quality/prefix
local EXCLUSION_KEYWORDS = {
    "purchase",
    "website",
    "previously",
    "bazaar",
    "seasonal",
    "reward",
    "promotional",
    "promo",
    "event",
    "limited"
}

-- Quality filter (6 = Artifact/Legendary - used for vanity items)
local VANITY_QUALITY = 6

-- Scanning state
local scanState = {
    isScanning = false,
    currentCategory = nil,
    currentIndex = 0,
    totalItems = 0,
    scannedItems = 0,
    startTime = nil
}

-- Utility: Print with addon prefix
local function Print(msg)
    print("|cFF00FF96[AscensionVanity]|r " .. msg)
end

-- Utility: Check if item is a combat pet vanity item
-- Filters by quality (6) AND name prefix AND exclusion keywords
local function IsCombatPetVanityItem(itemData)
    if not itemData then
        return false
    end
    
    -- Check quality first (must be 6 - Artifact/Legendary)
    if itemData.quality ~= VANITY_QUALITY then
        return false
    end
    
    -- Check if name starts with one of our combat pet prefixes
    local name = itemData.name or ""
    local nameLower = name:lower()
    
    local hasValidPrefix = false
    for _, prefix in ipairs(COMBAT_PET_PREFIXES) do
        if name:find("^" .. prefix) then
            hasValidPrefix = true
            break
        end
    end
    
    if not hasValidPrefix then
        return false
    end
    
    -- Check exclusion keywords (after prefix to avoid filtering "Blood" prefix)
    for _, keyword in ipairs(EXCLUSION_KEYWORDS) do
        if nameLower:find(keyword:lower()) then
            return false
        end
    end
    
    return true
end

-- Utility: Process raw item data from API
-- ONLY extracts the 5 essential fields we need for the database
-- NOW with filtering to only capture combat pet vanity items
local function ProcessItemData(itemData, itemID)
    if not itemData or type(itemData) ~= "table" then
        return nil
    end
    
    -- Filter: ONLY process combat pet vanity items
    if not IsCombatPetVanityItem(itemData) then
        return nil
    end
    
    -- The API returns 'itemid' as the ACTUAL game item ID
    local gameItemId = itemData.itemid
    
    if not gameItemId or gameItemId == 0 then
        return nil
    end
    
    -- Return ONLY the 5 fields we need (no extra data, no confusion)
    return {
        itemid = gameItemId,           -- Game item ID (what the API returns)
        name = itemData.name or "Unknown",
        description = itemData.description or "",
        icon = itemData.icon or "",
        creaturePreview = itemData.creaturePreview or 0
    }
end

-- Get all vanity items (no category filtering - get everything)
local function GetAllVanityItems()
    local items = {}
    
    -- Use C_VanityCollection.GetAllItems to get all items (correct Ascension API)
    local allItems = C_VanityCollection.GetAllItems() or {}
    
    for idx, itemData in pairs(allItems) do
        if type(itemData) == "table" then
            -- Process the raw item data (extracts only 5 essential fields)
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
    
    Print("Starting combat pet vanity item scan...")
    Print("Filtering for Quality 6 items with names starting with:")
    Print("  • Beastmaster's Whistle:")
    Print("  • Blood Soaked Vellum:")
    Print("  • Summoner's Stone:")
    Print("  • Draconic Warhorn:")
    Print("  • Elemental Lodestone:")
    Print("")
    Print("Excluding items containing: purchase, website, previously, bazaar, seasonal, reward, etc.")
    
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
    
    -- Update metadata
    AscensionVanityDump.LastScanDate = date("%Y-%m-%d %H:%M:%S")
    AscensionVanityDump.ScanVersion = "2.0"
    AscensionVanityDump.TotalItems = totalScanned
    
    scanState.isScanning = false
    scanState.scannedItems = totalScanned
    
    local elapsed = time() - scanState.startTime
    
    Print("========================================")
    Print("Scan Complete!")
    Print("  → Combat pet vanity items found: " .. totalScanned)
    Print("  → Time elapsed: " .. elapsed .. " seconds")
    Print("  → Data saved to: AscensionVanity_Dump.lua")
    Print("========================================")
    Print("Filtered for Quality 6 items with names starting with:")
    Print("  • Beastmaster's Whistle:")
    Print("  • Blood Soaked Vellum:")
    Print("  • Summoner's Stone:")
    Print("  • Draconic Warhorn:")
    Print("  • Elemental Lodestone:")
    Print("")
    Print("Excluded items containing: purchase, website, previously, bazaar, seasonal, reward")
    Print("Next: Exit WoW to save data, then run utilities to process the dump.")
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
    
    if scanState.isScanning then
        Print("Status: SCANNING...")
        Print("Current Category: " .. (scanState.currentCategory or "N/A"))
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
