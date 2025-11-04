-- Zone/Subzone Data Extraction Test
-- Run this in-game with /run to test available APIs

local function TestZoneAPIs()
    print("|cFF00FF96========================================|r")
    print("|cFF00FF96  WoW Zone/Subzone API Test|r")
    print("|cFF00FF96========================================|r")
    print(" ")
    
    -- Basic zone info
    print("|cFFFFFF00Current Location:|r")
    print("  GetZoneText():        " .. tostring(GetZoneText()))
    print("  GetSubZoneText():     " .. tostring(GetSubZoneText()))
    print("  GetMinimapZoneText(): " .. tostring(GetMinimapZoneText()))
    print(" ")
    
    -- Real zone name (localized)
    print("|cFFFFFF00Real Zone Name:|r")
    print("  GetRealZoneText():    " .. tostring(GetRealZoneText()))
    print(" ")
    
    -- PVP Info (shows zone type)
    print("|cFFFFFF00PVP Info:|r")
    local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
    print("  PVP Type:    " .. tostring(pvpType))
    print("  Is SubZone:  " .. tostring(isSubZonePvP))
    print("  Faction:     " .. tostring(factionName))
    print(" ")
    
    -- Try to get zone ID (if available)
    print("|cFFFFFF00Zone ID Functions:|r")
    
    -- C_Map API (TBC/WOTLK)
    if C_Map then
        print("  C_Map API detected:")
        
        if C_Map.GetBestMapForUnit then
            local mapID = C_Map.GetBestMapForUnit("player")
            print("    GetBestMapForUnit: " .. tostring(mapID))
        end
        
        if C_Map.GetMapInfo then
            local mapID = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
            if mapID then
                local mapInfo = C_Map.GetMapInfo(mapID)
                if mapInfo then
                    print("    MapInfo.name:     " .. tostring(mapInfo.name))
                    print("    MapInfo.mapID:    " .. tostring(mapInfo.mapID))
                    print("    MapInfo.mapType:  " .. tostring(mapInfo.mapType))
                end
            end
        end
    else
        print("  C_Map: Not available (pre-TBC?)")
    end
    
    print(" ")
    
    -- Get all available zone names (for mapping)
    print("|cFFFFFF00Scanning All Zones:|r")
    print("  Checking if we can enumerate zones...")
    
    -- Try GetMapZones (Classic API)
    if GetMapZones then
        print("  GetMapZones: Available")
        local continent = GetCurrentMapContinent()
        if continent and continent > 0 then
            local zones = { GetMapZones(continent) }
            print("    Current continent: " .. continent)
            print("    Zones found: " .. #zones)
            for i = 1, math.min(5, #zones) do
                print("      " .. i .. ". " .. tostring(zones[i]))
            end
        end
    else
        print("  GetMapZones: Not available")
    end
    
    print(" ")
    print("|cFF00FF96========================================|r")
    print("Test complete! Copy the output above.")
    print("|cFF00FF96========================================|r")
end

-- Run the test
TestZoneAPIs()
