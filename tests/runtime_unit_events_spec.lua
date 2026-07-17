local calls = {}
local function record(value) calls[#calls + 1] = value end
local function reset() calls = {} end
local function expect(expected, message)
    assert(#calls == #expected, message .. " count: " .. table.concat(calls, ","))
    for index, value in ipairs(expected) do
        assert(calls[index] == value,
            message .. " at " .. index .. ": " .. tostring(calls[index]))
    end
end

ApogeePartyHealthBars_S = {
    RequestLayoutUpdate = function() record("layout") end,
    RequestValuesUpdate = function(unit) record("values:" .. tostring(unit)) end,
}
ApogeePartyHealthBars_Auras = {
    InvalidateUnitAuraCache = function(unit) record("invalidate:" .. unit) end,
}
ApogeePartyHealthBars_ShortcutBar = {
    Refresh = function(full) record("shortcut:" .. tostring(full)) end,
}
ApogeePartyHealthBars_RaidMarkers = { Refresh = function() record("raid") end }
ApogeePartyHealthBars_Threat = { Refresh = function() record("threat") end }

local required, optional = {}, {}
local router = {}
function router.Subscribe(event, owner, callback)
    required[event] = { owner = owner, callback = callback }
end
function router.RegisterOptional(event, owner, callback)
    optional[event] = { owner = owner, callback = callback }
end
local function dispatch(event, ...)
    local subscription = required[event] or optional[event]
    assert(subscription, "missing subscription: " .. event)
    subscription.callback(event, ...)
end

local auraNeedsLayout = true
local deps = {
    Print = function(message) record("print:" .. message) end,
    IsPanelTrackedUnit = function(unit) return unit ~= "other" end,
    ResolvePanelUnit = function(unit) return unit == "party1" and "target" or unit end,
    ShieldTrackerSyncUnit = function(unit) record("shield:" .. unit) end,
    AuraEventNeedsLayout = function() return auraNeedsLayout end,
}

dofile("ApogeePartyHealthBars_RuntimeUnitEvents.lua")
local events = ApogeePartyHealthBars_RuntimeUnitEvents

local valid, validationError = pcall(events.Register, router, {})
assert(not valid and tostring(validationError):find("Print", 1, true),
    "unit subscriber accepted incomplete dependencies")
events.Register(router, deps)

for _, event in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_AURA" }) do
    assert(required[event] and required[event].owner == "Bootstrap",
        "required unit event changed registration: " .. event)
end
for _, event in ipairs({
    "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_PREDICTION", "UNIT_POWER_UPDATE",
    "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_TARGET",
    "UNIT_CONNECTION",
}) do
    assert(optional[event] and optional[event].owner == "Bootstrap",
        "optional unit event changed registration: " .. event)
end
assert(optional.RAID_TARGET_UPDATE.owner == "RaidMarkers"
        and optional.UNIT_THREAT_SITUATION_UPDATE.owner == "Threat"
        and optional.UNIT_THREAT_LIST_UPDATE.owner == "Threat",
    "visual event owners changed")

dispatch("UNIT_AURA", "party1")
expect({ "invalidate:party1", "invalidate:target", "shield:target", "layout" },
    "aura alias invalidation or layout request changed")

reset()
auraNeedsLayout = false
dispatch("UNIT_ABSORB_AMOUNT_CHANGED", "party1")
expect({ "invalidate:party1", "invalidate:target", "shield:target", "values:target" },
    "absorb alias invalidation or values request changed")

reset()
dispatch("UNIT_HEALTH", "party1")
expect({ "values:nil" }, "health aliases no longer coalesced into an all-row update")
reset()
dispatch("UNIT_HEAL_PREDICTION", "other")
expect({}, "untracked heal prediction triggered an update")

dispatch("UNIT_DISPLAYPOWER", "player")
expect({ "shortcut:false", "layout" }, "player display-power handling changed")
reset()
dispatch("UNIT_DISPLAYPOWER", "party1")
expect({ "values:target" }, "party display-power alias handling changed")

reset()
dispatch("UNIT_MAXPOWER", "player")
expect({ "shortcut:false", "layout" }, "player max-power layout handling changed")
reset()
dispatch("UNIT_POWER_UPDATE", "player")
expect({ "shortcut:false", "values:player" }, "player power update handling changed")

reset()
dispatch("UNIT_CONNECTION", "party1")
expect({ "layout" }, "connection changes stopped requesting layout")
reset()
dispatch("UNIT_TARGET", "party1")
dispatch("UNIT_TARGET", "target")
dispatch("UNIT_TARGET", "other")
expect({ "layout", "layout" }, "unit-target filtering changed")

reset()
dispatch("RAID_TARGET_UPDATE")
dispatch("UNIT_THREAT_LIST_UPDATE")
expect({ "raid", "threat" }, "raid-marker or threat visual refresh changed")

reset()
deps.ResolvePanelUnit = function() error("expected unit failure") end
dispatch("UNIT_AURA", "party1")
assert(calls[#calls]:find("print:event error (UNIT_AURA):", 1, true),
    "unit subscriber lost its event error bridge")

print("PASS runtime unit events")
