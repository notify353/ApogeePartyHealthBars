local Composer = {}
ApogeePartyHealthBars.Define("Core", "ChatComposer", Composer)

local PLAYER_UNAVAILABLE = "Player name is unavailable."
local WHISPER_UNAVAILABLE = "Blizzard's whisper composer is unavailable on this client."
local SAY_UNAVAILABLE = "Blizzard's say-chat sender is unavailable on this client."

local function isFunction(value)
    return type(value) == "function"
end

local function validText(value)
    return type(value) == "string" and value:find("%S") ~= nil
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

local function getSendChatFunction()
    if C_ChatInfo and isFunction(C_ChatInfo.SendChatMessage) then
        return C_ChatInfo.SendChatMessage
    end
    if isFunction(SendChatMessage) then return SendChatMessage end
    return nil
end

function Composer.CanWhisper(playerName)
    if not validText(playerName) then return false, PLAYER_UNAVAILABLE end
    if not getWhisperFunction() then return false, WHISPER_UNAVAILABLE end
    return true
end

function Composer.OpenWhisper(playerName, message)
    local available, reason = Composer.CanWhisper(playerName)
    if not available then return false, reason end
    if not validText(message) then return false, "Whisper text is unavailable." end
    local ok, failure = pcall(getWhisperFunction(), playerName, message)
    if not ok then
        return false, "Could not open whisper: " .. tostring(failure)
    end
    return true
end

function Composer.CanSendSay()
    if not getSendChatFunction() then return false, SAY_UNAVAILABLE end
    return true
end

function Composer.SendSay(message)
    local available, reason = Composer.CanSendSay()
    if not available then return false, reason end
    if not validText(message) then return false, "Say message text is unavailable." end
    local ok, failure = pcall(getSendChatFunction(), message, "SAY")
    if not ok then
        return false, "Could not send say message: " .. tostring(failure)
    end
    return true
end
