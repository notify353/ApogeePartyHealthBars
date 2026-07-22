local actionStart, actionDuration, actionEnabled, actionGCD = 10, 8, true, false
local gcdStart, gcdDuration = 20, 1.5
local requestedSpell

C_Spell = {
    GetSpellCooldown = function(identifier)
        requestedSpell = identifier
        if identifier == 29515 then
            return { startTime = gcdStart, duration = gcdDuration, isEnabled = true }
        end
        return {
            startTime = actionStart,
            duration = actionDuration,
            isEnabled = actionEnabled,
            isOnGCD = actionGCD,
        }
    end,
}

dofile("ApogeePartyHealthBars_ActionCooldowns.lua")
local cooldowns = ApogeePartyHealthBars_ActionCooldowns

local start, duration, enabled, reportedGCD = cooldowns.GetSpellCooldown(8092)
assert(start == 10 and duration == 8 and enabled and reportedGCD == false,
    "structured spell cooldown was not normalized")

assert(cooldowns.IsGlobalCooldown(10, 8, true),
    "client-reported global cooldown was ignored")
assert(cooldowns.IsGlobalCooldown(20, 1.5, false) and requestedSpell == 29515,
    "Classic global cooldown probe was not recognized")
assert(not cooldowns.IsGlobalCooldown(20.1, 1.5, false),
    "unrelated short cooldown matched the Classic global cooldown probe")
assert(not cooldowns.IsGlobalCooldown(20, 0, false),
    "zero-duration cooldown was classified as global")

assert(not cooldowns.IsAlertable(1.5, false, false),
    "start recovery met the real-cooldown alert floor")
assert(cooldowns.IsAlertable(1.51, false, false),
    "real cooldown above the alert floor was rejected")
assert(not cooldowns.IsAlertable(8, true, false),
    "global cooldown was classified as alertable")
assert(cooldowns.IsAlertable(0, true, true),
    "zero usable charges did not override duration classification")

local armed = {}
assert(not cooldowns.UpdateAlertState(armed, "slot", false, nil,
        "cooldown", false, true) and armed.slot == nil,
    "initial cooldown observation armed an alert")
assert(not cooldowns.UpdateAlertState(armed, "slot", true, "ready",
        "cooldown", false, true) and armed.slot == true,
    "observed real cooldown did not arm an alert")
assert(cooldowns.UpdateAlertState(armed, "slot", true, "cooldown",
        "ready", false, false) and armed.slot == nil,
    "real cooldown completion did not fire exactly once")
assert(not cooldowns.UpdateAlertState(armed, "slot", true, "ready",
        "ready", false, false),
    "settled ready state repeated an alert")

armed.slot = true
assert(not cooldowns.UpdateAlertState(armed, "slot", true, "cooldown",
        "ready", true, false) and armed.slot == nil,
    "global-cooldown transition emitted or retained an alert")
armed.slot = true
assert(not cooldowns.UpdateAlertState(armed, "slot", true, "cooldown",
        "unavailable", false, false) and armed.slot == nil,
    "unavailable action emitted or retained an alert")

C_Spell = nil
GetSpellCooldown = function()
    return 4, 12, 0
end
start, duration, enabled, reportedGCD = cooldowns.GetSpellCooldown(8092)
assert(start == 4 and duration == 12 and not enabled and reportedGCD == nil,
    "legacy spell cooldown was not normalized")

print("PASS shared action cooldown classification")
