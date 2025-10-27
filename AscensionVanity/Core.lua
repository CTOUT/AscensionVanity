-- AscensionVanity - Core Functionality
-- Hooks into tooltips to display vanity item information

local AddonName = "AscensionVanity"
local VERSION = "1.0.0"

-- Initialize saved variables
AscensionVanityDB = AscensionVanityDB or {
    enabled = true,
    showLearnedStatus = true,
    colorCode = true,
    debug = false,  -- Debug mode off by default
}

-- Color codes for tooltip text
local COLOR_VANITY_HEADER = "|cFF00FF96" -- Teal/cyan
local COLOR_VANITY_LEARNED = "|cFF00FF00" -- Green
local COLOR_VANITY_UNLEARNED = "|cFFFFFF00" -- Yellow
local COLOR_RESET = "|r"

-- Item type icons (icon IDs from Ascension database)
-- Icons verified from https://db.ascension.gg/?icon=<ID>
local ITEM_ICONS = {
    ["Beastmaster's Whistle"] = "|TInterface\\Icons\\ability_hunter_beastcall:16|t",  -- Icon 455
    ["Blood Soaked Vellum"] = "|TInterface\\Icons\\inv_glyph_primedeathknight:16|t",  -- Icon 13479
    ["Summoner's Stone"] = "|TInterface\\Icons\\inv_misc_uncutgemnormal1:16|t",  -- Icon 19474
    ["Draconic Warhorn"] = "|TInterface\\Icons\\inv_misc_horn_01:16|t",  -- Icon 1550
    ["Elemental Lodestone"] = "|TInterface\\Icons\\custom_t_nhance_rpg_icons_arcanestone_border:16|t",  -- Icon 62794
}

-- Local reference to GameTooltip
local tooltip = GameTooltip

-- Utility: Debug print (only prints if debug mode enabled)
local function DebugPrint(...)
    if AscensionVanityDB.debug then
        print("|cFF00FF96[AV Debug]|r", ...)
    end
end

-- Utility: Check if player has learned a vanity item
-- Uses Ascension's C_VanityCollection.IsCollectionItemOwned API
local function IsVanityItemLearned(itemID, itemName)
    if not itemID then
        return nil
    end
    
    -- Use Ascension's official vanity collection API
    if C_VanityCollection and C_VanityCollection.IsCollectionItemOwned then
        local isOwned = C_VanityCollection.IsCollectionItemOwned(itemID)
        DebugPrint("Item", itemID, "owned status:", isOwned)
        return isOwned
    end
    
    -- Fallback: API not available
    DebugPrint("C_VanityCollection.IsCollectionItemOwned not available")
    return nil
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
                -- Fetch localized item name from game API (language-independent)
                local itemName = GetItemInfo(itemID)
                if not itemName then
                    -- Item not yet cached, skip for now
                    -- Game will cache it and show on next tooltip
                    itemName = "Loading..."
                end
                
                -- Extract item type from name to get the icon
                local itemIcon = ""
                for itemType, icon in pairs(ITEM_ICONS) do
                    if string.find(itemName, itemType, 1, true) then
                        itemIcon = icon .. " "
                        break
                    end
                end
                
                local itemText = itemIcon .. itemName
                
                -- Check if player has learned this item (optional feature)
                if AscensionVanityDB.showLearnedStatus then
                    local isLearned = IsVanityItemLearned(itemID, itemName)
                    
                    if isLearned == true then
                        -- Learned: Green with WoW checkmark icon
                        local checkmark = "|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t"
                        if AscensionVanityDB.colorCode then
                            itemText = COLOR_VANITY_LEARNED .. checkmark .. " " .. itemText .. COLOR_RESET
                        else
                            itemText = checkmark .. " " .. itemText
                        end
                    elseif isLearned == false then
                        local cross = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:16|t"
                        -- Unlearned: Yellow with WoW cross icon
                        if AscensionVanityDB.colorCode then
                            itemText = COLOR_VANITY_UNLEARNED .. cross .. " " .. itemText .. COLOR_RESET
                        else
                            itemText = "   " .. itemText
                        end
                    else
                        -- Unknown status: Default color, no indicator
                        itemText = "   " .. itemText
                    end
                else
                    -- Learned status disabled: No indicator, default color
                    itemText = "   " .. itemText
                end
                
                tooltip:AddLine(itemText, 1, 1, 1, true) -- White text, word wrap enabled
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

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == AddonName then
        -- Addon loaded
        print("|cFF00FF96AscensionVanity|r v" .. VERSION .. " loaded!")
        print("Type |cFFFFFF00/av help|r for commands")
        
    elseif event == "PLAYER_LOGIN" then
        -- Hook into GameTooltip after player login
        GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
        
        -- Also hook into other tooltip types if needed
        -- GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
    end
end)

-- Slash commands
SLASH_ASCENSIONVANITY1 = "/av"
SLASH_ASCENSIONVANITY2 = "/ascensionvanity"

SlashCmdList["ASCENSIONVANITY"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "toggle" or msg == "" then
        AscensionVanityDB.enabled = not AscensionVanityDB.enabled
        if AscensionVanityDB.enabled then
            print("|cFF00FF96AscensionVanity:|r Enabled")
        else
            print("|cFF00FF96AscensionVanity:|r Disabled")
        end
        
    elseif msg == "learned" then
        AscensionVanityDB.showLearnedStatus = not AscensionVanityDB.showLearnedStatus
        if AscensionVanityDB.showLearnedStatus then
            print("|cFF00FF96AscensionVanity:|r Learned status display enabled")
        else
            print("|cFF00FF96AscensionVanity:|r Learned status display disabled")
        end
        
    elseif msg == "color" then
        AscensionVanityDB.colorCode = not AscensionVanityDB.colorCode
        if AscensionVanityDB.colorCode then
            print("|cFF00FF96AscensionVanity:|r Color coding enabled")
        else
            print("|cFF00FF96AscensionVanity:|r Color coding disabled")
        end
        
    elseif msg == "debug" then
        AscensionVanityDB.debug = not AscensionVanityDB.debug
        if AscensionVanityDB.debug then
            print("|cFF00FF96AscensionVanity:|r Debug mode enabled")
        else
            print("|cFF00FF96AscensionVanity:|r Debug mode disabled")
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
                    print("|cFFFFFF00Try:|r /av dump to see what items ARE in your collection")
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
                    print("|cFFFFFF00Tip:|r Use '/av dumpitem <itemID>' to search for a specific item")
                    print("|cFFFFFF00Example:|r /av dumpitem 79626  (Savannah Prowler whistle)")
                end
            else
                print("|cFFFF0000Error:|r GetAllItems() returned nil")
            end
        else
            print("|cFFFF0000Error:|r C_VanityCollection.GetAllItems not available")
        end
        
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
        print("|cFFFFFF00Validation:|r Use '/av validate' to compare API vs database")
        
    elseif msg == "validate" then
        -- Compare API data with our static database
        print("|cFF00FF96AscensionVanity:|r Validating database against API...")
        
        if not AscensionVanityDB.APIDump then
            print("|cFFFF0000Error:|r No API dump found. Run '/av apidump' first")
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
            print("|cFFFF0000Error:|r No API dump found. Run '/av apidump' first")
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
        print("|cFFFFFF00To view formatted output:|r /av showexport")
        
    elseif msg == "showexport" then
        -- Display exported data in chat (paginated)
        print("|cFF00FF96AscensionVanity:|r Displaying exported API data...")
        
        if not AscensionVanityDB.ExportedData then
            print("|cFFFF0000Error:|r No export found. Run '/av export' first")
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
        
    elseif msg == "help" then
        print("|cFF00FF96AscensionVanity v" .. VERSION .. " Commands:|r")
        print(" ")
        print("|cFFFFFF00=== Basic Commands ===|r")
        print("  |cFFFFFF00/av|r or |cFFFFFF00/av toggle|r - Toggle addon on/off")
        print("  |cFFFFFF00/av learned|r - Toggle learned status display")
        print("  |cFFFFFF00/av color|r - Toggle color coding")
        print("  |cFFFFFF00/av debug|r - Toggle debug mode")
        print(" ")
        print("|cFFFFFF00=== Database Validation ===|r")
        print("  |cFFFFFF00/av apidump|r - Dump complete API data to SavedVariables")
        print("  |cFFFFFF00/av validate|r - Compare API data vs static database")
        print("  |cFFFFFF00/av export|r - Export API data in VanityDB.lua format")
        print("  |cFFFFFF00/av showexport|r - Display exported data in chat")
        print("    |cFF808080(Run: apidump → reload → export → reload → showexport)|r")
        print(" ")
        print("|cFFFFFF00=== Debug Commands ===|r")
        print("  |cFFFFFF00/av api|r - Scan for Ascension vanity APIs")
        print("  |cFFFFFF00/av dump|r - Dump vanity collection data structure")
        print("  |cFFFFFF00/av dumpitem <itemID>|r - Dump specific item details")
        print("    |cFF808080Example: /av dumpitem 79626|r")
        print(" ")
        print("  |cFFFFFF00/av help|r - Show this help")
        
    else
        print("|cFF00FF96AscensionVanity:|r Unknown command. Type |cFFFFFF00/av help|r for help")
    end
end
