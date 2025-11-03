-- AscensionVanity - Collection Progress Frame
-- Standalone moveable frame showing collection progress
-- Version: 2.2

-- ============================================================================
-- Frame Creation
-- ============================================================================

-- Create main frame
local progressFrame = CreateFrame("Frame", "AV_CollectionProgressFrame", UIParent)
progressFrame:SetSize(250, 200)
progressFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -50, -200)
progressFrame:SetMovable(true)
progressFrame:EnableMouse(true)
progressFrame:SetClampedToScreen(true)
progressFrame:SetFrameStrata("MEDIUM")
progressFrame:SetFrameLevel(10)

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
yPos = -6

progressFrame.progressBars.beast = CreateProgressBar(progressFrame, AV_CATEGORY_SHORT_NAMES.beast, progressFrame.progressBars.overall.bg, yPos)
progressFrame.progressBars.demon = CreateProgressBar(progressFrame, AV_CATEGORY_SHORT_NAMES.demon, progressFrame.progressBars.beast.bg, yPos)
progressFrame.progressBars.undead = CreateProgressBar(progressFrame, AV_CATEGORY_SHORT_NAMES.undead, progressFrame.progressBars.demon.bg, yPos)
progressFrame.progressBars.dragonkin = CreateProgressBar(progressFrame, AV_CATEGORY_SHORT_NAMES.dragonkin, progressFrame.progressBars.undead.bg, yPos)
progressFrame.progressBars.elemental = CreateProgressBar(progressFrame, AV_CATEGORY_SHORT_NAMES.elemental, progressFrame.progressBars.dragonkin.bg, yPos)

-- ============================================================================
-- Update Logic
-- ============================================================================

-- Function to update all progress bars
local function UpdateProgressBars()
    if not AV_GetCollectionProgress then
        return  -- Function not available yet
    end
    
    local progress = AV_GetCollectionProgress()
    
    -- Update each progress bar
    for category, bar in pairs(progressFrame.progressBars) do
        if progress[category] then
            bar:SetProgress(progress[category].learned, progress[category].total)
        end
    end
end

-- Auto-update on show
progressFrame:SetScript("OnShow", function()
    UpdateProgressBars()
end)

-- Update periodically (every 5 seconds when visible)
local updateTimer = 0
progressFrame:SetScript("OnUpdate", function(self, elapsed)
    updateTimer = updateTimer + elapsed
    if updateTimer >= 5 then
        updateTimer = 0
        if self:IsVisible() then
            UpdateProgressBars()
        end
    end
end)

-- ============================================================================
-- Global Functions
-- ============================================================================

-- Show the collection progress frame
function AV_ShowCollectionProgress()
    -- Restore saved position if available
    if AscensionVanityDB.progressFramePosition then
        local pos = AscensionVanityDB.progressFramePosition
        progressFrame:ClearAllPoints()
        progressFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    end
    
    UpdateProgressBars()
    progressFrame:Show()
    AscensionVanityDB.showProgressFrame = true
end

-- Hide the collection progress frame
function AV_HideCollectionProgress()
    progressFrame:Hide()
    AscensionVanityDB.showProgressFrame = false
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
