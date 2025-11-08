-- AscensionVanity - Database Browser / Regional Guide
-- Comprehensive interface for exploring the vanity database with filtering options

local AddonName = "AscensionVanity"

-- ============================================================================
-- Frame Setup
-- ============================================================================

local browserFrame = CreateFrame("Frame", "AV_DatabaseBrowser", UIParent)
browserFrame:SetSize(565, 540)
browserFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
browserFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
browserFrame:SetBackdropColor(0, 0, 0, 0.95)
browserFrame:EnableMouse(true)
browserFrame:SetMovable(true)
browserFrame:RegisterForDrag("LeftButton")
browserFrame:SetScript("OnDragStart", browserFrame.StartMoving)
browserFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save position
    local point, _, relativePoint, x, y = self:GetPoint()
    if not AscensionVanityDB.browserPosition then
        AscensionVanityDB.browserPosition = {}
    end
    AscensionVanityDB.browserPosition.point = point
    AscensionVanityDB.browserPosition.relativePoint = relativePoint
    AscensionVanityDB.browserPosition.x = x
    AscensionVanityDB.browserPosition.y = y
end)
browserFrame:SetFrameStrata("DIALOG")
browserFrame:Hide()

-- Make closable with ESC key
table.insert(UISpecialFrames, "AV_DatabaseBrowser")

-- ============================================================================
-- Title Bar
-- ============================================================================

local titleBar = browserFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleBar:SetPoint("TOP", browserFrame, "TOP", 0, -12)
titleBar:SetText("|cFF00FF96AscensionVanity|r Database Browser")

-- Close Button
local closeButton = CreateFrame("Button", nil, browserFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", browserFrame, "TOPRIGHT", -5, -5)

-- ============================================================================
-- Filter Controls (Top Section)
-- ============================================================================

local filterSection = CreateFrame("Frame", nil, browserFrame)
filterSection:SetPoint("TOPLEFT", browserFrame, "TOPLEFT", 15, -30)
filterSection:SetPoint("TOPRIGHT", browserFrame, "TOPRIGHT", -15, -30)
filterSection:SetHeight(120)

-- Zone Filter Label
local zoneLabel = filterSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
zoneLabel:SetPoint("TOPLEFT", filterSection, "TOPLEFT", 0, 0)
zoneLabel:SetText("|cFFFFFFFFZone Filter:|r")

-- Radio buttons for All Zones / Current Zone
local allZonesRadio = CreateFrame("CheckButton", nil, filterSection, "UIRadioButtonTemplate")
allZonesRadio:SetPoint("TOPLEFT", zoneLabel, "BOTTOMLEFT", 5, -5)
allZonesRadio:SetSize(20, 20)

local allZonesLabel = filterSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
allZonesLabel:SetPoint("LEFT", allZonesRadio, "RIGHT", 2, 0)
allZonesLabel:SetText("All Zones")

local currentZoneRadio = CreateFrame("CheckButton", nil, filterSection, "UIRadioButtonTemplate")
currentZoneRadio:SetPoint("LEFT", allZonesLabel, "RIGHT", 10, 0)
currentZoneRadio:SetSize(20, 20)
currentZoneRadio:SetChecked(true)  -- Default to Current Zone

local currentZoneLabel = filterSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
currentZoneLabel:SetPoint("LEFT", currentZoneRadio, "RIGHT", 2, 0)
currentZoneLabel:SetText("Current Zone")

-- Category Filter Label
local categoryLabel = filterSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
categoryLabel:SetPoint("TOPLEFT", zoneLabel, "BOTTOMLEFT", 0, -40)
categoryLabel:SetText("|cFFFFFFFFCategory Filter:|r")

-- Category buttons
local categories = {
    {key = "all", name = "All", color = "|cFFFFFFFF"},
    {key = "beast", name = "Beast", color = "|cFF00FF00"},
    {key = "demon", name = "Demon", color = "|cFFFF00FF"},
    {key = "undead", name = "Undead", color = "|cFF808080"},
    {key = "dragonkin", name = "Dragonkin", color = "|cFFFF8000"},
    {key = "elemental", name = "Elemental", color = "|cFF00FFFF"}
}

local categoryButtons = {}
local buttonWidth = 85
local buttonSpacing = 5

for i, cat in ipairs(categories) do
    local btn = CreateFrame("Button", nil, filterSection, "UIPanelButtonTemplate")
    btn:SetSize(buttonWidth, 22)
    btn:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", (i - 1) * (buttonWidth + buttonSpacing), -5)
    btn:SetText(cat.color .. cat.name .. "|r")
    btn.category = cat.key
    btn:SetScript("OnClick", function()
        AV_DatabaseBrowser_FilterByCategory(cat.key)
    end)
    categoryButtons[cat.key] = btn
end

-- Learned Status Filter Label
local learnedLabel = filterSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
learnedLabel:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", 0, -32)
learnedLabel:SetText("|cFFFFFFFFShow:|r")

-- Learned status buttons
local learnedButtons = {}
local learnedOptions = {
    {key = "all", name = "All"},
    {key = "unlearned", name = "Unlearned"},
    {key = "learned", name = "Learned"}
}

for i, opt in ipairs(learnedOptions) do
    local btn = CreateFrame("Button", nil, filterSection, "UIPanelButtonTemplate")
    btn:SetSize(buttonWidth, 22)
    btn:SetPoint("TOPLEFT", learnedLabel, "BOTTOMLEFT", (i - 1) * (buttonWidth + buttonSpacing), -5)
    btn:SetText(opt.name)
    btn.learnedFilter = opt.key
    btn:SetScript("OnClick", function()
        AV_DatabaseBrowser_FilterByLearnedStatus(opt.key)
    end)
    learnedButtons[opt.key] = btn
end

-- ============================================================================
-- Browser State
-- ============================================================================

local browserState = {
    currentZone = nil,
    filterMode = "all",  -- "all" or "current"
    categoryFilter = "all",
    learnedFilter = "all",
    multipleItemsFilter = false,
    filteredData = {},
    displayedEntries = {},
    currentPage = 1,
    itemsPerPage = 18,
    totalPages = 1
}

-- Multiple Items Filter - CHECKBOX
local multipleItemsCheckbox = CreateFrame("CheckButton", nil, filterSection, "UICheckButtonTemplate")
multipleItemsCheckbox:SetSize(22, 22)
multipleItemsCheckbox:SetPoint("TOPLEFT", learnedLabel, "BOTTOMLEFT", 3 * (buttonWidth + buttonSpacing), -5)
multipleItemsCheckbox:SetScript("OnClick", function(self)
    browserState.multipleItemsFilter = self:GetChecked()
    browserState.currentPage = 1
    AV_DatabaseBrowser_RefreshDisplay()
end)

local multipleItemsLabel = filterSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
multipleItemsLabel:SetPoint("LEFT", multipleItemsCheckbox, "RIGHT", 2, 0)
multipleItemsLabel:SetText("|cFFFFFFFFMulti-Drop|r")

-- ============================================================================
-- Results Section
-- ============================================================================

local resultsLabel = browserFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
resultsLabel:SetPoint("TOPLEFT", filterSection, "BOTTOMLEFT", 0, -20)
resultsLabel:SetText("|cFFFFFFFFResults:|r Loading...")

local displayContainer = CreateFrame("Frame", nil, browserFrame)
displayContainer:SetPoint("TOPLEFT", resultsLabel, "BOTTOMLEFT", 0, -5)
displayContainer:SetPoint("BOTTOMRIGHT", browserFrame, "BOTTOMRIGHT", -10, 40)

-- ============================================================================
-- Pagination Controls
-- ============================================================================

local paginationFrame = CreateFrame("Frame", nil, browserFrame)
paginationFrame:SetSize(550, 30)
paginationFrame:SetPoint("BOTTOMLEFT", browserFrame, "BOTTOMLEFT", 10, 10)
paginationFrame:SetPoint("BOTTOMRIGHT", browserFrame, "BOTTOMRIGHT", -10, 10)

local prevButton = CreateFrame("Button", nil, paginationFrame, "UIPanelButtonTemplate")
prevButton:SetSize(80, 22)
prevButton:SetPoint("LEFT", paginationFrame, "LEFT", 0, 0)
prevButton:SetText("< Previous")
prevButton:SetScript("OnClick", function()
    if browserState.currentPage > 1 then
        browserState.currentPage = browserState.currentPage - 1
    else
        browserState.currentPage = browserState.totalPages
    end
    AV_DatabaseBrowser_RefreshDisplay()
end)

local pageButton = CreateFrame("Button", nil, paginationFrame)
pageButton:SetSize(100, 22)
pageButton:SetPoint("CENTER", paginationFrame, "CENTER", 0, 0)

local pageLabel = pageButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
pageLabel:SetPoint("CENTER", pageButton, "CENTER", 0, 0)
pageLabel:SetText("Page 1 of 1")

pageButton:SetScript("OnEnter", function(self)
    pageLabel:SetTextColor(1, 1, 0)
end)
pageButton:SetScript("OnLeave", function(self)
    pageLabel:SetTextColor(1, 1, 1)
end)
pageButton:SetScript("OnClick", function()
    StaticPopupDialogs["AV_JUMP_TO_PAGE"] = {
        text = "Enter page number (1-" .. browserState.totalPages .. "):",
        button1 = "Go",
        button2 = "Cancel",
        hasEditBox = true,
        maxLetters = 4,
        OnShow = function(self)
            self.editBox:SetText(tostring(browserState.currentPage))
            self.editBox:SetFocus()
            self.editBox:HighlightText()
        end,
        OnAccept = function(self)
            local page = tonumber(self.editBox:GetText())
            if page and page >= 1 and page <= browserState.totalPages then
                browserState.currentPage = page
                AV_DatabaseBrowser_RefreshDisplay()
            else
                print("|cFF00FF96AscensionVanity:|r Invalid page number. Must be between 1 and " .. browserState.totalPages)
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("AV_JUMP_TO_PAGE")
end)

local nextButton = CreateFrame("Button", nil, paginationFrame, "UIPanelButtonTemplate")
nextButton:SetSize(80, 22)
nextButton:SetPoint("RIGHT", paginationFrame, "RIGHT", 0, 0)
nextButton:SetText("Next >")
nextButton:SetScript("OnClick", function()
    if browserState.currentPage < browserState.totalPages then
        browserState.currentPage = browserState.currentPage + 1
    else
        browserState.currentPage = 1
    end
    AV_DatabaseBrowser_RefreshDisplay()
end)

browserState.paginationControls = {
    pageLabel = pageLabel,
    prevButton = prevButton,
    nextButton = nextButton
}

-- ============================================================================
-- Data Loading and Filtering
-- ============================================================================

local function GetCurrentZone()
    return GetZoneText() or "Unknown"
end

-- Build hierarchical continent/zone/subzone list from database
local function BuildGeographicHierarchy()
    -- TODO: Build hierarchical zone structure for advanced filtering
    -- Currently using flat zone filter (All Zones / Current Zone)
    return {}, {}
end

-- Radio button handlers
allZonesRadio:SetScript("OnClick", function(self)
    allZonesRadio:SetChecked(true)
    currentZoneRadio:SetChecked(false)
    browserState.filterMode = "all"
    browserState.currentPage = 1
    titleBar:SetText("|cFF00FF96AscensionVanity|r Database Browser")
    AV_DatabaseBrowser_RefreshDisplay()
end)

currentZoneRadio:SetScript("OnClick", function(self)
    allZonesRadio:SetChecked(false)
    currentZoneRadio:SetChecked(true)
    browserState.filterMode = "current"
    browserState.currentZone = GetCurrentZone()
    browserState.currentPage = 1
    titleBar:SetText("|cFF00FF96AscensionVanity|r Regional Guide - " .. browserState.currentZone)
    AV_DatabaseBrowser_RefreshDisplay()
end)

local function ApplyFilters()
    -- CRITICAL: Filter items FIRST, then group by creature
    -- This prevents creature_0 (unknown) from including items from all zones
    local currentZone = browserState.currentZone
    local filteredItems = {}
    
    -- Debug output
    local totalItems = 0
    for _ in pairs(AV_VanityItems) do
        totalItems = totalItems + 1
    end
    
    -- Step 1: Filter items by zone (if in current zone mode)
    for itemId, data in pairs(AV_VanityItems) do
        local includeItem = true
        
        -- Zone filter
        if browserState.filterMode == "current" and currentZone and currentZone ~= "" then
            if (data.zone or "Unknown") ~= currentZone then
                includeItem = false
            end
        end
        
        if includeItem then
            filteredItems[itemId] = data
        end
    end
    
    -- Step 2: Build creature list from FILTERED items only
    local creatures = {}
    
    local function GetCategoryFromName(itemName)
        if itemName:find("Beastmaster's Whistle", 1, true) then
            return "beast"
        elseif itemName:find("Blood Soaked Vellum", 1, true) then
            return "undead"
        elseif itemName:find("Summoner's Stone", 1, true) then
            return "demon"
        elseif itemName:find("Draconic Warhorn", 1, true) then
            return "dragonkin"
        elseif itemName:find("Elemental Lodestone", 1, true) then
            return "elemental"
        end
        return "unknown"
    end
    
    local function GetPetName(fullName)
        local petName = fullName:match(": (.+)$")
        return petName or fullName
    end
    
    for itemId, data in pairs(filteredItems) do
        local creatureId = data.creatureId or 0
        local creatureKey = "creature_" .. creatureId
        
        if not creatures[creatureKey] then
            creatures[creatureKey] = {
                creatureId = creatureId,
                name = GetPetName(data.name),
                category = GetCategoryFromName(data.name),
                zone = data.zone or "Unknown",
                subzone = data.subzone or "",
                items = {}
            }
        end
        
        table.insert(creatures[creatureKey].items, {
            id = itemId,
            name = GetPetName(data.name),
            icon = data.icon,
            zone = data.zone or "Unknown"
        })
    end
    
    -- Step 3: Apply remaining filters to creatures
    local filtered = {}
    
    for creatureName, creatureData in pairs(creatures) do
        local includeCreature = true
        
        -- Category filter
        if includeCreature and browserState.categoryFilter ~= "all" then
            if creatureData.category ~= browserState.categoryFilter then
                includeCreature = false
            end
        end
        
        -- Learned status filter
        if includeCreature and browserState.learnedFilter ~= "all" then
            local hasUnlearned = false
            local hasLearned = false
            
            for _, item in ipairs(creatureData.items) do
                local isLearned = AV_IsVanityItemLearned(item.id)
                if isLearned then
                    hasLearned = true
                else
                    hasUnlearned = true
                end
            end
            
            if browserState.learnedFilter == "unlearned" and not hasUnlearned then
                includeCreature = false
            elseif browserState.learnedFilter == "learned" and not hasLearned then
                includeCreature = false
            end
        end
        
        -- Multi-drop filter
        if includeCreature and browserState.multipleItemsFilter then
            if #creatureData.items < 2 then
                includeCreature = false
            end
        end
        
        if includeCreature then
            filtered[creatureName] = creatureData
        end
    end
    
    browserState.filteredData = filtered
    return filtered
end



-- ============================================================================
-- Display Functions
-- ============================================================================

local function ClearDisplayedEntries()
    for _, entry in ipairs(browserState.displayedEntries) do
        entry:Hide()
        entry:SetParent(nil)
    end
    wipe(browserState.displayedEntries)
end

local function CreateCreatureEntry(parent, xOffset, yOffset, width, height, creatureData)
    local entry = CreateFrame("Frame", nil, parent)
    entry:SetSize(width - 10, height)  -- Add padding
    entry:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset + 5, yOffset)
    
    entry.bg = entry:CreateTexture(nil, "BACKGROUND")
    entry.bg:SetAllPoints()
    entry.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    
    entry.nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entry.nameText:SetPoint("TOPLEFT", entry, "TOPLEFT", 3, -3)
    entry.nameText:SetWidth(width - 6)
    entry.nameText:SetJustifyH("LEFT")
    entry.nameText:SetText("|cFFFFFFFF" .. (creatureData.name or "Unknown") .. "|r")
    
    local location = creatureData.zone or "Unknown"
    entry.locationText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    entry.locationText:SetPoint("TOPLEFT", entry.nameText, "BOTTOMLEFT", 0, -1)
    entry.locationText:SetWidth(width - 6)
    entry.locationText:SetJustifyH("LEFT")
    entry.locationText:SetText("|cFF808080" .. location .. "|r")
    
    local learnedCount = 0
    for _, item in ipairs(creatureData.items) do
        if AV_IsVanityItemLearned(item.id) then
            learnedCount = learnedCount + 1
        end
    end
    
    local itemCountText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    itemCountText:SetPoint("TOPLEFT", entry.locationText, "BOTTOMLEFT", 0, -2)
    
    local countColor = learnedCount > 0 and "|cFF00FF00" or "|cFFFFFFFF"
    local checkIcon = learnedCount > 0 and "|TInterface\\RaidFrame\\ReadyCheck-Ready:10:10|t " or ""
    itemCountText:SetText(checkIcon .. countColor .. learnedCount .. "/" .. #creatureData.items .. " items|r")
    
    return entry
end

local function RefreshDisplay()
    ClearDisplayedEntries()
    
    local filtered = ApplyFilters()
    
    local sortedCreatures = {}
    for name, data in pairs(filtered) do
        table.insert(sortedCreatures, {name = (data.name or name), data = data, key = name})
    end
    table.sort(sortedCreatures, function(a, b)
        local nameA = string.lower(a.name)
        local nameB = string.lower(b.name)
        if nameA == nameB then
            -- Secondary sort by zone to ensure stable ordering
            local zoneA = string.lower(a.data.zone or "")
            local zoneB = string.lower(b.data.zone or "")
            if zoneA == zoneB then
                -- Tertiary sort by original key as final tie-breaker
                return string.lower(a.key) < string.lower(b.key)
            end
            return zoneA < zoneB
        end
        return nameA < nameB
    end)
    
    local totalCount = #sortedCreatures
    browserState.totalPages = math.max(1, math.ceil(totalCount / browserState.itemsPerPage))
    
    if browserState.currentPage > browserState.totalPages then
        browserState.currentPage = browserState.totalPages
    end
    if browserState.currentPage < 1 then
        browserState.currentPage = 1
    end
    
    local startIdx = ((browserState.currentPage - 1) * browserState.itemsPerPage) + 1
    local endIdx = math.min(startIdx + browserState.itemsPerPage - 1, totalCount)
    
    -- Build filter description
    local filterDesc = browserState.filterMode == "all" and "All Zones" or browserState.currentZone or "Current Zone"
    
    resultsLabel:SetText(string.format(
        "|cFFFFFFFFResults:|r %d creatures in %s (showing %d-%d)",
        totalCount, filterDesc, startIdx, endIdx
    ))
    
    if browserState.paginationControls then
        local controls = browserState.paginationControls
        controls.pageLabel:SetText(string.format("Page %d of %d", browserState.currentPage, browserState.totalPages))
        if browserState.totalPages > 1 then
            controls.prevButton:SetEnabled(true)
            controls.nextButton:SetEnabled(true)
        else
            controls.prevButton:SetEnabled(false)
            controls.nextButton:SetEnabled(false)
        end
    end
    
    -- Grid layout: 3 columns x 5 rows = 15 items per page (adjusts to 18 if more room)
    local entriesPerRow = 3
    local containerWidth = displayContainer:GetWidth()
    local entryWidth = math.floor((containerWidth - 40) / entriesPerRow)  -- Leave room for spacing
    local entryHeight = 45
    local spacingX = 10
    local spacingY = 8
    
    local row = 0
    local col = 0
    
    for i = startIdx, endIdx do
        local creature = sortedCreatures[i]
        if creature then
            local xOffset = col * (entryWidth + spacingX)
            local yOffset = -row * (entryHeight + spacingY)
            
            local entry = CreateCreatureEntry(displayContainer, xOffset, yOffset, entryWidth, entryHeight, creature.data)
            table.insert(browserState.displayedEntries, entry)
            
            col = col + 1
            if col >= entriesPerRow then
                col = 0
                row = row + 1
            end
        end
    end
end

-- ============================================================================
-- Public API Functions
-- ============================================================================

function AV_DatabaseBrowser_Show(zoneFilter)
    browserState.currentZone = GetCurrentZone()
    browserState.currentPage = 1
    
    -- Set filter mode based on parameter
    if zoneFilter and zoneFilter ~= "all" then
        browserState.filterMode = "current"
        currentZoneRadio:SetChecked(true)
        allZonesRadio:SetChecked(false)
        titleBar:SetText("|cFF00FF96AscensionVanity|r Regional Guide - " .. browserState.currentZone)
    else
        browserState.filterMode = "all"
        allZonesRadio:SetChecked(true)
        currentZoneRadio:SetChecked(false)
        titleBar:SetText("|cFF00FF96AscensionVanity|r Database Browser")
    end
    
    RefreshDisplay()
    browserFrame:Show()
end

function AV_DatabaseBrowser_Hide()
    browserFrame:Hide()
end

function AV_DatabaseBrowser_Toggle()
    if browserFrame:IsShown() then
        AV_DatabaseBrowser_Hide()
    else
        AV_DatabaseBrowser_Show()
    end
end



function AV_DatabaseBrowser_FilterByCategory(category)
    browserState.categoryFilter = category
    browserState.currentPage = 1
    RefreshDisplay()
end

function AV_DatabaseBrowser_FilterByLearnedStatus(status)
    browserState.learnedFilter = status
    browserState.currentPage = 1
    RefreshDisplay()
end

function AV_DatabaseBrowser_RefreshDisplay()
    RefreshDisplay()
end

-- ============================================================================
-- Initialization
-- ============================================================================

local function RestorePosition()
    if AscensionVanityDB and AscensionVanityDB.browserPosition then
        local pos = AscensionVanityDB.browserPosition
        browserFrame:ClearAllPoints()
        browserFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    end
end

local zoneFrame = CreateFrame("Frame")
zoneFrame:RegisterEvent("ZONE_CHANGED")
zoneFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
zoneFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneFrame:SetScript("OnEvent", function()
    if browserFrame:IsShown() and browserState.filterMode == "current" then
        local newZone = GetCurrentZone()
        browserState.currentZone = newZone
        titleBar:SetText("|cFF00FF96AscensionVanity|r Regional Guide - " .. newZone)
        RefreshDisplay()
    end
end)

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    RestorePosition()
end)
