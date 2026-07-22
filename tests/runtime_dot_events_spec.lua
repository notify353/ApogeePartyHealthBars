local callbacks = {}
local function register(event, callback) callbacks[event] = callbacks[event] or {}; callbacks[event][#callbacks[event] + 1] = callback end
local router = {
    Subscribe = function(event, _, callback) register(event, callback) end,
    RegisterOptional = function(event, _, callback) register(event, callback) end,
}
local calls = { initialize = 0, context = 0, refresh = 0, invalidations = 0 }
ApogeePartyHealthBars_DotTracker = {
    Initialize = function() calls.initialize = calls.initialize + 1 end,
    OnContextChanged = function() calls.context = calls.context + 1 end,
    Refresh = function() calls.refresh = calls.refresh + 1 end,
}
ApogeePartyHealthBars_Auras = {
    InvalidateUnitAuraCache = function(unit)
        assert(unit == "target"); calls.invalidations = calls.invalidations + 1
    end,
}

dofile("ApogeePartyHealthBars_RuntimeDotEvents.lua")
ApogeePartyHealthBars_RuntimeDotEvents.Register(router, { Print = function(message) error(message) end })
local function dispatch(event, ...)
    for _, callback in ipairs(callbacks[event] or {}) do callback(event, ...) end
end
dispatch("PLAYER_LOGIN")
dispatch("UNIT_AURA", "party1")
dispatch("UNIT_AURA", "target")
dispatch("PLAYER_TARGET_CHANGED")
dispatch("SPELLS_CHANGED")
dispatch("UNIT_POWER_UPDATE", "party1")
dispatch("UNIT_POWER_UPDATE", "player")
assert(calls.initialize == 1 and calls.context == 1 and calls.refresh == 3
        and calls.invalidations == 2,
    "DoT event policy did not isolate target auras, context, and player usability")

print("PASS event-driven DoT refresh policy")
