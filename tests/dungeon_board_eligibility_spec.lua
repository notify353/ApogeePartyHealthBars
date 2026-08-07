dofile("DungeonBoard/DungeonBoardCatalog.lua")
dofile("DungeonBoard/DungeonBoardEligibility.lua")
local Eligibility = ApogeePartyHealthBars_DungeonBoardEligibility

local chat = {
    source = "channel",
    dungeonKeys = { "WC" },
    neededRoles = { "tank", "healer" },
    heroic = false,
}
assert(Eligibility.NormalizeRole("tank") == "tank"
        and Eligibility.NormalizeRole("healer") == "healer"
        and Eligibility.NormalizeRole("both") == "healer"
        and Eligibility.NormalizeRole("off") == "healer"
        and Eligibility.NormalizeRole("anything") == "healer",
    "watched-role normalization changed")
assert(Eligibility.NeedsRole(chat, "tank") and Eligibility.NeedsRole(chat, "healer")
        and not Eligibility.NeedsRole(chat, "damage"),
    "needed-role lookup changed")
local defaultBelow, defaultAbove = Eligibility.GetDefaultLevelOffsets()
local defaultWindow = Eligibility.GetLevelWindow(60)
assert(defaultBelow == 10 and defaultAbove == 3
        and defaultWindow.minLevel == 50 and defaultWindow.maxLevel == 63
        and defaultWindow.playerLevel == 60,
    "default Dungeon Board level window changed")
local normalizedBelow, normalizedAbove =
    Eligibility.NormalizeLevelOffsets(-2, 100)
assert(normalizedBelow == 0 and normalizedAbove == 60
        and Eligibility.GetLevelWindow(2, 10, 3).minLevel == 1,
    "Dungeon Board level-window normalization changed")
assert(not Eligibility.IsBoardVisible(chat, "tank", 20)
        and not Eligibility.IsBoardVisible(chat, "healer", 20)
        and not Eligibility.IsFeedOpportunity(chat, "tank", 20)
        and not Eligibility.IsFeedOpportunity(chat, "healer", 20),
    "both-role request entered a single-role board or feed")

local tankOnly = {
    source = "channel", dungeonKeys = { "WC" },
    neededRoles = { "tank" }, heroic = false,
}
local healerOnly = {
    source = "channel", dungeonKeys = { "WC" },
    neededRoles = { "healer" }, heroic = false,
}
assert(Eligibility.IsBoardVisible(tankOnly, "tank", 20)
        and not Eligibility.IsBoardVisible(tankOnly, "healer", 20)
        and Eligibility.IsBoardVisible(healerOnly, "healer", 20)
        and not Eligibility.IsBoardVisible(healerOnly, "tank", 20),
    "single-role views did not require the opposite role to be covered")

local noRole = {
    source = "channel", dungeonKeys = { "WC" }, neededRoles = {}, heroic = false,
}
assert(not Eligibility.IsBoardVisible(noRole, "tank", 20)
        and not Eligibility.IsFeedOpportunity(noRole, "tank", 20),
    "generic LFM became a role opportunity")

local heroic = {
    source = "channel", dungeonKeys = { "RAMPS" },
    neededRoles = { "healer" }, heroic = true,
}
assert(not Eligibility.IsBoardVisible(heroic, "healer", 69)
        and Eligibility.IsBoardVisible(heroic, "healer", 70),
    "heroic level eligibility changed")

local ubrs = {
    source = "guild", dungeonKeys = { "UBRS" },
    neededRoles = { "tank" }, heroic = false,
}
assert(Eligibility.IsBoardVisible(ubrs, "tank", 60)
        and not Eligibility.IsFeedOpportunity(ubrs, "tank", 60),
    "UBRS board exception or LFG Alerts exclusion changed")

local official = {
    source = "blizzard",
    dungeonKeys = { "WC" },
    neededRoles = { "tank" },
    activityRanges = { WC = { minLevel = 18, maxLevel = 24 } },
}
assert(Eligibility.IsBoardVisible(official, "tank", 17)
        and Eligibility.IsBoardVisible(official, "tank", 18)
        and Eligibility.IsBoardVisible(official, "tank", 24)
        and not Eligibility.IsBoardVisible(official, "healer", 24)
        and Eligibility.IsBoardVisible(official, "tank", 25)
        and Eligibility.IsBoardVisible(
            official, "tank", 25, Eligibility.GetLevelWindow(25, 0, 0))
        and not Eligibility.IsBoardVisible(official, "tank", 36),
    "official catalog-window or role filtering changed")
assert(not Eligibility.IsFeedOpportunity(official, "tank", 20),
    "official listing entered real-time LFG Alerts")

local allClassicKeys = {}
for _, dungeon in ipairs(ApogeePartyHealthBars_DungeonBoardCatalog.GetDungeons(
    "classicEra"))
do
    allClassicKeys[#allClassicKeys + 1] = dungeon.key
end
local level37Window = Eligibility.GetLevelWindow(37, 5, 5)
local expectedLevel37Keys = "GNO,RFK,SMG,SML,SMA,SMC,RFD,ULD,MAR"
for _, source in ipairs({ "channel", "blizzard" }) do
    local entry = {
        source = source,
        dungeonKeys = allClassicKeys,
        neededRoles = { "healer" },
        heroic = false,
        activityRanges = {
            BFD = { minLevel = 1, maxLevel = 60 },
            STK = { minLevel = 1, maxLevel = 60 },
        },
    }
    assert(table.concat(Eligibility.GetEligibleDungeonKeys(
            entry, 37, level37Window), ",") == expectedLevel37Keys,
        source .. " listing did not use displayed catalog ranges for Lv 32-42")
end

print("PASS Dungeon Board eligibility")
