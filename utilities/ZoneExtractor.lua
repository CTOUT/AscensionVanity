-- Zone and Subzone Extraction Module
-- Extracts complete zone/subzone mappings from the game client
-- Can be integrated into APIScanner for comprehensive data collection

local ZoneExtractor = {}

-- Storage for extracted data
ZoneExtractor.data = {
    zones = {},
    continents = {},
    timestamp = nil,
    playerLocation = nil
}

-- Extract current player location
function ZoneExtractor:GetCurrentLocation()
    return {
        zone = GetZoneText() or "Unknown",
        subzone = GetSubZoneText() or "",
        minimapZone = GetMinimapZoneText() or "",
        realZone = GetRealZoneText() or GetZoneText() or "Unknown",
        pvpType = select(1, GetZonePVPInfo()) or "none",
        continent = GetCurrentMapContinent() or 0,
        x = 0, -- Would need LibMapData or similar for coords
        y = 0
    }
end

-- Extract all zone names from the current continent
function ZoneExtractor:ExtractContinentZones(continentID)
    if not GetMapZones then
        print("GetMapZones not available - using fallback method")
        return {}
    end
    
    local zones = { GetMapZones(continentID) }
    local zoneList = {}
    
    for i, zoneName in ipairs(zones) do
        if zoneName and zoneName ~= "" then
            table.insert(zoneList, {
                id = i,
                name = zoneName,
                continent = continentID
            })
        end
    end
    
    return zoneList
end

-- Extract all continents
function ZoneExtractor:ExtractContinents()
    if not GetMapContinents then
        print("GetMapContinents not available")
        return {}
    end
    
    local continents = { GetMapContinents() }
    local continentList = {}
    
    for i = 1, #continents, 2 do
        local continentID = continents[i]
        local continentName = continents[i + 1]
        
        if continentName and continentName ~= "" then
            table.insert(continentList, {
                id = continentID,
                name = continentName
            })
        end
    end
    
    return continentList
end

-- Main extraction function
function ZoneExtractor:ExtractAllZones()
    print("|cFF00FF96[ZoneExtractor]|r Starting zone extraction...")
    
    self.data.timestamp = date("%Y-%m-%d %H:%M:%S")
    self.data.playerLocation = self:GetCurrentLocation()
    
    -- Extract continents
    local continents = self:ExtractContinents()
    print("|cFF00FF96[ZoneExtractor]|r Found " .. #continents .. " continents")
    
    for _, continent in ipairs(continents) do
        print("|cFF00FF96[ZoneExtractor]|r Extracting zones from: " .. continent.name)
        
        local zones = self:ExtractContinentZones(continent.id)
        
        self.data.continents[continent.name] = {
            id = continent.id,
            zones = zones
        }
        
        -- Also store in flat zone list
        for _, zone in ipairs(zones) do
            self.data.zones[zone.name] = {
                id = zone.id,
                continent = continent.name,
                continentID = continent.id
            }
        end
        
        print("|cFF00FF96[ZoneExtractor]|r   Found " .. #zones .. " zones")
    end
    
    local totalZones = 0
    for _ in pairs(self.data.zones) do totalZones = totalZones + 1 end
    
    print("|cFF00FF96[ZoneExtractor]|r Extraction complete!")
    print("|cFF00FF96[ZoneExtractor]|r Total zones: " .. totalZones)
    
    return self.data
end

-- Export data to saved variables format
function ZoneExtractor:ExportToSavedVariable(variableName)
    variableName = variableName or "AscensionVanity_ZoneData"
    
    _G[variableName] = {
        version = "1.0",
        extractedDate = self.data.timestamp,
        playerLocation = self.data.playerLocation,
        continents = self.data.continents,
        zones = self.data.zones,
        totalZones = (function()
            local count = 0
            for _ in pairs(self.data.zones) do count = count + 1 end
            return count
        end)()
    }
    
    print("|cFF00FF96[ZoneExtractor]|r Data exported to: " .. variableName)
    print("|cFF00FFFF[ZoneExtractor]|r Use /reload to save, then check:")
    print("|cFFFFFF00  WTF/Account/[ACCOUNT]/SavedVariables/AscensionVanity.lua|r")
end

-- Slash command handler
SLASH_EXTRACTZONES1 = "/extractzones"
SlashCmdList["EXTRACTZONES"] = function(msg)
    if msg == "help" then
        print("|cFF00FF96========================================|r")
        print("|cFF00FF96  Zone Extractor Commands|r")
        print("|cFF00FF96========================================|r")
        print("|cFFFFFF00/extractzones|r          - Extract all zones")
        print("|cFFFFFF00/extractzones export|r   - Extract and export to SavedVariables")
        print("|cFFFFFF00/extractzones location|r - Show current location")
        print("|cFFFFFF00/extractzones help|r     - Show this help")
        print("|cFF00FF96========================================|r")
    elseif msg == "location" then
        local loc = ZoneExtractor:GetCurrentLocation()
        print("|cFF00FF96========================================|r")
        print("|cFF00FF96  Current Location|r")
        print("|cFF00FF96========================================|r")
        print("  Zone:        " .. loc.zone)
        print("  Subzone:     " .. loc.subzone)
        print("  Real Zone:   " .. loc.realZone)
        print("  Minimap:     " .. loc.minimapZone)
        print("  PVP Type:    " .. loc.pvpType)
        print("  Continent:   " .. loc.continent)
        print("|cFF00FF96========================================|r")
    elseif msg == "export" then
        ZoneExtractor:ExtractAllZones()
        ZoneExtractor:ExportToSavedVariable()
    else
        -- Default: just extract and display
        local data = ZoneExtractor:ExtractAllZones()
        
        print(" ")
        print("|cFF00FF96========================================|r")
        print("|cFF00FF96  Extraction Summary|r")
        print("|cFF00FF96========================================|r")
        print("  Current Location: " .. data.playerLocation.zone)
        if data.playerLocation.subzone ~= "" then
            print("                    " .. data.playerLocation.subzone)
        end
        
        local continentCount = 0
        for _ in pairs(data.continents) do continentCount = continentCount + 1 end
        print("  Continents: " .. continentCount)
        
        local zoneCount = 0
        for _ in pairs(data.zones) do zoneCount = zoneCount + 1 end
        print("  Zones:      " .. zoneCount)
        
        print(" ")
        print("Sample zones:")
        local count = 0
        for zoneName, zoneData in pairs(data.zones) do
            if count < 10 then
                print("  - " .. zoneName .. " (Continent: " .. zoneData.continent .. ")")
                count = count + 1
            end
        end
        
        print(" ")
        print("Use |cFFFFFF00/extractzones export|r to save to SavedVariables")
        print("|cFF00FF96========================================|r")
    end
end

print("|cFF00FF96[ZoneExtractor]|r Loaded! Type |cFFFFFF00/extractzones help|r for commands")

return ZoneExtractor
