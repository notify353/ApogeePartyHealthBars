local played = {}
local filters = {}
local saved = {
    mentionAlertsEnabled = true,
    mentionSoundKey = "toast",
    mentionHighlightEnabled = true,
}

function ChatFrame_AddMessageEventFilter(event, callback)
    filters[event] = callback
end

ApogeePartyHealthBars_MentionAlerts = nil
dofile("ApogeePartyHealthBars_MentionAlerts.lua")
local M = ApogeePartyHealthBars_MentionAlerts

M.Initialize({
    GetSavedVariables = function() return saved end,
    GetPlayerName = function() return "Apogee" end,
    GetPlayerGUID = function() return "Player-1" end,
    Sounds = {
        NormalizeKey = function(key, fallback)
            if key == "none" or key == "toast" or key == "glass" then return key end
            return fallback
        end,
        Play = function(key) played[#played + 1] = key; return key ~= "none" end,
    },
})

assert(M.IsMention("hey Apogee!"), "punctuated short name did not match")
assert(M.IsMention("APOGEE-Realm, invite?"), "case-insensitive realm name did not match")
assert(not M.IsMention("Apogeeish is not the player"), "longer word falsely matched")
assert(not M.IsMention("preApogee"), "prefixed word falsely matched")

local highlighted = M.HighlightMessage("Apogee, ask APOGEE-Realm")
assert(highlighted == "|cffffd100Apogee|r, ask |cffffd100APOGEE-Realm|r",
    "all name occurrences were not highlighted")

assert(M.HandleMessage("Apogee Apogee", "Other", "Player-2"),
    "incoming mention did not alert")
assert(#played == 1 and played[1] == "toast", "one message did not play exactly one sound")
assert(not M.HandleMessage("Apogee", "Apogee-Realm", nil), "own sender name alerted")
assert(not M.HandleMessage("Apogee", "Other", "Player-1"), "own sender GUID alerted")

saved.mentionSoundKey = "none"
assert(M.HandleMessage("Apogee", "Other", "Player-2"), "silent mention was not detected")
assert(#played == 2 and played[2] == "none", "None sound was not passed through safely")

saved.mentionHighlightEnabled = false
local _, unchanged = M.FilterMessage(nil, "CHAT_MSG_SAY", "Apogee", "Other")
assert(unchanged == "Apogee", "disabled highlighting changed the message")
saved.mentionHighlightEnabled = true
local _, filtered = M.FilterMessage(nil, "CHAT_MSG_SAY", "Hi Apogee", "Other")
assert(filtered == "Hi |cffffd100Apogee|r", "chat filter did not highlight")

local subscriptions = {}
M.Register({
    Subscribe = function(event, owner, callback)
        subscriptions[event] = { owner = owner, callback = callback }
    end,
})
for _, event in ipairs(M.GetEvents()) do
    assert(subscriptions[event] and subscriptions[event].owner == "MentionAlerts",
        "missing event subscription: " .. event)
    assert(filters[event] == M.FilterMessage, "missing chat filter: " .. event)
end

saved.mentionAlertsEnabled = false
assert(not M.HandleMessage("Apogee", "Other", "Player-2"), "disabled alerts still fired")
assert(#played == 2, "disabled alerts played sound")

assert(M.SetSoundKey("glass") and saved.mentionSoundKey == "glass",
    "sound selection did not persist")
assert(M.PreviewSound() and played[#played] == "glass", "sound preview failed")

print("PASS mention alerts")
