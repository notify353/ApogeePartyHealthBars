dofile("DungeonBoard/DungeonBoardCatalog.lua")
local Catalog = ApogeePartyHealthBars_DungeonBoardCatalog

local expectedClassic = {
    "RFC", "WC", "DM", "SFK", "BFD", "STK", "GNO", "RFK", "SMG", "SML",
    "SMA", "SMC", "RFD", "ULD", "ZF", "MAR", "ST", "BRD", "DME", "DMW",
    "DMN", "STR", "SCH", "LBRS", "UBRS",
}
local expectedTbcOnly = {
    "RAMPS", "BF", "SP", "UB", "MT", "CRYPTS", "OHB", "SETH",
    "SL", "SH", "BM", "SV", "MECH", "BOT", "ARC", "MGT",
}

local function assertKeyList(actual, expected, label)
    assert(#actual == #expected,
        label .. " count changed: expected " .. #expected .. ", got " .. #actual)
    for index, expectedKey in ipairs(expected) do
        assert(actual[index].key == expectedKey,
            label .. " order changed at " .. index .. ": expected " .. expectedKey
                .. ", got " .. tostring(actual[index].key))
    end
end

local classic = Catalog.GetDungeons("classicEra")
assertKeyList(classic, expectedClassic, "Classic dungeon catalog")

local tbcExpected = {}
for _, key in ipairs(expectedClassic) do tbcExpected[#tbcExpected + 1] = key end
for _, key in ipairs(expectedTbcOnly) do tbcExpected[#tbcExpected + 1] = key end
local tbc = Catalog.GetDungeons("tbcAnniversary")
assertKeyList(tbc, tbcExpected, "TBC dungeon catalog")

assert(#Catalog.GetDungeons("unsupported") == 0, "unsupported clients received dungeon data")

local seenKeys = {}
local seenAliases = {}
for _, definition in ipairs(tbc) do
    assert(not seenKeys[definition.key], "duplicate dungeon key: " .. definition.key)
    seenKeys[definition.key] = true
    assert(definition.expansion == "classicEra" or definition.expansion == "tbcAnniversary",
        definition.key .. " has invalid expansion")
    assert(type(definition.name) == "string" and definition.name ~= "",
        definition.key .. " has no English name")
    assert(type(definition.minLevel) == "number" and type(definition.maxLevel) == "number"
        and definition.minLevel <= definition.maxLevel,
        definition.key .. " has invalid level range")
    assert(definition.maxPlayers == 5 or definition.key == "UBRS"
        and definition.maxPlayers == 10,
        definition.key .. " has invalid group size")
    if definition.expansion == "tbcAnniversary" then
        assert(definition.heroicMinLevel == 70,
            definition.key .. " has an invalid heroic level requirement")
    else
        assert(definition.heroicMinLevel == nil,
            definition.key .. " unexpectedly allows heroic classification")
    end
    assert(type(definition.aliases) == "table" and #definition.aliases > 0,
        definition.key .. " has no aliases")

    for index, alias in ipairs(definition.aliases) do
        assert(type(alias) == "string" and alias ~= "", definition.key .. " has an empty alias")
        assert(alias == alias:lower() and alias:match("^[a-z0-9 ]+$")
            and not alias:match("^ ") and not alias:match(" $") and not alias:match("  "),
            definition.key .. " alias is not normalized: " .. alias)
        assert(not seenAliases[alias],
            "unexpected alias collision between " .. definition.key .. " and "
                .. tostring(seenAliases[alias]) .. ": " .. alias)
        seenAliases[alias] = definition.key
        assert(definition.aliases[index] == alias,
            definition.key .. " aliases are not a dense ordered list")
    end
end

local rfc = Catalog.GetDungeon("RFC")
assert(rfc and rfc.name == "Ragefire Chasm", "GetDungeon did not resolve RFC")
rfc.name = "Changed"
rfc.aliases[1] = "changed"
local freshRfc = Catalog.GetDungeon("RFC")
assert(freshRfc.name == "Ragefire Chasm" and freshRfc.aliases[1] == "rfc",
    "catalog callers can mutate private definitions")
assert(Catalog.GetDungeon("UNKNOWN") == nil, "unknown dungeon key resolved unexpectedly")
assert(Catalog.IsFivePlayer("RFC") and not Catalog.IsFivePlayer("UBRS"),
    "five-player catalog boundary changed")
assert(Catalog.IsLevelAppropriate("RFC", 15, false)
        and Catalog.IsLevelAppropriate("RFC", 20, false)
        and not Catalog.IsLevelAppropriate("RFC", 21, false)
        and not Catalog.IsLevelAppropriate("RFC", 20, true)
        and Catalog.IsLevelAppropriate("RAMPS", 70, true)
        and not Catalog.IsLevelAppropriate("RAMPS", 69, true),
    "catalog level eligibility changed")

print("PASS Dungeon Board catalog")
