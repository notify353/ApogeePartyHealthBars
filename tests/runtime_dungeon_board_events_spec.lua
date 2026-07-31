local initialized = 0
local ingested
ApogeePartyHealthBars_DungeonBoardRuntime = {
    Initialize = function() initialized = initialized + 1 end,
    Ingest = function(data) ingested = data end,
}
local groupFinderCalls = {}
ApogeePartyHealthBars_DungeonBoardGroupFinder = {
    HandleSearchResultsReceived = function()
        groupFinderCalls[#groupFinderCalls + 1] = "received"
    end,
    HandleSearchResultsUpdated = function()
        groupFinderCalls[#groupFinderCalls + 1] = "list-updated"
    end,
    HandleSearchFailed = function(reason)
        groupFinderCalls[#groupFinderCalls + 1] = "failed:" .. tostring(reason)
    end,
    HandleSearchResultUpdated = function(resultID)
        groupFinderCalls[#groupFinderCalls + 1] = "updated:" .. tostring(resultID)
    end,
}

dofile("Runtime/DungeonBoardEvents.lua")
local Events = ApogeePartyHealthBars_DungeonBoardEvents

local valid, validationError = pcall(Events.Register, {})
assert(not valid and tostring(validationError):find("event router", 1, true),
    "Dungeon Board events accepted an invalid router")

local subscriptions = {}
local optionalEvents = {}
local router = {
    Subscribe = function(event, owner, callback)
        subscriptions[event] = { owner = owner, callback = callback }
    end,
    RegisterOptional = function(event, owner, callback)
        optionalEvents[event] = true
        subscriptions[event] = { owner = owner, callback = callback }
        return true
    end,
}
Events.Register(router)
assert(subscriptions.PLAYER_LOGIN and subscriptions.CHAT_MSG_CHANNEL
    and subscriptions.CHAT_MSG_GUILD and subscriptions.LFG_LIST_SEARCH_RESULTS_RECEIVED
    and subscriptions.LFG_LIST_UPDATE_SEARCH_RESULTS
    and subscriptions.LFG_LIST_SEARCH_FAILED
    and subscriptions.LFG_LIST_SEARCH_RESULT_UPDATED,
    "Dungeon Board event subscriptions are incomplete")
assert(optionalEvents.LFG_LIST_SEARCH_RESULTS_RECEIVED
        and optionalEvents.LFG_LIST_UPDATE_SEARCH_RESULTS
        and optionalEvents.LFG_LIST_SEARCH_FAILED
        and optionalEvents.LFG_LIST_SEARCH_RESULT_UPDATED,
    "optional Group Finder events became required for live chat monitoring")
assert(subscriptions.PLAYER_LOGIN.owner == "DungeonBoard"
    and subscriptions.CHAT_MSG_CHANNEL.owner == "DungeonBoard"
    and subscriptions.CHAT_MSG_GUILD.owner == "DungeonBoard",
    "Dungeon Board event owner changed")

subscriptions.PLAYER_LOGIN.callback("PLAYER_LOGIN")
assert(initialized == 1, "PLAYER_LOGIN did not initialize Dungeon Board runtime")

subscriptions.CHAT_MSG_CHANNEL.callback(
    "CHAT_MSG_CHANNEL",
    "LFM RFC", "Sender-Realm", "Common", "4. LookingForGroup", "Sender-Realm", "",
    26, 4, "LookingForGroup", 7, 12345, "Player-1", 0, false, false, false, false)
assert(ingested and ingested.source == "channel"
    and ingested.message == "LFM RFC" and ingested.sender == "Sender-Realm"
    and ingested.guid == "Player-1" and ingested.channelName == "4. LookingForGroup"
    and ingested.channelBaseName == "LookingForGroup" and ingested.channelIndex == 4
    and ingested.zoneChannelID == 26 and ingested.lineID == 12345,
    "CHAT_MSG_CHANNEL payload was adapted incorrectly")

subscriptions.CHAT_MSG_GUILD.callback(
    "CHAT_MSG_GUILD",
    "LFG ZF", "Guildie-Realm", "Common", "Guild", "Guildie-Realm", "",
    0, 0, "", 7, 54321, "Player-2", 0, false, false, false, false)
assert(ingested and ingested.source == "guild"
    and ingested.message == "LFG ZF" and ingested.sender == "Guildie-Realm"
    and ingested.guid == "Player-2" and ingested.channelName == "Guild"
    and ingested.channelBaseName == "" and ingested.channelIndex == 0
    and ingested.zoneChannelID == 0 and ingested.lineID == 54321,
    "CHAT_MSG_GUILD payload was adapted incorrectly")

subscriptions.LFG_LIST_SEARCH_RESULTS_RECEIVED.callback("LFG_LIST_SEARCH_RESULTS_RECEIVED")
subscriptions.LFG_LIST_UPDATE_SEARCH_RESULTS.callback("LFG_LIST_UPDATE_SEARCH_RESULTS")
subscriptions.LFG_LIST_SEARCH_FAILED.callback("LFG_LIST_SEARCH_FAILED", "busy")
subscriptions.LFG_LIST_SEARCH_RESULT_UPDATED.callback("LFG_LIST_SEARCH_RESULT_UPDATED", 42)
assert(table.concat(groupFinderCalls, ",")
        == "received,list-updated,failed:busy,updated:42",
    "official listing events were not routed correctly")

print("PASS Dungeon Board runtime event adapter")
