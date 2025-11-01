-- AscensionVanity - Settings UI
-- User interface for addon configuration

local AddonName = "AscensionVanity"
local VERSION = "2.0.0"

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

-- Separator
local separator1 = settingsPanel:CreateTexture(nil, "ARTWORK")
separator1:SetHeight(1)
separator1:SetPoint("TOP", desc, "BOTTOM", 0, -12)
separator1:SetPoint("LEFT", 30, 0)
separator1:SetPoint("RIGHT", -30, 0)
separator1:SetColorTexture(0.25, 0.25, 0.25, 1)

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

local enabledCheckbox = CreateCheckbox(
    settingsPanel,
    "Enable Tooltip Integration",
    "Master switch for the addon. When disabled, no vanity information will be shown in creature tooltips.",
    separator1,
    30,
    -20
)

local learnedCheckbox = CreateCheckbox(
    settingsPanel,
    "Show Learned Status",
    'Display checkmark/cross icons next to each vanity item to show learned status.\n\nRequires: Ascension C_VanityCollection API',
    enabledCheckbox,
    20,
    -10
)

local colorCheckbox = CreateCheckbox(
    settingsPanel,
    "Color Code Items by Status",
    "Color vanity items based on learned status:\n• Green = Learned\n• Yellow = Not Learned\n\nRequires: Show Learned Status enabled",
    learnedCheckbox,
    20,
    -10
)

local regionsCheckbox = CreateCheckbox(
    settingsPanel,
    "Show Region Information (Coming Soon)",
    "Display location/region information for vanity item drops.\n\n|cFFFFAA00Note:|r Region data is currently being collected and will be available in a future update.",
    colorCheckbox,
    0,
    -10
)

-- Separator before category filters
local separatorCategories = settingsPanel:CreateTexture(nil, "ARTWORK")
separatorCategories:SetHeight(1)
separatorCategories:SetPoint("TOP", regionsCheckbox, "BOTTOM", 0, -16)
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
categoryDesc:SetText("|cFF888888Choose which vanity item types to display in tooltips|r")

-- Category Filter Checkboxes (Two-column layout)
local categoryCheckboxes = {}

-- Left column
categoryCheckboxes.pet = CreateCheckbox(
    settingsPanel,
    "Beastmaster's Whistle - Wild Animals",
    "Show wild animal companions (wolves, cats, bears, etc.) that can be summoned.",
    categoryDesc,
    30,
    -12
)

categoryCheckboxes.demon = CreateCheckbox(
    settingsPanel,
    "Blood Soaked Vellum - Undead",
    "Show undead creature summons (ghouls, skeletons, spirits, etc.).",
    categoryCheckboxes.pet,
    0,
    -8
)

categoryCheckboxes.elemental = CreateCheckbox(
    settingsPanel,
    "Summoner's Stone - Demons",
    "Show demon summons (imps, felguards, succubi, etc.).",
    categoryCheckboxes.demon,
    0,
    -8
)

-- Right column
categoryCheckboxes.dragonkin = CreateCheckbox(
    settingsPanel,
    "Draconic Warhorn - Dragonkin",
    "Show dragonkin companions (whelps, drakes, dragons, etc.).",
    categoryDesc,
    390,  -- Positioned to the right
    -12
)

categoryCheckboxes.totem = CreateCheckbox(
    settingsPanel,
    "Elemental Lodestone - Elementals",
    "Show elemental companions (fire, water, earth, air elementals, etc.).",
    categoryCheckboxes.dragonkin,
    0,
    -8
)

-- Store reference for later use
settingsPanel.categoryCheckboxes = categoryCheckboxes

-- Separator before combat behavior (positioned below the tallest column)
local separatorCombat = settingsPanel:CreateTexture(nil, "ARTWORK")
separatorCombat:SetHeight(1)
-- Position below left column (elemental is last in left column, totem is in right column)
separatorCombat:SetPoint("TOP", categoryCheckboxes.elemental, "BOTTOM", 0, -16)
separatorCombat:SetPoint("LEFT", 30, 0)
separatorCombat:SetPoint("RIGHT", -30, 0)
separatorCombat:SetColorTexture(0.25, 0.25, 0.25, 1)

-- Combat Behavior Section Header
local combatHeader = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
combatHeader:SetPoint("TOP", separatorCombat, "BOTTOM", 0, -12)
combatHeader:SetText("Combat Behavior")

local combatDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
combatDesc:SetPoint("TOP", combatHeader, "BOTTOM", 0, -4)
combatDesc:SetWidth(700)
combatDesc:SetJustifyH("CENTER")
combatDesc:SetText("|cFF888888Control how vanity tooltips display during combat|r")

-- Radio button helper function
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

-- Combat Behavior Radio Buttons
local combatRadios = {}

combatRadios.normal = CreateRadioButton(
    settingsPanel,
    "Normal (Show All)",
    "normal",
    "Display full vanity item information during combat.\n\nUse this if you want to see all details while fighting.",
    combatDesc,
    30,
    -12
)

combatRadios.minimal = CreateRadioButton(
    settingsPanel,
    "Minimal (Count Only)",
    "minimal",
    "Show only the number of vanity items available.\n\nExample: 'Vanity Items: 3 available'\n\nGood balance between information and clutter.",
    combatRadios.normal,
    0,
    -8
)

combatRadios.hide = CreateRadioButton(
    settingsPanel,
    "Hide Completely (Default)",
    "hide",
    "Hide all vanity information during combat.\n\nKeeps tooltips clean when fighting.\n\n|cFF00FF00Recommended for most players.|r",
    combatRadios.minimal,
    0,
    -8
)

-- Store reference
settingsPanel.combatRadios = combatRadios

-- Note: Radio button OnClick handlers set later (after SaveSettings is defined)

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

-- Separator before utility buttons
local separator2 = settingsPanel:CreateTexture(nil, "ARTWORK")
separator2:SetHeight(1)
separator2:SetPoint("TOP", combatRadios.hide, "BOTTOM", 0, -16)
separator2:SetPoint("LEFT", 30, 0)
separator2:SetPoint("RIGHT", -30, 0)
separator2:SetColorTexture(0.25, 0.25, 0.25, 1)

-- ============================================================================
-- Utility Buttons
-- ============================================================================

-- Open Scanner button
local scannerButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
scannerButton:SetPoint("TOP", separator2, "BOTTOM", 0, -16)
scannerButton:SetSize(200, 30)
scannerButton:SetText("Open API Scanner")
scannerButton:SetScript("OnClick", function()
    settingsPanel:Hide()  -- Close settings when opening scanner
    AscensionVanity_ShowScanner()
end)

-- Scanner button description
local scannerDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
scannerDesc:SetPoint("TOP", scannerButton, "BOTTOM", 0, -4)
scannerDesc:SetText("|cFF888888Developer tool for scanning vanity items|r")

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
autoSaveText:SetText("|cFF888888Settings are saved automatically|r")

-- ============================================================================
-- Settings Management
-- ============================================================================

-- Update checkboxes to reflect current settings and dependencies
local function UpdateCheckboxes()
    enabledCheckbox:SetChecked(AscensionVanityDB.enabled)
    learnedCheckbox:SetChecked(AscensionVanityDB.showLearnedStatus)
    colorCheckbox:SetChecked(AscensionVanityDB.colorCode)
    regionsCheckbox:SetChecked(AscensionVanityDB.showRegions)
    
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
    AscensionVanityDB.enabled = enabledCheckbox:GetChecked()
    AscensionVanityDB.colorCode = colorCheckbox:GetChecked()
    AscensionVanityDB.showLearnedStatus = learnedCheckbox:GetChecked()
    AscensionVanityDB.showRegions = regionsCheckbox:GetChecked()
    
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
    
    -- Note: debug setting now in Scanner UI
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

-- Add auto-save to category filter checkboxes (v2.1+)
for category, checkbox in pairs(settingsPanel.categoryCheckboxes) do
    checkbox:HookScript("OnClick", function(self)
        print("[AV Debug] Category checkbox clicked:", category, "New state:", self:GetChecked())
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
