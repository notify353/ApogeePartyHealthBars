local calls = {}
local function record(value) calls[#calls + 1] = value end
ApogeePartyHealthBars_CooldownTracker = {
    Initialize = function() record("initialize") end,
    Refresh = function() record("refresh") end,
    OnContextChanged = function() record("context") end,
}
local required, optional = {}, {}
local router = {
    Subscribe = function(event, owner, callback) required[event] = { owner = owner, callback = callback } end,
    RegisterOptional = function(event, owner, callback)
        optional[event] = { owner = owner, callback = callback }
    end,
}
local delayed = {}
C_Timer = { After = function(_, callback) delayed[#delayed + 1] = callback end }
dofile("Runtime/CooldownEvents.lua")
ApogeePartyHealthBars_CooldownEvents.Register(router, { Print = function(message) error(message) end })
assert(required.PLAYER_LOGIN.owner == "AbilityCooldowns"
        and optional.SPELL_UPDATE_COOLDOWN.owner == "AbilityCooldowns"
        and optional.SPELL_UPDATE_CHARGES.owner == "AbilityCooldowns"
        and optional.SPELL_UPDATE_USABLE.owner == "AbilityCooldowns"
        and optional.PET_BAR_UPDATE_COOLDOWN.owner == "AbilityCooldowns"
        and optional.UNIT_PET.owner == "AbilityCooldownContext"
        and optional.UNIT_SPELLCAST_SUCCEEDED.owner == "AbilityCooldownSampling",
    "Ability Cooldowns event ownership changed")
required.PLAYER_LOGIN.callback()
optional.SPELL_UPDATE_COOLDOWN.callback()
optional.SPELL_UPDATE_USABLE.callback()
optional.UNIT_PET.callback(nil, "other")
optional.UNIT_PET.callback(nil, "player")
optional.UNIT_SPELLCAST_SUCCEEDED.callback(nil, "player")
optional.UNIT_SPELLCAST_SUCCEEDED.callback(nil, "pet")
delayed[1]()
delayed[2]()
assert(table.concat(calls, ",") == "initialize,refresh,refresh,context,refresh",
    "Ability Cooldowns did not coalesce delayed post-cast sampling: "
        .. table.concat(calls, ","))
print("PASS Ability Cooldowns runtime events")
