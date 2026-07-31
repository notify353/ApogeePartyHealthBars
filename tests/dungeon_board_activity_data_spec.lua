dofile("DungeonBoard/DungeonBoardCatalog.lua")
dofile("DungeonBoard/DungeonBoardActivityData.lua")
local Catalog = ApogeePartyHealthBars_DungeonBoardCatalog
local ActivityData = ApogeePartyHealthBars_DungeonBoardActivityData

local expectedClassicIDs = {
    796, 797, 798, 799, 800, 801, 802, 803, 804, 805, 806, 807, 808,
    809, 810, 811, 812, 813, 814, 815, 816, 827, 828, 829, 1603,
}
local expectedTbcIDs = {
    817, 913, 818, 912, 819, 914, 820, 909, 821, 911, 822, 910, 823, 904,
    824, 903, 825, 905, 826, 906, 830, 908, 831, 907, 832, 916, 833, 918,
    834, 915, 835, 917,
}

local function assertIDs(actual, expected, label)
    assert(#actual == #expected, label .. " activity count changed")
    for index, definition in ipairs(actual) do
        assert(definition.id == expected[index],
            label .. " activity order changed at " .. tostring(index))
    end
end

local classic = ActivityData.GetActivities("classicEra")
assertIDs(classic, expectedClassicIDs, "Classic")

local tbc = ActivityData.GetActivities("tbcAnniversary")
local expectedAll = {}
for _, id in ipairs(expectedClassicIDs) do expectedAll[#expectedAll + 1] = id end
for _, id in ipairs(expectedTbcIDs) do expectedAll[#expectedAll + 1] = id end
assertIDs(tbc, expectedAll, "TBC")
assert(#ActivityData.GetActivities("unsupported") == 0,
    "unsupported clients received activity IDs")

local seenIDs = {}
local tbcNormalKeys, tbcHeroicKeys = {}, {}
for _, definition in ipairs(tbc) do
    assert(not seenIDs[definition.id], "duplicate activity ID " .. tostring(definition.id))
    seenIDs[definition.id] = true
    assert(Catalog.IsFivePlayer(definition.key),
        definition.key .. " mapped a non-five-player activity")
    if definition.expansion == "tbcAnniversary" then
        local target = definition.heroic and tbcHeroicKeys or tbcNormalKeys
        target[definition.key] = (target[definition.key] or 0) + 1
    else
        assert(not definition.heroic, "Classic activity was marked heroic")
    end
end
for _, key in ipairs({
    "RAMPS", "BF", "SH", "SP", "UB", "SV", "MT", "CRYPTS",
    "SETH", "SL", "OHB", "BM", "MECH", "BOT", "ARC", "MGT",
}) do
    assert(tbcNormalKeys[key] == 1 and tbcHeroicKeys[key] == 1,
        key .. " did not have exactly one normal and heroic activity")
end
assert(ActivityData.GetActivity(837, "classicEra") == nil,
    "UBRS was included in official five-player activities")
assert(ActivityData.GetActivity(917, "classicEra") == nil
        and ActivityData.GetActivity(917, "tbcAnniversary").heroic,
    "client filtering or heroic lookup changed")

print("PASS Dungeon Board activity mapping")
