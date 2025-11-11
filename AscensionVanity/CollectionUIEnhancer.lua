-- AscensionVanity - Collection UI Enhancer
-- Adds creature stats to the Vanity Collection preview
-- Version: 2.3 Phase 2A

-- ============================================================================
-- Local Variables
-- ============================================================================

local enhancerFrame = CreateFrame("Frame")
local statsTextFrame = nil
local lastCreatureID = nil

-- ============================================================================
-- Stats Display Creation
-- ============================================================================

local function CreateStatsDisplay()
    if statsTextFrame then return statsTextFrame end
    
    -- Find the collection frame
    if not StoreCollectionFrame then
        return nil
    end
    
    -- Create a text frame overlay for stats
    local frame = CreateFrame("Frame", "AV_CollectionStatsFrame", StoreCollectionFrame)
    frame:SetSize(400, 80)
    frame:SetPoint("BOTTOM", StoreCollectionFrame, "BOTTOM", 0, 40)
    frame:SetFrameStrata("HIGH")
    
    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.7)
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    title:SetText(AV_COLOR_CYAN .. "Combat Stats Preview" .. AV_COLOR_RESET)
    
    -- Stats text (will be updated dynamically)
    local stats = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stats:SetPoint("TOP", title, "BOTTOM", 0, -4)
    stats:SetJustifyH("CENTER")
    stats:SetWidth(380)
    
    frame.title = title
    frame.stats = stats
    frame:Hide()
    
    statsTextFrame = frame
    return frame
end

-- ============================================================================
-- Stats Lookup Functions
-- ============================================================================

-- Get stats for a creature by spawning data from our database
local function GetCreatureStatsFromDatabase(creatureID)
    if not creatureID or creatureID == 0 then return nil end
    
    -- Check if we have cached stats for this creature
    -- (This would come from previously summoned pets)
    if AV_CreatureStatsCache and AV_CreatureStatsCache[creatureID] then
        return AV_CreatureStatsCache[creatureID]
    end
    
    -- No cached stats available
    return nil
end

-- Format stats text for display
local function FormatStatsText(creatureID, itemName)
    local stats = GetCreatureStatsFromDatabase(creatureID)
    
    if stats then
        -- We have cached stats - show them!
        local lines = {}
        
        if stats.health then
            local healthStr = stats.health >= 1000 
                and string.format("%.1fK HP", stats.health / 1000)
                or string.format("%d HP", stats.health)
            table.insert(lines, healthStr)
        end
        
        if stats.attackSpeed then
            table.insert(lines, string.format("%.1fs", stats.attackSpeed))
        end
        
        if stats.minDamage and stats.maxDamage then
            table.insert(lines, string.format("%d-%d dmg", stats.minDamage, stats.maxDamage))
        end
        
        if stats.armor then
            local armorStr = stats.armor >= 1000
                and string.format("%.1fK armor", stats.armor / 1000)
                or string.format("%d armor", stats.armor)
            table.insert(lines, armorStr)
        end
        
        if #lines > 0 then
            return AV_COLOR_BLUE .. table.concat(lines, " | ") .. AV_COLOR_RESET .. "\n" ..
                   AV_COLOR_GRAY .. "(Baseline stats - out of combat)" .. AV_COLOR_RESET
        end
    end
    
    -- No cached stats - show helpful message
    return AV_COLOR_GRAY .. "Summon this pet out of combat to see baseline stats\n" ..
           "Stats will be cached for future previews" .. AV_COLOR_RESET
end

-- ============================================================================
-- Update Logic
-- ============================================================================

local function UpdateStatsDisplay()
    -- Check both preview frames (small left preview AND big right preview)
    local creatureID = nil
    
    -- Try main preview frame (big one on right)
    if StoreCollectionFrameModelPreview and StoreCollectionFrameModelPreview.Creature then
        creatureID = StoreCollectionFrameModelPreview.Creature
    end
    
    -- Fallback to paper preview frame (small one on left)
    if not creatureID and StoreCollectionFramePaperModelPreview and StoreCollectionFramePaperModelPreview.Creature then
        creatureID = StoreCollectionFramePaperModelPreview.Creature
    end
    
    -- No preview active
    if not creatureID or creatureID == 0 then
        if statsTextFrame then
            statsTextFrame:Hide()
        end
        lastCreatureID = nil
        return
    end
    
    -- Don't update if same creature
    if creatureID == lastCreatureID then
        return
    end
    
    lastCreatureID = creatureID
    
    -- Create stats display if needed
    local frame = CreateStatsDisplay()
    if not frame then return end
    
    -- Get item name for this creature (from database)
    local itemName = "Combat Pet"
    if AV_VanityItems then
        for itemID, itemData in pairs(AV_VanityItems) do
            if itemData.creatureId == creatureID or itemData.creaturePreview == creatureID then
                itemName = itemData.name
                break
            end
        end
    end
    
    -- Update stats text
    local statsText = FormatStatsText(creatureID, itemName)
    frame.stats:SetText(statsText)
    
    -- Show the frame
    frame:Show()
end

-- ============================================================================
-- Event Handlers & Hooks
-- ============================================================================

local function OnUpdate(self, elapsed)
    -- Check every 0.5 seconds if preview changed
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed >= 0.5 then
        self.elapsed = 0
        UpdateStatsDisplay()
    end
end

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "AscensionVanity" then
            -- Initialize stats cache if it doesn't exist
            if not AV_CreatureStatsCache then
                AV_CreatureStatsCache = {}
            end
            
            -- Start monitoring for collection UI
            self:SetScript("OnUpdate", OnUpdate)
        end
    end
end

enhancerFrame:RegisterEvent("ADDON_LOADED")
enhancerFrame:SetScript("OnEvent", OnEvent)

-- ============================================================================
-- Global Functions for Stats Caching
-- ============================================================================

-- Cache creature stats when player summons/encounters them
function AV_CacheCreatureStats(creatureID, unit)
    if not creatureID or not unit or not UnitExists(unit) then
        return
    end
    
    -- Only cache baseline stats (out of combat)
    -- In-combat stats can be skewed by buffs, debuffs, and temporary effects
    if UnitAffectingCombat("player") or UnitAffectingCombat(unit) then
        return  -- Skip caching during combat
    end
    
    -- Initialize cache
    if not AV_CreatureStatsCache then
        AV_CreatureStatsCache = {}
    end
    
    -- Capture stats
    local stats = {
        health = UnitHealthMax(unit),
        attackSpeed = UnitAttackSpeed(unit),
        armor = UnitArmor(unit),
        timestamp = time(),
        sampleType = "baseline"  -- Mark as clean, out-of-combat data
    }
    
    -- Capture damage
    local mainBase, mainMod = UnitDamage(unit)
    if mainBase then
        stats.minDamage = mainBase
        stats.maxDamage = mainBase + mainMod
    end
    
    -- Save to cache
    AV_CreatureStatsCache[creatureID] = stats
end
