local Composer = {}
ApogeePartyHealthBars.Define("Core", "ChatComposer", Composer)

local SAY_UNAVAILABLE = "Blizzard's say-chat sender is unavailable on this client."

local function isFunction(value)
    return type(value) == "function"
end

local function validText(value)
    return type(value) == "string" and value:find("%S") ~= nil
end

local function getSendChatFunction()
    if C_ChatInfo and isFunction(C_ChatInfo.SendChatMessage) then
        return C_ChatInfo.SendChatMessage
    end
    if isFunction(SendChatMessage) then return SendChatMessage end
    return nil
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
