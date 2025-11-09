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
    -- Get character info for metadata
    local className
    _, playerClassDisplayName, _, _, _, className = GetPlayerInfoByGUID(UnitGUID("player"))
    playerClass = className
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
        self:OnCombatLog()
    elseif event == "LOOT_READY" then
        self:OnLootReady()
    elseif event == "PLAYER_LOGOUT" then
        -- Data is saved automatically by SavedVariablesPerCharacter
    end
end

function statsFrame:OnCombatLog()
    local timestamp, subevent, _, sourceGUID, sourceName, _, _, 
          destGUID, destName, destFlags = CombatLogGetCurrentEventInfo()
    
    -- Only track PARTY_KILL events (we or our group killed something)
    if subevent ~= "PARTY_KILL" then
        return
    end
    
    -- Extract creature ID from GUID
    local creatureId = self:ExtractCreatureID(destGUID)
    if not creatureId then
        return
    end
    
    -- Record the kill
    self:RecordKill(creatureId, destName)
end

-- ============================================================================
-- Kill Tracking
-- ============================================================================

function statsFrame:RecordKill(creatureId, creatureName)
    -- Initialize creature stats if first kill
    if not AV_CreatureStats[creatureId] then
        AV_CreatureStats[creatureId] = {
            totalKills = 0,
            totalDrops = 0,
            firstKillDate = time(),
            lastKillDate = 0,
            lastDropDate = 0,
            dropsByCategory = {},
        }
    end
    
    -- Update lifetime stats
    local stats = AV_CreatureStats[creatureId]
    stats.totalKills = stats.totalKills + 1
    stats.lastKillDate = time()
    
    -- Update session stats
    if not AV_SessionStats.creatures[creatureId] then
        AV_SessionStats.creatures[creatureId] = {
            sessionKills = 0,
            sessionDrops = 0,
            firstKillTime = time(),
            lastKillTime = 0,
        }
    end
    
    local sessionStats = AV_SessionStats.creatures[creatureId]
    sessionStats.sessionKills = sessionStats.sessionKills + 1
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
        if cstats.sessionKills > topKills then
            topKills = cstats.sessionKills
            topCreature = cid
        end
    end
    AV_SessionStats.summary.topCreature = topCreature
    AV_SessionStats.summary.longestStreak = topKills
    
    -- Optional: Print to chat if configured
    if AV_Config and AV_Config.chatNotifyKills then
        print(string.format("|cFF00FF96AscensionVanity:|r Kill #%d: %s",
            stats.totalKills, creatureName or "Unknown"))
    end
end

-- ============================================================================
-- Drop Detection
-- ============================================================================

function statsFrame:OnLootReady()
    -- Get currently targeted creature
    local guid = UnitGUID("target")
    if not guid then return end
    
    local creatureId = self:ExtractCreatureID(guid)
    if not creatureId then return end
    
    -- Check loot slots for vanity items
    for slot = 1, GetNumLootItems() do
        local itemLink = GetLootSlotLink(slot)
        if itemLink then
            local itemId = tonumber(itemLink:match("item:(%d+)"))
            if itemId and self:IsVanityItem(itemId) then
                self:RecordDrop(creatureId, itemId)
            end
        end
    end
end

function statsFrame:RecordDrop(creatureId, itemId)
    -- Update lifetime stats
    local stats = AV_CreatureStats[creatureId]
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
    
    -- 🎉 CELEBRATION TIME! 🎉
    self:CelebrateDrop(creatureId, itemId, stats)
end

-- ============================================================================
-- Drop Celebration (Achievement-style Announcement)
-- ============================================================================

function statsFrame:CelebrateDrop(creatureId, itemId, stats)
    local itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
    if not itemName then return end
    
    -- Play achievement sound
    PlaySoundFile("Sound\\Interface\\LevelUp.ogg")
    
    -- Get drop chance for context
    local dropChance = 0
    if stats and stats.totalKills > 0 then
        dropChance = (stats.totalDrops / stats.totalKills) * 100
    end
    
    -- Format the announcement
    local category = self:GetItemCategory(itemId) or "Combat Pet"
    local killsText = stats and stats.totalKills > 1 
        and string.format(" after %d kills", stats.totalKills)
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
    if stats and stats.totalKills > 0 then
        print(string.format("    |cFF00FF96Drop Chance:|r %.2f%% (based on your data)", dropChance))
        print(string.format("    |cFF00FF96Total Kills:|r %d", stats.totalKills))
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
    
    -- GUID format: Creature-0-Server-Map-Reserved-CreatureID-SpawnID
    local creatureId = tonumber(guid:match("Creature%-0%-%d+%-%d+%-%d+%-(%d+)"))
    return creatureId
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
statsFrame:RegisterEvent("LOOT_READY")
statsFrame:RegisterEvent("PLAYER_LOGOUT")

statsFrame:SetScript("OnEvent", function(self, event, ...)
    self:OnEvent(event, ...)
end)
