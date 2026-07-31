ApogeePartyHealthBars_DungeonBoardActions = {}
local Actions = ApogeePartyHealthBars_DungeonBoardActions

local PLAYER_UNAVAILABLE = "Player name is unavailable."
local WHO_UNAVAILABLE = "Blizzard's Who lookup is unavailable on this client."
local WHISPER_UNAVAILABLE = "Blizzard's whisper composer is unavailable on this client."

local function isFunction(value)
    return type(value) == "function"
end

local function validPlayerName(playerName)
    return type(playerName) == "string" and playerName:find("%S") ~= nil
end

local function whoIsDisabled()
    if not C_GameRules or not isFunction(C_GameRules.IsGameRuleActive)
        or not Enum or not Enum.GameRule
        or Enum.GameRule.IngameWhoListDisabled == nil
    then
        return false
    end
    local ok, disabled = pcall(
        C_GameRules.IsGameRuleActive, Enum.GameRule.IngameWhoListDisabled)
    return ok and disabled == true
end

local function getWhisperFunction()
    if ChatFrameUtil and isFunction(ChatFrameUtil.SendTellWithMessage) then
        return ChatFrameUtil.SendTellWithMessage
    end
    if isFunction(ChatFrame_SendTellWithMessage) then
        return ChatFrame_SendTellWithMessage
    end
    return nil
end

function Actions.CanQueryWho(playerName)
    if not validPlayerName(playerName) then return false, PLAYER_UNAVAILABLE end
    if not C_FriendList or not isFunction(C_FriendList.SendWho)
        or not Enum or not Enum.SocialWhoOrigin
        or Enum.SocialWhoOrigin.Chat == nil
        or whoIsDisabled()
    then
        return false, WHO_UNAVAILABLE
    end
    return true
end

function Actions.QueryWho(playerName)
    local available, reason = Actions.CanQueryWho(playerName)
    if not available then return false, reason end
    local ok, failure = pcall(
        C_FriendList.SendWho, playerName, Enum.SocialWhoOrigin.Chat)
    if not ok then
        return false, "Could not query Who: " .. tostring(failure)
    end
    return true
end

function Actions.CanWhisper(playerName)
    if not validPlayerName(playerName) then return false, PLAYER_UNAVAILABLE end
    if not getWhisperFunction() then return false, WHISPER_UNAVAILABLE end
    return true
end

function Actions.OpenWhisper(playerName, role, dungeonText)
    local available, reason = Actions.CanWhisper(playerName)
    if not available then return false, reason end
    local roleText = role == "tank" and "Tank" or "Healer"
    local destination = type(dungeonText) == "string"
        and dungeonText:find("%S") and dungeonText or "this dungeon"
    local message = "Hi, do you still need a " .. roleText
        .. " for " .. destination .. "?"
    local ok, failure = pcall(getWhisperFunction(), playerName, message)
    if not ok then
        return false, "Could not open whisper: " .. tostring(failure)
    end
    return true
end
