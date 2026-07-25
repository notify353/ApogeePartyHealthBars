local DungeonBoard = ApogeePartyHealthBars_DungeonBoardRuntime
local GroupFinder = ApogeePartyHealthBars_DungeonBoardGroupFinder

ApogeePartyHealthBars_RuntimeDungeonBoardEvents = {}
local D = ApogeePartyHealthBars_RuntimeDungeonBoardEvents

local function ingestChatMessage(
    source,
    text, playerName, channelName, zoneChannelID, channelIndex, channelBaseName,
    lineID, guid)
    DungeonBoard.Ingest({
        source = source,
        message = text,
        sender = playerName,
        guid = guid,
        channelName = channelName,
        channelBaseName = channelBaseName,
        channelIndex = channelIndex,
        zoneChannelID = zoneChannelID,
        lineID = lineID,
    })
end

function D.Register(eventRouter)
    assert(type(eventRouter) == "table" and type(eventRouter.Subscribe) == "function",
        "RuntimeDungeonBoardEvents requires an event router")

    eventRouter.Subscribe("PLAYER_LOGIN", "DungeonBoard", function()
        DungeonBoard.Initialize()
        if ApogeePartyHealthBars_DungeonBoardFeed then
            ApogeePartyHealthBars_DungeonBoardFeed.RestorePosition()
        end
    end)

    eventRouter.Subscribe("CHAT_MSG_CHANNEL", "DungeonBoard", function(
        _, text, playerName, _, channelName, _, _, zoneChannelID, channelIndex,
        channelBaseName, _, lineID, guid)
        ingestChatMessage(
            "channel",
            text, playerName, channelName, zoneChannelID, channelIndex, channelBaseName,
            lineID, guid)
    end)

    eventRouter.Subscribe("CHAT_MSG_GUILD", "DungeonBoard", function(
        _, text, playerName, _, channelName, _, _, zoneChannelID, channelIndex,
        channelBaseName, _, lineID, guid)
        ingestChatMessage(
            "guild",
            text, playerName, channelName, zoneChannelID, channelIndex, channelBaseName,
            lineID, guid)
    end)

    local function subscribeGroupFinderEvent(event, callback)
        if type(eventRouter.RegisterOptional) == "function" then
            return eventRouter.RegisterOptional(event, "DungeonBoard", callback)
        end
        return eventRouter.Subscribe(event, "DungeonBoard", callback)
    end

    subscribeGroupFinderEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED", function()
        GroupFinder.HandleSearchResultsReceived()
    end)

    subscribeGroupFinderEvent("LFG_LIST_UPDATE_SEARCH_RESULTS", function()
        GroupFinder.HandleSearchResultsUpdated()
    end)

    subscribeGroupFinderEvent("LFG_LIST_SEARCH_FAILED", function(_, reason)
        GroupFinder.HandleSearchFailed(reason)
    end)

    subscribeGroupFinderEvent("LFG_LIST_SEARCH_RESULT_UPDATED",
        function(_, resultID)
            GroupFinder.HandleSearchResultUpdated(resultID)
        end)
end
