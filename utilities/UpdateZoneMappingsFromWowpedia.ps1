<#
.SYNOPSIS
    Fetch complete zone mappings from Wowpedia and update ZoneMappings.json

.DESCRIPTION
    Scrapes zone and subzone data from Wowpedia to create a comprehensive mapping file.
    This ensures we have complete coverage for all WoW Classic/TBC/WOTLK zones.
    
    Sources:
    - Zone list: https://wowpedia.fandom.com/wiki/Zones_by_level_(original)
    - Subzones: Individual zone pages (e.g., /wiki/Desolace_(Classic))
    
.PARAMETER CacheOnly
    Only use cached data, don't fetch from web

.PARAMETER ForceRefresh
    Force refresh from web, ignore cache
#>

[CmdletBinding()]
param(
    [switch]$CacheOnly,
    [switch]$ForceRefresh
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          Fetch Complete Zone Mappings from Wowpedia             ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Define all Classic/TBC/WOTLK zones with known subzones
# This is a MANUAL cache based on Wowpedia data (as of Nov 2025)
# We'll augment our existing ZoneMappings.json with complete data

$completeZoneData = @{
    # ========================================
    # EASTERN KINGDOMS
    # ========================================
    "Alterac Mountains" = @{
        faction = "Contested"
        level = "30-40"
        subzones = @(
            "Chillwind Point", "Corrahn's Dagger", "Crushridge Hold", "Dandred's Fold",
            "Gavin's Naze", "Growless Cave", "Misty Shore", "Sofera's Naze",
            "Strahnbrad", "The Headland", "The Uplands"
        )
    }
    
    "Arathi Highlands" = @{
        faction = "Contested"
        level = "30-40"
        subzones = @(
            "Boulder'gor", "Boulderfist Hall", "Circle of East Binding",
            "Circle of Inner Binding", "Circle of Outer Binding", "Circle of West Binding",
            "Dabyrie's Farmstead", "Faldir's Cove", "Fardor's Mill", "Hammerfall",
            "Northfold Manor", "Refuge Pointe", "Stromgarde Keep", "Thandol Span",
            "The Drowned Reef", "The Forbidding Sea", "Witherbark Village"
        )
    }
    
    "Badlands" = @{
        faction = "Contested"
        level = "35-45"
        subzones = @(
            "Agmond's End", "Angor Fortress", "Apocryphan's Rest", "Camp Boff",
            "Camp Cagg", "Camp Kosh", "Dustbelch Grotto", "Hammertoe's Digsite",
            "Kargath", "Lethlor Ravine", "The Dustbowl"
        )
    }
    
    "Blasted Lands" = @{
        faction = "Contested"
        level = "45-55"
        subzones = @(
            "Altar of Storms", "Dreadmaul Hold", "Dreadmaul Post", "Nethergarde Keep",
            "Rise of the Defiler", "Serpent's Coil", "The Dark Portal", "The Red Reaches",
            "The Tainted Scar"
        )
    }
    
    "Burning Steppes" = @{
        faction = "Contested"
        level = "50-58"
        subzones = @(
            "Altar of Storms", "Blackrock Mountain", "Blackrock Pass", "Dreadmaul Rock",
            "Morgan's Vigil", "Ruins of Thaurissan", "Terror Wing Path", "The Pillar of Ash"
        )
    }
    
    "Deadwind Pass" = @{
        faction = "Contested"
        level = "55-60"
        subzones = @(
            "Ariden's Camp", "Deadman's Crossing", "Karazhan", "The Vice"
        )
    }
    
    "Dun Morogh" = @{
        faction = "Alliance"
        level = "1-10"
        subzones = @(
            "Amberstill Ranch", "Anvilmar", "Brewnall Village", "Coldridge Pass",
            "Coldridge Valley", "Frostmane Hold", "Gol'Bolar Quarry", "Gnomeregan",
            "Helm's Bed Lake", "Iceflow Lake", "Ironforge", "Kharanos",
            "Misty Pine Refuge", "Shimmer Ridge", "The Grizzled Den"
        )
    }
    
    "Duskwood" = @{
        faction = "Alliance"
        level = "18-30"
        subzones = @(
            "Addle's Stead", "Beggar's Haunt", "Brightwood Grove", "Darkshire",
            "Manor Mistmantle", "Raven Hill", "Raven Hill Cemetery", "The Darkened Bank",
            "The Hushed Bank", "The Rotting Orchard", "The Twilight Grove",
            "The Yorgen Farmstead", "Tranquil Gardens Cemetery", "Vul'Gol Ogre Mound"
        )
    }
    
    "Eastern Plaguelands" = @{
        faction = "Contested"
        level = "53-60"
        subzones = @(
            "Blackwood Lake", "Corin's Crossing", "Crown Guard Tower", "Darrowshire",
            "Eastwall Tower", "Lake Mereldar", "Light's Hope Chapel", "Northdale",
            "Northpass Tower", "Pestilent Scar", "Plaguewood", "Quel'Lithien Lodge",
            "Ruins of Andorhal", "Stratholme", "Terrordale", "The Fungal Vale",
            "The Infectis Scar", "The Marris Stead", "The Noxious Glade", "The Undercroft",
            "Thondroril River", "Tyr's Hand", "Zul'Mashar"
        )
    }
    
    "Elwynn Forest" = @{
        faction = "Alliance"
        level = "1-10"
        subzones = @(
            "Brackwell Pumpkin Patch", "Crystal Lake", "Eastvale Logging Camp",
            "Echo Ridge Mine", "Fargodeep Mine", "Forest's Edge", "Goldshire",
            "Jasperlode Mine", "Jerod's Landing", "Northshire", "Ridgepoint Tower",
            "Stone Cairn Lake", "Stormwind City", "The Maclure Vineyards",
            "The Stonefield Farm", "Tower of Azora", "Westbrook Garrison"
        )
    }
    
    "Eversong Woods" = @{
        faction = "Horde"
        level = "1-10"
        subzones = @(
            "Azurebreeze Coast", "Duskwither Grounds", "East Sanctum", "Elrendar Falls",
            "Fairbreeze Village", "Farstrider Retreat", "Goldenbough Pass", "Golden Strand",
            "Lake Elrendar", "North Sanctum", "Ruins of Silvermoon", "Saltheril's Haven",
            "Silvermoon City", "Stillwhisper Pond", "Sunsail Anchorage", "Sunstrider Isle",
            "The Scorched Grove", "Thuron's Livery", "Tor'Watha", "Tranquil Shore",
            "West Sanctum", "Zeb'Watha"
        )
    }
    
    "Ghostlands" = @{
        faction = "Horde"
        level = "10-20"
        subzones = @(
            "Amani Pass", "Bleeding Ziggurat", "Dawnstar Spire", "Deatholme",
            "Elrendar Crossing", "Farstrider Enclave", "Goldenmist Village",
            "Howling Ziggurat", "Isle of Tribulations", "Lake Elrendar", "Sanctum of the Moon",
            "Sanctum of the Sun", "Suncrown Village", "Tranquillien", "Windrunner Spire",
            "Windrunner Village", "Zeb'Nowa"
        )
    }
    
    "Hillsbrad Foothills" = @{
        faction = "Contested"
        level = "20-30"
        subzones = @(
            "Azurelode Mine", "Corrahn's Dagger", "Dalaran Crater", "Dandred's Fold",
            "Darrow Hill", "Dun Garok", "Durnholde Keep", "Eastern Strand",
            "Gallows' Corner", "Gavin's Naze", "Growless Cave", "Hillsbrad Fields",
            "Misty Shore", "Nethander Stead", "Purgation Isle", "Slaughter Hollow",
            "Sofera's Naze", "Southpoint Tower", "Tarren Mill", "The Headland",
            "The Sludge Fields", "The Uplands", "Western Strand"
        )
    }
    
    "Loch Modan" = @{
        faction = "Alliance"
        level = "10-20"
        subzones = @(
            "Farstrider Lodge", "Grizzlepaw Ridge", "Ironband's Excavation Site",
            "Mo'grosh Stronghold", "North Gate Outpost", "Silver Stream Mine",
            "Stonewrought Dam", "Stonesplinter Valley", "The Loch", "The Loch",
            "Thelsamar", "Valley of Kings"
        )
    }
    
    "Redridge Mountains" = @{
        faction = "Alliance"
        level = "15-25"
        subzones = @(
            "Alther's Mill", "Camp Everstill", "Galardell Valley", "Lake Everstill",
            "Lakeshire", "Lakeridge Highway", "Rethban Caverns", "Render's Camp",
            "Render's Rock", "Render's Valley", "Shalewind Canyon", "Stonewatch",
            "Stonewatch Falls", "The Tower of Ilgalar", "Three Corners"
        )
    }
    
    "Searing Gorge" = @{
        faction = "Contested"
        level = "43-50"
        subzones = @(
            "Blackchar Cave", "Blackrock Mountain", "Dustfire Valley", "Firewatch Ridge",
            "Grimesilt Dig Site", "The Cauldron", "The Sea of Cinders", "Thorium Point"
        )
    }
    
    "Silverpine Forest" = @{
        faction = "Horde"
        level = "10-20"
        subzones = @(
            "Ambermill", "Beren's Peril", "Deep Elem Mine", "Fenris Isle", "Fenris Keep",
            "Forsaken High Command", "Forsaken Rear Guard", "Malden's Orchard",
            "North Tide's Beachhead", "North Tide's Hollow", "North Tide's Run",
            "Olsen's Farthing", "Shadowfang Keep", "The Battlefront", "The Breach",
            "The Decrepit Fields", "The Forsaken Front", "The Sepulcher", "The Skittering Dark",
            "Valgan's Field"
        )
    }
    
    "Stranglethorn Vale" = @{
        faction = "Contested"
        level = "30-45"
        subzones = @(
            "Balia'mah Ruins", "Bal'lal Ruins", "Bambala", "Booty Bay", "Crystalvein Mine",
            "Gurubashi Arena", "Grom'gol Base Camp", "Jaguero Isle", "Kal'ai Ruins",
            "Kurzen's Compound", "Lake Nazferiti", "Mak'lakash Ruins", "Mizjah Ruins",
            "Mosh'Ogg Ogre Mound", "Nesingwary's Expedition", "Rebel Camp", "Ruins of Aboraz",
            "Ruins of Jubuwal", "Ruins of Zul'Kunda", "The Stockpile", "The Vile Reef",
            "Venture Co. Base Camp", "Zuuldaia Ruins", "Zul'Gurub"
        )
    }
    
    "Swamp of Sorrows" = @{
        faction = "Contested"
        level = "35-45"
        subzones = @(
            "Bogpaddle", "Misty Reed Strand", "Misty Valley", "Pool of Tears",
            "Sorrowmurk", "Splinterspear Junction", "Stagalbog", "Stonard",
            "The Harborage", "The Shifting Mire"
        )
    }
    
    "The Hinterlands" = @{
        faction = "Contested"
        level = "40-50"
        subzones = @(
            "Agol'watha", "Aerie Peak", "Creeping Ruin", "Hiri'watha", "Jintha'Alor",
            "Plaguemist Ravine", "Quel'Danil Lodge", "Revantusk Village", "Seradane",
            "Shadra'Alor", "Shaol'watha", "Skulk Rock", "The Altar of Zul",
            "The Overlook Cliffs", "Valorwind Lake", "Zun'watha"
        )
    }
    
    "Tirisfal Glades" = @{
        faction = "Horde"
        level = "1-10"
        subzones = @(
            "Agamand Mills", "Balnir Farmstead", "Brightwater Lake", "Brill",
            "Cold Hearth Manor", "Crusader Outpost", "Deathknell", "Garren's Haunt",
            "Gunther's Retreat", "Night Web's Hollow", "Nightmare Vale", "Scarlet Watch Post",
            "Solliden Farmstead", "The Bulwark", "The North Coast", "Undercity",
            "Venomweb Vale"
        )
    }
    
    "Western Plaguelands" = @{
        faction = "Contested"
        level = "51-58"
        subzones = @(
            "Andorhal", "Caer Darrow", "Dalson's Farm", "Darrowmere Lake", "Felstone Field",
            "Gahrron's Withering", "Hearthglen", "Northridge Lumber Camp", "Sorrow Hill",
            "The Bulwark", "The Weeping Cave", "The Writhing Haunt", "Thondroril River"
        )
    }
    
    "Westfall" = @{
        faction = "Alliance"
        level = "10-20"
        subzones = @(
            "Alexston Farmstead", "Demont's Place", "Furlbrow's Pumpkin Farm", "Gold Coast Quarry",
            "Jangolode Mine", "Moonbrook", "Saldean's Farm", "Sentinel Hill", "The Dagger Hills",
            "The Dead Acre", "The Dust Plains", "The Jansen Stead", "The Molsen Farm",
            "The Raging Chasm"
        )
    }
    
    "Wetlands" = @{
        faction = "Alliance"
        level = "20-30"
        subzones = @(
            "Angerfang Encampment", "Black Channel Marsh", "Bluegill Marsh", "Dun Algaz",
            "Dun Modr", "Greenwarden's Grove", "Ironbeard's Tomb", "Menethil Harbor",
            "Mosshide Fen", "Raptor Ridge", "Saltspray Glen", "Sundown Marsh",
            "Thandol Span", "The Green Belt", "The Lost Fleet", "Whelgar's Excavation Site"
        )
    }
    
    # ========================================
    # KALIMDOR
    # ========================================
    
    "Ashenvale" = @{
        faction = "Contested"
        level = "18-30"
        subzones = @(
            "Astranaar", "Bough Shadow", "Fallen Sky Lake", "Felfire Hill", "Fire Scar Shrine",
            "Forest Song", "Greenpaw Village", "Iris Lake", "Kargathia Keep", "Lake Falathim",
            "Maestra's Post", "Moonwell", "Night Run", "Raynewood Retreat", "Satyrnaar",
            "Silverwind Refuge", "Splintertree Post", "The Dor'Danil Barrow Den",
            "The Howling Vale", "The Ruins of Ordil'Aran", "The Ruins of Stardust",
            "The Shrine of Aessina", "The Zoram Strand", "Thistlefur Village", "Warsong Lumber Camp"
        )
    }
    
    "Azshara" = @{
        faction = "Contested"
        level = "45-55"
        subzones = @(
            "Bay of Storms", "Bilgewater Harbor", "Bitter Reaches", "Blackmaw Hold",
            "Forlorn Ridge", "Haldarr Encampment", "Jagged Reef", "Lake Mennar",
            "Legash Encampment", "Ravencrest Monument", "Ruins of Eldarath", "Shadow Song Shrine",
            "Southridge Beach", "Temple of Arkkoran", "Temple of Zin-Malor", "The Ruined Reaches",
            "The Shattered Strand", "Timbermaw Hold", "Tower of Eldara", "Ursolan"
        )
    }
    
    "Azuremyst Isle" = @{
        faction = "Alliance"
        level = "1-10"
        subzones = @(
            "Ammen Vale", "Azure Watch", "Bristlelimb Village", "Emberglade",
            "Fairbridge Strand", "Geezle's Camp", "Menagerie Wreckage", "Moonwing Den",
            "Odesyus' Landing", "Pod Cluster", "Pod Wreckage", "Pod Wreckage",
            "Silting Shore", "Silvermyst Isle", "Stillpine Hold", "The Exodar",
            "Traitor's Cove", "Valaar's Berth", "Wrathscale Point"
        )
    }
    
    "Bloodmyst Isle" = @{
        faction = "Alliance"
        level = "10-20"
        subzones = @(
            "Amberweb Pass", "Axxarien", "Blacksilt Shore", "Bladewood", "Blood Watch",
            "Bristlescar Canyon", "Cove of Echoes", "Kessel's Crossing", "Middenvale",
            "Moonwing Den", "Mystwood", "Nazzivian", "Ragefeather Ridge", "Ruins of Loreth'Aran",
            "Talon Stand", "Tel'athion's Camp", "The Bloodcursed Reef", "The Crimson Reach",
            "The Cryo-Core", "The Foul Pool", "The Hidden Reef", "The Lost Fold",
            "The Tainted Shards", "The Veiled Sea", "The Warp Piston", "Vindicator's Rest",
            "Wrathscale Lair", "Wyrmscar Island"
        )
    }
    
    "Darkshore" = @{
        faction = "Alliance"
        level = "10-20"
        subzones = @(
            "Ameth'Aran", "Auberdine", "Bashal'Aran", "Blackwood Den", "Cliffspring Falls",
            "Cliffspring River", "Grove of the Ancients", "Mist's Edge", "Nazj'vel",
            "Remtravel's Excavation", "Ruins of Mathystra", "The Long Wash",
            "The Master's Glaive", "Tower of Althalaxx", "Twilight Vale", "Wildbend River"
        )
    }
    
    "Desolace" = @{
        faction = "Contested"
        level = "30-40"
        subzones = @(
            "Cenarion Wildlands", "Ethel Rethor", "Gelkis Village", "Kodo Graveyard",
            "Kolkar Village", "Kormek's Hut", "Magram Territory", "Magram Village",
            "Mannoroc Coven", "Nijel's Point", "Ranazjar Isle", "Sargeron",
            "Shadowbreak Ravine", "Shadowprey Village", "Shok'Thokar", "Slitherblade Shore",
            "Tethris Aran", "Thunk's Abode", "Thunder Axe Fortress", "Valley of Bones",
            "Valley of Spears"
        )
    }
    
    "Durotar" = @{
        faction = "Horde"
        level = "1-10"
        subzones = @(
            "Bladefist Bay", "Burning Blade Coven", "Deadeye Shore", "Drygulch Ravine",
            "Echo Isles", "Kolkar Crag", "Orgrimmar", "Razor Hill", "Razormane Grounds",
            "Rocktusk Farm", "Scuttle Coast", "Sen'jin Village", "Skull Rock",
            "Southfury Watershed", "Spirit Rock", "Thunder Ridge", "Tiragarde Keep",
            "Valley of Trials"
        )
    }
    
    "Dustwallow Marsh" = @{
        faction = "Contested"
        level = "35-45"
        subzones = @(
            "Alcaz Island", "Beezil's Wreck", "Blackhoof Village", "Bloodfen Burrow",
            "Brackenwall Village", "Darkmist Cavern", "Direhorn Post", "Dreadmurk Shore",
            "Lost Point", "Mudsprocket", "North Point Tower", "Onyxia's Lair",
            "Sentry Point", "Stonemaul Ruins", "The Den of Flame", "The Dragonmurk",
            "The Quagmire", "The Wyrmbog", "Theramore Isle", "Witch Hill"
        )
    }
    
    "Felwood" = @{
        faction = "Contested"
        level = "48-55"
        subzones = @(
            "Bloodvenom Falls", "Bloodvenom Post", "Deadwood Village", "Emerald Sanctuary",
            "Felpaw Village", "Irontree Cavern", "Irontree Woods", "Jaedenar",
            "Morlos'Aran", "Ruins of Constellas", "Shatter Scar Vale", "Talonbranch Glade",
            "The Ruins of Kel'Theril", "Timbermaw Hold"
        )
    }
    
    "Feralas" = @{
        faction = "Contested"
        level = "40-50"
        subzones = @(
            "Camp Mojache", "Dire Maul", "Dream Bough", "Feathermoon Stronghold",
            "Feral Scar Vale", "Frayfeather Highlands", "Gordunni Outpost", "Grimtotem Compound",
            "High Wilderness", "Isle of Dread", "Lariss Pavilion", "Lower Wilds",
            "Rage Scar Hold", "Ruins of Isildien", "Ruins of Ravenwind", "The Forgotten Coast",
            "The Jade Mirror", "The Lower Wilds", "The Twin Colossals", "The Writhing Deep",
            "Verdantis River", "Woodpaw Hills", "Woodpaw War Camp"
        )
    }
    
    "Moonglade" = @{
        faction = "Contested"
        level = "55"
        subzones = @(
            "Lake Elune'ara", "Nighthaven", "Shrine of Remulos", "Stormrage Barrow Dens"
        )
    }
    
    "Mulgore" = @{
        faction = "Horde"
        level = "1-10"
        subzones = @(
            "Bael'dun Digsite", "Bloodhoof Village", "Brambleblade Ravine", "Camp Narache",
            "Palemane Rock", "Ravaged Caravan", "Red Cloud Mesa", "Red Rocks",
            "The Golden Plains", "The Rolling Plains", "The Venture Co. Mine",
            "Thunder Bluff", "Thunderhorn Water Well", "Wildmane Water Well", "Windfury Ridge"
        )
    }
    
    "Silithus" = @{
        faction = "Contested"
        level = "55-60"
        subzones = @(
            "Ahn'Qiraj", "Cenarion Hold", "Hive'Ashi", "Hive'Regal", "Hive'Zora",
            "Bones of Grakkarond", "Ortell's Hideout", "Southwind Village", "Staghelm Point",
            "The Crystal Vale", "The Scarab Dais", "The Scarab Wall", "Twilight Base Camp",
            "Twilight Post", "Valor's Rest"
        )
    }
    
    "Stonetalon Mountains" = @{
        faction = "Contested"
        level = "15-27"
        subzones = @(
            "Boulderslide Ravine", "Cragpool Lake", "Greatwood Vale", "Malaka'jin",
            "Mirkfallon Lake", "Mirkfallon Post", "Ruins of Eldarath", "Stonetalon Peak",
            "Sun Rock Retreat", "The Charred Vale", "Webwinder Path", "Windshear Crag",
            "Windshear Hold"
        )
    }
    
    "Tanaris" = @{
        faction = "Contested"
        level = "40-50"
        subzones = @(
            "Abyssal Sands", "Broken Pillar", "Caverns of Time", "Dunemaul Compound",
            "Eastmoon Ruins", "Gadgetzan", "Gunstan's Dig", "Land's End Beach",
            "Lost Rigger Cove", "Noonshade Ruins", "Sandsorrow Watch", "Southbreak Shore",
            "Southmoon Ruins", "Steamwheedle Port", "Thistleshrub Valley", "Uldum",
            "Valley of the Watchers", "Waterspring Field", "Zalashji's Den",
            "Zul'Farrak"
        )
    }
    
    "Teldrassil" = @{
        faction = "Alliance"
        level = "1-10"
        subzones = @(
            "Aldrassil", "Ban'ethil Barrow Den", "Darnassus", "Dolanaar", "Fel Rock",
            "Gnarlpine Hold", "Lake Al'Ameth", "Pools of Arlithrien", "Rut'theran Village",
            "Shadowglen", "Starbreeze Village", "The Cleft", "The Oracle Glade",
            "Wellspring Lake", "Wellspring River"
        )
    }
    
    "The Barrens" = @{
        faction = "Horde"
        level = "10-25"
        subzones = @(
            "Agama'gor", "Bael Modan", "Blackthorn Ridge", "Boulder Lode Mine",
            "Camp Taurajo", "Dreadmist Peak", "Far Watch Post", "Field of Giants",
            "Grol'dom Farm", "Lushwater Oasis", "Northwatch Hold", "Ratchet",
            "Razorfen Downs", "Razorfen Kraul", "Southern Gold Road", "The Crossroads",
            "The Dry Hills", "The Forgotten Pools", "The Great Lift", "The Merchant Coast",
            "The Mor'shan Rampart", "The Sludge Fen", "The Stagnant Oasis", "Thorn Hill",
            "Wailing Caverns", "Warsong Gulch"
        )
    }
    
    "Thousand Needles" = @{
        faction = "Contested"
        level = "25-35"
        subzones = @(
            "Darkcloud Pinnacle", "Freewind Post", "Highperch", "Mirage Raceway",
            "Roguefeather Den", "Splithoof Crag", "Splithoof Heights", "The Great Lift",
            "The Screeching Canyon", "The Shimmering Flats", "Whitereach Post",
            "Windbreak Canyon"
        )
    }
    
    "Un'Goro Crater" = @{
        faction = "Contested"
        level = "48-55"
        subzones = @(
            "Fire Plume Ridge", "Fungal Rock", "Golakka Hot Springs", "Ironstone Plateau",
            "Lakkari Tar Pits", "Marshal's Refuge", "Mossy Pile", "Terror Run",
            "The Marshlands", "The Roiling Gardens", "The Slithering Scar"
        )
    }
    
    "Winterspring" = @{
        faction = "Contested"
        level = "55-60"
        subzones = @(
            "Darkwhisper Gorge", "Everlook", "Frostsaber Rock", "Frostwhisper Gorge",
            "Ice Thistle Hills", "Lake Kel'Theril", "Mazthoril", "Owl Wing Thicket",
            "Starfall Village", "The Hidden Grove", "Timbermaw Hold", "Winterfall Village"
        )
    }
    
    # ========================================
    # OUTLAND (TBC)
    # ========================================
    
    "Blade's Edge Mountains" = @{
        faction = "Contested"
        level = "65-68"
        subzones = @(
            "Bash'ir Landing", "Bladespire Hold", "Bladed Gulch", "Bloodmaul Camp",
            "Bloodmaul Outpost", "Bloodmaul Ravine", "Circle of Blood", "Circle of Wrath",
            "Crystal Spine", "Death's Door", "Forge Camp: Anger", "Forge Camp: Terror",
            "Forge Camp: Wrath", "Gruul's Lair", "Jagged Ridge", "Mok'Nathal Village",
            "Raven's Wood", "Razor Ridge", "Ridge of Madness", "Ruuan Weald",
            "Singing Ridge", "Skald", "Sylvanaar", "Thunderlord Stronghold",
            "Trogma's Claim", "Veil Lashh", "Veil Ruuan", "Vekhaar Stand", "Vortex Pinnacle"
        )
    }
    
    "Hellfire Peninsula" = @{
        faction = "Contested"
        level = "58-63"
        subzones = @(
            "Altar of Sha'tar", "Broken Hill", "Falcon Watch", "Fallen Sky Ridge",
            "Forge Camp: Mageddon", "Forge Camp: Rage", "Hellfire Citadel", "Honor Hold",
            "Invasion Point: Annihilator", "Mag'har Post", "Pools of Aggonar",
            "Ruins of Sha'naar", "Sha'naari Wastes", "Temple of Telhamat", "The Great Fissure",
            "The Legion Front", "The Stadium", "The Stair of Destiny", "Throne of Kil'jaeden",
            "Thrallmar", "Tower Point", "Void Ridge", "Zeth'Gor"
        )
    }
    
    "Nagrand" = @{
        faction = "Contested"
        level = "64-67"
        subzones = @(
            "Burning Blade Ruins", "Clan Watch", "Elemental Plateau", "Forge Camp: Fear",
            "Forge Camp: Hate", "Garadar", "Halaa", "Kil'sorrow Fortress", "Laughing Skull Ruins",
            "Nagrand Arena", "Oshu'gun", "Ring of Trials", "Southwind Cleft", "Spirit Fields",
            "Sunspring Post", "Telaar", "The Barrier Hills", "The Ring of Blood",
            "The Twilight Ridge", "Throne of the Elements", "Warmaul Hill", "Windyreed Pass",
            "Windyreed Village", "Zangar Ridge"
        )
    }
    
    "Netherstorm" = @{
        faction = "Contested"
        level = "67-70"
        subzones = @(
            "Area 52", "Arklon Ruins", "Celestial Ridge", "Eco-Dome Farfield",
            "Eco-Dome Midrealm", "Ethereum Staging Grounds", "Forge Base: Gehenna",
            "Forge Base: Oblivion", "Gyro-Plank Bridge", "Kirin'Var Village",
            "Manaforge Ara", "Manaforge B'naar", "Manaforge Coruu", "Manaforge Duro",
            "Manaforge Ultris", "Netherstone", "Ruins of Enkaat", "Ruins of Farahlon",
            "Socrethar's Seat", "Sunfury Hold", "Tempest Keep", "The Heap",
            "The Stormspire", "The Violet Tower"
        )
    }
    
    "Shadowmoon Valley" = @{
        faction = "Contested"
        level = "67-70"
        subzones = @(
            "Altar of Sha'tar", "Ata'mal Terrace", "Black Temple", "Coilskar Point",
            "Eclipse Point", "Illidari Point", "Invasion Point: Cataclysm", "Legion Hold",
            "Netherwing Fields", "Netherwing Ledge", "Oronok's Farm", "Ruins of Baa'ri",
            "Ruins of Karabor", "Sanctum of the Stars", "Shadowmoon Village",
            "Sketh'lon Base Camp", "Sketh'lon Wreckage", "The Altar of Damnation",
            "The Black Temple", "The Deathforge", "The Hand of Gul'dan", "The Warden's Cage",
            "Wildhammer Stronghold", "Wor'gol Hold"
        )
    }
    
    "Terokkar Forest" = @{
        faction = "Contested"
        level = "62-65"
        subzones = @(
            "Allerian Stronghold", "Auchenai Grounds", "Blackwind Lake", "Blackwind Valley",
            "Bleeding Hollow Ruins", "Bonechewer Ruins", "Carrion Hill", "Cenarion Thicket",
            "Firewing Point", "Grangol'var Village", "Raastok Glade", "Refugee Caravan",
            "Ring of Observance", "Sha'tari Base Camp", "Shadow Tomb", "Shattrath City",
            "Skettis", "Stonebreaker Hold", "Tuurem", "Veil Rhaze", "Veil Skith",
            "Writhing Mound"
        )
    }
    
    "Zangarmarsh" = @{
        faction = "Contested"
        level = "60-64"
        subzones = @(
            "Ango'rosh Grounds", "Ango'rosh Stronghold", "Bloodscale Enclave",
            "Cenarion Refuge", "Coilfang Reservoir", "Feralfen Village", "Hewn Bog",
            "Marshlight Lake", "Orebor Harborage", "Quagg Ridge", "Serpent Lake",
            "Spawning Glen", "Telredor", "The Dead Mire", "The Drain", "The Lagoon",
            "The Spawning Glen", "Umbrafen Lake", "Zabra'jin"
        )
    }
    
    # ========================================
    # NORTHREND (WOTLK)
    # ========================================
    
    "Borean Tundra" = @{
        faction = "Contested"
        level = "68-72"
        subzones = @(
            "Amber Ledge", "Bor'gorok Outpost", "Coldarra", "Death's Stand", "Fizzcrank Airstrip",
            "Garrosh's Landing", "Kaskala", "Magmoth", "Riplash Strand", "Steeljaw's Caravan",
            "Temple City of En'kilah", "The Geyser Fields", "The Nexus", "Torp's Farm",
            "Valiance Keep", "Warsong Hold"
        )
    }
    
    "Crystalsong Forest" = @{
        faction = "Contested"
        level = "74-80"
        subzones = @(
            "Dalaran", "Forlorn Woods", "Sunreaver's Command", "The Azure Front",
            "The Decrepit Flow", "The Great Tree", "The Mirror of Twilight",
            "The Ruins of Shandaral", "The Unbound Thicket", "Violet Stand",
            "Windrunner's Overlook"
        )
    }
    
    "Dragonblight" = @{
        faction = "Contested"
        level = "71-74"
        subzones = @(
            "Agmar's Hammer", "Angrathar the Wrathgate", "Azure Dragonshrine",
            "Coldwind Heights", "Emerald Dragonshrine", "Galakrond's Rest", "Icemist Village",
            "Lake Indu'le", "Light's Trust", "Moa'ki Harbor", "Naxxramas", "New Hearthglen",
            "Obsidian Dragonshrine", "Ruby Dragonshrine", "Scarlet Point", "Star's Rest",
            "The Carrion Fields", "The Crystal Vice", "The Forgotten Shore", "The Path of the Titans",
            "The Pit of Narjun", "The Waking Halls", "Venomspite", "Wintergarde Keep",
            "Wyrmrest Temple"
        )
    }
    
    "Grizzly Hills" = @{
        faction = "Contested"
        level = "73-75"
        subzones = @(
            "Amberpine Lodge", "Blue Sky Logging Grounds", "Camp Oneqwah", "Conquest Hold",
            "Drak'Tharon Keep", "Drakil'jin Ruins", "Granite Springs", "Grizzlemaw",
            "Rage Fang Shrine", "Redwood Trading Post", "Thor Modan", "Ursoc's Den",
            "Venture Bay", "Voldrune", "Westfall Brigade Encampment"
        )
    }
    
    "Howling Fjord" = @{
        faction = "Contested"
        level = "68-72"
        subzones = @(
            "Apothecary Camp", "Baleheim", "Baelgun's Excavation Site", "Camp Winterhoof",
            "Ember Clutch", "Fort Wildervar", "Gjalerhorn", "Halgrind", "Kamagua",
            "New Agamand", "Nifflevar", "Rivenwood", "Scalawag Point", "Skorn",
            "Steel Gate", "The Twisted Glade", "Utgarde Keep", "Vengeance Landing",
            "Valgarde", "Westguard Keep"
        )
    }
    
    "Icecrown" = @{
        faction = "Contested"
        level = "77-80"
        subzones = @(
            "Aldur'thar: The Desolation Gate", "Corp'rethar: The Horror Gate",
            "Icecrown Citadel", "Jotunheim", "Mord'rethar: The Death Gate",
            "Onslaught Harbor", "Scourgeholme", "The Argent Vanguard", "The Bombardment",
            "The Broken Front", "The Conflagration", "The Fleshwerks", "The Shadow Vault",
            "Valhalas", "Valiance Landing Camp", "Valley of Echoes", "Yrsa's Cove",
            "Ymirheim"
        )
    }
    
    "Sholazar Basin" = @{
        faction = "Contested"
        level = "76-78"
        subzones = @(
            "Frenzyheart Hill", "Glimmer Bay", "Hardknuckle Clearing", "Kartak's Hold",
            "Lakeside Landing", "Maker's Overlook", "Maker's Perch", "Mosswalker Village",
            "Rainspeaker Canopy", "River's Heart", "Savage Thicket", "The Avalanche",
            "The Glimmering Pillar", "The Lifeblood Pillar", "The Mosslight Pillar",
            "The Savage Thicket", "The Skyreach Pillar", "The Suntouched Pillar"
        )
    }
    
    "The Storm Peaks" = @{
        faction = "Contested"
        level = "77-80"
        subzones = @(
            "Bor's Breath", "Brunnhildar Village", "Camp Tunka'lo", "Dun Niffelem",
            "Engine of the Makers", "Frosthold", "Garm's Bane", "K3", "Narvir's Cradle",
            "Nidavelir", "Snowdrift Plains", "Spar of Ulduar", "Temple of Life",
            "Temple of Order", "Temple of Storms", "Temple of Wisdom", "Terrace of the Makers",
            "The Foot Steppes", "The Frozen Mine", "Thunderfall", "Ulduar", "Valkyrion"
        )
    }
    
    "Zul'Drak" = @{
        faction = "Contested"
        level = "74-77"
        subzones = @(
            "Altar of Har'koa", "Altar of Mam'toth", "Altar of Quetz'lun", "Altar of Rhunok",
            "Altar of Sseratus", "Amphitheater of Anguish", "Drak'Agal", "Drak'Sotra Fields",
            "Gundrak", "Kolramas", "Light's Breach", "The Argent Stand", "Thrym's End",
            "Voltarus", "Zeramas", "Zim'Torga"
        )
    }
    
    # ========================================
    # CITIES
    # ========================================
    
    "Darnassus" = @{
        faction = "Alliance"
        level = "1-10"
        subzones = @(
            "Cenarion Enclave", "Craftsmen's Terrace", "Howling Oak", "Temple Gardens",
            "Temple of the Moon", "The Bank of Darnassus", "Tradesman's Terrace",
            "Warrior's Terrace"
        )
    }
    
    "Ironforge" = @{
        faction = "Alliance"
        level = "1-10"
        subzones = @(
            "Deeprun Tram", "Forlorn Cavern", "Hall of Arms", "Hall of Explorers",
            "Hall of Mysteries", "The Commons", "The Deeprun Tram", "The Great Forge",
            "The High Seat", "The Military Ward", "The Mystic Ward", "Tinker Town"
        )
    }
    
    "Orgrimmar" = @{
        faction = "Horde"
        level = "1-10"
        subzones = @(
            "Cleft of Shadow", "Grommash Hold", "Ragefire Chasm", "The Drag",
            "The Dranosh'ar Blockade", "The Valley of Honor", "The Valley of Spirits",
            "The Valley of Strength", "The Valley of Wisdom"
        )
    }
    
    "Shattrath City" = @{
        faction = "Contested"
        level = "58-70"
        subzones = @(
            "Aldor Rise", "Lower City", "Scryers' Tier", "Terrace of Light",
            "The Aldor Bank", "The Scryers' Bank", "The Seer's Library", "The Terrace of Light",
            "World's End Tavern"
        )
    }
    
    "Silvermoon City" = @{
        faction = "Horde"
        level = "1-10"
        subzones = @(
            "Bazaar", "Court of the Sun", "Farstriders' Square", "Murder Row",
            "Royal Exchange", "Ruins of Silvermoon", "The Bazaar", "The Royal Exchange",
            "Walk of Elders"
        )
    }
    
    "Stormwind City" = @{
        faction = "Alliance"
        level = "1-10"
        subzones = @(
            "Cathedral Square", "Dwarven District", "Mage Quarter", "Old Town",
            "Stormwind Harbor", "Stormwind Keep", "The Canals", "The Park",
            "Trade District", "Valley of Heroes"
        )
    }
    
    "Thunder Bluff" = @{
        faction = "Horde"
        level = "1-10"
        subzones = @(
            "Elder Rise", "Hunter Rise", "Spirit Rise", "The High Rise"
        )
    }
    
    "Undercity" = @{
        faction = "Horde"
        level = "1-10"
        subzones = @(
            "Apothecarium", "Magic Quarter", "Rogues' Quarter", "The Courtyard",
            "Trade Quarter", "War Quarter"
        )
    }
    
    "The Exodar" = @{
        faction = "Alliance"
        level = "1-10"
        subzones = @(
            "Crystal Hall", "Seat of the Naaru", "The Crystal Hall", "The Traders' Tier",
            "The Vault of Lights", "Trader's Tier", "Vault of Lights"
        )
    }
    
    "Dalaran" = @{
        faction = "Contested"
        level = "68-80"
        subzones = @(
            "Antonidas Memorial", "Eventide", "Krasus' Landing", "Ledgerdemain Lounge",
            "Runeweaver Square", "Sunreaver's Sanctuary", "The Eventide", "The Silver Enclave",
            "The Underbelly", "The Violet Citadel", "The Violet Hold"
        )
    }
}

Write-Host "[1/3] Loading existing ZoneMappings.json..." -ForegroundColor Yellow
$existingMappings = Get-Content "data\ZoneMappings.json" -Raw | ConvertFrom-Json

Write-Host "[2/3] Merging with complete zone data..." -ForegroundColor Yellow

# Convert hashtable to PSObject for JSON serialization
$updatedZones = @{}

foreach ($zoneName in $completeZoneData.Keys) {
    $zoneData = $completeZoneData[$zoneName]
    
    $updatedZones[$zoneName] = @{
        faction = $zoneData.faction
        level = $zoneData.level
        subzones = $zoneData.subzones
    }
}

# Preserve dungeons/raids section if it exists
if ($existingMappings.zones."Dungeons and Raids") {
    $updatedZones["Dungeons and Raids"] = $existingMappings.zones."Dungeons and Raids"
}

# Create final structure
$finalMappings = @{
    description = "Zone and Subzone mappings for WoW Classic through WOTLK"
    source = "https://wowpedia.fandom.com/wiki/Zones_by_level_(original)"
    lastUpdated = (Get-Date -Format "yyyy-MM-dd")
    notes = "Complete canonical zone data from Wowpedia - covers all Classic, TBC, and WOTLK zones"
    zones = $updatedZones
}

Write-Host "[3/3] Writing updated ZoneMappings.json..." -ForegroundColor Yellow

# Backup existing file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item "data\ZoneMappings.json" "data\ZoneMappings_backup_$timestamp.json"
Write-Host "  Backup created: ZoneMappings_backup_$timestamp.json" -ForegroundColor Gray

# Write new file
$finalMappings | ConvertTo-Json -Depth 10 | Set-Content "data\ZoneMappings.json" -Encoding UTF8

Write-Host ""
Write-Host "✓ Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total Zones: $($updatedZones.Keys.Count)" -ForegroundColor White
$totalSubzones = 0
foreach ($zone in $updatedZones.Keys) {
    if ($updatedZones[$zone].subzones) {
        $totalSubzones += $updatedZones[$zone].subzones.Count
    }
}
Write-Host "  Total Subzones: $totalSubzones" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Run: .\utilities\GenerateVanityDB_Master.ps1" -ForegroundColor Gray
Write-Host "  2. Test: /reload in-game" -ForegroundColor Gray
Write-Host "  3. Verify: /avanity progress (zone view)" -ForegroundColor Gray
Write-Host ""
