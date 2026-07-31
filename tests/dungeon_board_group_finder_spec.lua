dofile("DungeonBoard/DungeonBoardCatalog.lua")
dofile("DungeonBoard/DungeonBoardEligibility.lua")
dofile("DungeonBoard/DungeonBoardGroupFinder.lua")
local GroupFinder = ApogeePartyHealthBars_DungeonBoardGroupFinder
local Eligibility = ApogeePartyHealthBars_DungeonBoardEligibility

local now = 100
local playerLevel = 70
local levelsBelow, levelsAbove = 10, 3
local available = true
local canUse, canUseReason = true, nil
local searchCalls = {}
local replacements = {}
local removed
local currentResultIDs = {}
local resultInfo = {}
local counts = {}
local activityInfo = {
    [101] = {
        categoryID = 2, maxNumPlayers = 5, minLevelSuggestion = 17,
        maxLevelSuggestion = 25, isNormalActivity = true, isHeroicActivity = false,
    },
    [201] = {
        categoryID = 2, maxNumPlayers = 5, minLevelSuggestion = 59,
        maxLevelSuggestion = 67, isNormalActivity = true, isHeroicActivity = false,
    },
    [202] = {
        categoryID = 2, maxNumPlayers = 5, minLevelSuggestion = 70,
        maxLevelSuggestion = 70, isNormalActivity = false, isHeroicActivity = true,
    },
    [203] = {
        categoryID = 2, maxNumPlayers = 5, minLevelSuggestion = 70,
        maxLevelSuggestion = 70, isNormalActivity = false, isHeroicActivity = true,
    },
    [999] = {
        categoryID = 2, maxNumPlayers = 10, minLevelSuggestion = 58,
        maxLevelSuggestion = 70, isNormalActivity = true, isHeroicActivity = false,
    },
}
local mapped = {
    [101] = { id = 101, key = "WC", expansion = "classicEra", heroic = false },
    [201] = { id = 201, key = "RAMPS", expansion = "tbcAnniversary", heroic = false },
    [202] = { id = 202, key = "RAMPS", expansion = "tbcAnniversary", heroic = true },
    [203] = { id = 203, key = "BF", expansion = "tbcAnniversary", heroic = true },
    [999] = { id = 999, key = "UBRS", expansion = "classicEra", heroic = false },
}
local activities = { mapped[101], mapped[201], mapped[202], mapped[203], mapped[999] }
local hook

local API = {
    Search = function(...)
        searchCalls[#searchCalls + 1] = { ... }
    end,
    GetSearchResults = function()
        return #currentResultIDs, currentResultIDs
    end,
    GetSearchResultInfo = function(resultID) return resultInfo[resultID] end,
    GetSearchResultMemberCounts = function(resultID) return counts[resultID] end,
    GetActivityInfoTable = function(activityID) return activityInfo[activityID] end,
    CanPlayerUsePremadeGroup = function() return canUse, canUseReason end,
}

GroupFinder.Initialize({
    Runtime = {
        ReplaceOfficialRequests = function(entries, atTime)
            replacements[#replacements + 1] = { entries = entries, atTime = atTime }
        end,
        RemoveOfficialRequest = function(resultID)
            removed = resultID
            return true
        end,
        GetOfficialSnapshot = function() return { { resultID = 77 } } end,
    },
    ActivityData = {
        GetActivities = function(clientFlavor)
            return clientFlavor == "tbcAnniversary" and activities or { mapped[101], mapped[999] }
        end,
        GetActivity = function(activityID, clientFlavor)
            local value = mapped[activityID]
            if value and (value.expansion == "classicEra" or clientFlavor == "tbcAnniversary") then
                return value
            end
        end,
    },
    Catalog = ApogeePartyHealthBars_DungeonBoardCatalog,
    Settings = {
        GetLevelWindow = function(level)
            return Eligibility.GetLevelWindow(level, levelsBelow, levelsAbove)
        end,
    },
    ClientCapabilities = {
        IsFeatureAvailable = function() return available end,
        GetFeatureReason = function() return "unsupported client" end,
    },
    API = API,
    GetClientFlavor = function() return "tbcAnniversary" end,
    GetPlayerLevel = function() return playerLevel end,
    Now = function() return now end,
    HookSearch = function(callback) hook = callback end,
})

assert(#searchCalls == 0 and GroupFinder.GetStatus().status == "idle",
    "Group Finder searched automatically during initialization")
assert(type(hook) == "function", "native/add-on search hook was not installed")
assert(GroupFinder.GetSnapshot()[1].resultID == 77,
    "Group Finder snapshot interface did not delegate to official runtime state")

assert(GroupFinder.RequestRefresh(), "hardware-click refresh did not start")
assert(#searchCalls == 1 and searchCalls[1][1] == 2
        and searchCalls[1][2] == 0 and searchCalls[1][3] == 0
        and searchCalls[1][4].enUS == true and searchCalls[1][5] == false
        and searchCalls[1][6] == nil
        and #searchCalls[1][7] == 3
        and searchCalls[1][7][1] == 201
        and searchCalls[1][7][2] == 202 and searchCalls[1][7][3] == 203,
    "refresh did not use English, configured-window, five-player activity filters")
assert(GroupFinder.GetStatus().status == "searching",
    "refresh did not enter the searching state")

resultInfo[10] = {
    searchResultID = 10, activityIDs = { 202 }, leaderName = "Tankless",
    name = "Heroic Ramparts", comment = "Need tank", hasSelf = false,
    numMembers = 3, isDelisted = false, partyGUID = "Party-10",
}
counts[10] = {
    TANK = 0, HEALER = 1, DAMAGER = 2,
    TANK_REMAINING = 1, HEALER_REMAINING = 0,
}
resultInfo[11] = {
    activityIDs = { 202 }, numMembers = 2, isDelisted = true, hasSelf = false,
}
resultInfo[12] = {
    activityIDs = { 202 }, numMembers = 2, isDelisted = false, hasSelf = true,
}
resultInfo[13] = {
    activityIDs = { 202 }, numMembers = 5, isDelisted = false, hasSelf = false,
}
resultInfo[14] = {
    activityIDs = { 201 }, numMembers = 2, isDelisted = false, hasSelf = false,
}
counts[14] = { TANK_REMAINING = 1, HEALER_REMAINING = 0 }
resultInfo[15] = {
    searchResultID = 15, activityIDs = { 202, 203, 101 }, leaderName = "Mixed",
    name = "Runs", comment = "Need heals", hasSelf = false,
    numMembers = 1, isDelisted = false, partyGUID = "Party-15",
}
counts[15] = { TANK_REMAINING = 0, HEALER_REMAINING = 1 }
resultInfo[16] = {
    activityIDs = { 555 }, numMembers = 2, isDelisted = false, hasSelf = false,
}
resultInfo[17] = {
    activityIDs = { 201 }, numMembers = 2, isDelisted = false, hasSelf = false,
}
counts[17] = { TANK_REMAINING = 0, HEALER_REMAINING = 0 }
resultInfo[18] = {
    activityIDs = { 201 }, numMembers = 2, isDelisted = false, hasSelf = false,
}
counts[18] = { TANK_REMAINING = 1, HEALER_REMAINING = 1 }
currentResultIDs = { 10, 11, 12, 13, 14, 15, 16, 17, 18 }
now = 110
GroupFinder.HandleSearchResultsReceived()
local replacement = replacements[#replacements]
assert(#replacement.entries == 3 and replacement.atTime == 110,
    "completed search did not replace results with eligible listings")
assert(replacement.entries[1].resultID == 10
        and replacement.entries[1].status == "matched"
        and replacement.entries[1].difficulty == "heroic"
        and replacement.entries[1].numMembers == 3
        and table.concat(replacement.entries[1].neededRoles, ",") == "tank"
        and replacement.entries[1].memberCounts.TANK_REMAINING == 1,
    "official Tank listing was parsed incorrectly")
assert(replacement.entries[2].resultID == 14
        and replacement.entries[2].difficulty == "normal"
        and table.concat(replacement.entries[2].dungeonKeys, ",") == "RAMPS",
    "normal official listing inside the configured window was filtered out")
assert(replacement.entries[3].resultID == 15
        and replacement.entries[3].status == "matched"
        and table.concat(replacement.entries[3].dungeonKeys, ",") == "RAMPS,BF"
        and table.concat(replacement.entries[3].neededRoles, ",") == "healer",
    "structured multi-dungeon activities were treated as ambiguous or filtered incorrectly")
for _, entry in ipairs(replacement.entries) do
    assert(#entry.neededRoles == 1,
        "official listing needing zero or both support roles entered the snapshot")
end
local status = GroupFinder.GetStatus()
assert(status.status == "ready" and status.lastRefreshAt == 110
        and status.failureReason == nil,
    "completed search state was not retained")

now = 115
local updateReplacementCount = #replacements
GroupFinder.HandleSearchResultsUpdated()
status = GroupFinder.GetStatus()
assert(#replacements == updateReplacementCount + 1
        and status.status == "ready" and status.lastRefreshAt == 110,
    "listing-only update was mistaken for a newly completed search")

local replacementCount = #replacements
GroupFinder.HandleSearchFailed("busy")
status = GroupFinder.GetStatus()
assert(status.status == "failed" and status.failureReason == "busy"
        and status.lastRefreshAt == 110 and #replacements == replacementCount,
    "failed refresh discarded prior listings or successful refresh time")

now = 120
GroupFinder.HandleSearchResultsUpdated()
status = GroupFinder.GetStatus()
assert(status.status == "failed" and status.failureReason == "busy"
        and status.lastRefreshAt == 110,
    "listing-only update cleared a failed refresh state or changed its age")

resultInfo[10].isDelisted = true
GroupFinder.HandleSearchResultUpdated(10)
assert(removed == 10, "delisted result was not removed")
currentResultIDs = { 15 }
local beforeUpdateReplacementCount = #replacements
GroupFinder.HandleSearchResultUpdated(15)
assert(#replacements == beforeUpdateReplacementCount + 1
        and replacements[#replacements].entries[1].resultID == 15,
    "live official listing update did not replace the official snapshot")

hook()
assert(GroupFinder.GetStatus().status == "searching" and #searchCalls == 1,
    "native/add-on search did not update status or triggered a second search")
GroupFinder.HandleSearchResultsReceived()
assert(GroupFinder.GetStatus().status == "ready",
    "native/add-on search results were not ingested")

canUse, canUseReason = false, "restricted"
assert(not GroupFinder.RequestRefresh()
        and GroupFinder.GetStatus().failureReason == "restricted"
        and #searchCalls == 1,
    "Group Finder eligibility failure still invoked Search")

canUse = true
available = false
assert(not GroupFinder.RequestRefresh()
        and GroupFinder.GetStatus().failureReason == "unsupported client"
        and #searchCalls == 1,
    "capability fallback still invoked Search")

print("PASS Dungeon Board manual Group Finder adapter")
