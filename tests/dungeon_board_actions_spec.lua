local whoCalls = {}
local whisperCalls = {}
SendChatMessage = function()
    error("whisper action must not send chat automatically")
end

Enum = {
    SocialWhoOrigin = { Chat = 7 },
    GameRule = { IngameWhoListDisabled = 11 },
}
C_GameRules = {
    IsGameRuleActive = function(rule)
        assert(rule == 11, "Who availability checked an unexpected game rule")
        return false
    end,
}
C_FriendList = {
    SendWho = function(playerName, origin)
        whoCalls[#whoCalls + 1] = { playerName, origin }
    end,
}
ChatFrameUtil = {
    SendTellWithMessage = function(playerName, message)
        whisperCalls[#whisperCalls + 1] = { playerName, message }
    end,
}

dofile("DungeonBoard/DungeonBoardActions.lua")
local Actions = ApogeePartyHealthBars_DungeonBoardActions

local available, reason = Actions.CanQueryWho(nil)
assert(not available and reason == "Player name is unavailable.",
    "Who accepted a missing player name")
assert(Actions.QueryWho("Player-Realm"),
    "Who rejected a supported realm-qualified player")
assert(#whoCalls == 1 and whoCalls[1][1] == "Player-Realm"
        and whoCalls[1][2] == Enum.SocialWhoOrigin.Chat,
    "Who did not preserve the exact name or use Blizzard's Chat origin")

C_GameRules.IsGameRuleActive = function() return true end
available, reason = Actions.CanQueryWho("Player-Realm")
assert(not available and reason:find("unavailable", 1, true),
    "Who ignored Blizzard's disabled Who-list rule")
C_GameRules.IsGameRuleActive = function() return false end

assert(Actions.OpenWhisper("Player-Realm", "healer", "WC"),
    "whisper rejected a supported realm-qualified player")
assert(#whisperCalls == 1 and whisperCalls[1][1] == "Player-Realm"
        and whisperCalls[1][2]
            == "Healer LF WC",
    "whisper did not prefill the native composer for the exact player and dungeon")

ChatFrameUtil = nil
ChatFrame_SendTellWithMessage = function(playerName, message)
    whisperCalls[#whisperCalls + 1] = { "legacy:" .. playerName, message }
end
assert(Actions.OpenWhisper("Legacy-Realm", "tank", "BRD")
        and whisperCalls[2][1] == "legacy:Legacy-Realm"
        and whisperCalls[2][2]
            == "Tank LF BRD",
    "whisper did not prefill the Classic legacy composer")
ChatFrame_SendTellWithMessage = nil
ChatFrameUtil = {
    SendTellWithMessage = function(playerName, message)
        whisperCalls[#whisperCalls + 1] = { playerName, message }
    end,
}
assert(Actions.OpenWhisper("Player-Realm", "healer", "")
        and whisperCalls[3][2] == "Healer LFG",
    "whisper without a dungeon did not use the terse role-only fallback")
ChatFrameUtil = nil
available, reason = Actions.CanWhisper("Player-Realm")
assert(not available and reason:find("unavailable", 1, true),
    "whisper accepted a missing native composer")
available, reason = Actions.CanWhisper(nil)
assert(not available and reason == "Player name is unavailable.",
    "whisper accepted a missing player name")

C_FriendList.SendWho = function() error("expected who failure") end
local queried, queryFailure = Actions.QueryWho("Player-Realm")
assert(not queried and queryFailure:find("expected who failure", 1, true),
    "Who API failure was not returned to the UI")

ChatFrameUtil = {
    SendTellWithMessage = function() error("expected whisper failure") end,
}
local whispered, whisperFailure = Actions.OpenWhisper(
    "Player-Realm", "healer", "WC")
assert(not whispered and whisperFailure:find("expected whisper failure", 1, true),
    "whisper API failure was not returned to the UI")
assert(#whisperCalls == 3,
    "whisper action unexpectedly sent or recorded an additional message")

assert(C_FriendList ~= nil,
    "action tests unexpectedly persisted Dungeon Board data")
print("PASS Dungeon Board player actions")
