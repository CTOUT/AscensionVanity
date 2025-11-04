-- AscensionVanity - Database Browser / Regional Guide
-- Comprehensive interface for exploring the vanity database with filtering options

local AddonName = "AscensionVanity"

-- ============================================================================
-- Frame Setup
-- ============================================================================

local browserFrame = CreateFrame("Frame", "AV_DatabaseBrowser", UIParent)
browserFrame:SetSize(600, 500)
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
filterSection:SetPoint("TOPLEFT", browserFrame, "TOPLEFT", 15, -40)
filterSection:SetPoint("TOPRIGHT", browserFrame, "TOPRIGHT", -15, -40)
filterSection:SetHeight(120)

-- Zone Filter Label
local zoneLabel = filterSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
zoneLabel:SetPoint("TOPLEFT", filterSection, "TOPLEFT", 0, 0)
zoneLabel:SetText("|cFFFFFFFFZone Filter:|r")

-- Current Zone Button
local currentZoneButton = CreateFrame("Button", nil, filterSection, "UIPanelButtonTemplate")
currentZoneButton:SetSize(150, 25)
currentZoneButton:SetPoint("TOPLEFT", zoneLabel, "BOTTOMLEFT", 0, -5)
currentZoneButton:SetText("Current Zone")
currentZoneButton:SetScript("OnClick", function()
    AV_DatabaseBrowser_FilterToCurrentZone()
end)

-- All Zones Button
local allZonesButton = CreateFrame("Button", nil, filterSection, "UIPanelButtonTemplate")
allZonesButton:SetSize(150, 25)
allZonesButton:SetPoint("LEFT", currentZoneButton, "RIGHT", 5, 0)
allZonesButton:SetText("All Zones")
allZonesButton:SetScript("OnClick", function()
    AV_DatabaseBrowser_ShowAllZones()
end)

-- Category Filter Label
local categoryLabel = filterSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
categoryLabel:SetPoint("TOPLEFT", currentZoneButton, "BOTTOMLEFT", 0, -10)
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
    
    -- Position in rows of 3
    local row = math.floor((i - 1) / 3)
    local col = (i - 1) % 3
    btn:SetPoint("TOPLEFT", categoryLabel, "BOTTOMLEFT", col * (buttonWidth + buttonSpacing), -5 - (row * 27))
    
    btn:SetText(cat.color .. cat.name .. "|r")
    btn.category = cat.key
    btn:SetScript("OnClick", function()
        AV_DatabaseBrowser_FilterByCategory(cat.key)
    end)
    
    categoryButtons[cat.key] = btn
end

-- Learned Status Filter Label
local learnedLabel = filterSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
learnedLabel:SetPoint("TOPLEFT", categoryButtons["undead"], "BOTTOMLEFT", 0, -10)
learnedLabel:SetText("|cFFFFFFFFShow:|r")

-- Learned status buttons
local learnedButtons = {}
local learnedOptions = {
    {key = "all", name = "All Items"},
    {key = "unlearned", name = "Unlearned Only"},
    {key = "learned", name = "Learned Only"}
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
-- Browser State (must be defined before UI elements that reference it)
-- ============================================================================

local browserState = {
    currentZone = nil,
    zoneFilter = "all", -- "all" or specific zone name
    categoryFilter = "all",
    learnedFilter = "all",
    filteredData = {},
    displayedEntries = {},
    -- Pagination
    currentPage = 1,
    itemsPerPage = 50,
    totalPages = 1
}

-- ============================================================================
-- Results Section
-- ============================================================================

local resultsLabel = browserFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
resultsLabel:SetPoint("TOPLEFT", filterSection, "BOTTOMLEFT", 0, -10)
resultsLabel:SetText("|cFFFFFFFFResults:|r Loading...")

-- ScrollFrame for creature list (positioned between results and pagination)
local scrollFrame = CreateFrame("ScrollFrame", "AV_DatabaseBrowser_ScrollFrame", browserFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", resultsLabel, "BOTTOMLEFT", 0, -5)
scrollFrame:SetPoint("BOTTOMRIGHT", browserFrame, "BOTTOMRIGHT", -30, 40)  -- Leave room for pagination at bottom

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(scrollFrame:GetWidth() - 20, 1)
scrollFrame:SetScrollChild(scrollChild)

-- ============================================================================
-- Pagination Controls (Bottom of Frame)
-- ============================================================================

-- Pagination Frame - anchored to bottom of browser frame
local paginationFrame = CreateFrame("Frame", nil, browserFrame)
paginationFrame:SetSize(550, 30)
paginationFrame:SetPoint("BOTTOMLEFT", browserFrame, "BOTTOMLEFT", 10, 10)
paginationFrame:SetPoint("BOTTOMRIGHT", browserFrame, "BOTTOMRIGHT", -10, 10)

-- Previous Page Button
local prevButton = CreateFrame("Button", nil, paginationFrame, "UIPanelButtonTemplate")
prevButton:SetSize(80, 22)
prevButton:SetPoint("LEFT", paginationFrame, "LEFT", 0, 0)
prevButton:SetText("< Previous")
prevButton:SetScript("OnClick", function()
    if browserState.currentPage > 1 then
        browserState.currentPage = browserState.currentPage - 1
        AV_DatabaseBrowser_RefreshDisplay()
    end
end)

-- Page Info Label
local pageLabel = paginationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
pageLabel:SetPoint("CENTER", paginationFrame, "CENTER", 0, 0)
pageLabel:SetText("Page 1 of 1")

-- Next Page Button
local nextButton = CreateFrame("Button", nil, paginationFrame, "UIPanelButtonTemplate")
nextButton:SetSize(80, 22)
nextButton:SetPoint("RIGHT", paginationFrame, "RIGHT", 0, 0)
nextButton:SetText("Next >")
nextButton:SetScript("OnClick", function()
    if browserState.currentPage < browserState.totalPages then
        browserState.currentPage = browserState.currentPage + 1
        AV_DatabaseBrowser_RefreshDisplay()
    end
end)

-- Store references to pagination controls for updates
browserState.paginationControls = {
    pageLabel = pageLabel,
    prevButton = prevButton,
    nextButton = nextButton
}

-- ============================================================================
-- Data Loading and Filtering
-- ============================================================================

-- Get current zone
local function GetCurrentZone()
    return GetZoneText() or "Unknown"
end

-- Build creature data from VanityDB
local function BuildCreatureList()
    local creatures = {}
    
    -- Helper: Extract category from item name prefix
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
    
    -- Helper: Extract pet name from full item name
    local function GetPetName(fullName)
        -- Extract text after ": " (e.g., "Beastmaster's Whistle: Young Wolf" -> "Young Wolf")
        local petName = fullName:match(": (.+)$")
        return petName or fullName
    end
    
    -- Build creature index from VanityDB
    -- Group items by creature ID to get all drops per creature
    for itemId, data in pairs(AV_VanityItems) do
        local creatureId = data.creatureId or 0
        local creatureKey = "creature_" .. creatureId
        
        if not creatures[creatureKey] then
            -- Initialize creature entry
            creatures[creatureKey] = {
                creatureId = creatureId,
                name = GetPetName(data.name),  -- Use first pet as creature name
                category = GetCategoryFromName(data.name),
                zone = data.zone or "Unknown",
                subzone = data.subzone or "",
                items = {}
            }
        end
        
        -- Add item to this creature's drops
        table.insert(creatures[creatureKey].items, {
            id = itemId,
            name = GetPetName(data.name),
            icon = data.icon
        })
    end
    
    return creatures
end

-- Filter creatures based on current browser state
local function ApplyFilters()
    local allCreatures = BuildCreatureList()
    local filtered = {}
    
    for creatureName, creatureData in pairs(allCreatures) do
        local includeCreature = true
        
        -- Zone filter
        if browserState.zoneFilter ~= "all" then
            if creatureData.zone ~= browserState.zoneFilter then
                includeCreature = false
            end
        end
        
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

-- Clear displayed entries
local function ClearDisplayedEntries()
    for _, entry in ipairs(browserState.displayedEntries) do
        entry:Hide()
        entry:SetParent(nil)
    end
    wipe(browserState.displayedEntries)
end

-- Create a creature entry display
local function CreateCreatureEntry(parent, yOffset, creatureData)
    local entry = CreateFrame("Frame", nil, parent)
    entry:SetSize(parent:GetWidth() - 10, 60)
    entry:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, yOffset)
    
    -- Background
    entry.bg = entry:CreateTexture(nil, "BACKGROUND")
    entry.bg:SetAllPoints()
    entry.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    
    -- Creature name
    entry.nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    entry.nameText:SetPoint("TOPLEFT", entry, "TOPLEFT", 5, -5)
    entry.nameText:SetText("|cFFFFFFFF" .. (creatureData.name or "Unknown") .. "|r")
    
    -- Location
    local location = creatureData.zone or "Unknown Zone"
    if creatureData.subzone then
        location = location .. " (" .. creatureData.subzone .. ")"
    end
    entry.locationText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entry.locationText:SetPoint("TOPLEFT", entry.nameText, "BOTTOMLEFT", 0, -2)
    entry.locationText:SetText("|cFF808080" .. location .. "|r")
    
    -- Items
    local itemY = -30
    for i, item in ipairs(creatureData.items) do
        local itemText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        itemText:SetPoint("TOPLEFT", entry, "TOPLEFT", 15, itemY)
        
        local isLearned = AV_IsVanityItemLearned(item.id)
        local color = isLearned and "|cFF00FF00" or "|cFFFFFFFF"
        local status = isLearned and " ✓" or ""
        
        itemText:SetText(color .. item.name .. status .. "|r")
        itemY = itemY - 14
    end
    
    -- Adjust entry height based on number of items
    local calculatedHeight = 35 + (#creatureData.items * 14)
    entry:SetHeight(calculatedHeight)
    
    return entry, calculatedHeight
end

-- Refresh the display
local function RefreshDisplay()
    ClearDisplayedEntries()
    
    local filtered = ApplyFilters()
    
    -- Sort creatures alphabetically
    local sortedCreatures = {}
    for name, data in pairs(filtered) do
        table.insert(sortedCreatures, {name = name, data = data})
    end
    table.sort(sortedCreatures, function(a, b) return a.name < b.name end)
    
    -- Calculate pagination
    local totalCount = #sortedCreatures
    browserState.totalPages = math.max(1, math.ceil(totalCount / browserState.itemsPerPage))
    
    -- Clamp current page to valid range
    if browserState.currentPage > browserState.totalPages then
        browserState.currentPage = browserState.totalPages
    end
    if browserState.currentPage < 1 then
        browserState.currentPage = 1
    end
    
    -- Calculate page slice
    local startIdx = ((browserState.currentPage - 1) * browserState.itemsPerPage) + 1
    local endIdx = math.min(startIdx + browserState.itemsPerPage - 1, totalCount)
    
    -- Update results label with pagination info
    local filterDesc = "All Zones"
    if browserState.zoneFilter ~= "all" then
        filterDesc = browserState.zoneFilter
    end
    
    resultsLabel:SetText(string.format(
        "|cFFFFFFFFResults:|r %d creatures in %s (showing %d-%d)", 
        totalCount, filterDesc, startIdx, endIdx
    ))
    
    -- Update pagination controls (use stored references)
    if browserState.paginationControls then
        local controls = browserState.paginationControls
        controls.pageLabel:SetText(string.format("Page %d of %d", browserState.currentPage, browserState.totalPages))
        controls.prevButton:SetEnabled(browserState.currentPage > 1)
        controls.nextButton:SetEnabled(browserState.currentPage < browserState.totalPages)
    end
    
    -- Create entries for current page only
    local yOffset = 0
    for i = startIdx, endIdx do
        local creature = sortedCreatures[i]
        if creature then
            local entry, height = CreateCreatureEntry(scrollChild, yOffset, creature.data)
            table.insert(browserState.displayedEntries, entry)
            yOffset = yOffset - height - 5
        end
    end
    
    -- Update scroll child height
    scrollChild:SetHeight(math.abs(yOffset) + 10)
    
    -- Reset scroll position to top
    scrollFrame:SetVerticalScroll(0)
end

-- ============================================================================
-- Public API Functions
-- ============================================================================

-- Show browser with optional zone filter
function AV_DatabaseBrowser_Show(zoneFilter)
    browserState.zoneFilter = zoneFilter or "all"
    browserState.currentZone = GetCurrentZone()
    browserState.currentPage = 1  -- Reset to first page when opening
    
    -- Update title if showing specific zone
    if browserState.zoneFilter ~= "all" then
        titleBar:SetText("|cFF00FF96AscensionVanity|r Regional Guide - " .. browserState.zoneFilter)
    else
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

function AV_DatabaseBrowser_FilterToCurrentZone()
    browserState.zoneFilter = GetCurrentZone()
    titleBar:SetText("|cFF00FF96AscensionVanity|r Regional Guide - " .. browserState.zoneFilter)
    RefreshDisplay()
end

function AV_DatabaseBrowser_ShowAllZones()
    browserState.zoneFilter = "all"
    titleBar:SetText("|cFF00FF96AscensionVanity|r Database Browser")
    RefreshDisplay()
end

function AV_DatabaseBrowser_FilterByCategory(category)
    browserState.categoryFilter = category
    browserState.currentPage = 1  -- Reset to first page on filter change
    RefreshDisplay()
end

function AV_DatabaseBrowser_FilterByLearnedStatus(status)
    browserState.learnedFilter = status
    browserState.currentPage = 1  -- Reset to first page on filter change
    RefreshDisplay()
end

-- Global wrapper for pagination buttons
function AV_DatabaseBrowser_RefreshDisplay()
    RefreshDisplay()
end

-- ============================================================================
-- Initialization
-- ============================================================================

-- Restore position on load
local function RestorePosition()
    if AscensionVanityDB and AscensionVanityDB.browserPosition then
        local pos = AscensionVanityDB.browserPosition
        browserFrame:ClearAllPoints()
        browserFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    end
end

-- Zone change detection
local zoneFrame = CreateFrame("Frame")
zoneFrame:RegisterEvent("ZONE_CHANGED")
zoneFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
zoneFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneFrame:SetScript("OnEvent", function()
    if browserFrame:IsShown() and browserState.zoneFilter ~= "all" then
        -- Auto-update if showing current zone
        local newZone = GetCurrentZone()
        if browserState.zoneFilter == browserState.currentZone then
            browserState.zoneFilter = newZone
            browserState.currentZone = newZone
            titleBar:SetText("|cFF00FF96AscensionVanity|r Regional Guide - " .. newZone)
            RefreshDisplay()
        end
    end
end)

-- Initialize on PLAYER_LOGIN
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    RestorePosition()
end)
