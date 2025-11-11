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

-- Create achievement-style popup frame (created once, reused)
local celebrationFrame = nil

local function CreateCelebrationFrame()
    if celebrationFrame then return celebrationFrame end
    
    -- Main frame (custom design, properly sized for content)
    local frame = CreateFrame("Frame", "AV_CelebrationFrame", UIParent)
    frame:SetSize(350, 90)  -- Base size, will be adjusted dynamically
    frame:SetPoint("TOP", UIParent, "TOP", 0, -120)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(100)
    frame:Hide()
    
    -- Function to resize frame based on text content
    frame.ResizeForContent = function(self, itemTypePart, petNamePart)
        -- Calculate required width based on longest text line
        local titleWidth = 220  -- "Vanity Item Acquired!" - roughly 180px, +40 buffer
        local typeWidth = (itemTypePart and string.len(itemTypePart) * 7) or 0  -- Rough char width
        local petWidth = (petNamePart and string.len(petNamePart) * 10) or 0    -- Larger font
        local statsWidth = 200  -- "Beast - 2.9% after 35 attempts" - roughly 180px
        
        local maxTextWidth = math.max(titleWidth, typeWidth, petWidth, statsWidth)
        local totalWidth = math.max(350, 80 + maxTextWidth)  -- 80px for icon + padding, min 350
        local totalHeight = 90  -- Keep height consistent
        
        self:SetSize(totalWidth, totalHeight)
        
        -- Update text width for new frame size
        local newTextWidth = totalWidth - 80  -- Account for icon + padding
        return newTextWidth
    end
    
    -- Custom background (solid with border, not stretched texture)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)  -- Dark background
    
    -- Gold border (like achievement frames)
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
    })
    border:SetBackdropBorderColor(1, 0.8, 0, 1)  -- Gold border
    
    -- Simple glow effect (animated border glow)
    local glow = border:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints(border)
    glow:SetTexture("Interface\\Glues\\Common\\Glue-Tooltip-Background")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(1, 0.8, 0, 0.3)  -- Subtle gold glow
    glow:SetAlpha(0)
    
    -- Simple icon frame (no stretched textures)
    local iconFrame = CreateFrame("Frame", nil, frame)
    iconFrame:SetSize(48, 48)
    iconFrame:SetPoint("LEFT", frame, "LEFT", 15, 0)
    
    -- Icon border (behind the icon)
    local iconBorder = iconFrame:CreateTexture(nil, "BACKGROUND")
    iconBorder:SetAllPoints()
    iconBorder:SetColorTexture(0.8, 0.6, 0, 1)  -- Gold border
    
    -- Icon background (behind the icon)
    local iconBg = iconFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
    iconBg:SetPoint("TOPLEFT", 2, -2)
    iconBg:SetPoint("BOTTOMRIGHT", -2, 2)
    iconBg:SetColorTexture(0, 0, 0, 0.8)  -- Dark background for icon
    
    -- The actual icon (on top)
    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 3, -3)  -- Inset to show border
    icon:SetPoint("BOTTOMRIGHT", -3, 3)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    -- Text layout (optimized for custom frame)
    local textX = 70  -- Start after icon + padding
    local textWidth = 270  -- Remaining width for text
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", textX, -12)
    title:SetSize(textWidth, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(1, 1, 0)  -- Yellow
    title:SetText("Vanity Item Acquired!")
    
    -- Item type line
    local itemType = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemType:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    itemType:SetSize(textWidth, 0)
    itemType:SetJustifyH("LEFT")
    itemType:SetTextColor(1, 0.82, 0)  -- Gold
    
    -- Pet name line
    local petName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    petName:SetPoint("TOPLEFT", itemType, "BOTTOMLEFT", 0, -1)
    petName:SetSize(textWidth, 0)
    petName:SetJustifyH("LEFT")
    petName:SetTextColor(1, 1, 1)  -- White
    
    -- Stats line with collection status
    local statsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statsText:SetPoint("TOPLEFT", petName, "BOTTOMLEFT", 0, -2)
    statsText:SetSize(textWidth, 0)
    statsText:SetJustifyH("LEFT")
    statsText:SetTextColor(0.8, 0.8, 0.8)  -- Light gray
    
    -- Collection status indicator (NEW vs DUPLICATE)
    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 8)
    statusText:SetJustifyH("RIGHT")
    
    -- Store references
    frame.glow = glow
    frame.icon = icon
    frame.title = title
    frame.itemType = itemType
    frame.petName = petName
    frame.statsText = statsText
    frame.statusText = statusText
    
    -- Animation groups for glow (WOTLK 3.3.5 compatible) - slower animations
    frame.glowAnimIn = glow:CreateAnimationGroup()
    local glowFadeIn = frame.glowAnimIn:CreateAnimation("Alpha")
    glowFadeIn:SetChange(1)
    glowFadeIn:SetDuration(0.4)  -- Increased from 0.2
    
    frame.glowAnimOut = glow:CreateAnimationGroup()
    local glowFadeOut = frame.glowAnimOut:CreateAnimation("Alpha")
    glowFadeOut:SetChange(-1)
    glowFadeOut:SetDuration(1.0)  -- Increased from 0.5
    glowFadeOut:SetStartDelay(0.5)  -- Increased from 0.2
    
    -- Chain animations
    frame.glowAnimIn:SetScript("OnFinished", function()
        frame.glowAnimOut:Play()
    end)
    
    frame.glowAnimOut:SetScript("OnFinished", function()
        C_Timer.After(5, function()
            frame:Hide()
        end)
    end)
    
    celebrationFrame = frame
    return frame
end

function statsFrame:CelebrateDrop(creatureId, itemId, stats)
    local itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
    
    -- Item info might not be cached yet - retry after a short delay
    if not itemName then
        C_Timer.After(0.5, function()
            self:CelebrateDrop(creatureId, itemId, stats)
        end)
        return
    end
    
    -- Play achievement sound (use PlaySound for better compatibility)
    PlaySound("LevelUp")  -- Classic level-up sound, guaranteed to work
    
    -- Get drop chance for context (based on looted creatures only)
    local dropChance = 0
    if stats and stats.totalLooted > 0 then
        dropChance = (stats.totalDrops / stats.totalLooted) * 100
    end
    
    -- Format the stats text
    local category = self:GetItemCategory(itemId) or "Combat Pet"
    local statsLine = category
    if stats and stats.totalLooted > 0 then
        statsLine = statsLine .. string.format(" - %.1f%% after %d attempts", dropChance, stats.totalLooted)
    end
    
    -- Split item name at colon (e.g., "Beastmaster's Whistle: Highland Thrasher")
    local itemTypePart, petNamePart = itemName:match("^(.-):%s*(.*)$")
    if not itemTypePart then
        -- No colon found, use full name
        itemTypePart = itemName
        petNamePart = ""
    end
    
    -- Check if item is already learned (duplicate = can sell)
    local isAlreadyLearned = AV_IsVanityItemLearned and AV_IsVanityItemLearned(itemId, itemName)
    local statusText = ""
    local statusColor = {1, 1, 1}  -- White default
    
    if isAlreadyLearned then
        statusText = "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:16|t DUPLICATE (Can Sell)"
        statusColor = {0.8, 0.8, 0.8}  -- Gray
    else
        statusText = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:16|t NEW COLLECTION!"
        statusColor = {0, 1, 0}  -- Green
    end
    
    -- Create/show celebration frame
    local frame = CreateCelebrationFrame()
    
    -- Resize frame based on text content before setting text
    local newTextWidth = frame:ResizeForContent(itemTypePart, petNamePart)
    
    frame.icon:SetTexture(itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
    frame.itemType:SetText(itemTypePart .. (petNamePart ~= "" and ":" or ""))
    frame.petName:SetText(petNamePart)
    frame.statsText:SetText(statsLine)
    frame.statusText:SetText(statusText)
    frame.statusText:SetTextColor(statusColor[1], statusColor[2], statusColor[3])
    
    -- Update text widths for new frame size
    frame.itemType:SetSize(newTextWidth, 0)
    frame.petName:SetSize(newTextWidth, 0)
    frame.statsText:SetSize(newTextWidth, 0)
    
    -- Show and animate
    frame.glow:SetAlpha(0)  -- Start transparent
    frame:Show()
    frame.glowAnimIn:Play()  -- Start glow fade in
    
    -- Simple chat message (one line)
    print(string.format("|cFF00FF96AscensionVanity:|r %s - %s!", itemLink, statsLine))
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
    
    -- V2.2+ database structure: AV_VanityItems is keyed by itemId
    return AV_VanityItems[itemId] ~= nil
end

function statsFrame:GetItemCategory(itemId)
    -- Get category from item name prefix
    if not AV_VanityItems then return nil end
    
    -- V2.2+ database structure: AV_VanityItems is keyed by itemId
    local itemData = AV_VanityItems[itemId]
    if not itemData or not itemData.name then return nil end
    
    -- Category is determined by the prefix in the item name
    if itemData.name:find("Beastmaster's Whistle") then
        return "Beast"
    elseif itemData.name:find("Elemental Lodestone") then
        return "Elemental"
    elseif itemData.name:find("Draconic Warhorn") then
        return "Dragonkin"
    elseif itemData.name:find("Summoner's Stone") then
        return "Demon"
    elseif itemData.name:find("Blood Soaked Vellum") then
        return "Undead"
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

-- ============================================================================
-- Test Commands (for development/testing)
-- ============================================================================

-- Test celebration with an item (use item link from bag)
SLASH_AVTESTDROP1 = "/avtestdrop"
SlashCmdList["AVTESTDROP"] = function(msg)
    -- Extract item ID from item link or direct number
    local itemId = tonumber(msg)
    
    if not itemId and msg ~= "" then
        -- Try to extract from item link
        itemId = tonumber(msg:match("item:(%d+)"))
    end
    
    if not itemId then
        print("|cFF00FF96AscensionVanity:|r Usage: /avtestdrop <itemId or shift-click item link>")
        print("  Example: /avtestdrop 79549")
        print("  Or shift-click an item from your bags and type: /avtestdrop [link]")
        return
    end
    
    -- Check if it's a vanity item
    if not statsFrame:IsVanityItem(itemId) then
        print(string.format("|cFFFF0000AscensionVanity:|r Item %d is not a vanity item!", itemId))
        return
    end
    
    print(string.format("|cFF00FF96AscensionVanity:|r Testing celebration for item %d...", itemId))
    
    -- Create fake stats for testing
    local fakeStats = {
        totalKilled = 42,
        totalLooted = 35,
        totalDrops = 1,
        dropsByCategory = {}
    }
    
    -- Trigger celebration
    statsFrame:CelebrateDrop(0, itemId, fakeStats)
end

