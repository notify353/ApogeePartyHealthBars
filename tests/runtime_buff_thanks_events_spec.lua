local calls = {}
ApogeePartyHealthBars_BuffThanks = {
    OnCombatLog = function() calls[#calls + 1] = "combat" end,
    VerifyPending = function() calls[#calls + 1] = "verify" end,
    ResetSession = function() calls[#calls + 1] = "reset" end,
    RestorePosition = function() calls[#calls + 1] = "restore" end,
}

dofile("Runtime/BuffThanksEvents.lua")
local optional = {}
local router = { RegisterOptional = function(event, owner, callback)
    optional[event] = optional[event] or {}
    optional[event][#optional[event] + 1] = { owner = owner, callback = callback }
end }
ApogeePartyHealthBars_BuffThanksEvents.Register(router, { Print = function(message)
    calls[#calls + 1] = "print:" .. message
end })

assert(optional.COMBAT_LOG_EVENT_UNFILTERED[1].owner == "BuffThanks",
    "combat-log event was not registered")
optional.COMBAT_LOG_EVENT_UNFILTERED[1].callback("COMBAT_LOG_EVENT_UNFILTERED")
optional.UNIT_AURA[1].callback("UNIT_AURA", "party1")
optional.UNIT_AURA[1].callback("UNIT_AURA", "player")
optional.PLAYER_LOGIN[1].callback("PLAYER_LOGIN")
assert(table.concat(calls, ",") == "combat,verify,reset,restore",
    "Buff Thanks runtime events dispatched unexpected lifecycle calls")

print("PASS Buff Thanks runtime events")
