ApogeePartyHealthBars_S = { sv = { enabled = true, buffThanksEnabled = true } }

local currentTime = 100
local currentAuras = {}
local auraScanCount = 0
local emotes = {}
local emoteRestricted = false
local currentCombatEvent
local settingsSurfaces = {
    Register = function() end,
    SetSurfaceChromeShown = function() end,
}

UnitGUID = function(unit) return unit == "player" and "Player-Self" or nil end
UnitClassFromGUID = function(guid)
    local classes = {
        ["Player-One"] = "MAGE",
        ["Player-Two"] = "PALADIN",
        ["Player-Party"] = "PRIEST",
        ["Player-Raid"] = "DRUID",
        ["Player-Other"] = "SHAMAN",
    }
    local classToken = classes[guid]
    if classToken then return classToken, classToken, 1 end
end
C_PlayerInfo = { GUIDIsPlayer = function(guid)
    return type(guid) == "string" and guid:find("^Player-") ~= nil
end }
Enum = { CombatLogObject = {
    AffiliationMine = 1, AffiliationParty = 2, AffiliationRaid = 4,
    AffiliationOutsider = 8, TypePlayer = 1024,
} }
local MINE_PLAYER_FLAGS = 1 + 16 + 256 + 1024
local PARTY_PLAYER_FLAGS = 2 + 16 + 256 + 1024
local RAID_PLAYER_FLAGS = 4 + 16 + 256 + 1024
local OUTSIDE_PLAYER_FLAGS = 8 + 16 + 256 + 1024
C_CombatLog = {
    DoesObjectMatchFilter = function(mask, flags)
        return math.floor(flags / mask) % 2 == 1
    end,
    GetCurrentEventInfo = function() return unpack(currentCombatEvent or {}) end,
}
DoEmote = function(token, name)
    emotes[#emotes + 1] = { token, name }
    return emoteRestricted
end

dofile("Reminders/BuffThanks.lua")
local thanks = ApogeePartyHealthBars_BuffThanks
thanks.Initialize({
    Auras = { ScanUnitHelpfulAuras = function(unit)
        assert(unit == "player", "Buff Thanks scanned the wrong aura unit")
        auraScanCount = auraScanCount + 1
        return { auras = currentAuras }
    end },
    ClientCapabilities = {
        IsFeatureAvailable = function(key) return key == "buffThanks" end,
        GetFeatureReason = function() return "unavailable" end,
    },
    SettingsSurfaces = settingsSurfaces,
    Now = function() return currentTime end,
})

local function event(sourceGUID, sourceName, sourceFlags, spellId, spellName, subevent, auraType)
    return {
        0, subevent or "SPELL_AURA_APPLIED", false,
        sourceGUID, sourceName, sourceFlags,
        0, "Player-Self", "Self", 0, 0,
        spellId, spellName, 1, auraType or "BUFF",
    }
end

local function dispelEvent(sourceGUID, sourceName, sourceFlags, removedSpellId,
        removedSpellName, auraType, subevent, destGUID)
    return {
        0, subevent or "SPELL_DISPEL", false,
        sourceGUID, sourceName, sourceFlags,
        0, destGUID or "Player-Self", "Self", 0, 0,
        527, "Purify", 2,
        removedSpellId, removedSpellName, 1, auraType or "DEBUFF",
    }
end

currentAuras = { { spellId = 1243, duration = 1800 } }
IsInGroup = function() return true end
currentCombatEvent = event("Player-One", "Kindmage", OUTSIDE_PLAYER_FLAGS, 1243,
    "Power Word: Fortitude")
assert(thanks.OnCombatLog(), "namespaced Era combat-log event was rejected")
assert(#thanks.GetEntries() == 1
        and thanks.GetEntries()[1].playerName == "Kindmage"
        and thanks.GetEntries()[1].classToken == "MAGE"
        and thanks.GetEntries()[1].reasonNames[1] == "Power Word: Fortitude",
    "outside-player buff was not detected while the recipient was grouped")

thanks.ResetSession()
currentAuras = { { spellId = 1243, duration = 1800, expirationTime = 1000 } }
assert(thanks.HandleCombatLogInfo(event("Player-One", "Kindmage", OUTSIDE_PLAYER_FLAGS, 1243,
        "Power Word: Fortitude")), "old login aura candidate was not observed")
assert(#thanks.GetEntries() == 0 and next(thanks.GetPending()) ~= nil,
    "old login aura created a Thank You prompt")
currentTime = 102
thanks.VerifyPending()
assert(next(thanks.GetPending()) == nil, "old login aura candidate did not expire")

thanks.BeginWorldSession()
currentAuras = { { spellId = 19740, duration = 0 } }
assert(not thanks.HandleCombatLogInfo(event("Player-Two", "Kindpaladin", OUTSIDE_PLAYER_FLAGS, 19740,
        "Blessing of Might")), "permanent login aura bypassed world-entry suppression")
assert(thanks.HandleCombatLogInfo(dispelEvent(
        "Player-Two", "Kindpaladin", OUTSIDE_PLAYER_FLAGS, 54321, "Ancient Curse")),
    "world-entry buff suppression blocked a fresh cleanse")
thanks.ResetSession()
currentTime = 103
assert(thanks.HandleCombatLogInfo(event("Player-Two", "Kindpaladin", OUTSIDE_PLAYER_FLAGS, 19740,
        "Blessing of Might")), "fresh permanent buff remained suppressed after login")
thanks.ResetSession()
currentTime = 100
currentAuras = { { spellId = 1243, duration = 1800 } }
assert(thanks.HandleCombatLogInfo(event("Player-One", "Kindmage", OUTSIDE_PLAYER_FLAGS, 1243,
        "Power Word: Fortitude")), "baseline buff was not restored after login tests")

currentAuras = { { spellId = 139, duration = 29 } }
assert(thanks.HandleCombatLogInfo(event("Player-Two", "Quickheal", OUTSIDE_PLAYER_FLAGS, 139, "Renew")),
    "short aura candidate was not observed")
assert(#thanks.GetEntries() == 1, "short helpful aura created a prompt")
currentTime = 102
thanks.VerifyPending()
assert(next(thanks.GetPending()) == nil, "hidden short-aura candidate did not expire")
currentTime = 100

currentAuras = { { spellId = 19740, duration = 0 } }
assert(thanks.HandleCombatLogInfo(event("Player-Two", "Kindpaladin", OUTSIDE_PLAYER_FLAGS, 19740,
        "Blessing of Might")), "permanent buff was rejected")
assert(#thanks.GetEntries() == 2, "permanent buff did not create a prompt")

currentAuras = { { spellId = 14752, duration = 900 } }
assert(not thanks.HandleCombatLogInfo(event("Player-Party", "Grouped", PARTY_PLAYER_FLAGS, 14752,
        "Divine Spirit")), "party source created a prompt")
assert(not thanks.HandleCombatLogInfo(event("Player-Raid", "Raider", RAID_PLAYER_FLAGS, 14752,
        "Divine Spirit")), "raid source created a prompt")
assert(not thanks.HandleCombatLogInfo(event("Player-Self", "Self", MINE_PLAYER_FLAGS, 14752,
        "Divine Spirit")), "self source created a prompt")
assert(not thanks.HandleCombatLogInfo(event("Creature-1", "NPC", 0, 14752,
        "Divine Spirit")), "NPC source created a prompt")
assert(not thanks.HandleCombatLogInfo(event("Player-Other", "Other", OUTSIDE_PLAYER_FLAGS, 14752,
        "Divine Spirit", "SPELL_AURA_REFRESH")), "refresh created a prompt")
assert(not thanks.HandleCombatLogInfo(event("Player-Other", "Other", OUTSIDE_PLAYER_FLAGS, 14752,
        "Divine Spirit", nil, "DEBUFF")), "debuff created a prompt")

currentAuras = { { spellId = 20217, duration = 600 } }
assert(thanks.HandleCombatLogInfo(event("Player-One", "Kindmage", OUTSIDE_PLAYER_FLAGS, 20217,
        "Blessing of Kings")), "second buff from the same player was rejected")
assert(#thanks.GetEntries() == 2 and #thanks.GetEntries()[1].reasonNames == 2,
    "same-caster buffs were not merged")
thanks.HandleCombatLogInfo(event("Player-One", "Kindmage", OUTSIDE_PLAYER_FLAGS, 20217,
    "Blessing of Kings"))
assert(#thanks.GetEntries()[1].reasonNames == 2, "duplicate buff name was appended")

currentAuras = { { spellId = 1126, duration = 1800 } }
thanks.HandleCombatLogInfo(event("Player-Three", "Druid", OUTSIDE_PLAYER_FLAGS, 1126, "Mark of the Wild"))
currentAuras = { { spellId = 1459, duration = 1800 } }
thanks.HandleCombatLogInfo(event("Player-Four", "Mage", OUTSIDE_PLAYER_FLAGS, 1459, "Arcane Intellect"))
assert(#thanks.GetEntries() == 3 and thanks.GetEntries()[1].guid == "Player-Two"
        and thanks.GetEntries()[3].guid == "Player-Four",
    "fourth caster did not evict the oldest row")

assert(thanks.PerformGesture("Player-Two", "THANK"), "Thank gesture failed")
assert(emotes[1][1] == "THANK" and emotes[1][2] == "Kindpaladin",
    "gesture did not use the selected token and captured player name")
assert(not thanks.PerformGesture("Player-Three", "DANCE"), "unsupported gesture was accepted")
assert(not thanks.PerformGesture("Player-Three", "BOW"), "removed Bow gesture was accepted")
assert(not thanks.PerformGesture("Player-Three", "SALUTE"), "removed Salute gesture was accepted")
assert(not thanks.PerformGesture("Player-Three", "WAVE"), "removed Wave gesture was accepted")
emoteRestricted = true
assert(not thanks.PerformGesture("Player-Three", "THANK")
        and thanks.GetEntries()[1].guid == "Player-Three",
    "restricted emote dismissed its prompt")
emoteRestricted = false
assert(thanks.Dismiss("Player-Three"), "dismiss did not remove a prompt")

currentTime = 131
assert(thanks.Expire(), "expired prompt was not removed")
assert(#thanks.GetEntries() == 0, "expired prompts remained queued")
assert(#thanks.GESTURES == 1 and thanks.GESTURES[1].token == "THANK",
    "Thank was not the sole gratitude action")

thanks.ResetSession()
currentTime = 200
local cleanseCases = {
    { "Player-Party", "Partypriest", PARTY_PLAYER_FLAGS, 12345, "Wicked Curse" },
    { "Player-Raid", "Raidpaladin", RAID_PLAYER_FLAGS, 23456, "Crippling Poison" },
    { "Player-Other", "Kindshaman", OUTSIDE_PLAYER_FLAGS, 34567, "Fevered Disease" },
    { "Player-Magic", "Helpfulpriest", OUTSIDE_PLAYER_FLAGS, 45678, "Arcane Shackles" },
}
for _, cleanse in ipairs(cleanseCases) do
    local scansBeforeCleanse = auraScanCount
    assert(thanks.HandleCombatLogInfo(dispelEvent(unpack(cleanse))),
        "successful player cleanse was rejected: " .. cleanse[5])
    assert(#thanks.GetEntries() == 1
            and thanks.GetEntries()[1].reasonNames[1] == "Cleansed: " .. cleanse[5]
            and auraScanCount == scansBeforeCleanse,
        "successful cleanse was not queued directly: " .. cleanse[5])
    thanks.ResetSession()
end

assert(thanks.HandleCombatLogInfo(dispelEvent(
        "Player-One", "Kindmage", OUTSIDE_PLAYER_FLAGS, 12345, "Wicked Curse")),
    "outside-player cleanse was rejected")
local cleanseExpiry = thanks.GetEntries()[1].expiresAt
currentTime = 205
assert(thanks.HandleCombatLogInfo(dispelEvent(
        "Player-One", "Kindmage", OUTSIDE_PLAYER_FLAGS, 12345, "Wicked Curse"))
        and #thanks.GetEntries()[1].reasonNames == 1
        and thanks.GetEntries()[1].expiresAt > cleanseExpiry,
    "duplicate cleanse did not suppress its label and refresh expiry")
cleanseExpiry = thanks.GetEntries()[1].expiresAt
currentTime = 206
assert(thanks.HandleCombatLogInfo(dispelEvent(
        "Player-One", "Kindmage", OUTSIDE_PLAYER_FLAGS, 23456, "Crippling Poison"))
        and #thanks.GetEntries()[1].reasonNames == 2
        and thanks.GetEntries()[1].reasonNames[2] == "Cleansed: Crippling Poison"
        and thanks.GetEntries()[1].expiresAt > cleanseExpiry,
    "distinct cleanses from one helper did not merge and refresh expiry")
currentAuras = { { spellId = 1243, duration = 1800 } }
assert(thanks.HandleCombatLogInfo(event(
        "Player-One", "Kindmage", OUTSIDE_PLAYER_FLAGS, 1243, "Power Word: Fortitude"))
        and #thanks.GetEntries() == 1
        and #thanks.GetEntries()[1].reasonNames == 3
        and thanks.GetEntries()[1].reasonNames[3] == "Power Word: Fortitude",
    "same-player buff and cleanse did not merge")
local emotesBeforeCombinedThanks = #emotes
assert(thanks.PerformGesture("Player-One", "THANK")
        and #thanks.GetEntries() == 0
        and emotes[emotesBeforeCombinedThanks + 1][1] == "THANK"
        and emotes[emotesBeforeCombinedThanks + 1][2] == "Kindmage",
    "one Thank did not clear a helper's combined cleanse and buff row")
assert(not thanks.HandleCombatLogInfo(event(
        "Player-Party", "Grouped", PARTY_PLAYER_FLAGS, 1243, "Power Word: Fortitude")),
    "group buff became eligible with group cleanses")

for _, rejected in ipairs({
    dispelEvent("Player-Self", "Self", MINE_PLAYER_FLAGS, 111, "Curse"),
    dispelEvent("Pet-1", "Pet", OUTSIDE_PLAYER_FLAGS, 111, "Curse"),
    dispelEvent("Creature-1", "NPC", 0, 111, "Curse"),
    dispelEvent("Player-Other", "Other", OUTSIDE_PLAYER_FLAGS, 111, "Curse", "DEBUFF", "SPELL_DISPEL_FAILED"),
    dispelEvent("Player-Other", "Other", OUTSIDE_PLAYER_FLAGS, 111, "Curse", "DEBUFF", "SPELL_STOLEN"),
    dispelEvent("Player-Other", "Other", OUTSIDE_PLAYER_FLAGS, 111, "Helpful Buff", "BUFF"),
    dispelEvent("Player-Other", "Other", OUTSIDE_PLAYER_FLAGS, 111, "Curse", "DEBUFF", nil, "Player-Else"),
    dispelEvent("Player-Other", "Other", OUTSIDE_PLAYER_FLAGS, 111, "Curse", "DEBUFF", "SPELL_AURA_REMOVED"),
    dispelEvent("Player-Other", "Other", OUTSIDE_PLAYER_FLAGS, 111, nil),
    dispelEvent("Player-Other", nil, OUTSIDE_PLAYER_FLAGS, 111, "Curse"),
}) do
    assert(not thanks.HandleCombatLogInfo(rejected),
        "invalid or non-helpful cleanse event created a prompt")
end

ApogeePartyHealthBars_S.sv.buffThanksEnabled = false
assert(not thanks.HandleCombatLogInfo(dispelEvent(
        "Player-Other", "Other", OUTSIDE_PLAYER_FLAGS, 111, "Curse")),
    "disabled Thank You prompts still captured cleanses")
ApogeePartyHealthBars_S.sv.buffThanksEnabled = true

thanks.ResetSession()
UnitClassFromGUID = nil
C_PlayerInfo, GUIDIsPlayer = nil, nil
assert(not thanks.HandleCombatLogInfo(event("Player-Five", "Unknown", OUTSIDE_PLAYER_FLAGS, 1243,
        "Power Word: Fortitude")),
    "missing player-GUID classifier did not fail closed")
GUIDIsPlayer = function(guid) return guid == "Player-Five" end
CombatLogGetCurrentEventInfo = function() return unpack(currentCombatEvent) end
C_CombatLog.GetCurrentEventInfo = nil
currentCombatEvent = event("Player-Five", "Legacy", OUTSIDE_PLAYER_FLAGS, 1243, "Power Word: Fortitude")
currentAuras = { { spellId = 1243, duration = 1800 } }
assert(thanks.OnCombatLog() and thanks.GetEntries()[1].playerName == "Legacy",
    "legacy combat-log and player-GUID fallbacks failed")

local function uiWidget()
    local value = { scripts = {}, elapsed = 0 }
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:GetScript(name) return self.scripts[name] end
    function value:CreateTexture() return uiWidget() end
    function value:CreateFontString() return uiWidget() end
    function value:GetPoint() return "TOP", UIParent, "TOP", 0, 0 end
    return setmetatable(value, { __index = function()
        return function() end
    end })
end

UIParent = uiWidget()
CreateFrame = function() return uiWidget() end
thanks.ResetSession()
currentTime = 300
currentAuras = {}
assert(thanks.HandleCombatLogInfo(event(
        "Player-Five", "Delayed", OUTSIDE_PLAYER_FLAGS, 1243,
        "Power Word: Fortitude"))
        and #thanks.GetEntries() == 0 and next(thanks.GetPending()) ~= nil,
    "delayed aura was not retained for verification")
thanks.Build()
currentAuras = { { spellId = 1243, duration = 1800, expirationTime = 2100 } }
currentTime = 300.2
local update = thanks.GetFrame():GetScript("OnUpdate")
assert(type(update) == "function", "Thank You frame did not install its retry ticker")
update(thanks.GetFrame(), 0.2)
assert(#thanks.GetEntries() == 1 and next(thanks.GetPending()) == nil,
    "periodic verification did not recover a delayed player aura")

print("PASS Buff Thanks detection, queue, and gestures")
