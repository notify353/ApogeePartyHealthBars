ApogeePartyHealthBars_C = {
    SLOT_UNITS = { "player", "party1", "party2", "party3", "party4" },
    LOW_HEALTH_DEFAULT_THRESHOLD = 50,
    LOW_HEALTH_MIN_THRESHOLD = 10,
    LOW_HEALTH_MAX_THRESHOLD = 90,
    LOW_HEALTH_THRESHOLD_STEP = 5,
    LOW_HEALTH_REARM_MARGIN = 10,
    LOW_HEALTH_SOUND_DEBOUNCE = 2.0,
    LOW_HEALTH_DEFAULT_SOUND = "focus",
}
ApogeePartyHealthBars_S = {
    sv = {
        enabled = true,
        lowHealthSoundKey = "focus",
        lowHealthThreshold = 50,
    },
}

local units = {
    player = { exists = true, connected = true, health = 100, maximum = 100, guid = "Player-1" },
    party1 = { exists = true, connected = true, health = 100, maximum = 100, guid = "Party-1" },
    party2 = { exists = true, connected = true, health = 100, maximum = 100, guid = "Party-2" },
    party3 = { exists = false, connected = true, health = 100, maximum = 100, guid = "Party-3" },
    party4 = { exists = false, connected = true, health = 100, maximum = 100, guid = "Party-4" },
}
local now = 0
local sounds = {}

function UnitExists(unitId) return units[unitId] and units[unitId].exists or false end
function UnitIsConnected(unitId) return units[unitId] and units[unitId].connected or false end
function UnitHealth(unitId) return units[unitId] and units[unitId].health or 0 end
function UnitHealthMax(unitId) return units[unitId] and units[unitId].maximum or 0 end
function UnitGUID(unitId) return units[unitId] and units[unitId].guid or nil end
function GetTime() return now end
function PlaySound(sound, channel) sounds[#sounds + 1] = { sound = sound, channel = channel } end
function PlaySoundFile(sound, channel)
    sounds[#sounds + 1] = { sound = sound, channel = channel }
    return true
end

local callbacks = {}
local router = {}
function router.Subscribe(event, _, callback)
    callbacks[event] = callbacks[event] or {}
    callbacks[event][#callbacks[event] + 1] = callback
end
router.RegisterOptional = router.Subscribe
local function Dispatch(event, unitId)
    for _, callback in ipairs(callbacks[event] or {}) do callback(event, unitId) end
end

dofile("ApogeePartyHealthBars_Sounds.lua")
dofile("ApogeePartyHealthBars_HealthAlerts.lua")
local H = ApogeePartyHealthBars_HealthAlerts
H.Register(router)
Dispatch("PLAYER_LOGIN")

units.party1.health = 50
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 0, "exactly 50% should not alert")
units.party1.health = 49
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 1 and sounds[1].sound:find("Focus.ogg", 1, true)
        and sounds[1].channel == "SFX",
    "party crossing did not use the low-health SFX sound")
units.party1.health = 40
Dispatch("UNIT_HEALTH", "party1")
units.party1.health = 55
Dispatch("UNIT_HEALTH", "party1")
units.party1.health = 49
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 1, "low-health events repeated before 60% recovery")

units.party1.health = 60
Dispatch("UNIT_HEALTH", "party1")
now = 3
units.party1.health = 49
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 2, "60% recovery did not re-arm the alert")

now = 3.5
units.party2.health = 49
Dispatch("UNIT_HEALTH", "party2")
assert(#sounds == 2, "simultaneous party damage bypassed the group cooldown")
now = 6
units.party2.health = 40
Dispatch("UNIT_HEALTH", "party2")
assert(#sounds == 2, "a suppressed crossing played a delayed sound")
units.party2.health = 60
Dispatch("UNIT_HEALTH", "party2")
now = 6.1
units.party2.health = 49
Dispatch("UNIT_HEALTH", "party2")
assert(#sounds == 3, "suppressed party member did not re-arm after recovery")

now = 9
units.player.health = 49
Dispatch("UNIT_HEALTH", "player")
assert(#sounds == 4, "the grouped player did not receive a low-health alert")

units.party1.health = 60
Dispatch("UNIT_HEALTH", "party1")
assert(H.SetSoundKey("none") == "none" and H.GetSoundLabel() == "None",
    "None was not accepted as the consolidated disabled choice")
now = 12
units.party1.health = 49
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 4, "None low-health sound still played")
assert(H.SetSoundKey("alarm_soft") == "alarm_soft")
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 4, "selecting a sound alerted for an already-low member")
units.party1.health = 60
Dispatch("UNIT_HEALTH", "party1")
now = 15
units.party1.health = 49
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 5, "enabled setting did not alert after a fresh crossing")

units.party1.exists = false
units.party2.exists = false
units.player.health = 100
Dispatch("GROUP_ROSTER_UPDATE")
now = 18
units.player.health = 49
Dispatch("UNIT_HEALTH", "player")
assert(#sounds == 5, "solo player received a party-only alert")

units.party1.exists = true
units.party1.connected = true
units.party1.health = 100
units.player.health = 100
Dispatch("GROUP_ROSTER_UPDATE")
units.party1.connected = false
Dispatch("UNIT_CONNECTION", "party1")
units.party1.health = 49
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 5, "disconnected party member received an alert")

units.party1.connected = true
Dispatch("UNIT_CONNECTION", "party1")
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 5, "reconnecting low-health party member received a false alert")
units.party1.health = 100
units.player.health = 60
units.player.maximum = 100
Dispatch("GROUP_ROSTER_UPDATE")
now = 21
units.player.maximum = 130
Dispatch("UNIT_MAXHEALTH", "player")
assert(#sounds == 6, "maximum-health change did not detect a threshold crossing")

units.player.health = 100
units.player.maximum = 100
Dispatch("UNIT_HEALTH", "player")
ApogeePartyHealthBars_S.sv.enabled = false
now = 24
units.player.health = 49
Dispatch("UNIT_HEALTH", "player")
assert(#sounds == 6, "disabled addon still played a low-health alert")
ApogeePartyHealthBars_S.sv.enabled = true
H.Rebaseline()

Dispatch("UNIT_HEALTH", "target")
assert(#sounds == 6, "untracked unit triggered a low-health alert")

assert(H.GetSoundKey() == "alarm_soft" and H.GetSoundLabel() == "Alarm Soft")
assert(H.SetSoundKey("alarm_bell") == "alarm_bell" and H.GetSoundLabel() == "Alarm Bell")
assert(H.SetSoundKey("invalid") == "focus", "invalid dropdown sound did not normalize")
assert(H.SetSoundKey("alarm_bell") == "alarm_bell", "dropdown sound selection did not persist")
assert(H.PreviewSound(), "selected low-health sound did not preview")
assert(#sounds == 7 and sounds[7].sound == 12889 and sounds[7].channel == "SFX",
    "selected low-health sound did not use the shared catalog")
units.party1.health = 60
Dispatch("UNIT_HEALTH", "party1")
units.party1.health = 49
now = 27
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 8 and sounds[8].sound == 12889 and sounds[8].channel == "SFX",
    "low-health crossing did not use the selected sound")

units.party1.health = 100
Dispatch("UNIT_HEALTH", "party1")
assert(H.SetThreshold(70) == 70 and H.GetThreshold() == 70,
    "low-health threshold did not update")
units.party1.health = 70
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 8, "exactly the configured threshold should not alert")
now = 30
units.party1.health = 69
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 9, "configured threshold crossing did not alert")

assert(H.SetThreshold(75) == 75, "second threshold update failed")
units.party1.health = 84
Dispatch("UNIT_HEALTH", "party1")
units.party1.health = 69
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 9, "alert re-armed before the configured recovery margin")
units.party1.health = 85
Dispatch("UNIT_HEALTH", "party1")
now = 33
units.party1.health = 74
Dispatch("UNIT_HEALTH", "party1")
assert(#sounds == 10, "configured recovery margin did not re-arm the alert")

assert(H.SetThreshold(999) == 90, "threshold maximum was not enforced")
assert(H.AdjustThreshold(1) == 90, "threshold increased past its maximum")
assert(H.AdjustThreshold(-1) == 85, "threshold decrement did not use the configured step")
ApogeePartyHealthBars_S.sv.lowHealthThreshold = 73
assert(H.GetThreshold() == 75, "saved threshold did not normalize to a valid step")
ApogeePartyHealthBars_S.sv.lowHealthThreshold = "invalid"
assert(H.GetThreshold() == 50, "invalid threshold did not return to the default")
assert(ApogeePartyHealthBars_S.sv.lowHealthThreshold == 50, "invalid threshold was not repaired")

ApogeePartyHealthBars_S.sv.lowHealthSoundKey = "invalid"
assert(H.GetSoundKey() == "focus", "invalid saved low-health sound did not return to default")
assert(ApogeePartyHealthBars_S.sv.lowHealthSoundKey == "focus", "invalid sound was not repaired")
print("PASS low-health alerts")
