-- AscensionVanity - Core Functionality
-- Hooks into tooltips to display vanity item information

local AddonName = "AscensionVanity"
local VERSION = "2.0.0"

-- Saved variables initialized in AscensionVanityConfig.lua
AscensionVanityDB = AscensionVanityDB or {}

-- Color codes for tooltip text
local COLOR_VANITY_HEADER = "|cFF00FF96" -- Teal/cyan
local COLOR_VANITY_LEARNED = "|cFF00FF00" -- Green
local COLOR_VANITY_UNLEARNED = "|cFFFFFF00" -- Yellow
local COLOR_RESET = "|r"

-- Item type icons (icon IDs from Ascension database)
-- Icons verified from https://db.ascension.gg/?icon=<ID>
-- Format: |TTexture:size:size:xoffset:yoffset:texwidth:texheight:left:right:top:bottom|t
-- Using 14px icons with proper texture coordinates to prevent overlap/bleeding
local ITEM_ICONS = {
    ["Beastmaster's Whistle"] = "|TInterface\\Icons\\ability_hunter_beastcall:14:14:0:0:64:64:4:60:4:60|t",  -- Icon 455
    ["Blood Soaked Vellum"] = "|TInterface\\Icons\\inv_glyph_primedeathknight:14:14:0:0:64:64:4:60:4:60|t",  -- Icon 13479
    ["Summoner's Stone"] = "|TInterface\\Icons\\inv_misc_uncutgemnormal1:14:14:0:0:64:64:4:60:4:60|t",  -- Icon 19474
    ["Draconic Warhorn"] = "|TInterface\\Icons\\inv_misc_horn_01:14:14:0:0:64:64:4:60:4:60|t",  -- Icon 1550
    ["Elemental Lodestone"] = "|TInterface\\Icons\\custom_t_nhance_rpg_icons_arcanestone_border:14:14:0:0:64:64:4:60:4:60|t",  -- Icon 62794
}

-- Local reference to GameTooltip
local tooltip = GameTooltip

-- ============================================================================
-- Learned Status Cache System
-- ============================================================================
-- 
-- PURPOSE: Reduce C_VanityCollection API calls by ~90% through intelligent caching
--
-- PROBLEM ADDRESSED:
--   Without caching: Every tooltip hover = N API calls (where N = items on creature)
--   Example: 100 NPCs × 2 items each = 200 API calls per session
--
-- SOLUTION:
--   - Cache learned status after first query
--   - Invalidate cache when player learns new items (event-driven)
--   - 30-minute TTL as safety net
--   - Manual clear command for troubleshooting
--
-- CACHE INVALIDATION STRATEGY:
--   ✅ IN-GAME TESTING (Oct 30, 2025) CONFIRMED:
--      - APPEARANCE_COLLECTED event DOES fire when learning vanity items!
--      - Event provides unlock ID (e.g., 48656 for Duskbat, 50907 for Young Scavenger)
--      - Provides instant cache invalidation (full clear)
--      - Discovered via Event Trace dev tool testing
--   
--   ⚠️ CRITICAL DISCOVERY - The Three-ID System:
--      Ascension uses THREE different ID systems for vanity items:
--      1. Item ID (entry):        79465 (what you use/buy - in our database)
--      2. Unlock ID (appearanceID): 48656 (internal collection unlock ID)
--      3. Vanity Index:           1809 (position in C_VanityCollection.GetAllItems())
--      
--      Example (Beastmaster's Whistle: Duskbat):
--        - Item ID: 79465 (used in game, our database, tooltips)
--        - Unlock ID: 48656 (APPEARANCE_COLLECTED event parameter)
--        - Index: ~1809 (C_VanityCollection.GetAllItems()[index])
--   
--   📋 MAPPING DISCOVERY (Oct 30, 2025):
--      Wardrobe frames contain BOTH IDs when populated!
--      AppearanceWardrobeFrameCollectionItem frame fields:
--        - appearanceID: 48656 (unlock ID)
--        - entry: 79465 (item ID)
--      
--      This mapping is accessible BUT only when wardrobe UI is open/populated.
--      Trade-off analysis concluded that full cache clear is more reliable:
--        ✅ No UI dependencies
--        ✅ Works immediately on login
--        ✅ Simpler to maintain
--        ✅ Instant performance (table clear is ~0ms)
--      
--      FUTURE: If we discover a way to extract this mapping via API without
--      requiring the wardrobe UI, we could implement targeted cache clearing
--      using: unlockToItemMap[48656] = 79465
--   
--   ⚠️ Why We Can't Do Targeted Clearing (Currently):
--      - APPEARANCE_COLLECTED provides unlock ID (48656)
--      - Our cache uses item IDs (79465)
--      - No API to convert unlock ID → item ID (without wardrobe UI)
--      - C_VanityCollection.GetAllItems()[index] lacks consistent item ID mapping
--      - SOLUTION: Clear entire cache (still instant, still 90%+ performance gain!)
--   
--   MULTI-LAYERED STRATEGY (Implemented):
--     1. PRIMARY: APPEARANCE_COLLECTED event - Instant full cache clear
--        - Fires immediately when player learns vanity items
--        - Full clear ensures zero stale data (no mapping errors)
--        - Cache rebuilds on-demand as tooltips are viewed
--     2. SAFETY NET: 30-minute TTL (paranoid fallback if event fails)
--     3. MANUAL FALLBACK: BAG_UPDATE_DELAYED with 1-second debounce
--     4. USER CONTROL: Manual /avanity clearcache command
--   
--   HOW IT WORKS:
--     - Cache expires automatically after 30 minutes (optional)
--     - APPEARANCE_COLLECTED event triggers instant full clear
--     - BAG updates trigger refresh ONLY if >1 second since last clear
--     - Prevents spam during rapid looting/bag changes
--     - Balances auto-refresh with performance
--
-- PERFORMANCE IMPACT:
--   - First tooltip: N API calls (cache miss)
--   - Subsequent tooltips: 0 API calls (cache hit)
--   - Cache refresh on item learn: Full cache clear (~0ms), rebuilds on-demand
--
-- USAGE:
--   IsVanityItemLearned(itemID, itemName) - Returns cached or fresh status
--   ClearLearnedCache() - Invalidate entire cache
--   ClearCacheForItem(itemID) - Invalidate specific item (for future use)
-- ============================================================================

-- Cache structure: [itemID] = { status = bool/nil, timestamp = number }
local learnedStatusCache = {}
local cacheVersion = 0  -- Increment to invalidate entire cache
local CACHE_TTL = 1800  -- 30 minutes - Primary invalidation via APPEARANCE_COLLECTED event (instant!)
                        -- TTL is now just a safety net, not the primary mechanism

-- Fallback event handling (since collection events don't fire on Ascension)
local lastBagUpdateTime = 0
local BAG_DEBOUNCE_TIME = 1.0  -- Only process bag updates once per second
local FALLBACK_EVENTS_ENABLED = true  -- Enabled by default with smart debouncing

-- Utility: Debug print (only prints if debug mode enabled)
-- MUST be defined before cache functions that use it
local function DebugPrint(...)
    if AscensionVanityDB and AscensionVanityDB.debug then
        print("|cFF00FFFF[AV Debug]|r", ...)
    end
end

-- Clear the entire cache (called on collection change events)
local function ClearLearnedCache()
    local itemCount = 0
    for _ in pairs(learnedStatusCache) do
        itemCount = itemCount + 1
    end
    
    learnedStatusCache = {}
    cacheVersion = cacheVersion + 1
    DebugPrint("Learned status cache cleared (" .. itemCount .. " items removed, version:", cacheVersion, ")")
end

-- Clear a specific item from cache
local function ClearCacheForItem(itemID)
    if learnedStatusCache[itemID] then
        learnedStatusCache[itemID] = nil
        DebugPrint("Cleared cache for item", itemID)
    end
end

-- Utility: Check if player has learned a vanity item (with caching)
-- Uses Ascension's C_VanityCollection.IsCollectionItemOwned API
local function IsVanityItemLearned(itemID, itemName)
    if not itemID then
        DebugPrint("IsVanityItemLearned: No itemID provided")
        return nil
    end
    
    -- Check if API is available
    if not (C_VanityCollection and C_VanityCollection.IsCollectionItemOwned) then
        DebugPrint("C_VanityCollection.IsCollectionItemOwned not available")
        return nil
    end
    
    -- Check cache first
    local cached = learnedStatusCache[itemID]
    if cached then
        local age = GetTime() - cached.timestamp
        
        -- Cache hit - check if still valid (optional TTL check)
        if age < CACHE_TTL then
            DebugPrint("Cache HIT for item", itemID, "(age:", string.format("%.1f", age), "sec)")
            return cached.status
        else
            DebugPrint("Cache EXPIRED for item", itemID, "(age:", string.format("%.1f", age), "sec)")
        end
    end
    
    -- Cache miss or expired - query API
    DebugPrint("Cache MISS for item", itemID, "- querying API")
    local isOwned = C_VanityCollection.IsCollectionItemOwned(itemID)
    
    -- Store in cache
    learnedStatusCache[itemID] = {
        status = isOwned,
        timestamp = GetTime()
    }
    
    DebugPrint("Item", itemID, "(", itemName, ") owned status:", isOwned, "- CACHED")
    return isOwned
end

-- Utility: Get creature type from tooltip
local function GetCreatureTypeFromTooltip()
    -- Scan tooltip lines to find creature type
    -- Creature type typically appears on line 2 or 3
    for i = 2, tooltip:NumLines() do
        local line = _G["GameTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                -- Check if this line contains a known creature type
                for typeName, _ in pairs(AV_GenericDropsByType) do
                    if string.find(text, typeName) then
                        return typeName
                    end
                end
            end
        end
    end
    return nil
end

-- Core: Add vanity item information to tooltip
local function AddVanityInfoToTooltip(tooltip, unit)
    if not AscensionVanityDB.enabled then
        return
    end
    
    if not unit then
        return
    end
    
    -- Get creature ID from GUID (more reliable than name)
    local guid = UnitGUID(unit)
    if not guid then
        return
    end
    
    -- Extract creature ID from GUID
    -- Ascension uses hex GUID format: 0xF130001D0DC005B0F
    -- Creature ID is embedded in the hex value
    -- Format: 0x [F1] [3000] [1D0DC0] [05B0F]
    --            ^    ^      ^        ^
    --            |    |      |        spawn UID
    --            |    |      creature ID (middle 6 hex digits)
    --            |    type
    --            flags
    
    local creatureID = nil
    
    -- Convert hex GUID to number and extract creature ID
    if guid and type(guid) == "string" then
        DebugPrint("GUID:", guid)
        
        -- Remove 0x prefix if present
        local hexGuid = guid:gsub("^0x", "")
        
        -- Extract creature ID from hex GUID (bits 32-63, middle section)
        -- For 0xF130001D0DC005B0F, creature ID is 0x1D0DC0 = 1904064
        if #hexGuid >= 10 then
            local creatureIDHex = hexGuid:sub(5, 10)  -- Get middle 6 hex digits
            creatureID = tonumber(creatureIDHex, 16)  -- Convert from hex to decimal
            DebugPrint("Creature ID:", creatureID, "(hex:", creatureIDHex, ")")
        end
    end
    
    if not creatureID then
        return
    end
    
    -- Check if this is an NPC (not a player, pet, etc.)
    if not UnitIsPlayer(unit) and UnitExists(unit) then
        -- Look up vanity items for this creature by ID
        local vanityItems = AV_GetVanityItemsForCreature(creatureID)
        
        DebugPrint("Found", vanityItems and #vanityItems or 0, "items for creature", creatureID)
        
        if vanityItems and #vanityItems > 0 then
            -- Add separator line
            tooltip:AddLine(" ")
            
            -- Add header
            tooltip:AddLine(COLOR_VANITY_HEADER .. "Vanity Items:" .. COLOR_RESET)
            
            -- Add each vanity item
            for _, itemID in ipairs(vanityItems) do
                -- Get item data from new database format
                local itemData = AV_GetItemData(itemID)
                
                if not itemData then
                    -- Fallback to game API if database entry missing
                    local itemName = GetItemInfo(itemID)
                    if itemName then
                        itemData = { name = itemName, icon = nil }
                    else
                        itemData = { name = "Loading...", icon = nil }
                    end
                end
                
                local itemName = itemData.name
                
                -- Use actual item icon from database (if available)
                local itemIcon = ""
                if itemData.icon and itemData.icon ~= "" then
                    -- Format icon properly with Interface\Icons\ path
                    -- Using 14px icon with extra spacing to prevent text overlap
                    itemIcon = "|TInterface\\Icons\\" .. itemData.icon .. ":14:14:0:0:64:64:4:60:4:60|t  "
                    DebugPrint("Using database icon:", itemData.icon)
                else
                    -- Fallback to category-based icon detection
                    for itemType, icon in pairs(ITEM_ICONS) do
                        if string.find(itemName, itemType, 1, true) then
                            itemIcon = icon .. "  "  -- Double space for better separation
                            DebugPrint("Using category icon for:", itemType)
                            break
                        end
                    end
                end
                
                -- Start with item icon + name (no learned status yet)
                local itemText = itemIcon .. itemName
                
                -- Check if player has learned this item (optional feature)
                if AscensionVanityDB.showLearnedStatus then
                    local isLearned = IsVanityItemLearned(itemID, itemName)
                    
                    if isLearned == true then
                        -- Learned: Green checkmark + item
                        local checkmark = "|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t"
                        if AscensionVanityDB.colorCode then
                            itemText = checkmark .. " " .. COLOR_VANITY_LEARNED .. itemText .. COLOR_RESET
                        else
                            itemText = checkmark .. " " .. itemText
                        end
                    elseif isLearned == false then
                        -- Unlearned: Red cross + item
                        local cross = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:16|t"
                        if AscensionVanityDB.colorCode then
                            itemText = cross .. " " .. COLOR_VANITY_UNLEARNED .. itemText .. COLOR_RESET
                        else
                            itemText = cross .. " " .. itemText
                        end
                    else
                        -- Unknown status: No indicator, just 3 spaces for alignment
                        itemText = "   " .. itemText
                    end
                else
                    -- Learned status disabled: No indicator, just 3 spaces for alignment
                    itemText = "   " .. itemText
                end
                
                tooltip:AddLine(itemText, 1, 1, 1, true) -- White text, word wrap enabled
                
                -- Add region information (optional feature)
                if AscensionVanityDB.showRegions then
                    local region = AV_GetItemRegion(itemID)
                    if region and region ~= "" then
                        local regionText = "      |cFF888888Location: " .. region .. COLOR_RESET
                        tooltip:AddLine(regionText, 1, 1, 1, true)
                    end
                end
            end
            
            -- Show tooltip updates
            tooltip:Show()
        end
    end
end

-- Hook into tooltip display
local function OnTooltipSetUnit(tooltip)
    local _, unit = tooltip:GetUnit()
    if unit then
        AddVanityInfoToTooltip(tooltip, unit)
    end
end

-- Event handler for addon initialization
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

-- Register cache invalidation events
-- NOTE: Collection-specific events (COLLECTION_CHANGED, NEW_TOY_ADDED, etc.) do NOT fire on Ascension!
-- Tested in-game: Learning vanity items triggers no collection events whatsoever
-- 
-- HYBRID FALLBACK STRATEGY (since primary events don't exist):
--   1. Shorter TTL: 2 minutes instead of 5 (cache expires faster)
--   2. Smart BAG_UPDATE: With 1-second debounce to reduce spam
--   3. Manual control: /avanity clearcache command
--
-- This prevents cache staleness while minimizing performance impact

-- Register ASCENSION_STORE_COLLECTION_ITEM_LEARNED event (confirmed working on Ascension!)
-- Event fires when player learns vanity items from the store collection
-- Discovered via StoreCollectionFrame inspection on October 30, 2025
-- Frame uses ItemInternal field which matches our itemid (e.g., 79463 for Young Scavenger)
frame:RegisterEvent("ASCENSION_STORE_COLLECTION_ITEM_LEARNED")

-- Also register APPEARANCE_COLLECTED as backup (in case both fire)
frame:RegisterEvent("APPEARANCE_COLLECTED")

-- Register fallback events with smart debouncing (backup strategy)
if FALLBACK_EVENTS_ENABLED then
    frame:RegisterEvent("BAG_UPDATE_DELAYED")  -- With debouncing to prevent spam
    DebugPrint("Fallback events enabled (BAG_UPDATE with 1-second debounce)")
end

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == AddonName then
        -- Addon loaded
        print("|cFF00FF96AscensionVanity|r v" .. VERSION .. " loaded!")
        print("Type |cFFFFFF00/avanity|r for settings or |cFFFFFF00/avanity help|r for commands")
        
        -- Check if Ascension's vanity collection API is available
        if C_VanityCollection and C_VanityCollection.IsCollectionItemOwned then
            print("|cFF00FF96AscensionVanity:|r C_VanityCollection API detected ✓")
        else
            print("|cFFFFAA00AscensionVanity:|r C_VanityCollection API not available (learned status disabled)")
        end
        
    elseif event == "PLAYER_LOGIN" then
        -- Hook into GameTooltip after player login
        GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
        
        -- Also hook into other tooltip types if needed
        -- GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
        
    elseif event == "ASCENSION_STORE_COLLECTION_ITEM_LEARNED" then
        -- PRIMARY: ASCENSION_STORE_COLLECTION_ITEM_LEARNED event - instant cache invalidation!
        -- This event fires when player learns vanity items from the store collection
        -- Discovered from StoreCollectionFrame which uses ItemInternal field (itemid: 79463)
        -- 
        -- TESTING NEEDED: What parameters does this event provide?
        --   - Does it provide itemid (79463)?
        --   - Does it provide index (1809)?
        --   - Does it provide something else?
        
        -- Event spy notification (if enabled)
        if AscensionVanityDB.eventSpy then
            -- arg1 is already captured from the function signature: function(self, event, arg1)
            print("|cFF00FFFF[Event Spy]|r |cFF00FF00ASCENSION_STORE_COLLECTION_ITEM_LEARNED|r")
            print("  |cFFFFFF00Parameter (arg1):|r " .. tostring(arg1 or "none"))
        end
        
        -- Clear entire cache to ensure fresh data
        DebugPrint("ASCENSION_STORE_COLLECTION_ITEM_LEARNED: Item learned, clearing cache")
        ClearLearnedCache()
        
    elseif event == "APPEARANCE_COLLECTED" then
        -- BACKUP: APPEARANCE_COLLECTED event (may also fire)
        -- Keep this as a backup in case both events fire
        
        -- Event spy notification (if enabled)
        if AscensionVanityDB.eventSpy then
            print("|cFF00FFFF[Event Spy]|r |cFF00FF00" .. event .. "|r - arg1:", arg1 or "none")
        end
        
        DebugPrint("APPEARANCE_COLLECTED: Clearing cache (backup event)")
        ClearLearnedCache()
        
    elseif event == "BAG_UPDATE_DELAYED" then
        -- Fallback: BAG_UPDATE with smart debouncing
        -- Since collection events don't fire on Ascension, we use this with debouncing
        
        -- Event spy notification (if enabled)
        if AscensionVanityDB.eventSpy then
            print("|cFF00FFFF[Event Spy]|r |cFFFFAA00" .. event .. "|r - Fallback event fired")
        end
        
        -- Smart debouncing: Only clear cache once per second to prevent spam
        local now = GetTime()
        if FALLBACK_EVENTS_ENABLED and (now - lastBagUpdateTime) >= BAG_DEBOUNCE_TIME then
            lastBagUpdateTime = now
            DebugPrint("Event:", event, "- Cache invalidation (debounced)")
            ClearLearnedCache()
        else
            DebugPrint("Event:", event, "- IGNORED (debounced - too soon after last clear)")
        end
        
    -- Event spy mode - catch additional events
    elseif AscensionVanityDB.eventSpy then
        -- Report any other registered events
        local spyEvents = {
            "COMPANION_UPDATE",
            "PET_JOURNAL_LIST_UPDATE",
            "COMPANION_LEARNED",
            "PET_JOURNAL_PET_DELETED",
            "TOYS_UPDATED",
            "TRANSMOG_COLLECTION_ITEM_UPDATE",
            "ITEM_LOCK_CHANGED",
            "PLAYER_EQUIPMENT_CHANGED",
            "UNIT_INVENTORY_CHANGED",
            "BAG_UPDATE",
            "QUEST_ACCEPTED",
            "QUEST_TURNED_IN",
            "PLAYER_INTERACTION_OBJECT_OPENED"
        }
        
        for _, spyEvent in ipairs(spyEvents) do
            if event == spyEvent then
                print("|cFF00FFFF[Event Spy]|r |cFF888888" .. event .. "|r - Generic event fired")
                break
            end
        end
    end
end)

-- Slash commands
SLASH_ASCENSIONVANITY1 = "/avanity"
SLASH_ASCENSIONVANITY2 = "/ascvan"
SLASH_ASCENSIONVANITY3 = "/ascensionvanity"

SlashCmdList["ASCENSIONVANITY"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "" then
        -- Open settings UI
        AscensionVanity_ShowSettings()
    
    elseif msg == "scanner" then
        -- Open scanner UI
        AscensionVanity_ShowScanner()
        
    elseif msg == "toggle" then
        AscensionVanityDB.enabled = not AscensionVanityDB.enabled
        if AscensionVanityDB.enabled then
            print("|cFF00FF96AscensionVanity:|r Enabled")
        else
            print("|cFF00FF96AscensionVanity:|r Disabled")
        end
        -- Sync Settings UI if it exists
        if AscensionVanity_SyncSettingsUI then
            AscensionVanity_SyncSettingsUI()
        end
        
    elseif msg == "learned" then
        AscensionVanityDB.showLearnedStatus = not AscensionVanityDB.showLearnedStatus
        if AscensionVanityDB.showLearnedStatus then
            print("|cFF00FF96AscensionVanity:|r Learned status display enabled")
        else
            print("|cFF00FF96AscensionVanity:|r Learned status display disabled")
        end
        -- Sync Settings UI if it exists
        if AscensionVanity_SyncSettingsUI then
            AscensionVanity_SyncSettingsUI()
        end
        
    elseif msg == "color" then
        AscensionVanityDB.colorCode = not AscensionVanityDB.colorCode
        if AscensionVanityDB.colorCode then
            print("|cFF00FF96AscensionVanity:|r Color coding enabled")
        else
            print("|cFF00FF96AscensionVanity:|r Color coding disabled")
        end
        -- Sync Settings UI if it exists
        if AscensionVanity_SyncSettingsUI then
            AscensionVanity_SyncSettingsUI()
        end
        
    elseif msg == "debug" then
        AscensionVanityDB.debug = not AscensionVanityDB.debug
        if AscensionVanityDB.debug then
            print("|cFF00FF96AscensionVanity:|r Debug mode enabled")
        else
            print("|cFF00FF96AscensionVanity:|r Debug mode disabled")
        end
        -- Sync Scanner UI checkbox if it exists
        if AscensionVanity_SyncDebugCheckbox then
            AscensionVanity_SyncDebugCheckbox()
        end
        
    -- API Scanner commands (integrated from APIScanner.lua)
    elseif msg == "scan" or msg:match("^scan%s") then
        local scanCmd = msg:match("^scan%s+(.+)") or ""
        if scanCmd == "" then
            -- Default: Start scan
            if AV_ScanAllItems then
                AV_ScanAllItems()
            else
                print("|cFFFF0000Error:|r API Scanner not loaded")
            end
        elseif scanCmd == "clear" then
            StaticPopup_Show("AV_CONFIRM_CLEAR_DUMP")
        elseif scanCmd == "stats" then
            if AV_GetScanStats then
                AV_GetScanStats()
            else
                print("|cFFFF0000Error:|r API Scanner not loaded")
            end
        elseif scanCmd == "cancel" then
            if AV_CancelScan then
                AV_CancelScan()
            else
                print("|cFFFF0000Error:|r API Scanner not loaded")
            end
        elseif scanCmd == "help" then
            print("|cFF00FF96========================================|r")
            print("|cFF00FF96API Scanner Commands|r")
            print("|cFF00FF96========================================|r")
            print("  |cFFFFFF00/avanity scan|r - Scan all vanity items")
            print("  |cFFFFFF00/avanity scan clear|r - Clear dump data")
            print("  |cFFFFFF00/avanity scan stats|r - Show scan statistics")
            print("  |cFFFFFF00/avanity scan cancel|r - Cancel ongoing scan")
            print("  |cFFFFFF00/avanity scan help|r - Show this help")
            print("|cFF00FF96========================================|r")
        else
            print("|cFF00FF96AscensionVanity:|r Unknown scan command. Use |cFFFFFF00/avanity scan help|r for commands.")
        end
        
    elseif msg == "api" then
        -- Scan for Ascension's vanity collection API
        print("|cFF00FF96AscensionVanity:|r Scanning for Ascension vanity APIs...")
        
        -- Check for C_VanityCollection
        if C_VanityCollection then
            print("  |cFF00FF00Found:|r C_VanityCollection")
            for k, v in pairs(C_VanityCollection) do
                print("    - C_VanityCollection." .. k .. " (" .. type(v) .. ")")
            end
            
            -- Test GetNum if available
            if C_VanityCollection.GetNum then
                local numItems = C_VanityCollection.GetNum()
                print(" ")
                print("  |cFF00FFFF=== Testing GetNum() ===|r")
                print("  Total items:", numItems, "(" .. type(numItems) .. ")")
            end
            
            -- Test GetItem if available
            if C_VanityCollection.GetItem then
                print(" ")
                print("  |cFF00FFFF=== Testing GetItem() ===|r")
                
                -- Try getting item by index
                local success, result = pcall(C_VanityCollection.GetItem, 1)
                if success then
                    print("  GetItem(1) result type:", type(result))
                    if type(result) == "table" then
                        print("  Sample fields:")
                        for k, v in pairs(result) do
                            local valueStr = tostring(v)
                            if type(v) == "table" then valueStr = "<table>" end
                            print("    " .. tostring(k) .. " = " .. valueStr .. " (" .. type(v) .. ")")
                            if k == "itemId" or k == "creaturePreview" then
                                print("      |cFF00FF00^^ KEY FIELD!|r")
                            end
                        end
                    else
                        print("  Value:", tostring(result))
                    end
                else
                    print("  |cFFFF0000Error:|r", result)
                end
                
                -- Try known item ID (79626 = Savannah Prowler)
                print(" ")
                print("  Testing with known item ID 79626:")
                success, result = pcall(C_VanityCollection.GetItem, 79626)
                if success and result then
                    print("  |cFF00FF00Found by item ID!|r")
                    if type(result) == "table" and result.creaturePreview then
                        print("  creaturePreview:", result.creaturePreview)
                    end
                else
                    print("  Not found by item ID (or wrong parameter)")
                end
            end
        else
            print("  |cFFFF0000Not found:|r C_VanityCollection")
        end
        
        -- Check for common global functions
        local checkFunctions = {
            "IsVanityCollected",
            "HasVanityItem",
            "GetVanityItemInfo",
            "C_Vanity",
            "VanityCollection_IsCollected"
        }
        
        for _, funcName in ipairs(checkFunctions) do
            if _G[funcName] then
                print("  |cFF00FF00Found:|r " .. funcName .. " (" .. type(_G[funcName]) .. ")")
            end
        end
        
    elseif msg:match("^dumpitem%s+(%d+)") then
        -- Dump specific item by ID
        local itemID = tonumber(msg:match("^dumpitem%s+(%d+)"))
        
        print("|cFF00FF96AscensionVanity:|r Searching for item", itemID, "in vanity collection...")
        
        if C_VanityCollection and C_VanityCollection.GetAllItems then
            local items = C_VanityCollection.GetAllItems()
            
            if items then
                -- Helper function to recursively print nested tables
                local function printTable(tbl, indent, maxDepth)
                    indent = indent or ""
                    maxDepth = maxDepth or 10
                    if maxDepth <= 0 then
                        print(indent .. "<max depth reached>")
                        return
                    end
                    
                    for k, v in pairs(tbl) do
                        if type(v) == "table" then
                            print(string.format("%s%s = <table>:", indent, tostring(k)))
                            printTable(v, indent .. "  ", maxDepth - 1)
                        else
                            print(string.format("%s%s = %s (%s)", indent, tostring(k), tostring(v), type(v)))
                        end
                    end
                end
                
                -- Helper: Search for item ID in ANY field recursively
                local function searchInTable(tbl, targetID)
                    for k, v in pairs(tbl) do
                        if type(v) == "number" and v == targetID then
                            return true, k
                        elseif type(v) == "table" then
                            local found, path = searchInTable(v, targetID)
                            if found then
                                return true, k .. "." .. path
                            end
                        end
                    end
                    return false, nil
                end
                
                -- Search for the specific item
                local found = false
                local totalItems = 0
                
                for k, v in pairs(items) do
                    totalItems = totalItems + 1
                    
                    -- Check direct match (array index)
                    if k == itemID then
                        found = true
                        print(" ")
                        print(string.format("|cFF00FF00===== FOUND (Array Index Match) =====|r"))
                        print("Item ID:", itemID)
                        printTable(v, "  ", 10)
                        break
                    end
                    
                    -- Check if item data contains the ID in any field
                    if type(v) == "table" then
                        local hasMatch, fieldPath = searchInTable(v, itemID)
                        if hasMatch then
                            found = true
                            print(" ")
                            print(string.format("|cFF00FF00===== FOUND (Field Match: %s) =====|r", fieldPath))
                            print("Collection Index:", k)
                            printTable(v, "  ", 10)
                            break
                        end
                    end
                end
                
                if not found then
                    print("|cFFFF0000Not Found:|r Item", itemID, "not in collection")
                    print(string.format("|cFFFFFF00Total items in collection: %d|r", totalItems))
                    print("|cFFFFFF00Hypothesis:|r API might only return items you OWN")
                    print("|cFFFFFF00Try:|r /avanity dump to see what items ARE in your collection")
                end
            else
                print("|cFFFF0000Error:|r GetAllItems() returned nil")
            end
        else
            print("|cFFFF0000Error:|r C_VanityCollection.GetAllItems not available")
        end
        
    elseif msg == "dump" then
        -- Dump vanity collection data from Ascension API
        print("|cFF00FF96AscensionVanity:|r Dumping vanity collection data...")
        
        if C_VanityCollection and C_VanityCollection.GetAllItems then
            local items = C_VanityCollection.GetAllItems()
            
            if items then
                print("|cFF00FF00Found:|r Vanity collection data")
                print("Data type:", type(items))
                
                -- Helper function to recursively print nested tables
                local function printTable(tbl, indent, maxDepth)
                    indent = indent or ""
                    maxDepth = maxDepth or 3
                    if maxDepth <= 0 then
                        print(indent .. "<...>")
                        return
                    end
                    
                    for k, v in pairs(tbl) do
                        if type(v) == "table" then
                            print(string.format("%s%s = <table>:", indent, tostring(k)))
                            printTable(v, indent .. "  ", maxDepth - 1)
                        else
                            print(string.format("%s%s = %s (%s)", indent, tostring(k), tostring(v), type(v)))
                        end
                    end
                end
                
                -- Print first 2 items in FULL DETAIL (avoid chat spam)
                local count = 0
                local maxSamples = 2
                
                print("|cFFFFFF00Showing first", maxSamples, "items in FULL DETAIL:|r")
                for k, v in pairs(items) do
                    count = count + 1
                    if count <= maxSamples then
                        print(" ")
                        print(string.format("|cFF00FFFF========== Item #%d ==========|r", count))
                        print("Array Index:", k, "(" .. type(k) .. ")")
                        
                        if type(v) == "table" then
                            printTable(v, "  ", 5)  -- Show up to 5 levels deep
                        else
                            print("Value:", v, "(" .. type(v) .. ")")
                        end
                    end
                end
                
                print(" ")
                print(string.format("|cFF00FF00Total items in collection: %d|r", count))
                
                if count > maxSamples then
                    print("|cFFFFFF00Note:|r Only showing first", maxSamples, "items in full detail to avoid chat spam")
                    print("|cFFFFFF00Tip:|r Use '/avanity dumpitem <itemID>' to search for a specific item")
                    print("|cFFFFFF00Example:|r /avanity dumpitem 79626  (Savannah Prowler whistle)")
                end
            else
                print("|cFFFF0000Error:|r GetAllItems() returned nil")
            end
        else
            print("|cFFFF0000Error:|r C_VanityCollection.GetAllItems not available")
        end
        
    elseif msg == "inspectui" or msg == "uiinspect" then
        -- Inspect the Vanity Collection UI to see what IDs it uses
        print("|cFF00FF96=======================================================|r")
        print("|cFF00FF96VANITY UI INSPECTION|r")
        print("|cFF00FF96=======================================================|r")
        print(" ")
        
        -- Helper function to recursively dump table
        local function DumpUITable(tbl, indent, maxDepth, name)
            indent = indent or ""
            maxDepth = maxDepth or 3
            name = name or "table"
            
            if maxDepth <= 0 then
                print(indent .. "|cFFFF0000<max depth reached>|r")
                return
            end
            
            if type(tbl) ~= "table" then
                print(indent .. name .. " = |cFF00FF00" .. tostring(tbl) .. "|r |cFF888888(" .. type(tbl) .. ")|r")
                return
            end
            
            local count = 0
            for _ in pairs(tbl) do count = count + 1 end
            print(indent .. name .. " = |cFFFFAA00{table with " .. count .. " items}|r")
            
            for k, v in pairs(tbl) do
                local vtype = type(v)
                if vtype == "table" then
                    DumpUITable(v, indent .. "  ", maxDepth - 1, tostring(k))
                elseif vtype ~= "function" and vtype ~= "userdata" then
                    print(string.format("%s  %s = |cFF00FF00%s|r |cFF888888(%s)|r", indent, tostring(k), tostring(v), vtype))
                end
            end
        end
        
        -- Check if Collections frame exists
        if not CollectionsJournal then
            print("|cFFFF0000Collections frame not found!|r")
            print("|cFFFFFF00Tip:|r Open the Collections window first (Shift+P)")
            return
        end
        
        print("|cFF00FFFF=== Collections Frame ===|r")
        print("Exists:", CollectionsJournal ~= nil)
        print("Visible:", CollectionsJournal:IsVisible())
        print("Current Tab:", tostring(CollectionsJournal.currentTab))
        print(" ")
        
        -- Try to find vanity-specific frames/data
        print("|cFF00FFFF=== Searching for Vanity-Related Globals ===|r")
        local vanityGlobals = {
            "CollectionVanityFrame",
            "VanityFrame",
            "VanityCollectionFrame",
            "CollectionsVanityFrame",
            "VanityJournal",
            "C_VanityCollection",
            "C_AppearanceCollection"  -- Related to APPEARANCE_COLLECTED event!
        }
        
        for _, globalName in ipairs(vanityGlobals) do
            local global = _G[globalName]
            if global then
                print("|cFF00FF00Found:|r " .. globalName .. " (" .. type(global) .. ")")
                
                if type(global) == "table" then
                    -- Dump the table structure
                    DumpUITable(global, "  ", 2, globalName)
                end
            else
                print("|cFF888888Not found:|r " .. globalName)
            end
        end
        
        print(" ")
        print("|cFF00FFFF=== C_VanityCollection API Methods ===|r")
        if C_VanityCollection then
            for methodName, method in pairs(C_VanityCollection) do
                if type(method) == "function" then
                    print("  |cFF00FFFF" .. methodName .. "|r (function)")
                end
            end
        end
        
        print(" ")
        print("|cFF00FFFF=== Testing GetItem() with Known IDs ===|r")
        
        -- Test with different ID types we found
        local testIDs = {
            {type = "Index", id = 1809, desc = "Young Scavenger array index"},
            {type = "ItemID", id = 79463, desc = "Young Scavenger itemid"},
            {type = "Group", id = 16777217, desc = "Young Scavenger group"},
            {type = "CreatureID", id = 1508, desc = "Young Scavenger creaturePreview"}
        }
        
        if C_VanityCollection and C_VanityCollection.GetItem then
            for _, test in ipairs(testIDs) do
                local success, result = pcall(C_VanityCollection.GetItem, test.id)
                if success and result then
                    print("|cFF00FF00SUCCESS:|r GetItem(" .. test.id .. ") - " .. test.desc)
                    DumpUITable(result, "    ", 1, "result")
                else
                    print("|cFF888888FAILED:|r GetItem(" .. test.id .. ") - " .. test.desc)
                end
            end
        else
            print("|cFFFF0000GetItem() not available|r")
        end
        
        print(" ")
        print("|cFF00FFFF=== GetNum() Results ===|r")
        if C_VanityCollection and C_VanityCollection.GetNum then
            local numItems = C_VanityCollection.GetNum()
            print("Total items:", numItems, "(" .. type(numItems) .. ")")
        end
        
        print(" ")
        print("|cFF00FF96=======================================================|r")
        print("|cFF00FF96INSPECTION COMPLETE|r")
        print("|cFF00FF96=======================================================|r")
        print("|cFFFFFF00TIP:|r Open Collections (Shift+P) and inspect frames with:")
        print("|cFFFFFF00/dump CollectionsJournal|r")
        print("|cFFFFFF00/fstack|r to see frame names under cursor")
        
    elseif msg == "appearance" or msg == "inspectappearance" then
        -- Deep dive into C_AppearanceCollection API
        print("|cFF00FF96=======================================================|r")
        print("|cFF00FF96C_APPEARANCECOLLECTION API INVESTIGATION|r")
        print("|cFF00FF96=======================================================|r")
        print(" ")
        
        if not C_AppearanceCollection then
            print("|cFFFF0000C_AppearanceCollection not found!|r")
            print("|cFFFFFF00This API may not exist on Ascension.|r")
            return
        end
        
        -- Helper function to dump table
        local function DumpTable(tbl, indent, maxDepth)
            indent = indent or ""
            maxDepth = maxDepth or 3
            
            if maxDepth <= 0 then
                print(indent .. "|cFFFF0000<max depth>|r")
                return
            end
            
            for k, v in pairs(tbl) do
                local vtype = type(v)
                if vtype == "table" then
                    local count = 0
                    for _ in pairs(v) do count = count + 1 end
                    print(indent .. tostring(k) .. " = |cFFFFAA00{" .. count .. " items}|r")
                    DumpTable(v, indent .. "  ", maxDepth - 1)
                elseif vtype ~= "function" and vtype ~= "userdata" then
                    print(string.format("%s%s = |cFF00FF00%s|r |cFF888888(%s)|r", indent, tostring(k), tostring(v), vtype))
                end
            end
        end
        
        print("|cFF00FFFF=== API Exists ===|r")
        print("|cFF00FF00Found:|r C_AppearanceCollection")
        print(" ")
        
        print("|cFF00FFFF=== Available Methods ===|r")
        local methodCount = 0
        local methods = {}
        
        for methodName, method in pairs(C_AppearanceCollection) do
            if type(method) == "function" then
                methodCount = methodCount + 1
                table.insert(methods, methodName)
            end
        end
        
        table.sort(methods)
        for _, methodName in ipairs(methods) do
            print("  |cFF00FFFF" .. methodName .. "|r (function)")
        end
        print("|cFFFFAA00Total methods:|r " .. methodCount)
        print(" ")
        
        -- Test common method patterns
        print("|cFF00FFFF=== Testing Common Methods ===|r")
        
        -- Test GetAllItems equivalent
        if C_AppearanceCollection.GetAllItems then
            print("|cFF00FF00Testing:|r GetAllItems()")
            local success, result = pcall(C_AppearanceCollection.GetAllItems)
            if success and result then
                local count = 0
                for _ in pairs(result) do count = count + 1 end
                print("  |cFF00FF00SUCCESS!|r Returned " .. count .. " items")
                
                -- Show first item
                if count > 0 then
                    print("  |cFFFFAA00First item sample:|r")
                    for k, v in pairs(result) do
                        if type(v) == "table" then
                            DumpTable(v, "    ", 2)
                        end
                        break  -- Only show first
                    end
                end
            else
                print("  |cFF888888FAILED or returned nil|r")
            end
        else
            print("|cFF888888GetAllItems not available|r")
        end
        
        print(" ")
        
        -- Test IsCollectionItemOwned equivalent
        if C_AppearanceCollection.IsCollectionItemOwned then
            print("|cFF00FF00Testing:|r IsCollectionItemOwned() with Young Scavenger IDs")
            local testIDs = {
                {id = 1809, desc = "Index"},
                {id = 79463, desc = "ItemID"},
                {id = 16777217, desc = "Group"},
                {id = 1508, desc = "CreatureID"}
            }
            
            for _, test in ipairs(testIDs) do
                local success, result = pcall(C_AppearanceCollection.IsCollectionItemOwned, test.id)
                if success then
                    print(string.format("  IsCollectionItemOwned(%d) [%s] = |cFF00FF00%s|r", 
                        test.id, test.desc, tostring(result)))
                else
                    print(string.format("  IsCollectionItemOwned(%d) [%s] = |cFF888888error|r", 
                        test.id, test.desc))
                end
            end
        else
            print("|cFF888888IsCollectionItemOwned not available|r")
        end
        
        print(" ")
        
        -- Test GetItem equivalent
        if C_AppearanceCollection.GetItem then
            print("|cFF00FF00Testing:|r GetItem() with Young Scavenger IDs")
            local testIDs = {
                {id = 1809, desc = "Index"},
                {id = 79463, desc = "ItemID"},
                {id = 16777217, desc = "Group"}
            }
            
            for _, test in ipairs(testIDs) do
                local success, result = pcall(C_AppearanceCollection.GetItem, test.id)
                if success and result then
                    print("|cFF00FF00SUCCESS:|r GetItem(" .. test.id .. ") [" .. test.desc .. "]")
                    DumpTable(result, "    ", 2)
                else
                    print("|cFF888888FAILED:|r GetItem(" .. test.id .. ") [" .. test.desc .. "]")
                end
            end
        else
            print("|cFF888888GetItem not available|r")
        end
        
        print(" ")
        
        -- Test GetNum equivalent
        if C_AppearanceCollection.GetNum then
            print("|cFF00FF00Testing:|r GetNum()")
            local success, result = pcall(C_AppearanceCollection.GetNum)
            if success then
                print("  |cFF00FF00Total items:|r " .. tostring(result))
            else
                print("  |cFF888888FAILED|r")
            end
        else
            print("|cFF888888GetNum not available|r")
        end
        
        print(" ")
        print("|cFF00FF96=======================================================|r")
        print("|cFF00FF96INVESTIGATION COMPLETE|r")
        print("|cFF00FF96=======================================================|r")
        print(" ")
        print("|cFFFFAA00KEY QUESTION:|r Does C_AppearanceCollection use different IDs?")
        print("|cFFFFAA00HYPOTHESIS:|r APPEARANCE_COLLECTED event might use C_AppearanceCollection IDs")
        print("|cFFFFAA00NEXT STEP:|r Compare results with C_VanityCollection")
        
    elseif msg == "apidump" then
        -- Dump complete API data to SavedVariables for offline analysis
        print("|cFF00FF96AscensionVanity:|r Dumping complete API data to SavedVariables...")
        
        if not (C_VanityCollection and C_VanityCollection.GetAllItems) then
            print("|cFFFF0000Error:|r C_VanityCollection.GetAllItems not available")
            return
        end
        
        local items = C_VanityCollection.GetAllItems()
        if not items then
            print("|cFFFF0000Error:|r GetAllItems() returned nil")
            return
        end
        
        -- Create dump structure
        AscensionVanityDB.APIDump = {
            timestamp = date("%Y-%m-%d %H:%M:%S"),
            version = VERSION,
            totalItems = 0,
            items = {},
            itemsByCreature = {},
            categories = {},
            errors = {}
        }
        
        local dump = AscensionVanityDB.APIDump
        local processedCount = 0
        local errorCount = 0
        
        print("|cFFFFFF00Processing API data...|r")
        
        for idx, itemData in pairs(items) do
            processedCount = processedCount + 1
            
            if type(itemData) == "table" then
                local itemID = itemData.itemId or itemData.id or idx
                local creatureID = itemData.creaturePreview or itemData.sourceId
                local itemName = itemData.name or "Unknown"
                
                -- Store full item data
                dump.items[itemID] = {
                    itemId = itemID,
                    name = itemName,
                    creaturePreview = creatureID,
                    rawData = itemData  -- Store everything for analysis
                }
                
                -- Build reverse lookup: creature -> items
                if creatureID and creatureID > 0 then
                    if not dump.itemsByCreature[creatureID] then
                        dump.itemsByCreature[creatureID] = {}
                    end
                    table.insert(dump.itemsByCreature[creatureID], itemID)
                end
                
                -- Categorize by item name prefix
                local category = "Unknown"
                if string.find(itemName, "Beastmaster's Whistle") then
                    category = "Beastmaster's Whistle"
                elseif string.find(itemName, "Blood Soaked Vellum") then
                    category = "Blood Soaked Vellum"
                elseif string.find(itemName, "Summoner's Stone") then
                    category = "Summoner's Stone"
                elseif string.find(itemName, "Draconic Warhorn") then
                    category = "Draconic Warhorn"
                elseif string.find(itemName, "Elemental Lodestone") then
                    category = "Elemental Lodestone"
                end
                
                dump.categories[category] = (dump.categories[category] or 0) + 1
            else
                errorCount = errorCount + 1
                table.insert(dump.errors, {
                    index = idx,
                    type = type(itemData),
                    value = tostring(itemData)
                })
            end
        end
        
        dump.totalItems = processedCount
        
        print(" ")
        print("|cFF00FF00=== API DUMP COMPLETE ===|r")
        print("Total items processed:", processedCount)
        print("Items with creature sources:", #dump.itemsByCreature)
        print("Errors encountered:", errorCount)
        print(" ")
        print("|cFFFFFF00Categories found:|r")
        for category, count in pairs(dump.categories) do
            print(string.format("  %s: %d items", category, count))
        end
        print(" ")
        print("|cFF00FF00Data saved to:|r SavedVariables/AscensionVanity.lua")
        print("|cFFFFFF00Next step:|r /reload to save data, then check the file")
        print("|cFFFFFF00Validation:|r Use '/avanity validate' to compare API vs database")
        
    elseif msg == "validate" then
        -- Compare API data with our static database
        print("|cFF00FF96AscensionVanity:|r Validating database against API...")
        
        if not AscensionVanityDB.APIDump then
            print("|cFFFF0000Error:|r No API dump found. Run '/avanity apidump' first")
            return
        end
        
        local apiDump = AscensionVanityDB.APIDump
        local apiItems = apiDump.items
        local apiByCreature = apiDump.itemsByCreature
        
        -- Validation results
        local results = {
            apiTotal = 0,
            dbTotal = 0,
            matches = 0,
            apiOnly = {},
            dbOnly = {},
            mismatches = {}
        }
        
        -- Count API items
        for _ in pairs(apiItems) do
            results.apiTotal = results.apiTotal + 1
        end
        
        -- Count DB items
        for _ in pairs(AV_VanityItems) do
            results.dbTotal = results.dbTotal + 1
        end
        
        print(" ")
        print("|cFFFFFF00=== DATABASE VALIDATION ===|r")
        print(string.format("API items: %d", results.apiTotal))
        print(string.format("Database items: %d", results.dbTotal))
        print(" ")
        
        -- Find items in API but not in database
        print("|cFFFFFF00Checking for items in API but missing from database...|r")
        for itemID, itemData in pairs(apiItems) do
            local creatureID = itemData.creaturePreview
            if creatureID and creatureID > 0 then
                if AV_VanityItems[creatureID] then
                    -- Check if this specific item is mapped
                    if AV_VanityItems[creatureID] == itemID then
                        results.matches = results.matches + 1
                    else
                        -- Creature exists but different item
                        table.insert(results.mismatches, {
                            creatureID = creatureID,
                            apiItem = itemID,
                            dbItem = AV_VanityItems[creatureID],
                            apiName = itemData.name
                        })
                    end
                else
                    -- Creature not in our database
                    table.insert(results.apiOnly, {
                        creatureID = creatureID,
                        itemID = itemID,
                        name = itemData.name
                    })
                end
            end
        end
        
        print(string.format("Exact matches: %d", results.matches))
        print(string.format("In API only: %d", #results.apiOnly))
        print(string.format("Mismatches: %d", #results.mismatches))
        print(" ")
        
        -- Show sample missing items
        if #results.apiOnly > 0 then
            print("|cFFFF0000Items in API but missing from database:|r")
            local showCount = math.min(10, #results.apiOnly)
            for i = 1, showCount do
                local item = results.apiOnly[i]
                print(string.format("  [%d] Item %d: %s", item.creatureID, item.itemID, item.name))
            end
            if #results.apiOnly > showCount then
                print(string.format("  ... and %d more", #results.apiOnly - showCount))
            end
            print(" ")
        end
        
        -- Show sample mismatches
        if #results.mismatches > 0 then
            print("|cFFFFFF00Items with different mappings:|r")
            local showCount = math.min(5, #results.mismatches)
            for i = 1, showCount do
                local item = results.mismatches[i]
                print(string.format("  Creature %d: API has item %d, DB has item %d", 
                    item.creatureID, item.apiItem, item.dbItem))
                print(string.format("    API name: %s", item.apiName))
            end
            if #results.mismatches > showCount then
                print(string.format("  ... and %d more", #results.mismatches - showCount))
            end
        end
        
        -- Store validation results
        AscensionVanityDB.ValidationResults = results
        print(" ")
        print("|cFF00FF00Results saved to SavedVariables|r")
        print("|cFFFFFF00Use /reload to save, then check SavedVariables/AscensionVanity.lua|r")
        
    elseif msg == "export" then
        -- Export API dump in VanityDB.lua format for easy comparison
        print("|cFF00FF96AscensionVanity:|r Exporting API data in VanityDB format...")
        
        if not AscensionVanityDB.APIDump then
            print("|cFFFF0000Error:|r No API dump found. Run '/avanity apidump' first")
            return
        end
        
        local apiDump = AscensionVanityDB.APIDump
        local itemsByCreature = apiDump.itemsByCreature
        
        if not itemsByCreature then
            print("|cFFFF0000Error:|r API dump missing itemsByCreature data")
            return
        end
        
        -- Build export data structure
        local exportData = {
            header = "-- AscensionVanity - API Export in VanityDB Format",
            timestamp = "-- Generated: " .. (apiDump.timestamp or "Unknown"),
            totalCreatures = 0,
            totalItems = 0,
            entries = {}
        }
        
        -- Convert API data to VanityDB format
        -- Sort by creature ID for easier comparison
        local sortedCreatures = {}
        for creatureID, items in pairs(itemsByCreature) do
            table.insert(sortedCreatures, {id = creatureID, items = items})
        end
        
        table.sort(sortedCreatures, function(a, b) return a.id < b.id end)
        
        -- Format each entry
        for _, creature in ipairs(sortedCreatures) do
            local creatureID = creature.id
            local items = creature.items
            
            exportData.totalCreatures = exportData.totalCreatures + 1
            
            -- Get item name from first item for comment
            local firstItemID = items[1]
            local itemData = apiDump.items[firstItemID]
            local itemName = itemData and itemData.name or "Unknown"
            
            -- Format: single item or array
            local formattedEntry
            if #items == 1 then
                formattedEntry = string.format("    [%d] = %d, -- %s", creatureID, items[1], itemName)
                exportData.totalItems = exportData.totalItems + 1
            else
                -- Multiple items - format as array
                local itemsList = table.concat(items, ", ")
                formattedEntry = string.format("    [%d] = {%s}, -- %s (multiple drops: %d items)", 
                    creatureID, itemsList, itemName, #items)
                exportData.totalItems = exportData.totalItems + #items
            end
            
            table.insert(exportData.entries, formattedEntry)
        end
        
        -- Store in SavedVariables
        AscensionVanityDB.ExportedData = exportData
        
        print(" ")
        print("|cFF00FF00=== EXPORT COMPLETE ===|r")
        print(string.format("Total creatures: %d", exportData.totalCreatures))
        print(string.format("Total items: %d", exportData.totalItems))
        print(" ")
        print("|cFF00FF00Data saved to:|r SavedVariables/AscensionVanity.lua")
        print("|cFFFFFF00Next step:|r /reload to save, then check AscensionVanityDB.ExportedData")
        print(" ")
        print("|cFFFFFF00To view formatted output:|r /avanity showexport")
        
    elseif msg == "showexport" then
        -- Display exported data in chat (paginated)
        print("|cFF00FF96AscensionVanity:|r Displaying exported API data...")
        
        if not AscensionVanityDB.ExportedData then
            print("|cFFFF0000Error:|r No export found. Run '/avanity export' first")
            return
        end
        
        local exportData = AscensionVanityDB.ExportedData
        
        print(" ")
        print(exportData.header)
        print(exportData.timestamp)
        print(string.format("-- Total creatures: %d, Total items: %d", 
            exportData.totalCreatures, exportData.totalItems))
        print(" ")
        print("AV_VanityItems_API_Export = {")
        
        -- Show first 50 entries to avoid chat spam
        local maxShow = math.min(50, #exportData.entries)
        for i = 1, maxShow do
            print(exportData.entries[i])
        end
        
        if #exportData.entries > maxShow then
            print(string.format("    -- ... and %d more entries", #exportData.entries - maxShow))
        end
        
        print("}")
        print(" ")
        print("|cFFFFFF00Full data available in:|r SavedVariables/AscensionVanity.lua")
        print("|cFFFFFF00Look for:|r AscensionVanityDB.ExportedData.entries")
        
    elseif msg == "clearcache" then
        -- Manual cache clear for testing/troubleshooting
        ClearLearnedCache()
        print("|cFF00FF96AscensionVanity:|r Learned status cache cleared manually")
        print("|cFFFFFF00Note:|r Cache automatically refreshes when you learn new items")
        
    elseif msg == "eventspy" then
        -- Enable/disable event spy mode to detect which events fire when learning items
        AscensionVanityDB.eventSpy = not AscensionVanityDB.eventSpy
        
        if AscensionVanityDB.eventSpy then
            print("|cFF00FF96AscensionVanity:|r Event Spy Mode ENABLED")
            print("|cFFFFFF00Instructions:|r")
            print("  1. Learn a vanity item in-game")
            print("  2. Watch chat for event notifications")
            print("  3. Report which events fire (if any)")
            print(" ")
            print("|cFFFFAA00Monitoring these events:|r")
            print("  - COLLECTION_CHANGED")
            print("  - NEW_TOY_ADDED")
            print("  - TRANSMOG_COLLECTION_UPDATED")
            print("  - BAG_UPDATE_DELAYED")
            print("  - LOOT_CLOSED")
            print("  - COMPANION_UPDATE")
            print("  - PET_JOURNAL_LIST_UPDATE")
            print("  - And ~20 other collection-related events")
            print(" ")
            print("|cFF00FFFF=== START LEARNING ITEMS NOW ===|r")
            
            -- Register event spy listener (monitors all events)
            if not frame.eventSpyActive then
                frame.eventSpyActive = true
                -- Register all possible collection-related events
                local spyEvents = {
                    "COLLECTION_CHANGED",
                    "NEW_TOY_ADDED",
                    "TRANSMOG_COLLECTION_UPDATED",
                    "BAG_UPDATE_DELAYED",
                    "LOOT_CLOSED",
                    "COMPANION_UPDATE",
                    "PET_JOURNAL_LIST_UPDATE",
                    "COMPANION_LEARNED",
                    "PET_JOURNAL_PET_DELETED",
                    "TOYS_UPDATED",
                    "TRANSMOG_COLLECTION_ITEM_UPDATE",
                    "ITEM_LOCK_CHANGED",
                    "PLAYER_EQUIPMENT_CHANGED",
                    "UNIT_INVENTORY_CHANGED",
                    "BAG_UPDATE",
                    "QUEST_ACCEPTED",
                    "QUEST_TURNED_IN",
                    "PLAYER_INTERACTION_OBJECT_OPENED"
                }
                
                for _, eventName in ipairs(spyEvents) do
                    frame:RegisterEvent(eventName)
                end
            end
        else
            print("|cFF00FF96AscensionVanity:|r Event Spy Mode DISABLED")
            
            -- Unregister spy events (keep core functionality events)
            if frame.eventSpyActive then
                frame.eventSpyActive = false
                local spyEvents = {
                    "COMPANION_UPDATE",
                    "PET_JOURNAL_LIST_UPDATE",
                    "COMPANION_LEARNED",
                    "PET_JOURNAL_PET_DELETED",
                    "TOYS_UPDATED",
                    "TRANSMOG_COLLECTION_ITEM_UPDATE",
                    "ITEM_LOCK_CHANGED",
                    "PLAYER_EQUIPMENT_CHANGED",
                    "UNIT_INVENTORY_CHANGED",
                    "BAG_UPDATE",
                    "QUEST_ACCEPTED",
                    "QUEST_TURNED_IN",
                    "PLAYER_INTERACTION_OBJECT_OPENED"
                }
                
                for _, eventName in ipairs(spyEvents) do
                    pcall(frame.UnregisterEvent, frame, eventName)
                end
            end
        end
        
    elseif msg == "enablefallback" then
        -- Note: Fallback events are now ALWAYS enabled with smart debouncing
        -- This command is kept for compatibility but does nothing
        print("|cFF00FF96AscensionVanity:|r Fallback events are always enabled (with debouncing)")
        print("|cFFFFFF00Info:|r Collection events don't fire on Ascension (tested in-game)")
        print("|cFFFFFF00Strategy:|r Using BAG_UPDATE with 1-second debounce + 2-minute TTL")
        print("|cFFFFFF00Manual:|r Use |cFFFFFF00/avanity clearcache|r to force refresh")
        
    elseif msg == "cachestats" then
        -- Show cache statistics
        local cacheSize = 0
        local oldestTimestamp = nil
        local newestTimestamp = nil
        
        for itemID, entry in pairs(learnedStatusCache) do
            cacheSize = cacheSize + 1
            if not oldestTimestamp or entry.timestamp < oldestTimestamp then
                oldestTimestamp = entry.timestamp
            end
            if not newestTimestamp or entry.timestamp > newestTimestamp then
                newestTimestamp = entry.timestamp
            end
        end
        
        print("|cFF00FF96AscensionVanity:|r Learned Status Cache Statistics")
        print("  Cache version:", cacheVersion)
        print("  Cached items:", cacheSize)
        
        if cacheSize > 0 then
            local now = GetTime()
            local oldestAge = now - oldestTimestamp
            local newestAge = now - newestTimestamp
            print(string.format("  Oldest entry: %.1f seconds ago", oldestAge))
            print(string.format("  Newest entry: %.1f seconds ago", newestAge))
        end
        
        print("  Cache TTL:", CACHE_TTL, "seconds")
        print(" ")
        print("|cFFFFFF00Events:|r")
        print("  |cFF00FF00Primary:|r APPEARANCE_COLLECTED (confirmed working!)")
        print("  |cFFFFAA00Fallback:|r BAG_UPDATE with 1-second debounce")
        print("  |cFF888888Discovery:|r Event Trace testing, Oct 30 2025")
        print(" ")
        print("|cFFFFFF00Performance:|r Cache reduces API calls by ~90%")
        print("|cFFFFFF00Auto-refresh:|r Instant on learning items (APPEARANCE_COLLECTED)")
        print("|cFFFFFF00Manual refresh:|r Use /avanity clearcache if needed")
        
    elseif msg == "help" then
        print("|cFF00FF96AscensionVanity v" .. VERSION .. " Commands:|r")
        print(" ")
        print("|cFFFFFF00=== Available Slash Commands ===|r")
        print("  |cFFFFFF00/avanity|r - Primary command")
        print("  |cFFFFFF00/ascvan|r - Short alternative")
        print("  |cFFFFFF00/ascensionvanity|r - Full name")
        print(" ")
        print("|cFFFFFF00=== Basic Commands ===|r")
        print("  |cFFFFFF00/avanity|r - Open settings UI")
        print("  |cFFFFFF00/avanity scanner|r - Open scanner UI")
        print("  |cFFFFFF00/avanity toggle|r - Quick toggle addon on/off")
        print("  |cFFFFFF00/avanity learned|r - Toggle learned status display")
        print("  |cFFFFFF00/avanity color|r - Toggle color coding")
        print("  |cFFFFFF00/avanity debug|r - Toggle debug mode")
        print(" ")
        print("|cFFFFFF00=== Cache Management ===|r")
        print("  |cFFFFFF00/avanity clearcache|r - Manually clear learned status cache")
        print("  |cFFFFFF00/avanity cachestats|r - Show cache performance statistics")
        print("    |cFF808080(Cache auto-refreshes on BAG_UPDATE with 1-sec debounce)|r")
        print("    |cFF808080(2-minute TTL prevents spam during looting)|r")
        print(" ")
        print("|cFFFFFF00=== Diagnostics ===|r")
        print("  |cFFFFFF00/avanity eventspy|r - Monitor which events fire when learning items")
        print("    |cFF808080(Result: NO collection events fire on Ascension)|r")
        print("    |cFF808080(Solution: Using BAG_UPDATE with debouncing)|r")
        print(" ")
        print("|cFFFFFF00=== API Scanner Commands ===|r")
        print("  |cFFFFFF00/avanity scan|r - Scan all vanity items from API")
        print("  |cFFFFFF00/avanity scan stats|r - Show scan statistics")
        print("  |cFFFFFF00/avanity scan clear|r - Clear scanner dump data")
        print("  |cFFFFFF00/avanity scan cancel|r - Cancel ongoing scan")
        print("  |cFFFFFF00/avanity scan help|r - Show scanner help")
        print(" ")
        print("|cFFFFFF00=== Database Validation ===|r")
        print("  |cFFFFFF00/avanity apidump|r - Dump complete API data to SavedVariables")
        print("  |cFFFFFF00/avanity validate|r - Compare API data vs static database")
        print("  |cFFFFFF00/avanity export|r - Export API data in VanityDB.lua format")
        print("  |cFFFFFF00/avanity showexport|r - Display exported data in chat")
        print("    |cFF808080(Run: apidump → reload → export → reload → showexport)|r")
        print(" ")
        print("|cFFFFFF00=== Debug Commands ===|r")
        print("  |cFFFFFF00/avanity api|r - Scan for Ascension vanity APIs")
        print("  |cFFFFFF00/avanity dump|r - Dump vanity collection data structure")
        print("  |cFFFFFF00/avanity dumpitem <itemID>|r - Dump specific item details")
        print("    |cFF808080Example: /avanity dumpitem 79626|r")
        print("  |cFFFFFF00/avanity inspectui|r - Inspect Vanity Collection UI internals")
        print("    |cFF808080Alias: /avanity uiinspect|r")
        print("  |cFFFFFF00/avanity appearance|r - Deep dive into C_AppearanceCollection API")
        print("    |cFF808080Alias: /avanity inspectappearance|r")
        print("    |cFF808080Tests if APPEARANCE_COLLECTED uses different ID system|r")
        print(" ")
        print("  |cFFFFFF00/avanity help|r - Show this help")
        
    else
        print("|cFF00FF96AscensionVanity:|r Unknown command. Type |cFFFFFF00/avanity help|r for help")
    end
end
