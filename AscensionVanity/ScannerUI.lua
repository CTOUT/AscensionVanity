-- AscensionVanity - Scanner UI Panel
-- Provides a simple interface for managing API scans

local AddonName = "AscensionVanity"

-- ============================================================================
-- Main Scanner Frame (Standalone)
-- ============================================================================

-- Create standalone scanner panel with DialogBox styling
local scannerPanel = CreateFrame("Frame", "AscensionVanityScannerFrame", UIParent)
scannerPanel:SetSize(650, 680)  -- Increased height to show all slash commands
scannerPanel:SetPoint("CENTER")
scannerPanel:SetFrameStrata("DIALOG")  -- Higher strata to prevent overlap
scannerPanel:SetMovable(true)
scannerPanel:EnableMouse(true)
scannerPanel:RegisterForDrag("LeftButton")
scannerPanel:SetScript("OnDragStart", scannerPanel.StartMoving)
scannerPanel:SetScript("OnDragStop", scannerPanel.StopMovingOrSizing)
scannerPanel:SetClampedToScreen(true)
scannerPanel:Hide()

-- Add DialogBox backdrop for professional look
scannerPanel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

-- Close on ESC key
tinsert(UISpecialFrames, "AscensionVanityScannerFrame")

-- Close button
local closeButton = CreateFrame("Button", nil, scannerPanel, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)

-- Title
local title = scannerPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -20)
title:SetText("AscensionVanity Scanner")

-- Version
local version = scannerPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
version:SetPoint("TOP", title, "BOTTOM", 0, -4)
version:SetText("Version 2.0.0")

-- Description
local desc = scannerPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
desc:SetPoint("TOP", version, "BOTTOM", 0, -12)
desc:SetWidth(580)
desc:SetJustifyH("CENTER")
desc:SetText("Scan vanity items from the Ascension API and export them for database generation.")

-- Separator line
local separator1 = scannerPanel:CreateTexture(nil, "ARTWORK")
separator1:SetHeight(1)
separator1:SetPoint("TOP", desc, "BOTTOM", 0, -12)
separator1:SetPoint("LEFT", 30, 0)
separator1:SetPoint("RIGHT", -30, 0)
separator1:SetColorTexture(0.25, 0.25, 0.25, 1)

-- ============================================================================
-- Status Section
-- ============================================================================

local statusHeader = scannerPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
statusHeader:SetPoint("TOPLEFT", separator1, "BOTTOMLEFT", 30, -16)
statusHeader:SetText("Current Status:")

local statusText = scannerPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
statusText:SetPoint("TOPLEFT", statusHeader, "BOTTOMLEFT", 0, -8)
statusText:SetWidth(580)
statusText:SetJustifyH("LEFT")
statusText:SetText("Loading...")

-- Update status display
local function UpdateStatus()
    local itemCount = 0
    for _ in pairs(AscensionVanityDump.APIDump or {}) do
        itemCount = itemCount + 1
    end
    
    local status = ""
    if itemCount > 0 then
        status = string.format(
            "|cFF00FF00Last Scan:|r %s\n" ..
            "|cFF00FF00Items in Dump:|r %d\n" ..
            "|cFF00FF00Version:|r %s",
            AscensionVanityDump.LastScanDate or "Unknown",
            itemCount,
            AscensionVanityDump.ScanVersion or "Unknown"
        )
    else
        status = "|cFFFFFF00No scan data found.|r\n\nClick 'Scan All Items' to begin."
    end
    
    statusText:SetText(status)
end

-- Separator line
local separator2 = scannerPanel:CreateTexture(nil, "ARTWORK")
separator2:SetHeight(1)
separator2:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -16)
separator2:SetPoint("LEFT", 30, 0)
separator2:SetPoint("RIGHT", -30, 0)
separator2:SetColorTexture(0.25, 0.25, 0.25, 1)

-- ============================================================================
-- Actions Section
-- ============================================================================

local actionsHeader = scannerPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
actionsHeader:SetPoint("TOPLEFT", separator2, "BOTTOMLEFT", 30, -16)
actionsHeader:SetText("Actions:")

-- Scan Button
local scanButton = CreateFrame("Button", nil, scannerPanel, "UIPanelButtonTemplate")
scanButton:SetPoint("TOPLEFT", actionsHeader, "BOTTOMLEFT", 0, -8)
scanButton:SetSize(200, 30)
scanButton:SetText("Scan All Items")
scanButton:SetScript("OnClick", function()
    AV_ScanAllItems()
    C_Timer.After(1, UpdateStatus)  -- Update status after scan completes
end)

-- Scan button description
local scanDesc = scannerPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
scanDesc:SetPoint("LEFT", scanButton, "RIGHT", 8, 0)
scanDesc:SetWidth(360)
scanDesc:SetJustifyH("LEFT")
scanDesc:SetText("Query the Ascension API for all vanity items")

-- Clear Button
local clearButton = CreateFrame("Button", nil, scannerPanel, "UIPanelButtonTemplate")
clearButton:SetPoint("TOPLEFT", scanButton, "BOTTOMLEFT", 0, -8)
clearButton:SetSize(200, 30)
clearButton:SetText("Clear Dump Data")
clearButton:SetScript("OnClick", function()
    StaticPopup_Show("AV_CONFIRM_CLEAR_DUMP_UI")
end)

-- Clear button description
local clearDesc = scannerPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
clearDesc:SetPoint("LEFT", clearButton, "RIGHT", 8, 0)
clearDesc:SetWidth(360)
clearDesc:SetJustifyH("LEFT")
clearDesc:SetText("Remove all scanned data (requires re-scan)")

-- Confirmation dialog for UI clear
StaticPopupDialogs["AV_CONFIRM_CLEAR_DUMP_UI"] = {
    text = "Clear all API dump data?\n\nThis will delete all scanned item data. You will need to run a new scan.",
    button1 = "Yes, Clear",
    button2 = "Cancel",
    OnAccept = function()
        AV_ClearDumpData()
        UpdateStatus()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Refresh Button
local refreshButton = CreateFrame("Button", nil, scannerPanel, "UIPanelButtonTemplate")
refreshButton:SetPoint("TOPLEFT", clearButton, "BOTTOMLEFT", 0, -8)
refreshButton:SetSize(200, 30)
refreshButton:SetText("Refresh Status")
refreshButton:SetScript("OnClick", function()
    UpdateStatus()
end)

-- Refresh button description
local refreshDesc = scannerPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
refreshDesc:SetPoint("LEFT", refreshButton, "RIGHT", 8, 0)
refreshDesc:SetWidth(360)
refreshDesc:SetJustifyH("LEFT")
refreshDesc:SetText("Update the status display")

-- Settings Button
local settingsButton = CreateFrame("Button", nil, scannerPanel, "UIPanelButtonTemplate")
settingsButton:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -8)
settingsButton:SetSize(200, 30)
settingsButton:SetText("Open Settings")
settingsButton:SetScript("OnClick", function()
    scannerPanel:Hide()  -- Close scanner when opening settings
    AscensionVanity_ShowSettings()
end)

-- Settings button description
local settingsDesc = scannerPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
settingsDesc:SetPoint("LEFT", settingsButton, "RIGHT", 8, 0)
settingsDesc:SetWidth(360)
settingsDesc:SetJustifyH("LEFT")
settingsDesc:SetText("Configure addon settings and preferences")

-- ============================================================================
-- Developer Options
-- ============================================================================

-- Debug Mode checkbox
local debugCheckbox = CreateFrame("CheckButton", nil, scannerPanel, "UICheckButtonTemplate")
debugCheckbox:SetPoint("TOPLEFT", settingsButton, "BOTTOMLEFT", 0, -12)
debugCheckbox:SetChecked(AscensionVanityDB.debug or false)
debugCheckbox:SetScript("OnClick", function(self)
    AscensionVanityDB.debug = self:GetChecked()
end)

-- Debug checkbox label
local debugLabel = scannerPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
debugLabel:SetPoint("LEFT", debugCheckbox, "RIGHT", 5, 0)
debugLabel:SetText("Debug Mode")

-- Debug checkbox tooltip
debugCheckbox:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Debug Mode", 1, 1, 1)
    GameTooltip:AddLine("Enable debug logging to chat for troubleshooting.", nil, nil, nil, true)
    GameTooltip:Show()
end)
debugCheckbox:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Separator line
local separator3 = scannerPanel:CreateTexture(nil, "ARTWORK")
separator3:SetHeight(1)
separator3:SetPoint("TOPLEFT", debugCheckbox, "BOTTOMLEFT", 0, -16)
separator3:SetPoint("LEFT", 30, 0)
separator3:SetPoint("RIGHT", -30, 0)
separator3:SetColorTexture(0.25, 0.25, 0.25, 1)

-- ============================================================================
-- Instructions Section
-- ============================================================================

local instructionsHeader = scannerPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
instructionsHeader:SetPoint("TOPLEFT", separator3, "BOTTOMLEFT", 30, -16)
instructionsHeader:SetText("How to Use:")

local instructions = scannerPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
instructions:SetPoint("TOPLEFT", instructionsHeader, "BOTTOMLEFT", 0, -8)
instructions:SetWidth(580)
instructions:SetJustifyH("LEFT")
instructions:SetText(
    "|cFF00FF001.|r Click 'Scan All Items' to query the Ascension API (takes 2-5 minutes)\n" ..
    "|cFF00FF002.|r Wait for the scan to complete (check chat for progress)\n" ..
    "|cFF00FF003.|r Exit WoW to save the data to AscensionVanity_Dump.lua\n" ..
    "|cFF00FF004.|r Run PowerShell utilities to process the dump and generate database\n" ..
    "|cFF00FF005.|r Deploy the updated addon to see new/changed items\n\n" ..
    "|cFFFFFF00File Location:|r\n" ..
    "WTF\\Account\\<your-account>\\SavedVariables\\AscensionVanity_Dump.lua"
)

-- Command Reference Section
local separator4 = scannerPanel:CreateTexture(nil, "ARTWORK")
separator4:SetHeight(1)
separator4:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -16)
separator4:SetPoint("LEFT", 30, 0)
separator4:SetPoint("RIGHT", -30, 0)
separator4:SetColorTexture(0.25, 0.25, 0.25, 1)

local commandHeader = scannerPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
commandHeader:SetPoint("TOPLEFT", separator4, "BOTTOMLEFT", 30, -16)
commandHeader:SetText("Slash Commands:")

local commands = scannerPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
commands:SetPoint("TOPLEFT", commandHeader, "BOTTOMLEFT", 0, -8)
commands:SetWidth(580)
commands:SetJustifyH("LEFT")
commands:SetText(
    "|cFF00FF96/avanity scanner|r - Open this scanner window\n" ..
    "|cFF00FF96/avanity scan|r - Start a new scan\n" ..
    "|cFF00FF96/avanity scan clear|r - Clear dump data\n" ..
    "|cFF00FF96/avanity scan stats|r - Show scan statistics"
)

-- Update status and sync UI when panel is shown
scannerPanel:SetScript("OnShow", function()
    UpdateStatus()
    -- Sync debug checkbox with saved variable (in case changed via slash command)
    debugCheckbox:SetChecked(AscensionVanityDB.debug or false)
end)

-- ============================================================================
-- Interface Options Integration (Launcher)
-- ============================================================================

-- Note: Scanner is now accessible via:
-- 1. Settings UI "Open API Scanner" button
-- 2. /avanity scanner command
-- 3. /avanity scan command (direct scan)
--
-- No separate Interface Options panel needed - keeps addon list clean

-- ============================================================================
-- Global Functions
-- ============================================================================

-- Function to show scanner panel
function AscensionVanity_ShowScanner()
    scannerPanel:Show()
end

-- Function to sync debug checkbox (called by slash commands)
function AscensionVanity_SyncDebugCheckbox()
    if debugCheckbox then
        debugCheckbox:SetChecked(AscensionVanityDB.debug or false)
    end
end

-- Also update status on addon load
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == AddonName then
        UpdateStatus()
    end
end)
