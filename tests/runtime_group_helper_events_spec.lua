dofile("Core/Namespace.lua")
dofile("Runtime/GroupHelperEvents.lua")
local Events = ApogeePartyHealthBars.Require("Runtime", "GroupHelperEvents")
local required, optional, calls = {}, {}, {}
local router = {
    Subscribe = function(event, owner, callback)
        required[event] = { owner = owner, callback = callback }
    end,
    RegisterOptional = function(event, owner, callback)
        optional[event] = { owner = owner, callback = callback }
    end,
}
local runtime = {
    ResetSession = function() calls[#calls + 1] = "reset" end,
    ScheduleRefresh = function(delay) calls[#calls + 1] = "refresh:" .. tostring(delay) end,
    OnRosterChanged = function() calls[#calls + 1] = "roster" end,
    ScheduleAuraRefresh = function(delay)
        calls[#calls + 1] = "aura-refresh:" .. tostring(delay)
    end,
    OnCombatStarted = function() calls[#calls + 1] = "combat-start" end,
    OnCombatEnded = function() calls[#calls + 1] = "combat-end" end,
}
Events.Register(router, { GroupHelperRuntime = runtime })
assert(required.PLAYER_LOGIN and required.PLAYER_ENTERING_WORLD
        and required.GROUP_ROSTER_UPDATE and required.PLAYER_REGEN_DISABLED
        and required.PLAYER_REGEN_ENABLED,
    "Group Helper required lifecycle subscriptions changed")
assert(optional.UNIT_AURA and optional.UNIT_POWER_UPDATE
        and optional.UNIT_POWER_FREQUENT and optional.UNIT_MAXPOWER
        and optional.UNIT_CONNECTION and optional.UNIT_HEALTH,
    "Group Helper unit observation subscriptions changed")
required.PLAYER_LOGIN.callback()
required.GROUP_ROSTER_UPDATE.callback()
optional.UNIT_POWER_UPDATE.callback("UNIT_POWER_UPDATE", "party1")
optional.UNIT_AURA.callback("UNIT_AURA", "target")
optional.UNIT_AURA.callback("UNIT_AURA", "party2")
required.PLAYER_REGEN_DISABLED.callback()
required.PLAYER_REGEN_ENABLED.callback()
assert(table.concat(calls, ",")
        == "reset,roster,refresh:0,aura-refresh:0.15,combat-start,combat-end",
    "Group Helper event routing changed: " .. table.concat(calls, ","))
print("PASS Group Helper runtime events")
