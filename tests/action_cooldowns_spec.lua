local actionStart, actionDuration, actionEnabled, actionGCD = 10, 8, true, false
local gcdStart, gcdDuration = 20, 1.5
local requestedSpell
local inCombat = false

ApogeePartyHealthBars_S = { sv = { enabled = true } }
function InCombatLockdown() return inCombat end

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
    GetSpellCharges = function(identifier)
        requestedSpell = identifier
        return {
            currentCharges = 1,
            maxCharges = 2,
            cooldownStartTime = 30,
            cooldownDuration = 12,
        }
    end,
    IsSpellUsable = function(identifier)
        requestedSpell = identifier
        return identifier ~= 9001, identifier == 9001
    end,
    IsSpellInRange = function(identifier, unit)
        requestedSpell = identifier
        return unit == "target" and true or nil
    end,
}

dofile("Actions/ActionCooldowns.lua")
local cooldowns = ApogeePartyHealthBars_ActionCooldowns

local start, duration, enabled, reportedGCD = cooldowns.GetSpellCooldown(8092)
assert(start == 10 and duration == 8 and enabled and reportedGCD == false,
    "structured spell cooldown was not normalized")
local charges, maximum, chargeStart, chargeDuration = cooldowns.GetSpellCharges(8092)
assert(charges == 1 and maximum == 2 and chargeStart == 30 and chargeDuration == 12
        and requestedSpell == 8092,
    "structured spell charges were not normalized")
local usable, lacksResource = cooldowns.GetSpellUsability(9001)
assert(not usable and lacksResource and requestedSpell == 9001,
    "structured spell usability was not normalized")
assert(cooldowns.GetSpellRange(9001, "target") == true and requestedSpell == 9001,
    "structured spell range was not normalized")

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
assert(not cooldowns.IsReadyFeedbackAllowed(),
    "ready feedback was allowed outside combat")
inCombat = true
assert(cooldowns.IsReadyFeedbackAllowed(),
    "ready feedback was suppressed during combat")
ApogeePartyHealthBars_S.sv.enabled = false
assert(not cooldowns.IsReadyFeedbackAllowed(),
    "globally disabled add-on allowed ready feedback during combat")
ApogeePartyHealthBars_S.sv.enabled = true
inCombat = false

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

inCombat = true
armed.slot = true
assert(not cooldowns.UpdateAlertState(armed, "slot", true, "cooldown",
        "resource", false, false) and armed.slot == true,
    "in-combat resource shortage consumed a pending cooldown alert")
assert(cooldowns.UpdateAlertState(armed, "slot", true, "resource",
        "ready", false, false) and armed.slot == nil,
    "resource recovery did not finish the pending cooldown alert")

inCombat = false
armed.slot = true
assert(not cooldowns.UpdateAlertState(armed, "slot", true, "cooldown",
        "resource", false, false) and armed.slot == nil,
    "out-of-combat resource shortage retained a pending cooldown alert")
inCombat = true
assert(not cooldowns.UpdateAlertState(armed, "slot", true, "resource",
        "ready", false, false),
    "discarded out-of-combat cooldown alert leaked into the next combat")
inCombat = false

armed.slot = true
assert(not cooldowns.UpdateAlertState(armed, "slot", true, "cooldown",
        "ready", true, false) and armed.slot == nil,
    "global-cooldown transition emitted or retained an alert")
armed.slot = true
assert(not cooldowns.UpdateAlertState(armed, "slot", true, "cooldown",
        "unavailable", false, false) and armed.slot == nil,
    "unavailable action emitted or retained an alert")

actionStart, actionDuration, actionEnabled, actionGCD = 20, 1.5, true, false
assert(not cooldowns.IsRealCooldownActive(8092, 20.5),
    "global cooldown was treated as a real DoT blocker")
actionStart, actionDuration = 18, 10
assert(cooldowns.IsRealCooldownActive(8092, 20.5),
    "real spell cooldown was ignored by DoT gating")
actionStart, actionDuration = 1, 2
assert(not cooldowns.IsRealCooldownActive(8092, 20.5),
    "expired spell cooldown remained active")

C_Spell = nil
GetSpellCooldown = function()
    return 4, 12, 0
end
GetSpellCharges = function()
    return 2, 3, 40, 15
end
IsUsableSpell = function(identifier)
    return identifier ~= 9000, false
end
IsSpellInRange = function(_, unit)
    return unit == "focus" and 1 or nil
end
start, duration, enabled, reportedGCD = cooldowns.GetSpellCooldown(8092)
assert(start == 4 and duration == 12 and not enabled and reportedGCD == nil,
    "legacy spell cooldown was not normalized")
charges, maximum, chargeStart, chargeDuration = cooldowns.GetSpellCharges(8092)
assert(charges == 2 and maximum == 3 and chargeStart == 40 and chargeDuration == 15,
    "legacy spell charges were not normalized")
usable, lacksResource = cooldowns.GetSpellUsability(9000)
assert(not usable and not lacksResource,
    "legacy spell usability was not normalized")
assert(cooldowns.GetSpellRange(9000, "focus") == 1,
    "legacy spell range was not normalized")

print("PASS shared action cooldown classification")
