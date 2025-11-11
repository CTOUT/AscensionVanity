-- Test script to verify Phase 2A migration works
-- Run in-game after /reload: /run dofile("C:\\Repos\\World of Warcraft\\AscensionVanity\\TestMigration.lua")

print("=== Phase 2A Migration Test ===")
print("Testing if config settings were properly migrated...")
print("")

local tests = {
    {"configVersion", 2},
    {"showCreatureInfo", true},
    {"creatureInfoFilter", "vanity"},
    {"showCreatureType", true},
    {"showAttackSpeed", true},
    {"showHealth", true},
    {"showDamage", true},
    {"showArmor", false}
}

local passed = 0
local failed = 0

for _, test in ipairs(tests) do
    local key = test[1]
    local expected = test[2]
    local actual = AscensionVanityDB[key]
    
    if actual == expected then
        print("|cFF00FF00✓|r " .. key .. " = " .. tostring(actual))
        passed = passed + 1
    else
        print("|cFFFF0000✗|r " .. key .. " = " .. tostring(actual) .. " (expected: " .. tostring(expected) .. ")")
        failed = failed + 1
    end
end

print("")
print("Results: " .. passed .. " passed, " .. failed .. " failed")

if failed == 0 then
    print("|cFF00FF00All tests passed! Phase 2A migration successful.|r")
else
    print("|cFFFF0000Some tests failed. Please /reload and try again.|r")
end
