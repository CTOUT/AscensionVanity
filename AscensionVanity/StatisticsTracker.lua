-- AscensionVanity - Statistics Tracker
-- Tracks kills and drops for farming efficiency analysis
-- Version: 2.3

-- ============================================================================
-- Local Variables
-- ============================================================================

local statsFrame = CreateFrame("Frame")
local playerClass, playerClassDisplayName
local realmName

-- ============================================================================
-- Initialization
-- ============================================================================

function statsFrame:Initialize()
    -- Get character info for metadata (simplified for Ascension compatibility)
    playerClass = select(2, UnitClass("player"))  -- Returns "HUNTER", "MAGE", etc.
    playerClassDisplayName = UnitClass("player")  -- Returns "Hunter", "Mage", etc.
    realmName = GetRealmName()
    
    -- Initialize creature stats if not exists
    if not AV_CreatureStats then
        AV_CreatureStats = {
            _metadata = {
                characterName = UnitName("player"),
                className = playerClass,
                classDisplayName = playerClassDisplayName,
                realm = realmName,
                dataVersion = "2.3.0",
            }
        }
    end
    
    -- Initialize session stats (always reset on login)
    self:InitializeSession()
    
    print("|cFF00FF96AscensionVanity:|r Statistics tracking enabled")
end

function statsFrame:InitializeSession()
    -- Reset session data on login (or manual reset)
    AV_SessionStats = {
        sessionStart = time(),
        lastKillTime = 0,
        creatures = {},
        summary = {
            totalKills = 0,
            totalDrops = 0,
            uniqueCreatures = 0,
            longestStreak = 0,
            topCreature = nil,
        }
    }
end

-- ============================================================================
-- Event Handlers
-- ============================================================================

function statsFrame:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        self:Initialize()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:OnCombatLog(...)  -- Pass combat log args
    elseif event == "LOOT_OPENED" then
        -- Ascension uses LOOT_OPENED instead of LOOT_READY
        self:OnLootReady()
    elseif event == "PLAYER_LOGOUT" then
        -- Data is saved automatically by SavedVariablesPerCharacter
    end
end

function statsFrame:OnCombatLog(...)
    -- Ascension combat log format (different from standard WOTLK!):
    -- arg1 = timestamp
    -- arg2 = subevent (PARTY_KILL, UNIT_DIED, etc.)
    -- arg3 = sourceGUID (hex)
    -- arg4 = sourceName (string)
    -- arg5 = sourceID (number)
    -- arg6 = destGUID (hex) ← WE NEED THIS!
    -- arg7 = destName (string) ← AND THIS!
    -- arg8 = destID (number)
    local timestamp, subevent, sourceGUID, sourceName, sourceID, 
          destGUID, destName, destID = ...
    
    -- Only track PARTY_KILL (you or your group got kill credit)
    if subevent ~= "PARTY_KILL" then
        return
    end
    
    -- Extract creature ID from hex GUID
    local creatureId = self:ExtractCreatureID(destGUID)
    if not creatureId then
        return
    end
    
    -- Store last killed creature for loot correlation (always track for loot detection)
    self.lastKilledCreatureId = creatureId
    self.lastKilledCreatureName = destName
    self.lastKilledGUID = destGUID
    self.lastKillTime = time()
    
    -- Only track stats for creatures in VanityDB (creatures that can drop vanity items)
    if self:IsVanityCreature(creatureId) then
        self:RecordKill(creatureId, destName, false)  -- wasLooted = false (not looted yet)
    end
end

-- ============================================================================
-- Kill Tracking
-- ============================================================================

function statsFrame:RecordKill(creatureId, creatureName, wasLooted)
    -- Initialize creature stats if first kill
    if not AV_CreatureStats[creatureId] then
        AV_CreatureStats[creatureId] = {
            totalKilled = 0,      -- All kills (looted + skipped)
            totalLooted = 0,      -- Only looted creatures
            totalDrops = 0,
            firstKillDate = time(),
            lastKillDate = 0,
            lastDropDate = 0,
            dropsByCategory = {},
        }
    end
    
    -- Update lifetime stats
    local stats = AV_CreatureStats[creatureId]
    
    -- Migrate old data format (totalKills -> totalKilled/totalLooted)
    if stats.totalKills and not stats.totalKilled then
        stats.totalKilled = stats.totalKills
        stats.totalLooted = stats.totalKills  -- Assume all were looted in old version
        stats.totalKills = nil  -- Remove old field
    end
    
    -- Ensure fields exist (for partial migrations)
    stats.totalKilled = stats.totalKilled or 0
    stats.totalLooted = stats.totalLooted or 0
    
    stats.totalKilled = stats.totalKilled + 1
    if wasLooted then
        stats.totalLooted = stats.totalLooted + 1
    end
    stats.lastKillDate = time()
    
    -- Update session stats
    if not AV_SessionStats.creatures[creatureId] then
        AV_SessionStats.creatures[creatureId] = {
            sessionKilled = 0,
            sessionLooted = 0,
            sessionDrops = 0,
            firstKillTime = time(),
            lastKillTime = 0,
        }
    end
    
    local sessionStats = AV_SessionStats.creatures[creatureId]
    
    -- Migrate old session data format
    if sessionStats.sessionKills and not sessionStats.sessionKilled then
        sessionStats.sessionKilled = sessionStats.sessionKills
        sessionStats.sessionLooted = sessionStats.sessionKills  -- Assume all were looted
        sessionStats.sessionKills = nil  -- Remove old field
    end
    
    -- Ensure fields exist
    sessionStats.sessionKilled = sessionStats.sessionKilled or 0
    sessionStats.sessionLooted = sessionStats.sessionLooted or 0
    
    sessionStats.sessionKilled = sessionStats.sessionKilled + 1
    if wasLooted then
        sessionStats.sessionLooted = sessionStats.sessionLooted + 1
    end
    sessionStats.lastKillTime = time()
    
    -- Update session summary
    AV_SessionStats.summary.totalKills = AV_SessionStats.summary.totalKills + 1
    AV_SessionStats.lastKillTime = time()
    
    -- Track unique creatures
    local uniqueCount = 0
    for _ in pairs(AV_SessionStats.creatures) do
        uniqueCount = uniqueCount + 1
    end
    AV_SessionStats.summary.uniqueCreatures = uniqueCount
    
    -- Determine top creature (most kills in session)
    local topKills = 0
    local topCreature = nil
    for cid, cstats in pairs(AV_SessionStats.creatures) do
        local killed = cstats.sessionKilled or cstats.sessionKills or 0  -- Support both old and new field names
        if killed > topKills then
            topKills = killed
            topCreature = cid
        end
    end
    AV_SessionStats.summary.topCreature = topCreature
    AV_SessionStats.summary.longestStreak = topKills
    
    -- Optional: Print to chat if configured
    if AV_Config and AV_Config.chatNotifyKills then
        print(string.format("|cFF00FF96AscensionVanity:|r Kill #%d: %s",
            stats.totalKilled, creatureName or "Unknown"))
    end
end

-- ============================================================================
-- Drop Detection
-- ============================================================================

function statsFrame:OnLootReady()
    -- Use the last killed creature (from PARTY_KILL event)
    local creatureId = self.lastKilledCreatureId
    local creatureName = self.lastKilledCreatureName
    local creatureGUID = self.lastKilledGUID
    
    if not creatureId then
        -- Fallback: try to get from target
        local guid = UnitGUID("target")
        if guid then
            creatureId = self:ExtractCreatureID(guid)
            creatureName = UnitName("target")
            creatureGUID = guid
        end
    end
    
    if not creatureId then return end
    
    -- Only track loot stats for creatures in VanityDB
    if self:IsVanityCreature(creatureId) then
        -- Check if we've already looted this specific creature (by GUID)
        -- This prevents counting the same corpse multiple times
        if self.lastLootedGUID == creatureGUID then
            -- Already looted this creature - don't count again
            -- But still check for vanity items (in case user didn't take them first time)
            print(string.format("|cFF888888AscensionVanity:|r Already counted loot from %s", creatureName or "creature"))
        else
            -- First time looting this creature - increment counters
            self.lastLootedGUID = creatureGUID
            
            local stats = AV_CreatureStats[creatureId]
            if stats then
                stats.totalLooted = stats.totalLooted + 1
            end
            
            local sessionStats = AV_SessionStats and AV_SessionStats.creatures and AV_SessionStats.creatures[creatureId]
            if sessionStats then
                sessionStats.sessionLooted = sessionStats.sessionLooted + 1
            end
        end
    end
    
    -- Check loot slots for vanity items
    local foundVanity = false
    local numSlots = GetNumLootItems()
    print(string.format("|cFFFF0000[DEBUG]|r Checking %d loot slots for vanity items", numSlots))
    
    for slot = 1, numSlots do
        local itemLink = GetLootSlotLink(slot)
        if itemLink then
            local itemId = tonumber(itemLink:match("item:(%d+)"))
            print(string.format("|cFFFF0000[DEBUG]|r Slot %d: Item ID %s", slot, tostring(itemId)))
            
            if itemId then
                local isVanity = self:IsVanityItem(itemId)
                print(string.format("|cFFFF0000[DEBUG]|r Item %d is vanity: %s", itemId, tostring(isVanity)))
                
                if isVanity then
                    -- Check if this is an unexpected drop (creature not in VanityDB)
                    local isExpected = self:IsVanityCreature(creatureId)
                    if not isExpected then
                        print(string.format("|cFFFF0000[ALERT]|r Unexpected vanity drop from %s (ID: %d) - NOT IN DATABASE!", 
                            creatureName or "Unknown", creatureId))
                    end
                    
                    self:RecordDrop(creatureId, itemId, not isExpected)
                    foundVanity = true
                end
            end
        end
    end
    
    -- Print result
    if foundVanity then
        print(string.format("|cFF00FF96AscensionVanity:|r Looted %s (ID: %d) - *** VANITY ITEM! ***", 
            creatureName or "Unknown", creatureId))
    end
    
    -- Clear last killed creature
    self.lastKilledCreatureId = nil
    self.lastKilledCreatureName = nil
    self.lastKilledGUID = nil
end

function statsFrame:RecordDrop(creatureId, itemId, isUnexpected)
    print(string.format("|cFFFF0000[DEBUG]|r RecordDrop called: creature=%d, item=%d, unexpected=%s", 
        creatureId or 0, itemId or 0, tostring(isUnexpected)))
    
    -- Update lifetime stats (or create if unexpected)
    local stats = AV_CreatureStats[creatureId]
    if not stats and isUnexpected then
        -- Create entry for unexpected drop
        stats = {
            totalKilled = 0,
            totalLooted = 1,  -- We know it was looted (we got the drop)
            totalDrops = 0,
            firstKillDate = time(),
            lastKillDate = time(),
            lastDropDate = 0,
            dropsByCategory = {},
            unexpected = true  -- Mark as unexpected
        }
        AV_CreatureStats[creatureId] = stats
    end
    
    if stats then
        stats.totalDrops = stats.totalDrops + 1
        stats.lastDropDate = time()
        
        -- Track by category for class affinity research
        local itemCategory = self:GetItemCategory(itemId)
        if itemCategory then
            stats.dropsByCategory[itemCategory] = (stats.dropsByCategory[itemCategory] or 0) + 1
        end
    end
    
    -- Update session stats
    local sessionStats = AV_SessionStats.creatures[creatureId]
    if sessionStats then
        sessionStats.sessionDrops = sessionStats.sessionDrops + 1
    end
    
    -- Update session summary
    AV_SessionStats.summary.totalDrops = AV_SessionStats.summary.totalDrops + 1
    
    print("|cFFFF0000[DEBUG]|r Calling CelebrateDrop...")
    -- 🎉 CELEBRATION TIME! 🎉
    self:CelebrateDrop(creatureId, itemId, stats)
end

-- ============================================================================
-- Drop Celebration (Achievement-style Announcement)
-- ============================================================================

function statsFrame:CelebrateDrop(creatureId, itemId, stats)
    local itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
    
    -- Item info might not be cached yet - retry after a short delay
    if not itemName then
        C_Timer.After(0.5, function()
            self:CelebrateDrop(creatureId, itemId, stats)
        end)
        return
    end
    
    -- Play achievement sound
    PlaySoundFile("Sound\\Interface\\LevelUp.ogg")
    
    -- Get drop chance for context (based on looted creatures only)
    local dropChance = 0
    if stats and stats.totalLooted > 0 then
        dropChance = (stats.totalDrops / stats.totalLooted) * 100
    end
    
    -- Format the announcement
    local category = self:GetItemCategory(itemId) or "Combat Pet"
    local killsText = stats and stats.totalLooted > 1 
        and string.format(" after looting %d", stats.totalLooted)
        or ""
    
    -- Big announcement in chat (multiple lines for impact!)
    print(" ")
    print("|cFFFFFF00" .. string.rep("=", 60) .. "|r")
    print("|cFFFF6600        🎉 VANITY ITEM ACQUIRED! 🎉|r")
    print("|cFFFFFF00" .. string.rep("=", 60) .. "|r")
    print(" ")
    print(string.format("    %s", itemLink))
    print(" ")
    print(string.format("    |cFF00FF96Category:|r %s", category))
    if stats and stats.totalLooted > 0 then
        print(string.format("    |cFF00FF96Drop Chance:|r %.2f%% (from %d looted)", dropChance, stats.totalLooted))
        if stats.totalKilled > stats.totalLooted then
            print(string.format("    |cFF888888Killed %d total (%d not looted)|r", stats.totalKilled, stats.totalKilled - stats.totalLooted))
        end
    end
    print(" ")
    print("|cFFFFFF00" .. string.rep("=", 60) .. "|r")
    print(" ")
    
    -- Also send a raid warning style message (if enabled)
    if AV_Config and AV_Config.showDropRaidWarning ~= false then
        local simpleMessage = string.format("VANITY ITEM: %s%s!", itemName, killsText)
        RaidNotice_AddMessage(RaidWarningFrame, simpleMessage, ChatTypeInfo["RAID_WARNING"])
    end
    
    -- Screen flash effect (optional, if enabled)
    if AV_Config and AV_Config.flashScreenOnDrop then
        self:FlashScreen()
    end
end

function statsFrame:FlashScreen()
    -- Create a brief screen flash animation
    local flash = UIParent:CreateTexture(nil, "FULLSCREEN_DIALOG")
    flash:SetAllPoints(UIParent)
    flash:SetTexture(1, 1, 1, 0.3)
    flash:SetBlendMode("ADD")
    
    -- Fade out animation
    local fadeOut = flash:CreateAnimationGroup()
    local alpha = fadeOut:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0.3)
    alpha:SetToAlpha(0)
    alpha:SetDuration(0.5)
    alpha:SetSmoothing("OUT")
    
    fadeOut:SetScript("OnFinished", function()
        flash:Hide()
        flash:SetParent(nil)
    end)
    
    fadeOut:Play()
end

-- ============================================================================
-- Helper Functions
-- ============================================================================

function statsFrame:ExtractCreatureID(guid)
    if not guid then return nil end
    
    -- Ascension uses hex GUID format: 0xF130001D0DC005B0F
    -- Format: 0x [F1] [3000] [1D0DC0] [05B0F]
    --            ^    ^      ^        ^
    --            |    |      |        spawn UID
    --            |    |      creature ID (middle 6 hex digits)
    --            |    type
    --            flags
    
    if type(guid) == "string" then
        -- Remove 0x prefix if present
        local hexGuid = guid:gsub("^0x", "")
        
        -- Extract creature ID from hex GUID (bits 32-63, middle section)
        -- For 0xF130001D0DC005B0F, creature ID is 0x1D0DC0 = 1904064
        if #hexGuid >= 10 then
            local creatureIDHex = hexGuid:sub(5, 10)  -- Get middle 6 hex digits
            local creatureID = tonumber(creatureIDHex, 16)  -- Convert from hex to decimal
            return creatureID
        end
    end
    
    return nil
end

function statsFrame:IsVanityCreature(creatureId)
    -- Check if creature is in our vanity database (can drop vanity items)
    if not AV_VanityItems then return false end
    
    -- Use VanityDB_Loader's lookup function if available
    if AV_GetVanityItemsForCreature then
        local items = AV_GetVanityItemsForCreature(creatureId)
        return items and #items > 0
    end
    
    return false
end

function statsFrame:IsVanityItem(itemId)
    -- Check if item is in our vanity database
    -- This requires VanityDB to be loaded first
    if not AV_VanityItems then return false end
    
    -- Search through all creatures and items
    for creatureName, creatureData in pairs(AV_VanityItems) do
        if creatureData.items then
            for _, item in ipairs(creatureData.items) do
                if item.id == itemId then
                    return true
                end
            end
        end
    end
    
    return false
end

function statsFrame:GetItemCategory(itemId)
    -- Get category from item name prefix
    if not AV_VanityItems then return nil end
    
    -- Search for the item and return its category
    for creatureName, creatureData in pairs(AV_VanityItems) do
        if creatureData.items then
            for _, item in ipairs(creatureData.items) do
                if item.id == itemId then
                    -- Category is determined by the prefix in the item name
                    if item.name:find("Beastmaster's Whistle") then
                        return "Beast"
                    elseif item.name:find("Elemental Lodestone") then
                        return "Elemental"
                    elseif item.name:find("Draconic Warhorn") then
                        return "Dragonkin"
                    elseif item.name:find("Summoner's Stone") then
                        return "Demon"
                    elseif item.name:find("Blood Soaked Vellum") then
                        return "Undead"
                    end
                end
            end
        end
    end
    
    return nil
end

-- ============================================================================
-- Global Access Functions
-- ============================================================================

function AV_GetCreatureStats(creatureId)
    return AV_CreatureStats and AV_CreatureStats[creatureId]
end

function AV_GetSessionStats(creatureId)
    return AV_SessionStats and AV_SessionStats.creatures and AV_SessionStats.creatures[creatureId]
end

function AV_ResetSession()
    if statsFrame then
        statsFrame:InitializeSession()
        print("|cFF00FF96AscensionVanity:|r Session statistics reset")
    end
end

function AV_CleanupNonVanityStats()
    -- Remove stats for creatures not in VanityDB
    local removed = 0
    local kept = 0
    
    for creatureId, stats in pairs(AV_CreatureStats) do
        if creatureId ~= "_metadata" then
            if not statsFrame:IsVanityCreature(creatureId) then
                AV_CreatureStats[creatureId] = nil
                removed = removed + 1
            else
                kept = kept + 1
            end
        end
    end
    
    print(string.format("|cFF00FF96AscensionVanity:|r Cleanup complete: Removed %d non-vanity creatures, kept %d vanity creatures", removed, kept))
end

function AV_ResetAllStats()
    -- Confirmation required (should be called from UI with confirmation dialog)
    AV_CreatureStats = {
        _metadata = {
            characterName = UnitName("player"),
            className = playerClass,
            classDisplayName = playerClassDisplayName,
            realm = realmName,
            dataVersion = "2.3.0",
        }
    }
    statsFrame:InitializeSession()
    print("|cFF00FF96AscensionVanity:|r All statistics reset")
end

-- ============================================================================
-- Event Registration
-- ============================================================================

statsFrame:RegisterEvent("PLAYER_LOGIN")
statsFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
statsFrame:RegisterEvent("LOOT_OPENED")  -- Ascension uses LOOT_OPENED, not LOOT_READY
statsFrame:RegisterEvent("PLAYER_LOGOUT")

statsFrame:SetScript("OnEvent", function(self, event, ...)
    self:OnEvent(event, ...)
end)
