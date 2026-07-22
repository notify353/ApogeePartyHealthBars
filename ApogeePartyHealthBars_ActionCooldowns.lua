ApogeePartyHealthBars_ActionCooldowns = {}
local A = ApogeePartyHealthBars_ActionCooldowns

-- WeakAuras uses 29515 as the GCD probe on Classic Era/TBC/Wrath. Short
-- cooldowns are not useful ready alerts and are also the safest final guard
-- against start-recovery data being mistaken for an inherent cooldown.
A.GCD_SPELL_ID = 29515
A.MIN_ALERTABLE_DURATION = 1.5

function A.GetSpellCooldown(identifier)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(identifier)
        if info then
            return info.startTime or 0, info.duration or 0, info.isEnabled ~= false,
                info.isOnGCD
        end
    end
    if GetSpellCooldown then
        local start, duration, enabled = GetSpellCooldown(identifier)
        return start or 0, duration or 0, enabled ~= 0
    end
    return 0, 0, true
end

function A.IsGlobalCooldown(start, duration, reportedGCD)
    duration = tonumber(duration) or 0
    if duration <= 0 then return false end
    if reportedGCD == true then return true end
    local gcdStart, gcdDuration = A.GetSpellCooldown(A.GCD_SPELL_ID)
    return gcdDuration > 0
        and math.abs((tonumber(start) or 0) - gcdStart) < 0.05
        and math.abs(duration - gcdDuration) < 0.05
end

function A.IsAlertable(duration, gcdOnly, noCharges)
    return noCharges == true
        or (gcdOnly ~= true and (tonumber(duration) or 0) > A.MIN_ALERTABLE_DURATION)
end

function A.UpdateAlertState(armed, key, initialized, previousState, state,
        gcdOnly, alertable)
    if initialized and state == "cooldown" and alertable then
        armed[key] = true
    end
    local finished = initialized
        and previousState == "cooldown"
        and state ~= "cooldown"
        and state ~= "unavailable"
        and gcdOnly ~= true
        and armed[key] == true
    if state ~= "cooldown" then armed[key] = nil end
    return finished
end
