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
filterSection:SetPoint("TOPLEFT", browserFrame, "TOPLEFT", 15, -30)
filterSection:SetPoint("TOPRIGHT", browserFrame, "TOPRIGHT", -15, -30)
filterSection:SetHeight(120)

-- Zone Filter Label
local zoneLabel = filterSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
zoneLabel:SetPoint("TOPLEFT", filterSection, "TOPLEFT", 0, 0)
zoneLabel:SetText("|cFFFFFFFFZone Filter:|r")

-- Comprehensive Zone/Subzone Dropdown with search
local zoneDropdown = CreateFrame("Frame", "AV_ZoneDropdown", filterSection, "UIDropDownMenuTemplate")
zoneDropdown:SetPoint("TOPLEFT", zoneLabel, "BOTTOMLEFT", -15, -5)
UIDropDownMenu_SetWidth(zoneDropdown, 200)

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
    zoneFilter = "all",
    categoryFilter = "all",
    learnedFilter = "all",
    multipleItemsFilter = false,
    subzoneFilter = nil,
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

-- Build hierarchical zone/subzone list from database
local function BuildZoneHierarchy()
    local zones = {}
    local zoneSet = {}
    
    -- Collect all zones and their subzones from the database
    for _, data in pairs(AV_VanityItems) do
        local zone = data.zone or "Unknown"
        local subzone = data.subzone or ""
        
        if not zoneSet[zone] then
            zoneSet[zone] = {subzones = {}}
            table.insert(zones, zone)
        end
        
        if subzone ~= "" and not zoneSet[zone].subzones[subzone] then
            zoneSet[zone].subzones[subzone] = true
        end
    end
    
    -- Sort zones alphabetically
    table.sort(zones)
    
    -- Convert subzones to sorted arrays
    for _, zone in ipairs(zones) do
        local subzoneList = {}
        for subzone in pairs(zoneSet[zone].subzones) do
            table.insert(subzoneList, subzone)
        end
        table.sort(subzoneList)
        zoneSet[zone].subzones = subzoneList
    end
    
    return zones, zoneSet
end

-- Initialize zone dropdown
local function InitializeZoneDropdown()
    local zones, zoneData = BuildZoneHierarchy()
    
    UIDropDownMenu_SetText(zoneDropdown, browserState.subzoneFilter or browserState.zoneFilter == "all" and "All Zones" or browserState.zoneFilter)
    
    UIDropDownMenu_Initialize(zoneDropdown, function(self, level, menuList)
        if level == 1 then
            -- "All Zones" option
            local info = UIDropDownMenu_CreateInfo()
            info.text = "All Zones"
            info.value = "all"
            info.checked = (browserState.zoneFilter == "all")
            info.func = function()
                browserState.zoneFilter = "all"
                browserState.subzoneFilter = nil
                browserState.currentPage = 1
                UIDropDownMenu_SetText(zoneDropdown, "All Zones")
                titleBar:SetText("|cFF00FF96AscensionVanity|r Database Browser")
                RefreshDisplay()
            end
            UIDropDownMenu_AddButton(info, level)
            
            -- "Current Zone" option
            local currentZone = GetCurrentZone()
            local info2 = UIDropDownMenu_CreateInfo()
            info2.text = "|cFF00FF96Current Zone:|r " .. currentZone
            info2.value = currentZone
            info2.checked = (browserState.zoneFilter == currentZone and not browserState.subzoneFilter)
            info2.func = function()
                browserState.zoneFilter = currentZone
                browserState.subzoneFilter = nil
                browserState.currentPage = 1
                UIDropDownMenu_SetText(zoneDropdown, currentZone)
                titleBar:SetText("|cFF00FF96AscensionVanity|r Regional Guide - " .. currentZone)
                RefreshDisplay()
            end
            UIDropDownMenu_AddButton(info2, level)
            
            -- Separator
            UIDropDownMenu_AddSeparator(level)
            
            -- All zones with subzones
            for _, zone in ipairs(zones) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = zone
                info.value = zone
                info.checked = (browserState.zoneFilter == zone and not browserState.subzoneFilter)
                info.hasArrow = (#zoneData[zone].subzones > 0)  -- Show arrow if has subzones
                info.menuList = zone  -- For submenu
                info.func = function()
                    if not info.hasArrow then
                        -- Zone has no subzones, select it directly
                        browserState.zoneFilter = zone
                        browserState.subzoneFilter = nil
                        browserState.currentPage = 1
                        UIDropDownMenu_SetText(zoneDropdown, zone)
                        titleBar:SetText("|cFF00FF96AscensionVanity|r Regional Guide - " .. zone)
                        RefreshDisplay()
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end
            
        elseif level == 2 then
            -- Subzone submenu
            local zoneName = menuList
            local info = UIDropDownMenu_CreateInfo()
            info.text = zoneName .. " (All)"
            info.value = zoneName
            info.checked = (browserState.zoneFilter == zoneName and not browserState.subzoneFilter)
            info.func = function()
                browserState.zoneFilter = zoneName
                browserState.subzoneFilter = nil
                browserState.currentPage = 1
                UIDropDownMenu_SetText(zoneDropdown, zoneName)
                titleBar:SetText("|cFF00FF96AscensionVanity|r Regional Guide - " .. zoneName)
                RefreshDisplay()
            end
            UIDropDownMenu_AddButton(info, level)
            
            -- Add separator
            UIDropDownMenu_AddSeparator(level)
            
            -- Subzones
            for _, subzone in ipairs(zoneData[zoneName].subzones) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = "  " .. subzone
                info.value = zoneName .. ":" .. subzone
                info.checked = (browserState.zoneFilter == zoneName and browserState.subzoneFilter == subzone)
                info.func = function()
                    browserState.zoneFilter = zoneName
                    browserState.subzoneFilter = subzone
                    browserState.currentPage = 1
                    UIDropDownMenu_SetText(zoneDropdown, subzone)
                    titleBar:SetText("|cFF00FF96AscensionVanity|r Regional Guide - " .. zoneName .. " (" .. subzone .. ")")
                    RefreshDisplay()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)
end

local function BuildCreatureList()
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
    
    for itemId, data in pairs(AV_VanityItems) do
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
            icon = data.icon
        })
    end
    
    return creatures
end

local function ApplyFilters()
    local allCreatures = BuildCreatureList()
    local filtered = {}
    
    for creatureName, creatureData in pairs(allCreatures) do
        local includeCreature = true
        
        if browserState.zoneFilter ~= "all" then
            if creatureData.zone ~= browserState.zoneFilter then
                includeCreature = false
            end
        end
        
        if includeCreature and browserState.subzoneFilter and browserState.subzoneFilter ~= "" then
            if (creatureData.subzone or "") ~= browserState.subzoneFilter then
                includeCreature = false
            end
        end
        
        if includeCreature and browserState.categoryFilter ~= "all" then
            if creatureData.category ~= browserState.categoryFilter then
                includeCreature = false
            end
        end
        
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
        table.insert(sortedCreatures, {name = (data.name or name), data = data})
    end
    table.sort(sortedCreatures, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
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
    
    local filterDesc = "All Zones"
    if browserState.zoneFilter ~= "all" then
        filterDesc = browserState.zoneFilter
    end
    
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
    
    -- Grid layout: 3 columns x 6 rows = 18 items per page
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
    browserState.zoneFilter = zoneFilter or "all"
    browserState.currentZone = GetCurrentZone()
    browserState.currentPage = 1
    browserState.subzoneFilter = nil
    
    -- Initialize dropdown
    InitializeZoneDropdown()
    
    -- Set title
    if browserState.zoneFilter == "all" then
        titleBar:SetText("|cFF00FF96AscensionVanity|r Database Browser")
    else
        titleBar:SetText("|cFF00FF96AscensionVanity|r Regional Guide - " .. browserState.zoneFilter)
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
    if browserFrame:IsShown() and browserState.zoneFilter ~= "all" then
        local newZone = GetCurrentZone()
        if browserState.zoneFilter == browserState.currentZone then
            browserState.zoneFilter = newZone
            browserState.currentZone = newZone
            titleBar:SetText("|cFF00FF96AscensionVanity|r Regional Guide - " .. newZone)
            RefreshDisplay()
        end
    end
end)

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    RestorePosition()
end)
