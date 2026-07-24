local initialized = 0
local ingested = {}
ApogeePartyHealthBars_DungeonBoardRuntime = {
    Initialize = function() initialized = initialized + 1 end,
    Ingest = function(data) ingested[#ingested + 1] = data end,
}

local filterEvent, filterCallback, filterRegistrations
filterRegistrations = 0
function ChatFrame_AddMessageEventFilter(event, callback)
    filterEvent = event
    filterCallback = callback
    filterRegistrations = filterRegistrations + 1
end

dofile("ApogeePartyHealthBars_RuntimeDungeonBoardEvents.lua")
local Events = ApogeePartyHealthBars_RuntimeDungeonBoardEvents

local valid, validationError = pcall(Events.Register, {})
assert(not valid and tostring(validationError):find("event router", 1, true),
    "Dungeon Board events accepted an invalid router")

local subscriptions = {}
local router = {
    Subscribe = function(event, owner, callback)
        subscriptions[event] = { owner = owner, callback = callback }
    end,
}
Events.Register(router)
assert(subscriptions.PLAYER_LOGIN and subscriptions.CHAT_MSG_CHANNEL,
    "Dungeon Board event subscriptions are incomplete")
assert(subscriptions.PLAYER_LOGIN.owner == "DungeonBoard"
    and subscriptions.CHAT_MSG_CHANNEL.owner == "DungeonBoard",
    "Dungeon Board event owner changed")

subscriptions.PLAYER_LOGIN.callback("PLAYER_LOGIN")
assert(initialized == 1, "PLAYER_LOGIN did not initialize Dungeon Board runtime")
assert(filterEvent == "CHAT_MSG_CHANNEL" and type(filterCallback) == "function",
    "PLAYER_LOGIN did not install the live chat-filter fallback")
subscriptions.PLAYER_LOGIN.callback("PLAYER_LOGIN")
assert(initialized == 2 and filterRegistrations == 1,
    "live chat-filter fallback was registered more than once")

subscriptions.CHAT_MSG_CHANNEL.callback(
    "CHAT_MSG_CHANNEL",
    "LFM RFC", "Sender-Realm", "Common", "4. LookingForGroup", "Sender-Realm", "",
    26, 4, "LookingForGroup", 7, 12345, "Player-1", 0, false, false, false, false)
local eventData = ingested[1]
assert(eventData and eventData.message == "LFM RFC" and eventData.sender == "Sender-Realm"
    and eventData.guid == "Player-1" and eventData.channelName == "4. LookingForGroup"
    and eventData.channelBaseName == "LookingForGroup" and eventData.channelIndex == 4
    and eventData.zoneChannelID == 26 and eventData.lineID == 12345,
    "CHAT_MSG_CHANNEL payload was adapted incorrectly")

local filterResult = filterCallback(
    {}, "CHAT_MSG_CHANNEL",
    "Need 1 DPS BFD", "Filter-Realm", "Common", "6. LookingForGroup",
    "Filter-Realm", "", 26, 6, "LookingForGroup", 7, 67890, "Player-2",
    0, false, false)
local filterData = ingested[2]
assert(filterResult == nil and filterData and filterData.message == "Need 1 DPS BFD"
    and filterData.sender == "Filter-Realm" and filterData.guid == "Player-2"
    and filterData.channelName == "6. LookingForGroup"
    and filterData.channelBaseName == "LookingForGroup" and filterData.channelIndex == 6
    and filterData.zoneChannelID == 26 and filterData.lineID == 67890,
    "chat-filter fallback altered or incorrectly adapted the channel message")

print("PASS Dungeon Board runtime event adapter")
