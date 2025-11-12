-- AscensionVanity - Settings UI (Tabbed Design)
-- Modern tabbed interface for addon configuration

-- Use shared constants from AscensionVanityConstants.lua
local AddonName = AV_ADDON_NAME
local VERSION = AV_VERSION

-- ============================================================================
-- Settings Panel (Main Container)
-- ============================================================================

-- Create the main settings panel
local settingsPanel = CreateFrame("Frame", "AscensionVanitySettingsPanel", UIParent)
settingsPanel:SetSize(700, 600)  -- Compact, elegant size
settingsPanel:SetPoint("CENTER")
settingsPanel:SetFrameStrata("DIALOG")
settingsPanel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
settingsPanel:SetMovable(true)
settingsPanel:EnableMouse(true)
settingsPanel:RegisterForDrag("LeftButton")
settingsPanel:SetScript("OnDragStart", settingsPanel.StartMoving)
settingsPanel:SetScript("OnDragStop", settingsPanel.StopMovingOrSizing)
settingsPanel:Hide()

-- Make panel closable with ESC key
tinsert(UISpecialFrames, "AscensionVanitySettingsPanel")

-- Title
local title = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -20)
title:SetText("AscensionVanity Settings")

-- Close button
local closeButton = CreateFrame("Button", nil, settingsPanel, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)

-- Version info
local versionText = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
versionText:SetPoint("TOP", title, "BOTTOM", 0, -4)
versionText:SetText("Version " .. AV_GetFullVersion())

-- ============================================================================
-- Helper Functions
-- ============================================================================

local function CreateCheckbox(parent, label, tooltip, anchor, xOffset, yOffset)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", xOffset, yOffset)
    
    local checkboxLabel = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    checkboxLabel:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkboxLabel:SetText(label)
    checkbox.label = checkboxLabel
    
    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    checkbox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    return checkbox
end

local function CreateRadioButton(parent, label, value, tooltip, anchor, xOffset, yOffset)
    local radio = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
    radio:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", xOffset, yOffset)
    radio.value = value
    
    local radioLabel = radio:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    radioLabel:SetPoint("LEFT", radio, "RIGHT", 5, 0)
    radioLabel:SetText(label)
    radio.label = radioLabel
    
    radio:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    radio:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    return radio
end

-- ============================================================================
-- Tab System
-- ============================================================================

local tabs = {}
local tabButtons = {}
local activeTab = nil

-- Tab bar container (position inside the frame border)
local tabBar = CreateFrame("Frame", nil, settingsPanel)
tabBar:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 30, -70)  -- Inside frame, below title/version
tabBar:SetPoint("TOPRIGHT", settingsPanel, "TOPRIGHT", -30, -70)
tabBar:SetHeight(30)

-- Tab button style
local function StyleTabButton(button, isActive)
    if isActive then
        button:SetAlpha(1.0)
        button.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        button.text:SetTextColor(1, 0.82, 0)  -- Gold
    else
        button:SetAlpha(0.8)
        button.bg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
        button.text:SetTextColor(1, 1, 1)  -- White
    end
end

local function CreateTab(name, index)
    -- Create tab content frame
    local tab = CreateFrame("Frame", nil, settingsPanel)
    tab:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 25, -120)  -- Position relative to panel, below title/version/tabs
    tab:SetPoint("BOTTOMRIGHT", settingsPanel, "BOTTOMRIGHT", -25, 20)  -- Fill to panel bottom with margin
    tab:Hide()
    tabs[name] = tab
    
    -- Create tab button
    local button = CreateFrame("Button", nil, tabBar)
    button:SetSize(220, 28)
    if index == 1 then
        button:SetPoint("LEFT", tabBar, "LEFT", 10, 0)
    else
        button:SetPoint("LEFT", tabButtons[index - 1], "RIGHT", 5, 0)
    end
    
    -- Button background
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
    
    -- Button text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("CENTER")
    button.text:SetText(name)
    
    -- Hover effect
    button:SetScript("OnEnter", function(self)
        if tabs[name] ~= activeTab then
            self:SetAlpha(0.9)
        end
    end)
    button:SetScript("OnLeave", function(self)
        if tabs[name] ~= activeTab then
            self:SetAlpha(0.8)
        end
    end)
    
    -- Click handler
    button:SetScript("OnClick", function(self)
        for tabName, tabFrame in pairs(tabs) do
            tabFrame:Hide()
        end
        tab:Show()
        activeTab = tab
        
        for i, btn in ipairs(tabButtons) do
            StyleTabButton(btn, btn == self)
        end
    end)
    
    tabButtons[index] = button
    StyleTabButton(button, index == 1)
    
    return tab
end

-- Create tabs
local displayTab = CreateTab("Display", 1)
local filtersTab = CreateTab("Filters", 2)
local toolsTab = CreateTab("Tools", 3)

-- Show first tab by default
displayTab:Show()
activeTab = displayTab

-- ============================================================================
-- TAB 1: DISPLAY
-- ============================================================================

-- Create an anchor point at the top-center of the tab for centered layout
local displayAnchor = displayTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
displayAnchor:SetPoint("TOP", displayTab, "TOP", 0, -10)
displayAnchor:SetText("")  -- Invisible anchor

-- Master toggle (offset left from center for checkbox)
local enabledCheckbox = CreateCheckbox(
    displayTab,
    "Enable Tooltip Integration",
    "Master switch for the addon. When disabled, no vanity information will be shown in creature tooltips.",
    displayAnchor,
    -110,  -- Offset left from center
    -5
)

-- Section: Display Options
local displayHeader = displayTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
displayHeader:SetPoint("TOPLEFT", enabledCheckbox, "BOTTOMLEFT", 0, -20)
displayHeader:SetText(AV_COLOR_GOLD .. "Display Options" .. AV_COLOR_RESET)

local learnedCheckbox = CreateCheckbox(
    displayTab,
    "Show Learned Status",
    'Display checkmark/cross icons next to each vanity item to show learned status.\n\nRequires: Ascension C_VanityCollection API',
    displayHeader,
    0,
    -10
)

local colorCheckbox = CreateCheckbox(
    displayTab,
    "Color Code Items by Status",
    "Color vanity items based on learned status:\n- Green = Learned\n- Yellow = Not Learned\n\nRequires: Show Learned Status enabled",
    learnedCheckbox,
    0,
    -8
)

local questWarningsCheckbox = CreateCheckbox(
    displayTab,
    "Show Quest-Locked NPC Warnings",
    "Display warnings for vanity items that drop from quest-spawned NPCs.\n\n" .. AV_COLOR_ORANGE .. "[!] Important:" .. AV_COLOR_RESET .. " These NPCs become unavailable after completing the quest!",
    colorCheckbox,
    0,
    -8
)

-- Section: Creature Stats
local creatureStatsHeader = displayTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
creatureStatsHeader:SetPoint("TOPLEFT", questWarningsCheckbox, "BOTTOMLEFT", 0, -20)
creatureStatsHeader:SetText(AV_COLOR_GOLD .. "Creature Stats" .. AV_COLOR_RESET)

local showCreatureInfoCheckbox = CreateCheckbox(
    displayTab,
    "Show Creature Stats",
    "Display creature type/family and attack speed in tooltips.\n\nExample: " .. AV_COLOR_BLUE .. "Beast (Wolf) | 2.0s" .. AV_COLOR_RESET .. "\n\n" .. AV_COLOR_GRAY .. "Note: Health/level/classification already visible on tooltip." .. AV_COLOR_RESET,
    creatureStatsHeader,
    0,
    -10
)

-- Creature stats filter dropdown
local creatureInfoLabel = displayTab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
creatureInfoLabel:SetPoint("TOPLEFT", showCreatureInfoCheckbox, "BOTTOMLEFT", 25, -8)
creatureInfoLabel:SetText("Show Stats For:")

local creatureInfoDropdown = CreateFrame("Frame", "AV_CreatureInfoDropdown", displayTab, "UIDropDownMenuTemplate")
creatureInfoDropdown:SetPoint("TOPLEFT", creatureInfoLabel, "BOTTOMLEFT", -15, -5)

local creatureInfoOptions = {
    {value = "all", text = "All Creatures"},
    {value = "vanity", text = "Vanity Drop Creatures Only"},
    {value = "tameable", text = "Tameable Beasts Only"},
    {value = "vanity_and_tameable", text = "Vanity + Tameable"}
}

UIDropDownMenu_SetWidth(creatureInfoDropdown, 200)
UIDropDownMenu_Initialize(creatureInfoDropdown, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    for _, option in ipairs(creatureInfoOptions) do
        info.text = option.text
        info.value = option.value
        info.func = function()
            AscensionVanityDB.creatureInfoFilter = option.value
            UIDropDownMenu_SetSelectedValue(creatureInfoDropdown, option.value)
        end
        info.checked = (AscensionVanityDB.creatureInfoFilter == option.value)
        UIDropDownMenu_AddButton(info, level)
    end
end)

-- Note: Attack speed is the only useful stat for wild creatures
-- Health, damage, and armor are either already visible or return 0 for non-controlled units
-- Creature type/family are shown automatically in the stats line

-- Section: Kill Tracking
local trackingHeader = displayTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
trackingHeader:SetPoint("TOPLEFT", creatureInfoDropdown, "BOTTOMLEFT", 0, -50)
trackingHeader:SetText(AV_COLOR_GOLD .. "Kill Tracking" .. AV_COLOR_RESET)

local enableKillTrackingCheckbox = CreateCheckbox(
    displayTab,
    "Enable Kill Tracking",
    "Track your kills and loot drops for farming efficiency.",
    trackingHeader,
    0,
    -10
)

local showKillStatsCheckbox = CreateCheckbox(
    displayTab,
    "Show Kill Statistics",
    "Display kill tracking statistics in creature tooltips.",
    enableKillTrackingCheckbox,
    0,
    -8
)

-- ============================================================================
-- TAB 2: FILTERS
-- ============================================================================

-- Create an anchor point at the top-center of the tab
local filtersAnchor = filtersTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
filtersAnchor:SetPoint("TOP", filtersTab, "TOP", 0, -10)
filtersAnchor:SetText("")  -- Invisible anchor

-- Category Filters (centered header)
local categoryHeader = filtersTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
categoryHeader:SetPoint("TOP", filtersAnchor, "BOTTOM", 0, -5)
categoryHeader:SetText(AV_COLOR_GOLD .. "Category Filters" .. AV_COLOR_RESET)

local categoryDesc = filtersTab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
categoryDesc:SetPoint("TOP", categoryHeader, "BOTTOM", 0, -4)
categoryDesc:SetText(AV_COLOR_GRAY .. "Choose which vanity item types to display in tooltips" .. AV_COLOR_RESET)

local categoryCheckboxes = {}

-- Two-column layout
categoryCheckboxes.beast = CreateCheckbox(filtersTab, AV_GetCategoryLabel("beast", 16), "Show beast companions", categoryDesc, 30, -15)
categoryCheckboxes.demon = CreateCheckbox(filtersTab, AV_GetCategoryLabel("demon", 16), "Show demon summons", categoryCheckboxes.beast, 0, -8)
categoryCheckboxes.dragonkin = CreateCheckbox(filtersTab, AV_GetCategoryLabel("dragonkin", 16), "Show dragonkin companions", categoryCheckboxes.demon, 0, -8)

categoryCheckboxes.elemental = CreateCheckbox(filtersTab, AV_GetCategoryLabel("elemental", 16), "Show elemental companions", categoryDesc, 370, -15)
categoryCheckboxes.undead = CreateCheckbox(filtersTab, AV_GetCategoryLabel("undead", 16), "Show undead summons", categoryCheckboxes.elemental, 0, -8)

settingsPanel.categoryCheckboxes = categoryCheckboxes

-- Combat Behavior (increased spacing to avoid overlap)
local combatHeader = filtersTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
combatHeader:SetPoint("TOPLEFT", categoryCheckboxes.dragonkin, "BOTTOMLEFT", -30, -30)
combatHeader:SetText(AV_COLOR_GOLD .. "Combat Behavior" .. AV_COLOR_RESET)

local combatRadios = {}
combatRadios.normal = CreateRadioButton(filtersTab, "Show All", "normal", "Display full vanity item information during combat.", combatHeader, 0, -10)
combatRadios.minimal = CreateRadioButton(filtersTab, "Count Only", "minimal", "Show only the number of vanity items available.", combatRadios.normal, 0, -6)
combatRadios.hide = CreateRadioButton(filtersTab, "Hide (Default)", "hide", "Hide all vanity information during combat.", combatRadios.minimal, 0, -6)
settingsPanel.combatRadios = combatRadios

-- Collection Status (increased spacing to avoid overlap)
local collectionHeader = filtersTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
collectionHeader:SetPoint("TOPLEFT", categoryCheckboxes.undead, "BOTTOMLEFT", -370, -30)
collectionHeader:SetText(AV_COLOR_GOLD .. "Collection Status" .. AV_COLOR_RESET)

local collectionRadios = {}
collectionRadios.both = CreateRadioButton(filtersTab, "Show All", "both", "Display all vanity items regardless of learned status.", collectionHeader, 0, -10)
collectionRadios.unknown = CreateRadioButton(filtersTab, "Unknown Only", "unknown", "Show only vanity items you haven't learned yet.", collectionRadios.both, 0, -6)
collectionRadios.known = CreateRadioButton(filtersTab, "Known Only", "known", "Show only vanity items you've already learned.", collectionRadios.unknown, 0, -6)
settingsPanel.collectionRadios = collectionRadios

-- ============================================================================
-- TAB 3: TOOLS
-- ============================================================================

-- Create an anchor point at the top-center of the tab
local toolsAnchor = toolsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
toolsAnchor:SetPoint("TOP", toolsTab, "TOP", 0, -20)
toolsAnchor:SetText("")  -- Invisible anchor

local toolsDesc = toolsTab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
toolsDesc:SetPoint("TOP", toolsAnchor, "BOTTOM", 0, -10)
toolsDesc:SetWidth(600)
toolsDesc:SetJustifyH("CENTER")
toolsDesc:SetText("Access collection tools and utilities")

-- Buttons in vertical layout for cleaner look
local progressButton = CreateFrame("Button", nil, toolsTab, "UIPanelButtonTemplate")
progressButton:SetPoint("TOP", toolsDesc, "BOTTOM", 0, -30)
progressButton:SetSize(300, 35)
progressButton:SetText("Collection Progress")
progressButton:SetScript("OnClick", function()
    if AV_CollectionProgressFrame then
        AV_CollectionProgressFrame:SetShown(not AV_CollectionProgressFrame:IsShown())
    end
end)

local browserButton = CreateFrame("Button", nil, toolsTab, "UIPanelButtonTemplate")
browserButton:SetPoint("TOP", progressButton, "BOTTOM", 0, -15)
browserButton:SetSize(300, 35)
browserButton:SetText("Database Browser")
browserButton:SetScript("OnClick", function()
    settingsPanel:Hide()
    AscensionVanity_ShowDatabaseBrowser()
end)

local scannerButton = CreateFrame("Button", nil, toolsTab, "UIPanelButtonTemplate")
scannerButton:SetPoint("TOP", browserButton, "BOTTOM", 0, -15)
scannerButton:SetSize(300, 35)
scannerButton:SetText("Open API Scanner")
scannerButton:SetScript("OnClick", function()
    settingsPanel:Hide()
    AscensionVanity_ShowScanner()
end)

-- ============================================================================
-- Settings Management
-- ============================================================================

local function UpdateCheckboxes()
    enabledCheckbox:SetChecked(AscensionVanityDB.enabled)
    learnedCheckbox:SetChecked(AscensionVanityDB.showLearnedStatus)
    colorCheckbox:SetChecked(AscensionVanityDB.colorCode)
    questWarningsCheckbox:SetChecked(AscensionVanityDB.showQuestWarnings == nil and true or AscensionVanityDB.showQuestWarnings)
    enableKillTrackingCheckbox:SetChecked(AscensionVanityDB.enableKillTracking == nil and true or AscensionVanityDB.enableKillTracking)
    showKillStatsCheckbox:SetChecked(AscensionVanityDB.showKillStats == nil and true or AscensionVanityDB.showKillStats)
    showCreatureInfoCheckbox:SetChecked(AscensionVanityDB.showCreatureInfo == nil and true or AscensionVanityDB.showCreatureInfo)
    
    local currentFilter = AscensionVanityDB.creatureInfoFilter or "vanity"
    UIDropDownMenu_SetSelectedValue(creatureInfoDropdown, currentFilter)
    for _, option in ipairs(creatureInfoOptions) do
        if option.value == currentFilter then
            UIDropDownMenu_SetText(creatureInfoDropdown, option.text)
            break
        end
    end
    
    for category, checkbox in pairs(settingsPanel.categoryCheckboxes) do
        if AscensionVanityDB.categoryFilters and AscensionVanityDB.categoryFilters[category] ~= nil then
            checkbox:SetChecked(AscensionVanityDB.categoryFilters[category])
        else
            checkbox:SetChecked(true)
        end
    end
    
    for _, radio in pairs(settingsPanel.combatRadios) do
        radio:SetChecked(AscensionVanityDB.combatBehavior == radio.value)
    end
    
    for _, radio in pairs(settingsPanel.collectionRadios) do
        radio:SetChecked(AscensionVanityDB.collectionStatusFilter == radio.value)
    end
    
    if not AscensionVanityDB.showLearnedStatus then
        colorCheckbox:Disable()
        colorCheckbox.label:SetFontObject("GameFontDisable")
    else
        colorCheckbox:Enable()
        colorCheckbox.label:SetFontObject("GameFontHighlight")
    end
end

local function SaveSettings()
    AscensionVanityDB.enabled = enabledCheckbox:GetChecked() and true or false
    AscensionVanityDB.colorCode = colorCheckbox:GetChecked() and true or false
    AscensionVanityDB.showLearnedStatus = learnedCheckbox:GetChecked() and true or false
    AscensionVanityDB.showQuestWarnings = questWarningsCheckbox:GetChecked() and true or false
    AscensionVanityDB.enableKillTracking = enableKillTrackingCheckbox:GetChecked() and true or false
    AscensionVanityDB.showKillStats = showKillStatsCheckbox:GetChecked() and true or false
    AscensionVanityDB.showCreatureInfo = showCreatureInfoCheckbox:GetChecked() and true or false
    
    if not AscensionVanityDB.categoryFilters then
        AscensionVanityDB.categoryFilters = {}
    end
    for category, checkbox in pairs(settingsPanel.categoryCheckboxes) do
        AscensionVanityDB.categoryFilters[category] = checkbox:GetChecked() and true or false
    end
end

-- Auto-save handlers
enabledCheckbox:SetScript("OnClick", function(self) SaveSettings() UpdateCheckboxes() end)
colorCheckbox:HookScript("OnClick", SaveSettings)
learnedCheckbox:SetScript("OnClick", function(self) SaveSettings() UpdateCheckboxes() end)
questWarningsCheckbox:HookScript("OnClick", SaveSettings)
enableKillTrackingCheckbox:HookScript("OnClick", SaveSettings)
showKillStatsCheckbox:HookScript("OnClick", SaveSettings)
showCreatureInfoCheckbox:HookScript("OnClick", SaveSettings)

for category, checkbox in pairs(settingsPanel.categoryCheckboxes) do
    checkbox:HookScript("OnClick", SaveSettings)
end

for _, radio in pairs(settingsPanel.combatRadios) do
    radio:SetScript("OnClick", function(self)
        AscensionVanityDB.combatBehavior = self.value
        for _, r in pairs(settingsPanel.combatRadios) do
            r:SetChecked(r == self)
        end
    end)
end

for _, radio in pairs(settingsPanel.collectionRadios) do
    radio:SetScript("OnClick", function(self)
        AscensionVanityDB.collectionStatusFilter = self.value
        for _, r in pairs(settingsPanel.collectionRadios) do
            r:SetChecked(r == self)
        end
    end)
end

settingsPanel:SetScript("OnShow", function()
    UpdateCheckboxes()
end)

-- ============================================================================
-- Global Functions
-- ============================================================================

function AscensionVanity_ShowSettings()
    settingsPanel:Show()
end

function AscensionVanity_SyncSettingsUI()
    if settingsPanel:IsShown() then
        UpdateCheckboxes()
    end
end

-- ============================================================================
-- Interface Options Integration
-- ============================================================================

local optionsPanel = CreateFrame("Frame", "AscensionVanityOptionsPanel", UIParent)
optionsPanel.name = "AscensionVanity"

local optionsTitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
optionsTitle:SetPoint("TOPLEFT", 16, -16)
optionsTitle:SetText("AscensionVanity")

local optionsDesc = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
optionsDesc:SetPoint("TOPLEFT", optionsTitle, "BOTTOMLEFT", 0, -8)
optionsDesc:SetWidth(580)
optionsDesc:SetJustifyH("LEFT")
optionsDesc:SetText("Track vanity item drops in creature tooltips with learned status indicators.")

local optionsSettingsButton = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
optionsSettingsButton:SetPoint("TOPLEFT", optionsDesc, "BOTTOMLEFT", 0, -16)
optionsSettingsButton:SetSize(200, 30)
optionsSettingsButton:SetText("Open Settings")
optionsSettingsButton:SetScript("OnClick", function()
    InterfaceOptionsFrame:Hide()
    settingsPanel:Show()
end)

InterfaceOptions_AddCategory(optionsPanel)
