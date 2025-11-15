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
    
    -- Find the large model preview frame
    if not StoreCollectionFrameModelPreview then
        return nil
    end
    
    -- Create a text frame overlay for stats (attached to large preview)
    local frame = CreateFrame("Frame", "AV_CollectionStatsFrame", StoreCollectionFrameModelPreview)
    frame:SetPoint("TOP", StoreCollectionFrameModelPreview, "TOP", 0, -20)
    frame:SetFrameStrata("DIALOG")
    
    -- Background with border (will be dynamically sized)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -8, 8)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 8, -8)
    bg:SetColorTexture(0, 0, 0, 0.65)  -- More transparent, darker background
    
    -- Border texture for polish
    local border = frame:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", frame, "TOPLEFT", -10, 10)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 10, -10)
    border:SetColorTexture(0.15, 0.15, 0.15, 0.7)  -- Darker, slightly more transparent border
    
    -- Title text (creature type/family)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -6)
    title:SetTextColor(0.4, 0.8, 1.0)  -- Light blue
    title:SetJustifyH("CENTER")
    title:SetWidth(540)  -- Max width constraint
    
    -- Stats text (will be updated dynamically)
    local stats = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    stats:SetPoint("TOP", title, "BOTTOM", 0, -4)
    stats:SetJustifyH("CENTER")
    stats:SetWidth(540)  -- Max width constraint
    
    frame.title = title
    frame.stats = stats
    frame.bg = bg
    frame.border = border
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

-- Get creature type and family from database
local function GetCreatureTypeFamily(creatureID)
    if not AV_VanityItems or not creatureID then return nil, nil end
    
    -- Search database for this creature by checking all items
    for itemID, itemData in pairs(AV_VanityItems) do
        -- Match either the preview model OR the source creature
        if itemData.creaturePreview == creatureID or itemData.creatureId == creatureID then
            if itemData.name then
                -- Try to extract family from item name
                -- Patterns: "Beastmaster's Whistle: Wolf", "Blood Soaked Vellum: Imp"
                local family = itemData.name:match(": (.+)$")
                
                if family then
                    -- Determine type from item category
                    if itemData.name:find("Beastmaster") then
                        return "Beast", family
                    elseif itemData.name:find("Blood Soaked Vellum") or itemData.name:find("Elemental Lodestone") then
                        -- Demons and Elementals from vellum/lodestone
                        return "Demon/Elemental", family
                    elseif itemData.name:find("Summoner") then
                        return "Undead", family
                    elseif itemData.name:find("Draconic Warhorn") then
                        return "Dragonkin", family
                    end
                    -- Fallback: just return the family
                    return nil, family
                end
            end
            break  -- Found the item, stop searching
        end
    end
    
    return nil, nil
end

-- Format stats text for display
local function FormatStatsText(creatureID, itemName)
    local stats = GetCreatureStatsFromDatabase(creatureID)
    local creatureType, family = GetCreatureTypeFamily(creatureID)
    
    -- Build title with type and family
    local titleText = ""
    if creatureType and family then
        titleText = string.format("%s (%s)", family, creatureType)
    elseif family then
        titleText = family
    elseif creatureType then
        titleText = creatureType
    else
        titleText = "Combat Pet"
    end
    
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
        
        if stats.armor and AV_Config.showArmor then
            local armorStr = stats.armor >= 1000
                and string.format("%.1fK armor", stats.armor / 1000)
                or string.format("%d armor", stats.armor)
            table.insert(lines, armorStr)
        end
        
        if #lines > 0 then
            return titleText,
                   AV_COLOR_WHITE .. table.concat(lines, " | ") .. AV_COLOR_RESET .. "\n" ..
                   AV_COLOR_GRAY .. "(Baseline stats - out of combat)" .. AV_COLOR_RESET
        end
    end
    
    -- No cached stats - show helpful message
    return titleText,
           AV_COLOR_GRAY .. "Summon this pet out of combat to see baseline stats\n" ..
           "Stats will be cached for future previews" .. AV_COLOR_RESET
end

-- ============================================================================
-- Update Logic
-- ============================================================================

local function UpdateStatsDisplay()
    -- Check both preview frames (small left preview AND big right preview)
    local creatureID = nil
    
    -- Try large preview frame (big 3D model on right)
    if StoreCollectionFrameModelPreview and StoreCollectionFrameModelPreview.Creature then
        creatureID = StoreCollectionFrameModelPreview.Creature
    end
    
    -- Fallback to small preview frame (paper doll on left)
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
    
    -- Update title and stats text
    local titleText, statsText = FormatStatsText(creatureID, itemName)
    frame.title:SetText(titleText)
    frame.stats:SetText(statsText)
    
    -- Calculate dynamic size based on text
    local titleWidth = frame.title:GetStringWidth()
    local statsWidth = frame.stats:GetStringWidth()
    local titleHeight = frame.title:GetStringHeight()
    local statsHeight = frame.stats:GetStringHeight()
    
    -- Use the wider of the two, but never exceed 560px
    local contentWidth = math.max(titleWidth, statsWidth)
    contentWidth = math.min(contentWidth, 540)  -- Max width
    
    -- Add padding to width and calculate total height
    local frameWidth = contentWidth + 16  -- 8px padding each side
    local frameHeight = titleHeight + statsHeight + 20  -- Spacing between + top/bottom padding
    
    -- Resize the frame
    frame:SetSize(frameWidth, frameHeight)
    
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
    -- Save to cache
    AV_CreatureStatsCache[creatureID] = stats
end