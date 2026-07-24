local DungeonBoard = ApogeePartyHealthBars_DungeonBoardRuntime

ApogeePartyHealthBars_RuntimeDungeonBoardEvents = {}
local D = ApogeePartyHealthBars_RuntimeDungeonBoardEvents

function D.Register(eventRouter)
    assert(type(eventRouter) == "table" and type(eventRouter.Subscribe) == "function",
        "RuntimeDungeonBoardEvents requires an event router")

    eventRouter.Subscribe("PLAYER_LOGIN", "DungeonBoard", function()
        DungeonBoard.Initialize()
    end)

    eventRouter.Subscribe("CHAT_MSG_CHANNEL", "DungeonBoard", function(
        _, text, playerName, _, channelName, _, _, zoneChannelID, channelIndex,
        channelBaseName, _, lineID, guid)
        DungeonBoard.Ingest({
            message = text,
            sender = playerName,
            guid = guid,
            channelName = channelName,
            channelBaseName = channelBaseName,
            channelIndex = channelIndex,
            zoneChannelID = zoneChannelID,
            lineID = lineID,
        })
    end)
end
