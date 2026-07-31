ApogeePartyHealthBars_C = {
    SLOT_UNITS = { "player", "party1", "party2", "party3", "party4" },
}

local invalidated = {}
ApogeePartyHealthBars_Auras = {
    InvalidateUnitAuraCache = function(unitId)
        invalidated[#invalidated + 1] = unitId
    end,
}

local refreshed, capabilitiesRefreshed, restored = 0, 0, 0
ApogeePartyHealthBars_CleanseWatch = {
    Refresh = function() refreshed = refreshed + 1 end,
    RefreshCapabilities = function()
        capabilitiesRefreshed = capabilitiesRefreshed + 1
    end,
    RestorePosition = function() restored = restored + 1 end,
}

local callbacks = {}
local router = {
    RegisterOptional = function(event, _, callback)
        callbacks[event] = callback
        return true
    end,
}
local errors = {}

dofile("Runtime/CleanseEvents.lua")
ApogeePartyHealthBars_CleanseEvents.Register(router, {
    Print = function(message) errors[#errors + 1] = message end,
})

callbacks.UNIT_AURA("UNIT_AURA", "party2")
assert(invalidated[1] == "party2" and refreshed == 1,
    "UNIT_AURA did not invalidate and refresh the affected unit")

invalidated = {}
callbacks.GROUP_ROSTER_UPDATE("GROUP_ROSTER_UPDATE")
assert(#invalidated == 5
        and invalidated[1] == "player"
        and invalidated[5] == "party4"
        and capabilitiesRefreshed == 1,
    "roster update retained harmful-aura cache entries for reused unit tokens")

invalidated = {}
callbacks.PLAYER_ENTERING_WORLD("PLAYER_ENTERING_WORLD")
assert(#invalidated == 5 and capabilitiesRefreshed == 2 and restored == 1,
    "world entry did not reset roster aura caches and panel position")

callbacks.SPELL_TEXT_UPDATE("SPELL_TEXT_UPDATE", 118)
assert(refreshed == 2 and capabilitiesRefreshed == 2,
    "spell-text update performed the wrong Cleanse Watch refresh")
assert(#errors == 0, "Cleanse Watch event adapter reported an unexpected error")

print("PASS Cleanse Watch runtime event policy")
