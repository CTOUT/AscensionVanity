-- Global function to sync settings UI with frame visibility
function AscensionVanity_SyncSettingsUI()
    if progressFrameCheckbox and AscensionVanityDB and AscensionVanityDB.showProgressFrame ~= nil then
        progressFrameCheckbox:SetChecked(AscensionVanityDB.showProgressFrame)
    end
end
-- AscensionVanity - Settings UI
-- User interface for addon configuration

local AddonName = "AscensionVanity"

-- Use shared constants from AscensionVanityConstants.lua
local VERSION = AV_VERSION

-- ============================================================================
-- Settings Panel
-- ============================================================================

-- Create the main settings panel
local settingsPanel = CreateFrame("Frame", "AscensionVanitySettingsPanel", UIParent)
settingsPanel:SetSize(750, 700)  -- Landscape format with two-column layout, extended for API scanner button
settingsPanel:SetPoint("CENTER")
settingsPanel:SetFrameStrata("DIALOG")  -- Higher strata to prevent overlap
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
versionText:SetText("Version " .. VERSION)

-- Description
local desc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
desc:SetPoint("TOP", versionText, "BOTTOM", 0, -12)
desc:SetWidth(700)
desc:SetJustifyH("LEFT")
desc:SetText("Configure how vanity item information is displayed in creature tooltips.")

-- ============================================================================
-- Checkbox Helper
-- ============================================================================

local function CreateCheckbox(parent, label, tooltip, anchor, xOffset, yOffset)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", xOffset, yOffset)
    
    local checkboxLabel = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    checkboxLabel:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkboxLabel:SetText(label)
    
    -- Store label reference for later manipulation
    checkbox.label = checkboxLabel
    
    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(label, 1, 1, 1)
        GameTooltip:AddLine(tooltip, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    checkbox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    return checkbox
end

-- ============================================================================
-- Settings Checkboxes
-- ============================================================================

-- Master Enable checkbox (top-left corner)
local enabledCheckbox = CreateCheckbox(
    settingsPanel,
    "Enable Tooltip Integration",
    "Master switch for the addon. When disabled, no vanity information will be shown in creature tooltips.",
    desc,
    0,
    -20
)

-- Options box container
local optionsBox = settingsPanel:CreateTexture(nil, "BACKGROUND")
optionsBox:SetPoint("TOPLEFT", enabledCheckbox, "BOTTOMLEFT", -10, -12)
optionsBox:SetPoint("RIGHT", -30, 0)
optionsBox:SetHeight(80)
optionsBox:SetColorTexture(0.1, 0.1, 0.1, 0.5)

-- Options header
local optionsHeader = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
optionsHeader:SetPoint("TOPLEFT", optionsBox, "TOPLEFT", 10, -8)
optionsHeader:SetText(AV_COLOR_GRAY .. "Display Options" .. AV_COLOR_RESET)

-- Display options in horizontal layout (left to right)
local learnedCheckbox = CreateCheckbox(
    settingsPanel,
    "Show Learned Status",
    'Display checkmark/cross icons next to each vanity item to show learned status.\n\nRequires: Ascension C_VanityCollection API',
    optionsHeader,
    0,
    -10
)

local colorCheckbox = CreateCheckbox(
    settingsPanel,
    "Color Code Items by Status",
    "Color vanity items based on learned status:\n- Green = Learned\n- Yellow = Not Learned\n\nRequires: Show Learned Status enabled",
    optionsHeader,
    240,
    -10
)

local regionsCheckbox = CreateCheckbox(
    settingsPanel,
    "Show Region Information",
    "Display zone/region location information for vanity item drops in tooltips.",
    optionsHeader,
    480,
    -10
)

local questWarningsCheckbox = CreateCheckbox(
    settingsPanel,
    "Show Quest-Locked NPC Warnings",
    "Display warnings for vanity items that drop from quest-spawned NPCs.\n\n" .. AV_COLOR_ORANGE .. "[!] Important:" .. AV_COLOR_RESET .. " These NPCs become unavailable after completing the quest!\n\nWarnings show:\n- Quest name and ID\n- Faction requirement\n- Quest completion status\n- Summon/unlock methods",
    learnedCheckbox,
    0,
    -10
)

local showIDsCheckbox = CreateCheckbox(
    settingsPanel,
    "Show Item/Creature IDs",
    "Display internal game IDs in tooltips.\n\n" .. AV_COLOR_YELLOW .. "[Dev Tool]" .. AV_COLOR_RESET .. "\n- Shows Item ID for vanity items\n- Shows Creature ID for NPCs\n- Useful for debugging and research\n\n" .. AV_COLOR_GRAY .. "Example:" .. AV_COLOR_RESET .. " " .. AV_COLOR_BRIGHT_ORANGE .. "[Item: 82875]" .. AV_COLOR_RESET .. " Beastmaster's Whistle: Pet Name\n" .. AV_COLOR_GRAY .. "          Creature ID:" .. AV_COLOR_RESET .. " " .. AV_COLOR_WHITE .. "12345" .. AV_COLOR_RESET,
    questWarningsCheckbox,
    0,
    -10
)

local progressFrameCheckbox = CreateCheckbox(
    settingsPanel,
    "Show Collection Progress Frame",
    "Display a moveable frame showing your collection progress.\n\n" .. AV_COLOR_GREEN .. "Features:" .. AV_COLOR_RESET .. "\n- Real-time progress tracking\n- Per-category breakdown\n- Color-coded completion\n- Draggable and resizable\n\n" .. AV_COLOR_YELLOW .. "Tip:" .. AV_COLOR_RESET .. " Use " .. AV_COLOR_WHITE .. "/avanity progress" .. AV_COLOR_RESET .. " to toggle",
    showIDsCheckbox,
    0,
    -10
)

-- Separator before category filters
local separatorCategories = settingsPanel:CreateTexture(nil, "ARTWORK")
separatorCategories:SetHeight(1)
separatorCategories:SetPoint("TOP", progressFrameCheckbox, "BOTTOM", 0, -16)
separatorCategories:SetPoint("LEFT", 30, 0)
separatorCategories:SetPoint("RIGHT", -30, 0)
separatorCategories:SetColorTexture(0.25, 0.25, 0.25, 1)

-- Category Filters Section Header
local categoryHeader = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
categoryHeader:SetPoint("TOP", separatorCategories, "BOTTOM", 0, -12)
categoryHeader:SetText("Category Filters")

local categoryDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
categoryDesc:SetPoint("TOP", categoryHeader, "BOTTOM", 0, -4)
categoryDesc:SetWidth(700)
categoryDesc:SetJustifyH("CENTER")
categoryDesc:SetText(AV_COLOR_GRAY .. "Choose which vanity item types to display in tooltips" .. AV_COLOR_RESET)

-- Category Filter Checkboxes (Two-column layout, alphabetically sorted)
-- IMPORTANT: Keys must match AscensionVanityConfig.lua categoryFilters
-- Icons sourced from shared AscensionVanityConstants.lua (DRY principle)
local categoryCheckboxes = {}

-- Left column (alphabetical: Beast, Demon, Dragonkin)
categoryCheckboxes.beast = CreateCheckbox(
    settingsPanel,
    AV_GetCategoryLabel("beast", 16),
    "Show beast companions (wolves, cats, bears, etc.) that can be summoned.",
    categoryDesc,
    30,
    -12
)

categoryCheckboxes.demon = CreateCheckbox(
    settingsPanel,
    AV_GetCategoryLabel("demon", 16),
    "Show demon summons (imps, felguards, succubi, etc.).",
    categoryCheckboxes.beast,
    0,
    -8
)

categoryCheckboxes.dragonkin = CreateCheckbox(
    settingsPanel,
    AV_GetCategoryLabel("dragonkin", 16),
    "Show dragonkin companions (whelps, drakes, dragons, etc.).",
    categoryCheckboxes.demon,
    0,
    -8
)

-- Right column (alphabetical: Elemental, Undead)
categoryCheckboxes.elemental = CreateCheckbox(
    settingsPanel,
    AV_GetCategoryLabel("elemental", 16),
    "Show elemental companions (fire, water, earth, air elementals, etc.).",
    categoryDesc,
    390,  -- Positioned to the right
    -12
)

categoryCheckboxes.undead = CreateCheckbox(
    settingsPanel,
    AV_GetCategoryLabel("undead", 16),
    "Show undead creature summons (ghouls, skeletons, spirits, etc.).",
    categoryCheckboxes.elemental,
    0,
    -8
)

-- Store reference for later use
settingsPanel.categoryCheckboxes = categoryCheckboxes

-- Separator before combat/collection filters (positioned below the tallest column)
local separatorCombat = settingsPanel:CreateTexture(nil, "ARTWORK")
separatorCombat:SetHeight(1)
-- Position below left column (dragonkin is last in left column with 3 items)
separatorCombat:SetPoint("TOP", categoryCheckboxes.dragonkin, "BOTTOM", 0, -16)
separatorCombat:SetPoint("LEFT", 30, 0)
separatorCombat:SetPoint("RIGHT", -30, 0)
separatorCombat:SetColorTexture(0.25, 0.25, 0.25, 1)

-- ============================================================================
-- Two-Column Layout: Combat Behavior (Left) | Collection Status (Right)
-- ============================================================================

-- Combat Behavior Section Header (LEFT COLUMN)
local combatHeader = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
combatHeader:SetPoint("TOPLEFT", separatorCombat, "BOTTOMLEFT", 30, -12)
combatHeader:SetText("Combat Behavior")

local combatDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
combatDesc:SetPoint("TOPLEFT", combatHeader, "BOTTOMLEFT", 0, -4)
combatDesc:SetWidth(300)
combatDesc:SetJustifyH("LEFT")
combatDesc:SetText(AV_COLOR_GRAY .. "Control tooltips during combat" .. AV_COLOR_RESET)

-- Radio button helper functions
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
        GameTooltip:SetText(label, 1, 1, 1)
        GameTooltip:AddLine(tooltip, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    radio:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    return radio
end

-- Right-aligned radio button helper
local function CreateRadioButtonRight(parent, label, value, tooltip, anchor, xOffset, yOffset)
    local radio = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
    radio:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", xOffset, yOffset)
    radio.value = value
    
    local radioLabel = radio:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    radioLabel:SetPoint("RIGHT", radio, "LEFT", -5, 0)
    radioLabel:SetText(label)
    radio.label = radioLabel
    
    radio:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(label, 1, 1, 1)
        GameTooltip:AddLine(tooltip, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    radio:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    return radio
end

-- Combat Behavior Radio Buttons
local combatRadios = {}

combatRadios.normal = CreateRadioButton(
    settingsPanel,
    "Show All",
    "normal",
    "Display full vanity item information during combat.\n\nUse this if you want to see all details while fighting.",
    combatDesc,
    0,
    -12
)

combatRadios.minimal = CreateRadioButton(
    settingsPanel,
    "Count Only",
    "minimal",
    "Show only the number of vanity items available.\n\nExample: 'Vanity Items: 3 available'\n\nGood balance between information and clutter.",
    combatRadios.normal,
    0,
    -6
)

combatRadios.hide = CreateRadioButton(
    settingsPanel,
    "Hide (Default)",
    "hide",
    "Hide all vanity information during combat.\n\nKeeps tooltips clean when fighting.\n\n" .. AV_COLOR_GREEN .. "Recommended for most players." .. AV_COLOR_RESET,
    combatRadios.minimal,
    0,
    -6
)

-- Store reference
settingsPanel.combatRadios = combatRadios

-- Note: Radio button OnClick handlers set later (after SaveSettings is defined)

-- Collection Status Section Header (RIGHT COLUMN)
local collectionHeader = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
collectionHeader:SetPoint("TOPRIGHT", separatorCombat, "BOTTOMRIGHT", -30, -12)
collectionHeader:SetText("Collection Status Filter")

local collectionDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
collectionDesc:SetPoint("TOPRIGHT", collectionHeader, "BOTTOMRIGHT", 0, -4)
collectionDesc:SetWidth(300)
collectionDesc:SetJustifyH("RIGHT")
collectionDesc:SetText(AV_COLOR_GRAY .. "Filter by learned status" .. AV_COLOR_RESET)

-- Collection Status Radio Buttons (RIGHT COLUMN)
local collectionRadios = {}

collectionRadios.both = CreateRadioButtonRight(
    settingsPanel,
    "Show All",
    "both",
    "Display all vanity items regardless of learned status.\n\nIdeal for: Complete reference and discovery",
    collectionDesc,
    0,
    -12
)

collectionRadios.unknown = CreateRadioButtonRight(
    settingsPanel,
    "Unknown Only",
    "unknown",
    "Display only vanity items you haven't learned yet.\n\nIdeal for: Focused collecting and farming",
    collectionRadios.both,
    0,
    -6
)

collectionRadios.known = CreateRadioButtonRight(
    settingsPanel,
    "Known Only",
    "known",
    "Display only vanity items you've already learned.\n\nIdeal for: Reviewing your collection and discoveries",
    collectionRadios.unknown,
    0,
    -6
)

-- Store reference
settingsPanel.collectionRadios = collectionRadios

-- ============================================================================
-- Checkbox Dependencies
-- ============================================================================

-- Add onChange handler for learned status to update color checkbox state
-- (Must be after colorCheckbox is created)
learnedCheckbox:SetScript("OnClick", function(self)
    if self:GetChecked() then
        colorCheckbox:Enable()
        colorCheckbox.label:SetFontObject("GameFontHighlight")  -- Normal text
    else
        colorCheckbox:Disable()
        colorCheckbox.label:SetFontObject("GameFontDisable")   -- Greyed out text
        -- Keep checkbox state to remember user preference
    end
end)

-- Separator before utility buttons (position below tallest column)
-- Both columns have 3 items, so use either as anchor
local separator2 = settingsPanel:CreateTexture(nil, "ARTWORK")
separator2:SetHeight(1)
separator2:SetPoint("TOP", combatRadios.hide, "BOTTOM", 0, -16)
separator2:SetPoint("LEFT", 30, 0)
separator2:SetPoint("RIGHT", -30, 0)
separator2:SetColorTexture(0.25, 0.25, 0.25, 1)

-- ============================================================================
-- Utility Buttons
-- ============================================================================

-- Collection Progress button
local progressButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
progressButton:SetPoint("TOP", separator2, "BOTTOM", 0, -16)
progressButton:SetSize(200, 30)
progressButton:SetText("Collection Progress")
progressButton:SetScript("OnClick", function()
    if AV_ShowCollectionProgress then
        AV_ShowCollectionProgress()
    end
end)

-- Progress button description
local progressDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
progressDesc:SetPoint("TOP", progressButton, "BOTTOM", 0, -4)
progressDesc:SetText(AV_COLOR_GRAY .. "Track your collection progress" .. AV_COLOR_RESET)

-- Database Browser button
local browserButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
browserButton:SetPoint("TOP", progressDesc, "BOTTOM", 0, -12)
browserButton:SetSize(200, 30)
browserButton:SetText("Database Browser")
browserButton:SetScript("OnClick", function()
    if AV_DatabaseBrowser_Toggle then
        AV_DatabaseBrowser_Toggle()
    end
end)

-- Browser button description
local browserDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
browserDesc:SetPoint("TOP", browserButton, "BOTTOM", 0, -4)
browserDesc:SetText(AV_COLOR_GRAY .. "Explore database & regional hunting guide" .. AV_COLOR_RESET)

-- Open Scanner button
local scannerButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
scannerButton:SetPoint("TOP", browserDesc, "BOTTOM", 0, -12)
scannerButton:SetSize(200, 30)
scannerButton:SetText("Open API Scanner")
scannerButton:SetScript("OnClick", function()
    settingsPanel:Hide()  -- Close settings when opening scanner
    AscensionVanity_ShowScanner()
end)

-- Scanner button description
local scannerDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
scannerDesc:SetPoint("TOP", scannerButton, "BOTTOM", 0, -4)
scannerDesc:SetText(AV_COLOR_GRAY .. "Developer tool for scanning vanity items" .. AV_COLOR_RESET)

-- Separator before footer
local separator3 = settingsPanel:CreateTexture(nil, "ARTWORK")
separator3:SetHeight(1)
separator3:SetPoint("TOP", scannerDesc, "BOTTOM", 0, -12)
separator3:SetPoint("LEFT", 30, 0)
separator3:SetPoint("RIGHT", -30, 0)
separator3:SetColorTexture(0.25, 0.25, 0.25, 1)

-- Auto-save notice
local autoSaveText = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
autoSaveText:SetPoint("TOP", separator3, "BOTTOM", 0, -8)
autoSaveText:SetText(AV_COLOR_GRAY .. "Settings are saved automatically" .. AV_COLOR_RESET)

-- ============================================================================
-- Settings Management
-- ============================================================================

-- Update checkboxes to reflect current settings and dependencies
local function UpdateCheckboxes()
    enabledCheckbox:SetChecked(AscensionVanityDB.enabled)
    learnedCheckbox:SetChecked(AscensionVanityDB.showLearnedStatus)
    colorCheckbox:SetChecked(AscensionVanityDB.colorCode)
    regionsCheckbox:SetChecked(AscensionVanityDB.showRegions)
    questWarningsCheckbox:SetChecked(AscensionVanityDB.showQuestWarnings == nil and true or AscensionVanityDB.showQuestWarnings)
    showIDsCheckbox:SetChecked(AscensionVanityDB.showIDs == nil and false or AscensionVanityDB.showIDs)
    progressFrameCheckbox:SetChecked(AscensionVanityDB.showProgressFrame == nil and false or AscensionVanityDB.showProgressFrame)
    
    -- Update category filter checkboxes (v2.1+)
    if AscensionVanityDB.categoryFilters then
        for category, checkbox in pairs(settingsPanel.categoryCheckboxes) do
            if AscensionVanityDB.categoryFilters[category] ~= nil then
                checkbox:SetChecked(AscensionVanityDB.categoryFilters[category])
            else
                checkbox:SetChecked(true)  -- Default to enabled
            end
        end
    end
    
    -- Update combat behavior radio buttons (v2.1+)
    local combatBehavior = AscensionVanityDB.combatBehavior or "hide"
    for _, radio in pairs(settingsPanel.combatRadios) do
        radio:SetChecked(radio.value == combatBehavior)
    end
    
    -- Update collection status filter radio buttons (v2.1+)
    local collectionFilter = AscensionVanityDB.collectionFilter or "both"
    for _, radio in pairs(settingsPanel.collectionRadios) do
        radio:SetChecked(radio.value == collectionFilter)
    end
    
    -- Master dependency: All settings require addon enabled
    if AscensionVanityDB.enabled then
        -- Addon enabled - apply normal dependency rules
        
        -- Handle dependencies: Color coding requires learned status
        if AscensionVanityDB.showLearnedStatus then
            learnedCheckbox:Enable()
            learnedCheckbox.label:SetFontObject("GameFontHighlight")
            colorCheckbox:Enable()
            colorCheckbox.label:SetFontObject("GameFontHighlight")
        else
            learnedCheckbox:Enable()
            learnedCheckbox.label:SetFontObject("GameFontHighlight")
            colorCheckbox:Disable()
            colorCheckbox.label:SetFontObject("GameFontDisable")
        end
    else
        -- Addon disabled - disable all sub-settings
        learnedCheckbox:Disable()
        learnedCheckbox.label:SetFontObject("GameFontDisable")
        colorCheckbox:Disable()
        colorCheckbox.label:SetFontObject("GameFontDisable")
    end
    
    -- Disable regions checkbox (feature not yet implemented)
    regionsCheckbox:Disable()
    regionsCheckbox:SetChecked(false)
    regionsCheckbox.label:SetFontObject("GameFontDisable")
    AscensionVanityDB.showRegions = false
end

-- Auto-save settings on change (no confirmation needed)
local function SaveSettings()
    -- Convert WoW checkbox values (1/nil) to proper booleans (true/false)
    AscensionVanityDB.enabled = enabledCheckbox:GetChecked() and true or false
    AscensionVanityDB.colorCode = colorCheckbox:GetChecked() and true or false
    AscensionVanityDB.showLearnedStatus = learnedCheckbox:GetChecked() and true or false
    AscensionVanityDB.showRegions = regionsCheckbox:GetChecked() and true or false
    AscensionVanityDB.showQuestWarnings = questWarningsCheckbox:GetChecked() and true or false
    AscensionVanityDB.showIDs = showIDsCheckbox:GetChecked() and true or false
    
    -- Save progress frame visibility (v2.2)
    local wasVisible = AscensionVanityDB.showProgressFrame
    AscensionVanityDB.showProgressFrame = progressFrameCheckbox:GetChecked() and true or false
    
    -- Toggle frame visibility if changed
    if wasVisible ~= AscensionVanityDB.showProgressFrame then
        if AscensionVanityDB.showProgressFrame then
            if AV_ShowCollectionProgress then
                AV_ShowCollectionProgress()
            end
        else
            if AV_HideCollectionProgress then
                AV_HideCollectionProgress()
            end
        end
    end
    
    -- Save category filter settings (v2.1+)
    if not AscensionVanityDB.categoryFilters then
        AscensionVanityDB.categoryFilters = {}
    end
    for category, checkbox in pairs(settingsPanel.categoryCheckboxes) do
        -- WoW checkboxes return 1 (truthy) or nil; store strict boolean
        AscensionVanityDB.categoryFilters[category] = checkbox:GetChecked() and true or false
    end
    
    -- Save combat behavior setting (v2.1+)
    for _, radio in pairs(settingsPanel.combatRadios) do
        if radio:GetChecked() then
            AscensionVanityDB.combatBehavior = radio.value
            break
        end
    end
    
    -- Save collection status filter setting (v2.1+)
    for _, radio in pairs(settingsPanel.collectionRadios) do
        if radio:GetChecked() then
            AscensionVanityDB.collectionFilter = radio.value
            break
        end
    end
    
    -- Note: debug setting managed in Scanner UI
    -- No chat spam - changes are saved silently
end

-- ============================================================================
-- Auto-Save Handlers
-- ============================================================================

-- Master switch handler: Enable/disable all sub-settings
enabledCheckbox:SetScript("OnClick", function(self)
    SaveSettings()
    UpdateCheckboxes()  -- Update all checkbox states based on new enabled state
end)

-- Add auto-save to other checkboxes
colorCheckbox:HookScript("OnClick", SaveSettings)
regionsCheckbox:HookScript("OnClick", SaveSettings)
questWarningsCheckbox:HookScript("OnClick", SaveSettings)
showIDsCheckbox:HookScript("OnClick", SaveSettings)
progressFrameCheckbox:HookScript("OnClick", SaveSettings)

-- Add auto-save to category filter checkboxes (v2.1+)
for category, checkbox in pairs(settingsPanel.categoryCheckboxes) do
    checkbox:HookScript("OnClick", function(self)
        SaveSettings()
    end)
end

-- Add radio button group behavior (v2.1+) - now that SaveSettings exists
for _, radio in pairs(settingsPanel.combatRadios) do
    radio:SetScript("OnClick", function(self)
        -- Ensure only one radio is checked at a time
        for _, otherRadio in pairs(settingsPanel.combatRadios) do
            otherRadio:SetChecked(false)
        end
        self:SetChecked(true)
        SaveSettings()
    end)
end

-- Add radio button group behavior for collection filter (v2.1+)
for _, radio in pairs(settingsPanel.collectionRadios) do
    radio:SetScript("OnClick", function(self)
        -- Ensure only one radio is checked at a time
        for _, otherRadio in pairs(settingsPanel.collectionRadios) do
            otherRadio:SetChecked(false)
        end
        self:SetChecked(true)
        SaveSettings()
    end)
end

-- Note: learnedCheckbox already has OnClick handler, add save there
local originalLearnedHandler = learnedCheckbox:GetScript("OnClick")
learnedCheckbox:SetScript("OnClick", function(self)
    -- Call original handler for dependency management
    if originalLearnedHandler then
        originalLearnedHandler(self)
    end
    -- Auto-save after state change
    SaveSettings()
end)

-- ============================================================================
-- Panel Events
-- ============================================================================

-- Update checkboxes when panel is shown
settingsPanel:SetScript("OnShow", function()
    UpdateCheckboxes()
end)

-- ============================================================================
-- Global Sync Function
-- ============================================================================

-- Function to sync checkboxes (called by slash commands)
function AscensionVanity_SyncSettingsUI()
    if settingsPanel and settingsPanel:IsShown() then
        UpdateCheckboxes()
    end
end

-- ============================================================================
-- Interface Options Integration (Launcher Panel)
-- ============================================================================

-- Create a simple launcher panel in Interface Options
local optionsPanel = CreateFrame("Frame", "AscensionVanityOptionsPanel", UIParent)
optionsPanel.name = "AscensionVanity"

-- Title
local optionsTitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
optionsTitle:SetPoint("TOPLEFT", 16, -16)
optionsTitle:SetText("AscensionVanity")

-- Description
local optionsDesc = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
optionsDesc:SetPoint("TOPLEFT", optionsTitle, "BOTTOMLEFT", 0, -8)
optionsDesc:SetWidth(580)
optionsDesc:SetJustifyH("LEFT")
optionsDesc:SetText("Track vanity item drops in creature tooltips with learned status indicators.")

-- Settings button
local optionsSettingsButton = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
optionsSettingsButton:SetPoint("TOPLEFT", optionsDesc, "BOTTOMLEFT", 0, -16)
optionsSettingsButton:SetSize(200, 30)
optionsSettingsButton:SetText("Open Settings")
optionsSettingsButton:SetScript("OnClick", function()
    -- Close scanner if open, then show settings
    if AscensionVanityScannerFrame and AscensionVanityScannerFrame:IsShown() then
        AscensionVanityScannerFrame:Hide()
    end
    settingsPanel:Show()
end)

-- Scanner button
local optionsScannerButton = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
optionsScannerButton:SetPoint("TOPLEFT", optionsSettingsButton, "BOTTOMLEFT", 0, -8)
optionsScannerButton:SetSize(200, 30)
optionsScannerButton:SetText("Open API Scanner")
optionsScannerButton:SetScript("OnClick", function()
    -- Close settings if open, then show scanner
    if settingsPanel:IsShown() then
        settingsPanel:Hide()
    end
    AscensionVanity_ShowScanner()
end)

-- Register with Interface Options
InterfaceOptions_AddCategory(optionsPanel)

-- ============================================================================
-- Global Functions
-- ============================================================================

-- Global function to show settings panel
function AscensionVanity_ShowSettings()
    settingsPanel:Show()
end
