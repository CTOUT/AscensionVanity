-- AscensionVanity - Scanner UI Panel
-- Provides a simple interface for managing API scans

local AddonName = "AscensionVanity"

-- Create the main options panel
local panel = CreateFrame("Frame", "AscensionVanityScannerPanel", UIParent)
panel.name = "Vanity Scanner"
panel.parent = "AscensionVanity"

-- Title
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Vanity Item API Scanner")

-- Description
local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetWidth(580)
desc:SetJustifyH("LEFT")
desc:SetText("Use this tool to scan all vanity items from the Ascension API and export them for database generation.")

-- Separator line
local separator1 = panel:CreateTexture(nil, "ARTWORK")
separator1:SetHeight(1)
separator1:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -8)
separator1:SetPoint("RIGHT", -16, 0)
separator1:SetColorTexture(0.25, 0.25, 0.25, 1)

-- Current Status Section
local statusHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
statusHeader:SetPoint("TOPLEFT", separator1, "BOTTOMLEFT", 0, -16)
statusHeader:SetText("Current Status:")

local statusText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
statusText:SetPoint("TOPLEFT", statusHeader, "BOTTOMLEFT", 20, -8)
statusText:SetWidth(540)
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
local separator2 = panel:CreateTexture(nil, "ARTWORK")
separator2:SetHeight(1)
separator2:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", -20, -16)
separator2:SetPoint("RIGHT", -16, 0)
separator2:SetColorTexture(0.25, 0.25, 0.25, 1)

-- Actions Section
local actionsHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
actionsHeader:SetPoint("TOPLEFT", separator2, "BOTTOMLEFT", 0, -16)
actionsHeader:SetText("Actions:")

-- Scan Button
local scanButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
scanButton:SetPoint("TOPLEFT", actionsHeader, "BOTTOMLEFT", 0, -8)
scanButton:SetSize(200, 30)
scanButton:SetText("Scan All Items")
scanButton:SetScript("OnClick", function()
    AV_ScanAllItems()
    C_Timer.After(1, UpdateStatus)  -- Update status after scan completes
end)

-- Scan button description
local scanDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
scanDesc:SetPoint("LEFT", scanButton, "RIGHT", 8, 0)
scanDesc:SetWidth(360)
scanDesc:SetJustifyH("LEFT")
scanDesc:SetText("Query the Ascension API for all vanity items")

-- Clear Button
local clearButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
clearButton:SetPoint("TOPLEFT", scanButton, "BOTTOMLEFT", 0, -8)
clearButton:SetSize(200, 30)
clearButton:SetText("Clear Dump Data")
clearButton:SetScript("OnClick", function()
    StaticPopup_Show("AV_CONFIRM_CLEAR_DUMP_UI")
end)

-- Clear button description
local clearDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
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
local refreshButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
refreshButton:SetPoint("TOPLEFT", clearButton, "BOTTOMLEFT", 0, -8)
refreshButton:SetSize(200, 30)
refreshButton:SetText("Refresh Status")
refreshButton:SetScript("OnClick", function()
    UpdateStatus()
    print("|cFF00FF96[AscensionVanity]|r Status refreshed.")
end)

-- Refresh button description
local refreshDesc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
refreshDesc:SetPoint("LEFT", refreshButton, "RIGHT", 8, 0)
refreshDesc:SetWidth(360)
refreshDesc:SetJustifyH("LEFT")
refreshDesc:SetText("Update the status display")

-- Separator line
local separator3 = panel:CreateTexture(nil, "ARTWORK")
separator3:SetHeight(1)
separator3:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -16)
separator3:SetPoint("RIGHT", -16, 0)
separator3:SetColorTexture(0.25, 0.25, 0.25, 1)

-- Instructions Section
local instructionsHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
instructionsHeader:SetPoint("TOPLEFT", separator3, "BOTTOMLEFT", 0, -16)
instructionsHeader:SetText("How to Use:")

local instructions = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
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
local separator4 = panel:CreateTexture(nil, "ARTWORK")
separator4:SetHeight(1)
separator4:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -16)
separator4:SetPoint("RIGHT", -16, 0)
separator4:SetColorTexture(0.25, 0.25, 0.25, 1)

local commandHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
commandHeader:SetPoint("TOPLEFT", separator4, "BOTTOMLEFT", 0, -16)
commandHeader:SetText("Slash Commands:")

local commands = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
commands:SetPoint("TOPLEFT", commandHeader, "BOTTOMLEFT", 0, -8)
commands:SetWidth(580)
commands:SetJustifyH("LEFT")
commands:SetText(
    "|cFF00FF96/avscan scan|r - Start a new scan\n" ..
    "|cFF00FF96/avscan clear|r - Clear dump data\n" ..
    "|cFF00FF96/avscan stats|r - Show scan statistics\n" ..
    "|cFF00FF96/avscan help|r - Show help"
)

-- Update status when panel is shown
panel:SetScript("OnShow", function()
    UpdateStatus()
end)

-- Register panel with WoW interface options
InterfaceOptions_AddCategory(panel)

-- Also update status on addon load
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == AddonName then
        UpdateStatus()
    end
end)
