local cooldowns = {}
function GetSpellCooldown(id)
    local value = cooldowns[id] or { 0, 0, 1 }
    return value[1], value[2], value[3]
end
function GetTime() return 10 end

dofile("ApogeePartyHealthBars_ActionCooldowns.lua")
local C = ApogeePartyHealthBars_ActionCooldowns
cooldowns[C.GCD_SPELL_ID] = { 9, 1.5, 1 }
cooldowns[172] = { 9, 1.5, 1 }
assert(not C.IsRealCooldownActive(172, 10), "global cooldown was treated as a real blocker")
cooldowns[172] = { 8, 10, 1 }
assert(C.IsRealCooldownActive(172, 10), "real spell cooldown was ignored")
cooldowns[172] = { 1, 2, 1 }
assert(not C.IsRealCooldownActive(172, 10), "expired cooldown remained active")

print("PASS DoT cooldown gating")

