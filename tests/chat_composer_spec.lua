local sent = {}
C_ChatInfo = {
    SendChatMessage = function(message, channel)
        sent[#sent + 1] = { message = message, channel = channel }
    end,
}
dofile("Core/Namespace.lua")
dofile("Core/ChatComposer.lua")
local Composer = ApogeePartyHealthBars.Require("Core", "ChatComposer")

assert(Composer.SendSay("buff up")
        and sent[1].message == "buff up" and sent[1].channel == "SAY",
    "direct say did not send the exact message through Blizzard's chat API")
C_ChatInfo = nil
SendChatMessage = function(message, channel)
    sent[#sent + 1] = { message = "legacy:" .. message, channel = channel }
end
assert(Composer.SendSay("waiting for mana")
        and sent[2].message == "legacy:waiting for mana"
        and sent[2].channel == "SAY",
    "legacy Classic chat sender fallback did not preserve the exact say")

SendChatMessage = nil
local ok, reason = Composer.SendSay("buff up")
assert(not ok and reason:find("unavailable", 1, true),
    "missing direct say capability was accepted")
print("PASS shared chat composer")
