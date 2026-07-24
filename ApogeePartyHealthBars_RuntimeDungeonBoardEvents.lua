local DungeonBoard = ApogeePartyHealthBars_DungeonBoardRuntime

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
end
