-- AscensionVanity - Creature Information Module
-- Gathers and displays enhanced creature information (combat stats, portraits, etc.)
-- Version: 2.3 - Phase 2A

-- ============================================================================
-- Local Variables
-- ============================================================================

-- Cache for creature portraits to avoid repeated texture creation
local portraitCache = {}

-- ============================================================================
-- API Wrappers (Safe calls with fallbacks)
-- ============================================================================

-- Get creature level with scaling detection
-- Returns: level (number or string), isScaled (boolean), isBoss (boolean)
function AV_GetCreatureLevelInfo(unit)
    if not unit then return nil, false, false end
    
    local level = UnitLevel(unit)
    
    -- Skull level (boss/high level creature)
    if level == -1 then
        return "??", false, true
    end
    
    -- Check for level scaling (if API exists)
    local effectiveLevel = UnitEffectiveLevel and UnitEffectiveLevel(unit)
    local isScaled = effectiveLevel and effectiveLevel ~= level
    
    return level, isScaled or false, false
end

-- Get creature classification (normal, elite, rare, boss, etc.)
-- Returns: classification string, display text, color
function AV_GetCreatureClassification(unit)
    if not unit then return "normal", "", {1, 1, 1} end
    
    local classification = UnitClassification(unit)
    
    local classificationData = {
        worldboss = { text = "Boss", color = {1, 0, 0} },        -- Red
        rareelite = { text = "Rare Elite", color = {1, 0.5, 1} }, -- Pink
        elite = { text = "Elite", color = {1, 0.8, 0} },          -- Gold
        rare = { text = "Rare", color = {0.5, 0.5, 1} },          -- Light Blue
        normal = { text = "", color = {1, 1, 1} },                 -- White
    }
    
    local data = classificationData[classification] or classificationData.normal
    return classification, data.text, data.color
end

-- Get creature type/family (Beast, Humanoid, Demon, etc.)
-- Returns: creature type string, family icon path
function AV_GetCreatureTypeInfo(unit)
    if not unit then return nil, nil end
    
    local creatureType = UnitCreatureType(unit)
    if not creatureType then return nil, nil end
    
    -- Get family icon from constants (if available)
    local familyIcon = AV_CATEGORY_ICONS[string.lower(creatureType)]
    
    return creatureType, familyIcon
end

-- Get creature attack speed
-- Returns: mainSpeed (number), offSpeed (number or nil)
function AV_GetCreatureAttackSpeed(unit)
    if not unit then return nil, nil end
    
    local mainSpeed, offSpeed = UnitAttackSpeed(unit)
    return mainSpeed, offSpeed
end

-- Get creature health information
-- Returns: currentHealth (number), maxHealth (number), healthPercent (number)
function AV_GetCreatureHealth(unit)
    if not unit then return nil, nil, nil end
    
    local currentHealth = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    local healthPercent = maxHealth > 0 and (currentHealth / maxHealth * 100) or 0
    
    return currentHealth, maxHealth, healthPercent
end

-- Get creature damage range
-- Returns: minDamage (number), maxDamage (number), offHandMin (number or nil), offHandMax (number or nil)
function AV_GetCreatureDamage(unit)
    if not unit then return nil, nil, nil, nil end
    
    local mainBase, mainMod, offBase, offMod = UnitDamage(unit)
    
    -- Calculate min/max for main hand
    local mainMin = mainBase
    local mainMax = mainBase + mainMod
    
    -- Calculate min/max for off hand (if dual wielding)
    local offMin, offMax = nil, nil
    if offBase and offBase > 0 then
        offMin = offBase
        offMax = offBase + offMod
    end
    
    return mainMin, mainMax, offMin, offMax
end

-- Get creature family (for beasts)
-- Returns: family string (e.g., "Wolf", "Bear") or nil
function AV_GetCreatureFamily(unit)
    if not unit then return nil end
    
    -- Only beasts have families
    local creatureType = UnitCreatureType(unit)
    if creatureType ~= "Beast" then return nil end
    
    local family = UnitCreatureFamily(unit)
    return family
end

-- Get creature armor
-- Returns: armor value (number)
function AV_GetCreatureArmor(unit)
    if not unit then return nil end
    
    local base, effective, armor, posBuff, negBuff = UnitArmor(unit)
    return effective or armor or base
end

-- ============================================================================
-- Portrait Management
-- ============================================================================

-- Get or create a portrait texture for a creature
-- Returns: texture object with creature's 3D portrait
function AV_GetCreaturePortrait(unit)
    if not unit then return nil end
    
    -- For now, we'll use family icons instead of 3D portraits
    -- 3D portraits require frame creation and are more complex
    local creatureType, familyIcon = AV_GetCreatureTypeInfo(unit)
    
    if familyIcon then
        return familyIcon
    end
    
    -- Fallback to generic creature icon
    return AV_ICON_QUESTION_MARK
end

-- ============================================================================
-- Tooltip Integration Helper
-- ============================================================================

-- Check if creature stats should be shown based on filter setting
-- Returns: true if should show, false otherwise
local function ShouldShowCreatureInfo(unit, creatureId, isPlayerControlled)
    if not AscensionVanityDB or not AscensionVanityDB.showCreatureInfo then
        return false
    end
    
    -- ALWAYS show for player-controlled pets (your own combat pets)
    if isPlayerControlled then
        return true
    end
    
    local filter = AscensionVanityDB.creatureInfoFilter or "vanity"
    
    if filter == "all" then
        return true
    elseif filter == "vanity" then
        -- Only show for creatures that can drop vanity items
        if not creatureId then return false end
        if not AV_VanityItems then return false end
        
        -- Check if creature is in vanity database
        if AV_GetVanityItemsForCreature then
            local items = AV_GetVanityItemsForCreature(creatureId)
            return items and #items > 0
        end
        return false
    elseif filter == "tameable" then
        -- Only show for tameable beasts
        local creatureType = UnitCreatureType(unit)
        if creatureType ~= "Beast" then return false end
        
        -- Check if tameable (not exotic, not untameable)
        -- Note: We can't perfectly detect this, but we can check basic criteria
        local classification = UnitClassification(unit)
        if classification == "worldboss" or classification == "rareelite" then
            return false -- Bosses and rare elites are never tameable
        end
        return true
    elseif filter == "vanity_and_tameable" then
        -- Show for vanity creatures OR tameable beasts
        -- Check vanity first
        if creatureId and AV_VanityItems and AV_GetVanityItemsForCreature then
            local items = AV_GetVanityItemsForCreature(creatureId)
            if items and #items > 0 then
                return true
            end
        end
        
        -- Check tameable
        local creatureType = UnitCreatureType(unit)
        if creatureType == "Beast" then
            local classification = UnitClassification(unit)
            if classification ~= "worldboss" and classification ~= "rareelite" then
                return true
            end
        end
        
        return false
    end
    
    return false
end

-- Add creature information section to tooltip
-- Call this from Core.lua tooltip handler
-- Returns: true if info was added, false otherwise
function AV_AddCreatureInfoToTooltip(tooltip, unit, creatureId)
    if not tooltip or not unit then return false end
    if not UnitExists(unit) then return false end
    
    -- Skip players (but NOT player-controlled pets - we want to show stats for those!)
    if UnitIsPlayer(unit) then
        return false
    end
    
    -- Check if this is a player-controlled pet (your combat pet, hunter pet, etc.)
    -- Optimized: Check fastest methods first
    local isPlayerControlled = false
    
    -- Fast check 1: Direct unit comparison (fastest)
    if UnitIsUnit(unit, "pet") or UnitIsUnit(unit, "playerpet") then
        isPlayerControlled = true
    -- Fast check 2: UnitPlayerControlled (standard API)
    elseif UnitPlayerControlled(unit) then
        isPlayerControlled = true
    -- Check 3: Ownership check (if API exists)
    elseif UnitIsOwnerOrControllerOfUnit and UnitIsOwnerOrControllerOfUnit("player", unit) then
        isPlayerControlled = true
    end
    
    -- Check if we should show info for this creature based on filter setting
    if not ShouldShowCreatureInfo(unit, creatureId, isPlayerControlled) then
        return false
    end
    
    -- Gather creature information
    local level, isScaled, isBoss = AV_GetCreatureLevelInfo(unit)
    local classification, classText, classColor = AV_GetCreatureClassification(unit)
    local creatureType, familyIcon = AV_GetCreatureTypeInfo(unit)
    local creatureFamily = AV_GetCreatureFamily(unit)
    local attackSpeed = AV_GetCreatureAttackSpeed(unit)
    local currentHealth, maxHealth, healthPercent = AV_GetCreatureHealth(unit)
    local minDamage, maxDamage, offMin, offMax = AV_GetCreatureDamage(unit)
    local armor = AV_GetCreatureArmor(unit)
    
    -- Build info line
    local infoLine = ""
    
    -- Creature Type with icon (and family for beasts)
    if creatureType and AscensionVanityDB.showCreatureType then
        if familyIcon then
            local iconStr = AV_FormatIcon(familyIcon, 14)
            infoLine = infoLine .. " " .. iconStr .. " " .. AV_COLOR_GRAY .. creatureType
            if creatureFamily then
                infoLine = infoLine .. " (" .. creatureFamily .. ")"
            end
            infoLine = infoLine .. AV_COLOR_RESET
        else
            infoLine = infoLine .. " " .. AV_COLOR_GRAY .. creatureType
            if creatureFamily then
                infoLine = infoLine .. " (" .. creatureFamily .. ")"
            end
            infoLine = infoLine .. AV_COLOR_RESET
        end
    end
    
    -- Add to tooltip if we have info
    if infoLine ~= "" then
        tooltip:AddLine(infoLine, 1, 1, 1, true)
    end
    
    -- Build combat stats line (compact format)
    local combatStats = {}
    
    if attackSpeed and AscensionVanityDB.showAttackSpeed then
        table.insert(combatStats, string.format("%.1fs", attackSpeed))
    end
    
    if maxHealth and AscensionVanityDB.showHealth then
        -- Format health with K suffix for thousands
        local healthStr
        if maxHealth >= 1000 then
            healthStr = string.format("%.1fK HP", maxHealth / 1000)
        else
            healthStr = string.format("%d HP", maxHealth)
        end
        table.insert(combatStats, healthStr)
    end
    
    if minDamage and maxDamage and AscensionVanityDB.showDamage then
        table.insert(combatStats, string.format("%d-%d dmg", minDamage, maxDamage))
    end
    
    if armor and AscensionVanityDB.showArmor then
        -- Format armor with K suffix for thousands
        local armorStr
        if armor >= 1000 then
            armorStr = string.format("%.1fK armor", armor / 1000)
        else
            armorStr = string.format("%d armor", armor)
        end
        table.insert(combatStats, armorStr)
    end
    
    -- Add combat stats line if any stats are enabled
    if #combatStats > 0 then
        local combatLine = AV_COLOR_BLUE .. table.concat(combatStats, " | ") .. AV_COLOR_RESET
        tooltip:AddLine(combatLine, 1, 1, 1, true)
    end
    
    -- Cache creature stats for collection UI preview (v2.3 Phase 2A)
    if creatureId and AV_CacheCreatureStats then
        AV_CacheCreatureStats(creatureId, unit)
    end
    
    -- Force immediate tooltip update to prevent delayed expansion
    tooltip:Show()
    
    return true
end

-- ============================================================================
-- Compact Info String (for database browser, etc.)
-- ============================================================================

-- Get a compact single-line creature info string
-- Returns: formatted string like "38 Elite Beast • 2.0s"
function AV_GetCompactCreatureInfo(unit)
    if not unit or not UnitExists(unit) then return "" end
    
    local level, isScaled, isBoss = AV_GetCreatureLevelInfo(unit)
    local classification, classText = AV_GetCreatureClassification(unit)
    local creatureType = AV_GetCreatureTypeInfo(unit)
    local attackSpeed = AV_GetCreatureAttackSpeed(unit)
    
    local parts = {}
    
    -- Level
    if isBoss then
        table.insert(parts, "??")
    elseif level then
        table.insert(parts, tostring(level))
    end
    
    -- Classification
    if classText ~= "" then
        table.insert(parts, classText)
    end
    
    -- Type
    if creatureType then
        table.insert(parts, creatureType)
    end
    
    -- Attack speed
    if attackSpeed then
        table.insert(parts, string.format("%.1fs", attackSpeed))
    end
    
    return table.concat(parts, " ")
end

-- ============================================================================
-- Debug/Testing Functions
-- ============================================================================

-- Test function to print creature info to chat
function AV_PrintCreatureInfo(unit)
    unit = unit or "mouseover"
    
    if not UnitExists(unit) then
        print(AV_COLOR_RED .. "No unit found!" .. AV_COLOR_RESET)
        return
    end
    
    local name = UnitName(unit)
    local level, isScaled, isBoss = AV_GetCreatureLevelInfo(unit)
    local classification, classText, classColor = AV_GetCreatureClassification(unit)
    local creatureType, familyIcon = AV_GetCreatureTypeInfo(unit)
    local creatureFamily = AV_GetCreatureFamily(unit)
    local attackSpeed = AV_GetCreatureAttackSpeed(unit)
    local currentHealth, maxHealth, healthPercent = AV_GetCreatureHealth(unit)
    local minDamage, maxDamage, offMin, offMax = AV_GetCreatureDamage(unit)
    local armor = AV_GetCreatureArmor(unit)
    
    print(AV_COLOR_CYAN .. "=== Creature Info ===" .. AV_COLOR_RESET)
    print("Name: " .. (name or "Unknown"))
    print("Level: " .. tostring(level) .. (isScaled and " (scaled)" or "") .. (isBoss and " (BOSS)" or ""))
    print("Classification: " .. classification .. " (" .. classText .. ")")
    print("Type: " .. (creatureType or "Unknown"))
    if creatureFamily then
        print("Family: " .. creatureFamily)
    end
    print("Family Icon: " .. (familyIcon or "None"))
    print(AV_COLOR_CYAN .. "--- Combat Stats ---" .. AV_COLOR_RESET)
    print("Attack Speed: " .. (attackSpeed and string.format("%.2fs", attackSpeed) or "N/A"))
    print("Health: " .. (maxHealth and string.format("%d / %d (%.0f%%)", currentHealth, maxHealth, healthPercent) or "N/A"))
    print("Damage: " .. (minDamage and string.format("%d - %d", minDamage, maxDamage) or "N/A"))
    if offMin and offMax then
        print("Off-Hand: " .. string.format("%d - %d", offMin, offMax))
    end
    print("Armor: " .. (armor and tostring(armor) or "N/A"))
end

-- Add creature preview stats to item tooltip (vanity items)
-- Shows what the creature's stats would be when summoned
-- Called from Core.lua OnTooltipSetItem handler
function AV_AddCreaturePreviewToTooltip(tooltip, creatureId, itemName)
    if not tooltip or not creatureId then return false end
    if not (AscensionVanityDB and AscensionVanityDB.showCreatureInfo) then
        return false
    end
    
    -- Extract pet name from item name (e.g., "Beastmaster's Whistle: Wolf" -> "Wolf")
    local petName = itemName and itemName:match(": (.+)") or "Combat Pet"
    
    -- Add a blank line for spacing before preview stats
    tooltip:AddLine(" ")
    
    -- Add preview header
    local headerText = AV_COLOR_CYAN .. "Combat Pet Preview:" .. AV_COLOR_RESET
    tooltip:AddLine(headerText, 1, 1, 1, false)
    
    -- Note: We can't get actual stats without a unit, so we show a helpful message
    -- Users can compare by summoning the pet and mousing over it
    local infoText = AV_COLOR_GRAY .. "Summon " .. petName .. " to see its combat stats" .. AV_COLOR_RESET
    tooltip:AddLine(infoText, 1, 1, 1, true)
    
    -- Show creature ID for reference (if built-in IDs are enabled, this won't duplicate)
    -- local creatureIdText = AV_COLOR_GRAY .. "Creature ID: " .. AV_COLOR_WHITE .. creatureId .. AV_COLOR_RESET
    -- tooltip:AddLine(creatureIdText, 1, 1, 1, true)
    
    tooltip:Show()
    return true
end

-- Slash command for testing - integrated into main /avanity command
-- Use: /avanity creature or /ascvan creature
