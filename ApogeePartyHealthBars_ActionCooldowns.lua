ApogeePartyHealthBars_ActionCooldowns = {}
local A = ApogeePartyHealthBars_ActionCooldowns

A.GCD_SPELL_ID = 29515

function A.GetSpellCooldown(identifier)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(identifier)
        if info then return info.startTime or 0, info.duration or 0, info.isEnabled ~= false end
    end
    if GetSpellCooldown then
        local start, duration, enabled = GetSpellCooldown(identifier)
        return tonumber(start) or 0, tonumber(duration) or 0, enabled ~= 0
    end
    return 0, 0, true
end

function A.IsRealCooldownActive(identifier, now)
    local start, duration, enabled = A.GetSpellCooldown(identifier)
    if not enabled or start <= 0 or duration <= 0 then return false end
    local gcdStart, gcdDuration = A.GetSpellCooldown(A.GCD_SPELL_ID)
    if gcdStart > 0 and gcdDuration > 0
        and math.abs(start - gcdStart) < 0.05 and math.abs(duration - gcdDuration) < 0.05 then
        return false
    end
    return start + duration > (now or (GetTime and GetTime()) or 0)
end

