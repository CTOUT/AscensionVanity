-- AscensionVanity - Collection Progress Frame
-- Standalone moveable frame showing collection progress
-- Version: 2.2

-- ============================================================================
-- Frame Creation
-- ============================================================================

-- Create main frame
local progressFrame = CreateFrame("Frame", "AV_CollectionProgressFrame", UIParent)
progressFrame:SetSize(250, 200)  -- Initial size, will be resized dynamically
progressFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -50, -200)
progressFrame:SetMovable(true)
progressFrame:EnableMouse(true)
progressFrame:SetClampedToScreen(true)
progressFrame:SetFrameStrata("MEDIUM")
progressFrame:SetFrameLevel(10)

-- Storage for expanded item lists
progressFrame.expandedItems = {}  -- Stores FontStrings for expanded items

-- Background
local bg = progressFrame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.8)

-- Border
local border = progressFrame:CreateTexture(nil, "BORDER")
border:SetPoint("TOPLEFT", -1, 1)
border:SetPoint("BOTTOMRIGHT", 1, -1)
border:SetColorTexture(0.3, 0.3, 0.3, 1)

-- Header background
local headerBg = progressFrame:CreateTexture(nil, "ARTWORK")
headerBg:SetHeight(24)
headerBg:SetPoint("TOPLEFT", 1, -1)
headerBg:SetPoint("TOPRIGHT", -1, -1)
headerBg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

-- Title
local title = progressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", headerBg, "TOPLEFT", 8, -4)
title:SetText(AV_COLOR_HEADER .. "Collection Progress" .. AV_COLOR_RESET)

-- Details button (opens Database Browser)
local detailsButton = CreateFrame("Button", nil, progressFrame, "UIPanelButtonTemplate")
detailsButton:SetSize(60, 18)
detailsButton:SetPoint("TOPRIGHT", headerBg, "TOPRIGHT", -5, -3)
detailsButton:SetText("Details")
detailsButton:SetNormalFontObject("GameFontNormalSmall")
detailsButton:SetScript("OnClick", function(self)
    if AV_DatabaseBrowser_Show then
        -- Get current zone if in zone view
        local viewMode = progressFrame.getViewMode and progressFrame.getViewMode() or "zone"
        if viewMode == "zone" then
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

-- Refresh button (manual update trigger)
local refreshButton = CreateFrame("Button", nil, progressFrame, "UIPanelButtonTemplate")
refreshButton:SetSize(20, 18)
refreshButton:SetPoint("RIGHT", detailsButton, "LEFT", -3, 0)
refreshButton:SetText("⟳")
refreshButton:SetNormalFontObject("GameFontNormalLarge")
refreshButton:SetScript("OnClick", function(self)
    local updateFunc = _G.AV_UpdateProgressBars
    if updateFunc then
        updateFunc()
    end
end)
refreshButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Refresh Progress", 1, 1, 1)
    GameTooltip:AddLine("Manually update collection progress", nil, nil, nil, true)
    GameTooltip:AddLine("Use this if progress doesn't auto-update", 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
end)
refreshButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- View mode toggle button (Global/Zone)
local viewMode = "zone"  -- Default to zone view
local viewButton = CreateFrame("Button", nil, progressFrame, "UIPanelButtonTemplate")
viewButton:SetSize(60, 18)
viewButton:SetPoint("RIGHT", refreshButton, "LEFT", -3, 0)
viewButton:SetText("Zone")
viewButton:SetNormalFontObject("GameFontNormalSmall")
viewButton:SetScript("OnClick", function(self)
    if viewMode == "zone" then
        viewMode = "global"
        self:SetText("Global")
        print(AV_COLOR_YELLOW .. "Switched to Global view" .. AV_COLOR_RESET)
    else
        viewMode = "zone"
        self:SetText("Zone")
        print(AV_COLOR_YELLOW .. "Switched to Zone view" .. AV_COLOR_RESET)
    end
    -- Update progress bars with new view
    if progressFrame:IsVisible() then
        local updateFunc = _G.AV_UpdateProgressBars or function() end
        updateFunc()
    end
end)
viewButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    if viewMode == "zone" then
        GameTooltip:SetText("Zone View", 1, 1, 1)
        GameTooltip:AddLine("Showing progress for items in your current zone", nil, nil, nil, true)
        GameTooltip:AddLine("Click to switch to Global view", 0.7, 0.7, 0.7, true)
    else
        GameTooltip:SetText("Global View", 1, 1, 1)
        GameTooltip:AddLine("Showing overall collection progress", nil, nil, nil, true)
        GameTooltip:AddLine("Click to switch to Zone view", 0.7, 0.7, 0.7, true)
    end
    GameTooltip:Show()
end)
viewButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
progressFrame.viewButton = viewButton
progressFrame.getViewMode = function() return viewMode end

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

-- Progress bars container
progressFrame.progressBars = {}

-- Helper function to create a progress bar
local function CreateProgressBar(parent, label, anchor, yOffset)
    -- Bar background
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetHeight(18)
    bg:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 8, yOffset)
    bg:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", -8, yOffset)
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)
    
    -- Bar fill (progress indicator)
    local fill = parent:CreateTexture(nil, "ARTWORK")
    fill:SetHeight(16)
    fill:SetPoint("TOPLEFT", bg, "TOPLEFT", 1, -1)
    fill:SetWidth(1)  -- Will be updated dynamically
    fill:SetColorTexture(0.2, 0.6, 0.2, 1)  -- Green by default
    
    -- Bar text (category name + progress)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", bg, "LEFT", 4, 0)
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
                self.fill:SetColorTexture(0.2, 0.8, 0.2, 1)  -- Bright green (100%)
            elseif percent >= 0.75 then
                self.fill:SetColorTexture(0.4, 0.7, 0.3, 1)  -- Yellow-green (75%+)
            elseif percent >= 0.5 then
                self.fill:SetColorTexture(0.8, 0.8, 0.2, 1)  -- Yellow (50%+)
            elseif percent >= 0.25 then
                self.fill:SetColorTexture(0.9, 0.6, 0.2, 1)  -- Orange (25%+)
            else
                self.fill:SetColorTexture(0.8, 0.2, 0.2, 1)  -- Red (< 25%)
            end
            
            -- Update text
            self.text:SetText(string.format("%s: %d/%d (%.1f%%)", self.label, learned, total, percent * 100))
        end
    }
end

-- Create progress bars
local yPos = -8
progressFrame.progressBars.overall = CreateProgressBar(progressFrame, "Overall", headerBg, yPos)

-- Flat anchoring for categories (all anchored to overall bar, spaced vertically)
local categoryOrder = {"beast", "demon", "undead", "dragonkin", "elemental"}
local categoryOffsets = {
    beast = -28,
    demon = -52,
    undead = -76,
    dragonkin = -100,
    elemental = -124
}
for _, cat in ipairs(categoryOrder) do
    progressFrame.progressBars[cat] = CreateProgressBar(progressFrame, AV_CATEGORY_SHORT_NAMES[cat], progressFrame.progressBars.overall.bg, categoryOffsets[cat])
end

-- Expand/collapse state
local overallExpanded = true
local expandedCategories = { beast=true, demon=true, undead=true, dragonkin=true, elemental=true }

-- Add expand/collapse button for OVERALL bar (master collapse)
local overallBtn = CreateFrame("Button", nil, progressFrame)
overallBtn:SetSize(14, 14)
overallBtn:SetPoint("RIGHT", progressFrame.progressBars.overall.bg, "LEFT", -4, 0)
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
    btn:SetPoint("RIGHT", bar.bg, "LEFT", -4, 0)
    btn:SetNormalFontObject("GameFontNormal")
    btn:SetText("+")  -- Start collapsed
    
    btn:SetScript("OnClick", function()
        expandedCategories[cat] = not expandedCategories[cat]
        btn:SetText(expandedCategories[cat] and "-" or "+")
        
        if expandedCategories[cat] then
            -- Show pet names for this category
            ShowExpandedItems(cat, bar.bg, -25)  -- -25 is bar height
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

-- Helper function to get items for a category (filtered by zone in zone view)
local function GetCategoryItems(category)
    local items = {}
    
    -- Get current view mode (zone or global)
    local viewMode = progressFrame.getViewMode()
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
            -- If zone view, filter by current zone
            local includeItem = true
            if currentZone and itemData.zone then
                includeItem = (itemData.zone == currentZone)
            end
            
            if includeItem then
                -- Extract pet name (everything after ": ")
                local petName = itemData.name:match(": (.+)$") or itemData.name
                table.insert(items, {
                    id = itemId,
                    name = petName,
                    learned = AV_IsVanityItemLearned and AV_IsVanityItemLearned(itemId) or false
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
    
    for _, fontString in ipairs(progressFrame.expandedItems[category]) do
        fontString:Hide()
        -- Don't use SetParent(nil) for FontStrings - just hide and remove reference
    end
    progressFrame.expandedItems[category] = {}
end

-- Helper function to create expanded item list for a category
ShowExpandedItems = function(category, anchorBar, yOffset)
    ClearExpandedItems(category)
    
    local items = GetCategoryItems(category)
    if #items == 0 then return 0 end  -- Return 0 height if no items
    
    progressFrame.expandedItems[category] = {}
    local itemHeight = 16
    local currentY = yOffset - 4  -- Start below the bar
    
    for i, item in ipairs(items) do
        local itemText = progressFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        itemText:SetPoint("TOPLEFT", anchorBar, "BOTTOMLEFT", 20, currentY)  -- Indent items
        itemText:SetPoint("TOPRIGHT", anchorBar, "BOTTOMRIGHT", -8, currentY)
        itemText:SetJustifyH("LEFT")
        
        -- Color code: green if learned, white if not
        local color = item.learned and AV_COLOR_GREEN or "|cFFCCCCCC"
        local checkmark = item.learned and "✓ " or "  "
        itemText:SetText(checkmark .. color .. item.name .. AV_COLOR_RESET)
        
        table.insert(progressFrame.expandedItems[category], itemText)
        currentY = currentY - itemHeight
    end
    
    -- Return total height used by expanded items
    return #items * itemHeight + 4  -- +4 for spacing
end

-- Helper function to resize frame based on visible content
local function ResizeFrame()
    local headerHeight = 45  -- Title + buttons + padding
    local barHeight = 25
    local padding = 10
    local totalHeight = headerHeight
    
    -- Add overall bar
    totalHeight = totalHeight + barHeight
    
    -- Add visible category bars and their expanded items
    if overallExpanded then
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
    end
    
    totalHeight = totalHeight + padding
    progressFrame:SetHeight(totalHeight)
end

-- Function to update all progress bars
UpdateProgressBars = function()
    if not AV_GetCollectionProgress then
        return  -- Function not available yet
    end
    
    local progress
    local viewMode = progressFrame.getViewMode()
    
    if viewMode == "zone" then
        -- Get zone-specific progress (if available)
        if AV_GetZoneCollectionProgress then
            progress = AV_GetZoneCollectionProgress()
            
            -- Update title to show current zone
            local zoneName = GetZoneText()
            if zoneName and zoneName ~= "" then
                title:SetText(AV_COLOR_HEADER .. zoneName .. AV_COLOR_RESET)
            else
                title:SetText(AV_COLOR_HEADER .. "Collection Progress" .. AV_COLOR_RESET)
            end
        else
            -- Fallback to global if zone function not available yet
            progress = AV_GetCollectionProgress()
            title:SetText(AV_COLOR_HEADER .. "Collection Progress" .. AV_COLOR_RESET)
        end
    else
        -- Global view
        progress = AV_GetCollectionProgress()
        title:SetText(AV_COLOR_HEADER .. "Collection Progress" .. AV_COLOR_RESET)
    end
    
    -- Update each progress bar
    for category, bar in pairs(progressFrame.progressBars) do
        if progress[category] then
            bar:SetProgress(progress[category].learned, progress[category].total)
        end
    end
    
    -- Show/hide category bars based on view mode and expansion state
    local currentY = -70  -- Start position below overall bar
    
    if overallExpanded then
        for _, cat in ipairs(categoryOrder) do
            local bar = progressFrame.progressBars[cat]
            local shouldShow = true
            
            if viewMode == "zone" then
                -- In zone view: hide categories with 0 items
                if progress[cat] and progress[cat].total == 0 then
                    shouldShow = false
                end
            end
            
            if shouldShow then
                -- Reposition bar to current Y (handles moving up when categories hidden)
                bar.bg:SetPoint("TOPLEFT", progressFrame, "TOPLEFT", 8, currentY)
                bar.bg:Show()
                bar.fill:Show()
                bar.text:Show()
                if bar.expandBtn then bar.expandBtn:Show() end
                
                -- Move down for next bar
                currentY = currentY - 25  -- Bar height
                
                -- If this category is expanded, account for expanded items
                if expandedCategories[cat] and progressFrame.expandedItems[cat] then
                    currentY = currentY - (#progressFrame.expandedItems[cat] * 16) - 4
                end
            else
                bar.bg:Hide()
                bar.fill:Hide()
                bar.text:Hide()
                if bar.expandBtn then bar.expandBtn:Hide() end
                -- Also hide any expanded items for this category
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
    
    -- Resize frame to fit visible content
    ResizeFrame()
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
        Initialize()
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
