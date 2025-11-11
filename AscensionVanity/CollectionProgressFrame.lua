-- AscensionVanity - Collection Progress Frame
-- Standalone moveable frame showing collection progress
-- Version: 2.2

-- ============================================================================
-- Frame Creation
-- ============================================================================

-- Create main frame
local progressFrame = CreateFrame("Frame", "AV_CollectionProgressFrame", UIParent)
progressFrame:SetSize(380, 260)  -- Wider to accommodate stats columns (was 260)
progressFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -50, -200)
progressFrame:SetMovable(true)
progressFrame:EnableMouse(true)
progressFrame:SetClampedToScreen(true)
progressFrame:SetFrameStrata("LOW")  -- Below character frame (MEDIUM)
progressFrame:SetFrameLevel(10)

-- Storage for expanded item lists
progressFrame.expandedItems = {}  -- Stores FontStrings for expanded items

-- Background (translucent dark overlay)
local bg = progressFrame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)  -- Dark gray with transparency instead of solid black

-- Border (softer)
local border = progressFrame:CreateTexture(nil, "BORDER")
border:SetPoint("TOPLEFT", -1, 1)
border:SetPoint("BOTTOMRIGHT", 1, -1)
border:SetColorTexture(0.4, 0.4, 0.4, 0.5)  -- Lighter and slightly transparent

-- Header background (also more transparent)
local headerBg = progressFrame:CreateTexture(nil, "ARTWORK")
headerBg:SetHeight(24)
headerBg:SetPoint("TOPLEFT", 1, -1)
headerBg:SetPoint("TOPRIGHT", -1, -1)
headerBg:SetColorTexture(0.15, 0.15, 0.15, 0.5)  -- Slightly lighter and more transparent

-- Title
local title = progressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", headerBg, "TOPLEFT", 8, -4)
title:SetText(AV_COLOR_HEADER .. "Collection Progress" .. AV_COLOR_RESET)

-- View mode state and filter state
local viewMode = "zone"  -- Can be "zone" or "global"
local groupMode = "creatures"  -- Can be "creatures" or "subzones"
local learnedFilter = "all"  -- Can be "all", "learned", or "unlearned"

-- Store a function that will collapse categories (defined later after expandedCategories exists)
local collapseAllCategories

-- Button bar below header (for controls that don't overlap title)
local buttonBar = CreateFrame("Frame", nil, progressFrame)
buttonBar:SetSize(240, 20)
buttonBar:SetPoint("TOPLEFT", headerBg, "BOTTOMLEFT", 5, -5)

-- View mode toggle button (Zone ↔ Global)
local viewButton = CreateFrame("Button", nil, buttonBar, "UIPanelButtonTemplate")
viewButton:SetSize(55, 18)
viewButton:SetPoint("LEFT", buttonBar, "LEFT", 0, 0)
viewButton:SetText("Zone")
viewButton:SetNormalFontObject("GameFontNormalSmall")
viewButton:SetScript("OnClick", function(self)
    -- Toggle between zone and global
    if viewMode == "zone" then
        viewMode = "global"
        self:SetText("Global")
        -- Disable subzones button in global view
        local gButton = progressFrame.groupButton
        if gButton then
            -- Force to creatures mode (subzones don't exist in global)
            groupMode = "creatures"
            gButton:SetText("Creatures")
            gButton:Disable()
            gButton:SetAlpha(0.5)
            
            -- Clear all subzone expanded states and items (if initialized)
            if expandedSubzones then
                for subzone, _ in pairs(expandedSubzones) do
                    expandedSubzones[subzone] = false
                    if ClearExpandedItems then
                        ClearExpandedItems(subzone)
                    end
                end
            end
            
            -- Clear the subzone bars table to force recreation (if exists)
            if progressFrame.subzoneBars then
                for name, bar in pairs(progressFrame.subzoneBars) do
                    if bar.bg then bar.bg:Hide() end
                    if bar.fill then bar.fill:Hide() end
                    if bar.text then bar.text:Hide() end
                    if bar.expandBtn then bar.expandBtn:Hide() end
                end
            end
        end
    else
        viewMode = "zone"
        self:SetText("Zone")
        -- Re-enable subzones button in zone view
        local gButton = progressFrame.groupButton
        if gButton then
            -- Update button text to reflect current mode
            gButton:SetText(groupMode == "subzones" and "Subzones" or "Creatures")
            gButton:Enable()
            gButton:SetAlpha(1.0)
        end
    end
    
    -- Don't collapse - let user's expansion state persist
    
    -- Update progress bars with new view
    if progressFrame:IsVisible() then
        local updateFunc = _G.AV_UpdateProgressBars or function() end
        updateFunc()
    end
end)
viewButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    
    local zone = GetZoneText()
    
    if viewMode == "zone" then
        GameTooltip:SetText("Zone View", 1, 1, 1)
        GameTooltip:AddLine("Showing items in: " .. (zone or "Unknown"), nil, nil, nil, true)
        GameTooltip:AddLine("Click to switch to Global view", 0.7, 0.7, 0.7, true)
    else
        GameTooltip:SetText("Global View", 1, 1, 1)
        GameTooltip:AddLine("Showing all items across all zones", nil, nil, nil, true)
        GameTooltip:AddLine("Click to switch to Zone view", 0.7, 0.7, 0.7, true)
    end
    GameTooltip:Show()
end)
viewButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
progressFrame.viewButton = viewButton
progressFrame.getViewMode = function() return viewMode end

-- Group mode toggle button (Creatures ↔ Subzones, only enabled in Zone view)
local groupButton = CreateFrame("Button", nil, buttonBar, "UIPanelButtonTemplate")
groupButton:SetSize(70, 18)
groupButton:SetPoint("LEFT", viewButton, "RIGHT", 3, 0)
groupButton:SetText("Creatures")
groupButton:SetNormalFontObject("GameFontNormalSmall")
groupButton:SetScript("OnClick", function(self)
    -- Only allow toggle in zone view
    if viewMode ~= "zone" then return end
    
    -- Toggle between creatures and subzones grouping
    if groupMode == "creatures" then
        groupMode = "subzones"
        self:SetText("Subzones")
    else
        groupMode = "creatures"
        self:SetText("Creatures")
    end
    
    -- Collapse all when switching group modes
    if collapseAllCategories then
        collapseAllCategories()
    end
    
    -- Update display
    if progressFrame:IsVisible() then
        local updateFunc = _G.AV_UpdateProgressBars or function() end
        updateFunc()
    end
end)
groupButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    if groupMode == "creatures" then
        GameTooltip:SetText("Grouped by Creatures", 1, 1, 1)
        GameTooltip:AddLine("Showing categories: Beasts, Demons, etc.", nil, nil, nil, true)
        GameTooltip:AddLine("Click to group by Subzones", 0.7, 0.7, 0.7, true)
    else
        GameTooltip:SetText("Grouped by Subzones", 1, 1, 1)
        GameTooltip:AddLine("Showing subzones in current zone", nil, nil, nil, true)
        GameTooltip:AddLine("Click to group by Creatures", 0.7, 0.7, 0.7, true)
    end
    GameTooltip:Show()
end)
groupButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
progressFrame.groupButton = groupButton
progressFrame.getGroupMode = function() return groupMode end

-- Learned filter toggle button (cycles through All → Learned → Unlearned)
local learnedButton = CreateFrame("Button", nil, buttonBar, "UIPanelButtonTemplate")
learnedButton:SetSize(65, 18)
learnedButton:SetPoint("LEFT", groupButton, "RIGHT", 3, 0)
learnedButton:SetText("All")
learnedButton:SetNormalFontObject("GameFontNormalSmall")
learnedButton:SetScript("OnClick", function(self)
    -- Cycle through three states
    if learnedFilter == "all" then
        learnedFilter = "learned"
        self:SetText("Learned")
    elseif learnedFilter == "learned" then
        learnedFilter = "unlearned"
        self:SetText("Unlearned")
    else
        learnedFilter = "all"
        self:SetText("All")
    end
    
    -- Update progress bars (will recalculate, reposition, AND refresh expanded items)
    if progressFrame:IsVisible() then
        local updateFunc = _G.AV_UpdateProgressBars or function() end
        updateFunc()  -- This will now handle refreshing expanded items internally
    end
end)
learnedButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    if learnedFilter == "all" then
        GameTooltip:SetText("Showing All Items", 1, 1, 1)
        GameTooltip:AddLine("Click to show learned items only", 0.7, 0.7, 0.7, true)
    elseif learnedFilter == "learned" then
        GameTooltip:SetText("Showing Learned Only", 1, 1, 1)
        GameTooltip:AddLine("Click to show unlearned items only", 0.7, 0.7, 0.7, true)
    else
        GameTooltip:SetText("Showing Unlearned Only", 1, 1, 1)
        GameTooltip:AddLine("Click to show all items", 0.7, 0.7, 0.7, true)
    end
    GameTooltip:Show()
end)
learnedButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
progressFrame.learnedButton = learnedButton
progressFrame.getLearnedFilter = function() return learnedFilter end

-- Details button (opens Database Browser)
local detailsButton = CreateFrame("Button", nil, buttonBar, "UIPanelButtonTemplate")
detailsButton:SetSize(50, 18)
detailsButton:SetPoint("LEFT", learnedButton, "RIGHT", 3, 0)
detailsButton:SetText("Details")
detailsButton:SetNormalFontObject("GameFontNormalSmall")
detailsButton:SetScript("OnClick", function(self)
    -- Toggle browser (close if already open)
    local browserFrame = _G["AV_DatabaseBrowser"]
    if browserFrame and browserFrame:IsVisible() then
        if AV_DatabaseBrowser_Hide then
            AV_DatabaseBrowser_Hide()
        end
    elseif AV_DatabaseBrowser_Show then
        -- Get current zone if in zone view
        local mode = progressFrame.getViewMode and progressFrame.getViewMode() or "zone"
        if mode == "zone" then
            local currentZone = GetZoneText()
            AV_DatabaseBrowser_Show(currentZone)
        else
            AV_DatabaseBrowser_Show("all")
        end
    end
end)
detailsButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("View Details", 1, 1, 1)
    GameTooltip:AddLine("Open Database Browser for detailed exploration", nil, nil, nil, true)
    GameTooltip:AddLine("Shows creatures, items, and locations", 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
end)
detailsButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Close button
local closeButton = CreateFrame("Button", nil, progressFrame, "UIPanelCloseButton")
closeButton:SetSize(20, 20)
closeButton:SetPoint("TOPRIGHT", headerBg, "TOPRIGHT", -2, -2)
closeButton:SetScript("OnClick", function()
    AV_HideCollectionProgress()
end)

-- Make draggable
progressFrame:RegisterForDrag("LeftButton")
progressFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
progressFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save position
    local point, _, relativePoint, x, y = self:GetPoint()
    AscensionVanityDB.progressFramePosition = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y
    }
end)

-- ============================================================================
-- Progress Bar Creation
-- ============================================================================

-- Forward declarations (functions used before they're defined)
local ShowExpandedItems
local ClearExpandedItems
local UpdateProgressBars
local GetCreaturesInSubzone
local RefreshExpandedItems

-- Progress bars container
progressFrame.progressBars = {}
progressFrame.subzoneBars = {}  -- Dynamic bars for subzone mode

-- Helper function to create a progress bar
local function CreateProgressBar(parent, label, anchor, yOffset)
    -- Bar background
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetHeight(18)
    bg:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 8, yOffset)
    bg:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", -8, yOffset)
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.5)
    
    -- Bar fill (progress indicator)
    local fill = parent:CreateTexture(nil, "ARTWORK")
    fill:SetHeight(16)
    fill:SetPoint("TOPLEFT", bg, "TOPLEFT", 1, -1)
    fill:SetWidth(1)  -- Will be updated dynamically
    fill:SetColorTexture(0.2, 0.6, 0.2, 0.5)  -- Green by default
    
    -- Bar text (category name + progress)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", bg, "LEFT", 22, 0)  -- Offset to make room for expand button
    text:SetJustifyH("LEFT")
    text:SetText(label)
    
    return {
        bg = bg,
        fill = fill,
        text = text,
        label = label,
        SetProgress = function(self, learned, total)
            local percent = total > 0 and (learned / total) or 0
            local width = bg:GetWidth() - 2
            self.fill:SetWidth(math.max(1, width * percent))
            
            -- Color code based on completion
            if percent >= 1.0 then
                self.fill:SetColorTexture(0.2, 0.8, 0.2, 0.5)  -- Bright green (100%)
            elseif percent >= 0.75 then
                self.fill:SetColorTexture(0.4, 0.7, 0.3, 0.5)  -- Yellow-green (75%+)
            elseif percent >= 0.5 then
                self.fill:SetColorTexture(0.8, 0.8, 0.2, 0.5)  -- Yellow (50%+)
            elseif percent >= 0.25 then
                self.fill:SetColorTexture(0.9, 0.6, 0.2, 0.5)  -- Orange (25%+)
            else
                self.fill:SetColorTexture(0.8, 0.2, 0.2, 0.5)  -- Red (< 25%)
            end
            
            -- Update text
            self.text:SetText(string.format("%s: %d/%d (%.1f%%)", self.label, learned, total, percent * 100))
        end
    }
end

-- Create progress bars
local yPos = -30  -- Moved down to make room for button bar
progressFrame.progressBars.overall = CreateProgressBar(progressFrame, "Overall", headerBg, yPos)

-- Flat anchoring for categories (all anchored to overall bar, spaced vertically)
-- Categories sorted alphabetically: Beast, Demon, Dragonkin, Elemental, Undead
local categoryOrder = {"beast", "demon", "dragonkin", "elemental", "undead"}
local categoryOffsets = {
    beast = -28,
    demon = -52,
    dragonkin = -76,
    elemental = -100,
    undead = -124
}
for _, cat in ipairs(categoryOrder) do
    progressFrame.progressBars[cat] = CreateProgressBar(progressFrame, AV_CATEGORY_SHORT_NAMES[cat], progressFrame.progressBars.overall.bg, categoryOffsets[cat])
end

-- Expand/collapse state
local overallExpanded = true
local expandedCategories = { beast=false, demon=false, dragonkin=false, elemental=false, undead=false }
local expandedSubzones = {}  -- Dynamic, changes per zone

-- Define collapse function for view/group mode toggles (declared earlier)
collapseAllCategories = function()
    -- Collapse category bars
    for _, cat in ipairs({"beast", "demon", "dragonkin", "elemental", "undead"}) do
        if expandedCategories[cat] then
            expandedCategories[cat] = false
            local bar = progressFrame.progressBars[cat]
            if bar and bar.expandBtn then
                bar.expandBtn:SetText("+")
            end
            if ClearExpandedItems then
                ClearExpandedItems(cat)
            end
        end
    end
    
    -- Collapse subzone bars
    for subzone, _ in pairs(expandedSubzones) do
        expandedSubzones[subzone] = false
        if ClearExpandedItems then
            ClearExpandedItems(subzone)
        end
    end
end

-- Helper function to refresh expanded items without collapsing
RefreshExpandedItems = function()
    local groupMode = progressFrame.getGroupMode()
    
    -- Refresh creature categories
    for _, cat in ipairs({"beast", "demon", "dragonkin", "elemental", "undead"}) do
        if expandedCategories[cat] then
            local bar = progressFrame.progressBars[cat]
            if bar and bar.bg then
                ShowExpandedItems(cat, bar.bg, -6)
            end
        end
    end
    
    -- Refresh subzones
    if groupMode == "subzones" then
        for subzone, expanded in pairs(expandedSubzones) do
            if expanded then
                local bar = progressFrame.subzoneBars[subzone]
                if bar and bar.bg then
                    ShowExpandedItems(subzone, bar.bg, -6)
                end
            end
        end
    end
end

-- Add expand/collapse button for OVERALL bar (master collapse)
local overallBtn = CreateFrame("Button", nil, progressFrame)
overallBtn:SetSize(14, 14)
overallBtn:SetPoint("LEFT", progressFrame.progressBars.overall.bg, "LEFT", 4, 0)  -- Inside frame on left
overallBtn:SetNormalFontObject("GameFontNormal")
overallBtn:SetText("-")
overallBtn:SetScript("OnClick", function()
    overallExpanded = not overallExpanded
    overallBtn:SetText(overallExpanded and "-" or "+")
    UpdateProgressBars()  -- Handle all show/hide logic
end)
progressFrame.progressBars.overall.expandBtn = overallBtn

-- Add expand/collapse button to each category bar
for _, cat in ipairs(categoryOrder) do
    local bar = progressFrame.progressBars[cat]
    local btn = CreateFrame("Button", nil, progressFrame)
    btn:SetSize(14, 14)
    btn:SetPoint("LEFT", bar.bg, "LEFT", 4, 0)  -- Inside frame on left
    btn:SetNormalFontObject("GameFontNormal")
    btn:SetText("+")  -- Start collapsed
    
    btn:SetScript("OnClick", function()
        expandedCategories[cat] = not expandedCategories[cat]
        btn:SetText(expandedCategories[cat] and "-" or "+")
        
        if expandedCategories[cat] then
            -- Show pet names for this category
            ShowExpandedItems(cat, bar.bg, -6)  -- Tight gap between category and items
        else
            -- Hide pet names for this category
            ClearExpandedItems(cat)
        end
        
        -- Update all bars (handles repositioning and resize)
        UpdateProgressBars()
    end)
    bar.expandBtn = btn
end

-- ============================================================================
-- Update Logic
-- ============================================================================

-- Helper function to get items for a category (filtered by zone/subzone/learned)
local function GetCategoryItems(category)
    local items = {}
    
    -- Get current view mode and filters
    local viewMode = progressFrame.getViewMode()
    local learnedFilter = progressFrame.getLearnedFilter()
    local currentZone = viewMode == "zone" and GetZoneText() or nil
    
    -- Filter by category based on item name prefix
    local categoryPrefixes = {
        beast = "Beastmaster's Whistle:",
        undead = "Blood Soaked Vellum:",
        demon = "Summoner's Stone:",
        dragonkin = "Draconic Warhorn:",
        elemental = "Elemental Lodestone:"
    }
    
    local prefix = categoryPrefixes[category]
    if not prefix then return items end
    
    for itemId, itemData in pairs(AV_VanityItems or {}) do
        if itemData.name and itemData.name:find(prefix, 1, true) then
            local includeItem = true
            
            -- Zone filtering (simple now - no subzone)
            if viewMode == "zone" and currentZone then
                if not itemData.zone or itemData.zone ~= currentZone then
                    includeItem = false
                end
            end
            
            -- Learned filter (three states)
            if includeItem and learnedFilter ~= "all" then
                local isLearned = AV_IsVanityItemLearned and AV_IsVanityItemLearned(itemId) or false
                if learnedFilter == "learned" and not isLearned then
                    includeItem = false
                elseif learnedFilter == "unlearned" and isLearned then
                    includeItem = false
                end
            end
            
            if includeItem then
                -- Extract pet name (everything after ": ")
                local petName = itemData.name:match(": (.+)$") or itemData.name
                table.insert(items, {
                    id = itemId,
                    name = petName,
                    learned = AV_IsVanityItemLearned and AV_IsVanityItemLearned(itemId) or false,
                    creatureId = itemData.creatureId  -- Add creature ID for stats lookup
                })
            end
        end
    end
    
    -- Sort alphabetically
    table.sort(items, function(a, b)
        return a.name < b.name
    end)
    
    return items
end

-- Helper function to clear expanded item displays
ClearExpandedItems = function(category)
    if not progressFrame.expandedItems[category] then 
        progressFrame.expandedItems[category] = {}
        return 
    end
    
    for _, element in ipairs(progressFrame.expandedItems[category]) do
        element:Hide()
        -- Works for both frames and FontStrings
    end
    progressFrame.expandedItems[category] = {}
end

-- Helper function to create expanded item list for a category
ShowExpandedItems = function(category, anchorBar, yOffset)
    ClearExpandedItems(category)
    
    local groupMode = progressFrame.getGroupMode()
    local items = {}
    
    -- Determine what to show based on group mode
    if groupMode == "subzones" then
        -- In subzone mode, category is actually a subzone name - show creatures
        items = GetCreaturesInSubzone(category)
        if #items == 0 then return 0 end
    else
        -- In creatures mode, show items for this category
        items = GetCategoryItems(category)
        if #items == 0 then return 0 end
    end
    
    progressFrame.expandedItems[category] = {}
    local itemHeight = 16
    local currentY = yOffset - 2  -- Small gap below the bar
    local maxItemsToShow = 10  -- Limit to prevent screen overflow
    local itemsToDisplay = math.min(#items, maxItemsToShow)
    
    -- Add header row if any items have stats
    local hasAnyStats = false
    for i = 1, itemsToDisplay do
        local item = items[i]
        if item.creatureId and (AV_GetSessionStats(item.creatureId) or AV_GetCreatureStats(item.creatureId)) then
            hasAnyStats = true
            break
        end
    end
    
    if hasAnyStats then
        -- Create header with three separate text elements for proper alignment
        local headerFrame = CreateFrame("Frame", nil, progressFrame)
        headerFrame:SetSize(400, itemHeight)
        headerFrame:SetPoint("TOPLEFT", anchorBar, "BOTTOMLEFT", 20, currentY)
        
        -- Pet Name header (left-aligned)
        local nameHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameHeader:SetPoint("LEFT", headerFrame, "LEFT", 0, 0)
        nameHeader:SetWidth(160)  -- Fixed width for name column
        nameHeader:SetJustifyH("LEFT")
        if groupMode == "subzones" then
            nameHeader:SetText("|cFFFFD700Creature (Progress)|r")  -- Bold gold
        else
            nameHeader:SetText("|cFFFFD700Pet Name|r")  -- Bold gold
        end
        
        -- Lifetime header (centered in its column)
        local lifetimeHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lifetimeHeader:SetPoint("LEFT", nameHeader, "RIGHT", 10, 0)
        lifetimeHeader:SetWidth(80)  -- Fixed width for lifetime stats
        lifetimeHeader:SetJustifyH("CENTER")
        lifetimeHeader:SetText("|cFFFFFFFFLifetime|r")
        
        -- Session header (centered in its column)
        local sessionHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sessionHeader:SetPoint("LEFT", lifetimeHeader, "RIGHT", 5, 0)
        sessionHeader:SetWidth(80)  -- Fixed width for session stats
        sessionHeader:SetJustifyH("CENTER")
        sessionHeader:SetText("|cFF82C5FFSession|r")
        
        table.insert(progressFrame.expandedItems[category], headerFrame)
        currentY = currentY - itemHeight
    end
    
    for i = 1, itemsToDisplay do
        local item = items[i]
        
        if groupMode == "subzones" then
            -- Create row frame with separate columns for proper alignment
            local rowFrame = CreateFrame("Frame", nil, progressFrame)
            rowFrame:SetSize(400, itemHeight)
            rowFrame:SetPoint("TOPLEFT", anchorBar, "BOTTOMLEFT", 20, currentY)
            
            local color = (item.learned == item.total) and AV_COLOR_GREEN or "|cFFCCCCCC"
            local icon = (item.learned == item.total) and "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:16|t " or "   "
            
            -- Creature name + progress (left column)
            local nameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nameText:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
            nameText:SetWidth(160)
            nameText:SetJustifyH("LEFT")
            nameText:SetText(icon .. color .. item.name .. string.format(" (%d/%d)", item.learned, item.total) .. AV_COLOR_RESET)
            
            -- Get stats for this creature
            local sessionStats = item.creatureId and AV_GetSessionStats and AV_GetSessionStats(item.creatureId)
            local lifetimeStats = item.creatureId and AV_GetCreatureStats and AV_GetCreatureStats(item.creatureId)
            
            -- Lifetime stats (center column)
            local lifetimeText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lifetimeText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
            lifetimeText:SetWidth(80)
            lifetimeText:SetJustifyH("CENTER")
            
            if lifetimeStats and (lifetimeStats.totalKilled > 0 or lifetimeStats.totalLooted > 0 or lifetimeStats.totalDrops > 0) then
                lifetimeText:SetText(string.format("|cFFFFFFFFK%d|L%d|D%d|r",
                    lifetimeStats.totalKilled or 0,
                    lifetimeStats.totalLooted or 0,
                    lifetimeStats.totalDrops or 0))
            else
                lifetimeText:SetText("|cFF666666-|r")
            end
            
            -- Session stats (right column)
            local sessionText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            sessionText:SetPoint("LEFT", lifetimeText, "RIGHT", 5, 0)
            sessionText:SetWidth(80)
            sessionText:SetJustifyH("CENTER")
            
            if sessionStats and (sessionStats.sessionKilled > 0 or sessionStats.sessionLooted > 0 or sessionStats.sessionDrops > 0) then
                sessionText:SetText(string.format("|cFF82C5FFK%d|L%d|D%d|r",
                    sessionStats.sessionKilled or 0,
                    sessionStats.sessionLooted or 0,
                    sessionStats.sessionDrops or 0))
            else
                sessionText:SetText("|cFF666666-|r")
            end
            
            table.insert(progressFrame.expandedItems[category], rowFrame)
        else
            -- Creatures mode - show item name with stats (if available)
            local hasStatsForItem = false
            local sessionStats, lifetimeStats
            
            if item.creatureId and AV_GetSessionStats and AV_GetCreatureStats then
                sessionStats = AV_GetSessionStats(item.creatureId)
                lifetimeStats = AV_GetCreatureStats(item.creatureId)
                if sessionStats or lifetimeStats then
                    local sk = sessionStats and sessionStats.sessionKilled or 0
                    local sl = sessionStats and sessionStats.sessionLooted or 0
                    local sd = sessionStats and sessionStats.sessionDrops or 0
                    local lk = lifetimeStats and lifetimeStats.totalKilled or 0
                    local ll = lifetimeStats and lifetimeStats.totalLooted or 0
                    local ld = lifetimeStats and lifetimeStats.totalDrops or 0
                    hasStatsForItem = (sk > 0 or sl > 0 or sd > 0 or lk > 0 or ll > 0 or ld > 0)
                end
            end
            
            if hasStatsForItem then
                -- Create row frame with columns (like subzones mode)
                local rowFrame = CreateFrame("Frame", nil, progressFrame)
                rowFrame:SetSize(400, itemHeight)
                rowFrame:SetPoint("TOPLEFT", anchorBar, "BOTTOMLEFT", 20, currentY)
                
                local color = item.learned and AV_COLOR_GREEN or "|cFFCCCCCC"
                local icon = item.learned and "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:16|t " or "   "
                
                -- Pet name (left column)
                local nameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                nameText:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
                nameText:SetWidth(160)
                nameText:SetJustifyH("LEFT")
                nameText:SetText(icon .. color .. item.name .. AV_COLOR_RESET)
                
                -- Lifetime stats (center column)
                local lifetimeText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                lifetimeText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
                lifetimeText:SetWidth(80)
                lifetimeText:SetJustifyH("CENTER")
                
                if lifetimeStats and (lifetimeStats.totalKilled > 0 or lifetimeStats.totalLooted > 0 or lifetimeStats.totalDrops > 0) then
                    lifetimeText:SetText(string.format("|cFFFFFFFFK%d|L%d|D%d|r",
                        lifetimeStats.totalKilled or 0,
                        lifetimeStats.totalLooted or 0,
                        lifetimeStats.totalDrops or 0))
                else
                    lifetimeText:SetText("|cFF666666-|r")
                end
                
                -- Session stats (right column)
                local sessionText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                sessionText:SetPoint("LEFT", lifetimeText, "RIGHT", 5, 0)
                sessionText:SetWidth(80)
                sessionText:SetJustifyH("CENTER")
                
                if sessionStats and (sessionStats.sessionKilled > 0 or sessionStats.sessionLooted > 0 or sessionStats.sessionDrops > 0) then
                    sessionText:SetText(string.format("|cFF82C5FFK%d|L%d|D%d|r",
                        sessionStats.sessionKilled or 0,
                        sessionStats.sessionLooted or 0,
                        sessionStats.sessionDrops or 0))
                else
                    sessionText:SetText("|cFF666666-|r")
                end
                
                table.insert(progressFrame.expandedItems[category], rowFrame)
            else
                -- No stats - simple item display
                local itemText = progressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                itemText:SetPoint("TOPLEFT", anchorBar, "BOTTOMLEFT", 20, currentY)
                itemText:SetPoint("TOPRIGHT", anchorBar, "BOTTOMRIGHT", -8, currentY)
                itemText:SetJustifyH("LEFT")
                
                local color = item.learned and AV_COLOR_GREEN or "|cFFCCCCCC"
                local icon = item.learned and "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:16|t " or "   "
                itemText:SetText(icon .. color .. item.name .. AV_COLOR_RESET)
                
                table.insert(progressFrame.expandedItems[category], itemText)
            end
        end
        currentY = currentY - itemHeight
    end
    
    -- Add truncation indicator if there are more items
    if #items > maxItemsToShow then
        local truncText = progressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        truncText:SetPoint("TOPLEFT", anchorBar, "BOTTOMLEFT", 20, currentY)
        truncText:SetPoint("TOPRIGHT", anchorBar, "BOTTOMRIGHT", -8, currentY)
        truncText:SetJustifyH("LEFT")
        local itemType = groupMode == "subzones" and "creatures" or "items"
        truncText:SetText("|cFF888888... and " .. (#items - maxItemsToShow) .. " more " .. itemType .. "|r")
        
        table.insert(progressFrame.expandedItems[category], truncText)
        currentY = currentY - itemHeight
    end
    
    -- Return total height used by expanded items (including truncation line if present)
    local displayedLines = itemsToDisplay + (#items > maxItemsToShow and 1 or 0)
    return displayedLines * itemHeight + 12  -- +12 for spacing after list
end

-- Helper function to get subzones in current zone with their items
local function GetSubzonesInZone()
    if viewMode ~= "zone" then return {} end
    
    local currentZone = GetZoneText()
    if not currentZone or currentZone == "" then return {} end
    
    local subzones = {}
    local learnedFilter = progressFrame.getLearnedFilter()
    
    -- First pass: Find ALL subzones in zone (unfiltered) to establish structure
    -- This ensures we show all subzones even with 0/X when filtering
    for itemId, itemData in pairs(AV_VanityItems or {}) do
        if itemData.zone == currentZone and itemData.subzone and itemData.subzone ~= "" then
            local subzone = itemData.subzone
            if not subzones[subzone] then
                subzones[subzone] = { total = 0, learned = 0, totalUnfiltered = 0, creatures = {} }
            end
            -- Count total items in subzone (unfiltered)
            subzones[subzone].totalUnfiltered = subzones[subzone].totalUnfiltered + 1
        end
    end
    
    -- Second pass: Count learned items (always show learned/total regardless of filter)
    for itemId, itemData in pairs(AV_VanityItems or {}) do
        if itemData.zone == currentZone and itemData.subzone and itemData.subzone ~= "" then
            local subzone = itemData.subzone
            
            -- Always count total (unfiltered)
            subzones[subzone].total = subzones[subzone].total + 1
            
            -- Always count learned
            local isLearned = AV_IsVanityItemLearned and AV_IsVanityItemLearned(itemId) or false
            if isLearned then
                subzones[subzone].learned = subzones[subzone].learned + 1
            end
            
            -- Track creatures for expansion - apply filter here for what's shown in expanded list
            local includeCreature = true
            if learnedFilter ~= "all" then
                if learnedFilter == "learned" and not isLearned then
                    includeCreature = false
                elseif learnedFilter == "unlearned" and isLearned then
                    includeCreature = false
                end
            end
            
            if includeCreature then
                -- Track creatures (extract from item name or use creatureId)
                local creatureName = itemData.creatureName or "Unknown"
                if not subzones[subzone].creatures[creatureName] then
                    subzones[subzone].creatures[creatureName] = { total = 0, learned = 0 }
                end
                subzones[subzone].creatures[creatureName].total = subzones[subzone].creatures[creatureName].total + 1
                if isLearned then
                    subzones[subzone].creatures[creatureName].learned = subzones[subzone].creatures[creatureName].learned + 1
                end
            end
        end
    end
    
    -- Remove subzones with 0 total unfiltered items (shouldn't happen, but safety check)
    for subzone, data in pairs(subzones) do
        if data.totalUnfiltered == 0 then
            subzones[subzone] = nil
        end
    end
    
    return subzones
end

-- Helper function to get creatures in a subzone (for expansion)
GetCreaturesInSubzone = function(subzone)
    local currentZone = GetZoneText()
    if not currentZone or currentZone == "" then return {} end
    
    local creatures = {}
    local learnedFilter = progressFrame.getLearnedFilter()
    
    for itemId, itemData in pairs(AV_VanityItems or {}) do
        if itemData.zone == currentZone and itemData.subzone == subzone then
            -- Check learned filter (three states)
            local includeItem = true
            if learnedFilter ~= "all" then
                local isLearned = AV_IsVanityItemLearned and AV_IsVanityItemLearned(itemId) or false
                if learnedFilter == "learned" and not isLearned then
                    includeItem = false
                elseif learnedFilter == "unlearned" and isLearned then
                    includeItem = false
                end
            end
            
            if includeItem then
                -- Extract creature name from description (format: "Has a chance to drop from CreatureName within Zone")
                local creatureName = "Unknown"
                if itemData.description and itemData.description ~= "" then
                    local match = itemData.description:match("drop from ([^%s][^%.]+) within")
                    if match then
                        creatureName = match
                    end
                end
                
                if not creatures[creatureName] then
                    creatures[creatureName] = { 
                        total = 0, 
                        learned = 0, 
                        items = {},
                        creatureId = itemData.creatureId  -- Store creature ID for session stats
                    }
                end
                
                creatures[creatureName].total = creatures[creatureName].total + 1
                local isLearned = AV_IsVanityItemLearned and AV_IsVanityItemLearned(itemId) or false
                if isLearned then
                    creatures[creatureName].learned = creatures[creatureName].learned + 1
                end
                
                table.insert(creatures[creatureName].items, {
                    id = itemId,
                    name = itemData.name,
                    learned = isLearned
                })
            end
        end
    end
    
    -- Convert to sorted array
    local creatureList = {}
    for name, data in pairs(creatures) do
        table.insert(creatureList, {
            name = name,
            total = data.total,
            learned = data.learned,
            items = data.items,
            creatureId = data.creatureId  -- Include creature ID for session stats lookup
        })
    end
    
    table.sort(creatureList, function(a, b)
        return a.name < b.name
    end)
    
    return creatureList
end

-- Helper function to resize frame based on visible content
local function ResizeFrame()
    local headerHeight = 45  -- Title bar height
    local buttonBarHeight = 22  -- Button bar below title
    local barHeight = 25
    local padding = -5  -- Reduced from 10 for tighter UI
    local totalHeight = headerHeight + buttonBarHeight
    
    -- Calculate required width
    local minWidth = 260  -- Increased to properly fit all 4 buttons (Zone, Creatures, All, Details)
    local statsWidth = 380  -- Width needed when showing stats columns
    local hasAnyStats = false
    
    -- Check if any expanded items have stats
    for category, items in pairs(progressFrame.expandedItems) do
        if items and #items > 0 then
            for _, element in ipairs(items) do
                -- Check if this is a frame (stats layout) vs FontString (simple layout)
                if element.CreateFontString then  -- It's a frame
                    hasAnyStats = true
                    break
                end
            end
            if hasAnyStats then break end
        end
    end
    
    local frameWidth = hasAnyStats and statsWidth or minWidth
    
    -- Add overall bar
    totalHeight = totalHeight + barHeight
    
    -- Add visible bars and their expanded items
    if overallExpanded then
        -- Count category bars (creature mode)
        for _, cat in ipairs(categoryOrder) do
            local bar = progressFrame.progressBars[cat]
            if bar.bg:IsShown() then
                totalHeight = totalHeight + barHeight
                
                -- Add height of expanded items if this category is expanded
                if expandedCategories[cat] and progressFrame.expandedItems[cat] then
                    totalHeight = totalHeight + (#progressFrame.expandedItems[cat] * 16) + 4
                end
            end
        end
        
        -- Count subzone bars (subzone mode)
        for _, bar in pairs(progressFrame.subzoneBars) do
            if bar.bg:IsShown() then
                totalHeight = totalHeight + barHeight
                
                -- Add height of expanded items if this subzone is expanded
                local subzoneName = bar.label
                if expandedSubzones[subzoneName] and progressFrame.expandedItems[subzoneName] then
                    totalHeight = totalHeight + (#progressFrame.expandedItems[subzoneName] * 16) + 4
                end
            end
        end
    end
    
    totalHeight = totalHeight + padding
    progressFrame:SetHeight(totalHeight)
    progressFrame:SetWidth(frameWidth)
end

-- Helper function to calculate progress for current view mode
local function CalculateProgress()
    local viewMode = progressFrame.getViewMode()
    local groupMode = progressFrame.getGroupMode()
    
    -- For subzone grouping, calculate progress by subzone
    if viewMode == "zone" and groupMode == "subzones" then
        local subzones = GetSubzonesInZone()
        local progress = {
            overall = { learned = 0, total = 0 }
        }
        
        -- Add each subzone to progress
        for subzone, data in pairs(subzones) do
            progress[subzone] = {
                learned = data.learned,
                total = data.total
            }
            progress.overall.learned = progress.overall.learned + data.learned
            progress.overall.total = progress.overall.total + data.total
        end
        
        return progress
    end
    
    -- For creature grouping (default)
    if viewMode == "zone" and AV_GetZoneCollectionProgress then
        return AV_GetZoneCollectionProgress()
    elseif AV_GetCollectionProgress then
        return AV_GetCollectionProgress()
    end
    
    return {}
end

-- Function to update all progress bars
local isRefreshing = false  -- Prevent infinite recursion
UpdateProgressBars = function(skipRefresh)
    if not AV_GetCollectionProgress then
        return  -- Function not available yet
    end
    
    if isRefreshing then
        return  -- Already in refresh cycle
    end
    
    local viewMode = progressFrame.getViewMode()
    
    -- Update title based on view mode
    if viewMode == "zone" then
        local zoneName = GetZoneText()
        if zoneName and zoneName ~= "" then
            title:SetText(AV_COLOR_HEADER .. zoneName .. AV_COLOR_RESET)
        else
            title:SetText(AV_COLOR_HEADER .. "Collection Progress" .. AV_COLOR_RESET)
        end
    else
        -- Global view
        title:SetText(AV_COLOR_HEADER .. "Collection Progress" .. AV_COLOR_RESET)
    end
    
    -- Get progress using our helper function
    local progress = CalculateProgress()
    local groupMode = progressFrame.getGroupMode()
    
    -- Update overall bar
    if progress.overall then
        progressFrame.progressBars.overall:SetProgress(progress.overall.learned, progress.overall.total)
    end
    
    -- Branch based on group mode
    local currentY = -80  -- Start position below overall bar (adjusted for button bar)
    
    if viewMode == "zone" and groupMode == "subzones" and overallExpanded then
        -- ============== SUBZONE MODE ==============
        -- Hide all category bars
        for _, cat in ipairs(categoryOrder) do
            local bar = progressFrame.progressBars[cat]
            bar.bg:Hide()
            bar.fill:Hide()
            bar.text:Hide()
            if bar.expandBtn then bar.expandBtn:Hide() end
        end
        
        -- Create/show subzone bars dynamically
        local subzones = GetSubzonesInZone()
        local subzoneNames = {}
        for name in pairs(subzones) do
            table.insert(subzoneNames, name)
        end
        table.sort(subzoneNames)
        
        for _, subzoneName in ipairs(subzoneNames) do
            local data = subzones[subzoneName]
            
            -- Always show subzones that have data (even if filtered total is 0)
            -- This shows "0/X" when filtering, consistent with creature categories
            -- Get or create bar for this subzone
            local bar = progressFrame.subzoneBars[subzoneName]
            if not bar then
                -- Create new bar dynamically
                local bg = progressFrame:CreateTexture(nil, "BACKGROUND")
                bg:SetHeight(18)
                bg:SetColorTexture(0.15, 0.15, 0.15, 0.5)
                
                local fill = progressFrame:CreateTexture(nil, "ARTWORK")
                fill:SetHeight(16)
                fill:SetPoint("TOPLEFT", bg, "TOPLEFT", 1, -1)
                fill:SetWidth(1)
                fill:SetColorTexture(0.2, 0.6, 0.2, 0.5)
                
                local text = progressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                text:SetPoint("LEFT", bg, "LEFT", 22, 0)
                text:SetJustifyH("LEFT")
                
                -- Create expand button
                local btn = CreateFrame("Button", nil, progressFrame)
                btn:SetSize(14, 14)
                btn:SetPoint("LEFT", bg, "LEFT", 4, 0)
                btn:SetNormalFontObject("GameFontNormal")
                btn:SetText("+")
                btn:SetScript("OnClick", function()
                    expandedSubzones[subzoneName] = not expandedSubzones[subzoneName]
                    btn:SetText(expandedSubzones[subzoneName] and "-" or "+")
                    
                    if expandedSubzones[subzoneName] then
                        ShowExpandedItems(subzoneName, bg, -6)
                    else
                        ClearExpandedItems(subzoneName)
                    end
                    
                    UpdateProgressBars()
                end)
                
                bar = {
                    bg = bg,
                    fill = fill,
                    text = text,
                    expandBtn = btn,
                    label = subzoneName,
                    SetProgress = function(self, learned, total)
                        local percent = total > 0 and (learned / total) or 0
                        local width = bg:GetWidth() - 2
                        self.fill:SetWidth(math.max(1, width * percent))
                        
                        if percent >= 1.0 then
                            self.fill:SetColorTexture(0.2, 0.8, 0.2, 0.5)
                        elseif percent >= 0.75 then
                            self.fill:SetColorTexture(0.4, 0.7, 0.3, 0.5)
                        elseif percent >= 0.5 then
                            self.fill:SetColorTexture(0.8, 0.8, 0.2, 0.5)
                        elseif percent >= 0.25 then
                            self.fill:SetColorTexture(0.9, 0.6, 0.2, 0.5)
                        else
                            self.fill:SetColorTexture(0.8, 0.2, 0.2, 0.5)
                        end
                        
                        self.text:SetText(string.format("%s: %d/%d (%.1f%%)", self.label, learned, total, percent * 100))
                    end
                }
                
                progressFrame.subzoneBars[subzoneName] = bar
            end
            
            -- Position and show bar
            bar.bg:SetPoint("TOPLEFT", progressFrame, "TOPLEFT", 8, currentY)
            bar.bg:SetPoint("TOPRIGHT", progressFrame, "TOPRIGHT", -8, currentY)
            bar.bg:Show()
            bar.fill:Show()
            bar.text:Show()
            bar.expandBtn:Show()
            
            -- Update progress
            bar:SetProgress(data.learned, data.total)
            
            -- Move down for next bar
            currentY = currentY - 25
            
            -- Account for expanded items
            if expandedSubzones[subzoneName] and progressFrame.expandedItems[subzoneName] then
                currentY = currentY - (#progressFrame.expandedItems[subzoneName] * 16) - 4
            end
        end  -- Close the for loop
        
        -- Hide unused subzone bars
        for name, bar in pairs(progressFrame.subzoneBars) do
            if not subzones[name] then
                bar.bg:Hide()
                bar.fill:Hide()
                bar.text:Hide()
                bar.expandBtn:Hide()
            end
        end
        
    else
        -- ============== CREATURE MODE (default) ==============
        -- Hide all subzone bars
        for _, bar in pairs(progressFrame.subzoneBars) do
            bar.bg:Hide()
            bar.fill:Hide()
            bar.text:Hide()
            bar.expandBtn:Hide()
        end
        
        -- Update category bars
        for category, bar in pairs(progressFrame.progressBars) do
            if category ~= "overall" and progress[category] then
                bar:SetProgress(progress[category].learned, progress[category].total)
            end
        end
        
        -- Show/hide category bars
        if overallExpanded then
            for _, cat in ipairs(categoryOrder) do
                local bar = progressFrame.progressBars[cat]
                local shouldShow = false  -- Default to hidden
                
                -- Only show if category has items (total > 0)
                -- This hides categories with literally no items in zone (0/0)
                -- But shows categories with items even if filtered to 0 (0/X where X > 0)
                if progress[cat] and progress[cat].total > 0 then
                    shouldShow = true
                end
                
                if shouldShow then
                    bar.bg:SetPoint("TOPLEFT", progressFrame, "TOPLEFT", 8, currentY)
                    bar.bg:Show()
                    bar.fill:Show()
                    bar.text:Show()
                    if bar.expandBtn then bar.expandBtn:Show() end
                    
                    currentY = currentY - 25
                    
                    if expandedCategories[cat] and progressFrame.expandedItems[cat] then
                        currentY = currentY - (#progressFrame.expandedItems[cat] * 16) - 4
                    end
                else
                    bar.bg:Hide()
                    bar.fill:Hide()
                    bar.text:Hide()
                    if bar.expandBtn then bar.expandBtn:Hide() end
                    ClearExpandedItems(cat)
                    expandedCategories[cat] = false
                    if bar.expandBtn then bar.expandBtn:SetText("+") end
                end
            end
        else
            -- Overall is collapsed, hide all categories
            for _, cat in ipairs(categoryOrder) do
                local bar = progressFrame.progressBars[cat]
                bar.bg:Hide()
                bar.fill:Hide()
                bar.text:Hide()
                if bar.expandBtn then bar.expandBtn:Hide() end
                ClearExpandedItems(cat)
            end
        end
    end
    
    -- Resize frame to fit visible content
    ResizeFrame()
    
    -- If we haven't refreshed items yet, check if we need to refresh expanded items
    if not skipRefresh and RefreshExpandedItems then
        -- Check if any categories or subzones are expanded
        local hasExpanded = false
        
        -- Check category expansions
        for _, expanded in pairs(expandedCategories) do
            if expanded then
                hasExpanded = true
                break
            end
        end
        
        -- Check subzone expansions
        if not hasExpanded then
            for _, expanded in pairs(expandedSubzones) do
                if expanded then
                    hasExpanded = true
                    break
                end
            end
        end
        
        if hasExpanded then
            isRefreshing = true
            RefreshExpandedItems()
            isRefreshing = false
            -- Call UpdateProgressBars again to reposition with new item counts
            UpdateProgressBars(true)  -- Skip refresh on recursive call
        end
    end
end

-- Expose globally for external updates
_G.AV_UpdateProgressBars = UpdateProgressBars

-- Auto-update on show
progressFrame:SetScript("OnShow", function()
    UpdateProgressBars()
end)

progressFrame:SetScript("OnHide", function()
    -- Placeholder for future cleanup if needed
end)

-- Event-driven updates (primary method)
-- Progress frame registers for relevant events and updates only when needed
progressFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")  -- Zone changes
progressFrame:RegisterEvent("ASCENSION_STORE_COLLECTION_ITEM_LEARNED")  -- Item learned
progressFrame:RegisterEvent("APPEARANCE_COLLECTED")  -- Fallback item learned event
progressFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")  -- Real-time kill tracking
progressFrame:RegisterEvent("LOOT_OPENED")  -- Real-time loot tracking

progressFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ZONE_CHANGED_NEW_AREA" then
        -- Zone changed - update if in zone view mode
        if self:IsVisible() and viewMode == "zone" then
            UpdateProgressBars()
        end
    elseif event == "ASCENSION_STORE_COLLECTION_ITEM_LEARNED" or event == "APPEARANCE_COLLECTED" then
        -- Item learned - update with small delay to allow API to update
        C_Timer.After(0.5, function()
            if self:IsVisible() then
                UpdateProgressBars()
            end
        end)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        -- Real-time kill tracking - refresh expanded items if visible
        local timestamp, subevent = ...
        if subevent == "PARTY_KILL" and self:IsVisible() then
            -- Quick refresh of expanded items only (don't recalculate everything)
            if RefreshExpandedItems then
                C_Timer.After(0.1, function()  -- Small delay for data processing
                    RefreshExpandedItems()
                end)
            end
        end
    elseif event == "LOOT_OPENED" then
        -- Real-time loot tracking - refresh expanded items if visible
        if self:IsVisible() then
            if RefreshExpandedItems then
                C_Timer.After(0.1, function()  -- Small delay for data processing
                    RefreshExpandedItems()
                end)
            end
        end
    end
end)

-- ============================================================================
-- Global Functions
-- ============================================================================

-- Show the collection progress frame
function AV_ShowCollectionProgress()
    if AscensionVanityDB.progressFramePosition then
        local pos = AscensionVanityDB.progressFramePosition
        progressFrame:ClearAllPoints()
        progressFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    end
    UpdateProgressBars()
    progressFrame:Show()
    AscensionVanityDB.showProgressFrame = true
    if _G.AscensionVanity_SyncSettingsUI then _G.AscensionVanity_SyncSettingsUI() end
end

function AV_HideCollectionProgress()
    progressFrame:Hide()
    AscensionVanityDB.showProgressFrame = false
    if _G.AscensionVanity_SyncSettingsUI then _G.AscensionVanity_SyncSettingsUI() end
end

-- Toggle the collection progress frame
function AV_ToggleCollectionProgress()
    if progressFrame:IsVisible() then
        AV_HideCollectionProgress()
    else
        AV_ShowCollectionProgress()
    end
end

-- Initialize on load
local function Initialize()
    -- Hide by default (will be shown if saved state says so)
    progressFrame:Hide()
    
    -- Restore visibility from saved variables
    if AscensionVanityDB.showProgressFrame then
        AV_ShowCollectionProgress()
    end
end

-- Wait for addon to fully load before initializing
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Delay initialization slightly to ensure zone data is loaded
        C_Timer.After(0.5, function()
            Initialize()
        end)
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
