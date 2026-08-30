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
ApogeePartyHealthBars_RaidMarkers = {
    OnRaidTargetUpdate = function() record("raid-update") end,
    OnUnitDied = function(guid) record("raid-death:" .. tostring(guid)) end,
}
ApogeePartyHealthBars_Threat = { Refresh = function() record("threat") end }
ApogeePartyHealthBars_ThreatObserver = {
    OnNamePlateAdded = function(unit) record("plate+:" .. unit) end,
    OnNamePlateRemoved = function(unit) record("plate-:" .. unit) end,
    IsObservedUnit = function(unit) return unit == "other" end,
    InvalidateAuras = function(unit) record("observer-aura:" .. unit) end,
}
ApogeePartyHealthBars_ThreatAwareness = { Refresh = function(suppress)
    record("awareness:" .. tostring(suppress))
end, RefreshUnit = function(unit) record("awareness-unit:" .. unit) end,
RefreshPlayer = function() record("awareness-player") end }

local required, optional = {}, {}
local router = {}
function router.Subscribe(event, owner, callback)
    required[event] = { owner = owner, callback = callback }
end
function router.RegisterOptional(event, owner, callback)
    local subscription = { owner = owner, callback = callback }
    if not optional[event] then
        optional[event] = { subscription }
    else
        optional[event][#optional[event] + 1] = subscription
    end
end
local function dispatch(event, ...)
    local subscription = required[event]
    if subscription then
        subscription.callback(event, ...)
        return
    end
    local subscriptions = optional[event]
    assert(subscriptions, "missing subscription: " .. event)
    for _, current in ipairs(subscriptions) do current.callback(event, ...) end
end
local function optionalHasOwner(event, owner)
    for _, subscription in ipairs(optional[event] or {}) do
        if subscription.owner == owner then return true end
    end
    return false
end

local auraNeedsLayout = true
local deps = {
    Print = function(message) record("print:" .. message) end,
    IsPanelTrackedUnit = function(unit) return unit ~= "other" end,
    ResolvePanelUnit = function(unit) return unit == "party1" and "target" or unit end,
    ShieldTrackerSyncUnit = function(unit) record("shield:" .. unit) end,
    AuraEventNeedsLayout = function() return auraNeedsLayout end,
}

dofile("Runtime/UnitEvents.lua")
local events = ApogeePartyHealthBars_UnitEvents

local valid, validationError = pcall(events.Register, router, {})
assert(not valid and tostring(validationError):find("Print", 1, true),
    "unit subscriber accepted incomplete dependencies")
events.Register(router, deps)

for _, event in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH" }) do
    assert(required[event] and required[event].owner == "Bootstrap",
        "required unit event changed registration: " .. event)
end
for _, event in ipairs({
    "UNIT_AURA", "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_PREDICTION", "UNIT_POWER_UPDATE",
    "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_TARGET",
    "UNIT_CONNECTION",
}) do
    assert(optionalHasOwner(event, "Bootstrap"),
        "optional unit event changed registration: " .. event)
end
for _, event in ipairs({
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_FAILED_QUIET", "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE",
    "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_INTERRUPTIBLE",
    "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
}) do
    assert(optionalHasOwner(event, "ThreatAwareness"),
        "Threat Control cast event changed registration: " .. event)
end
assert(optionalHasOwner("RAID_TARGET_UPDATE", "RaidMarkers")
        and optionalHasOwner("UNIT_DIED", "RaidMarkers")
        and optionalHasOwner("NAME_PLATE_UNIT_ADDED", "ThreatAwareness")
        and optionalHasOwner("NAME_PLATE_UNIT_REMOVED", "ThreatAwareness"),
    "visual event owners changed")

dispatch("RAID_TARGET_UPDATE")
dispatch("UNIT_DIED", "Creature-dead")
expect({ "raid-update", "raid-death:Creature-dead" },
    "raid-marker ownership events were not routed")
reset()

dispatch("UNIT_AURA", "party1")
expect({ "invalidate:party1", "invalidate:target", "shield:party1", "layout" },
    "aura alias invalidation or layout request changed")

reset()
dispatch("UNIT_AURA", "other")
expect({ "invalidate:other", "observer-aura:other", "awareness:nil" },
    "observed enemy aura change did not refresh Threat Control debuffs")

reset()
auraNeedsLayout = false
dispatch("UNIT_ABSORB_AMOUNT_CHANGED", "party1")
expect({ "invalidate:party1", "invalidate:target", "shield:party1", "values:target" },
    "absorb alias invalidation or values request changed")
reset()
dispatch("UNIT_ABSORB_AMOUNT_CHANGED", "player")
expect({ "invalidate:player", "shield:player", "awareness-player", "values:player" },
    "player absorb change did not refresh Threat Control")

reset()
dispatch("UNIT_HEALTH", "party1")
expect({ "values:nil" }, "health aliases no longer coalesced into an all-row update")
reset()
dispatch("UNIT_HEALTH", "other")
expect({ "awareness-unit:other" }, "observed enemy health did not refresh Threat Control")
reset()
dispatch("UNIT_SPELLCAST_START", "other")
dispatch("UNIT_SPELLCAST_CHANNEL_UPDATE", "other")
dispatch("UNIT_SPELLCAST_INTERRUPTED", "party1")
expect({ "awareness-unit:other", "awareness-unit:other" },
    "observed enemy casts did not refresh Threat Control")
reset()
dispatch("UNIT_HEAL_PREDICTION", "other")
expect({}, "untracked heal prediction triggered an update")
reset()
dispatch("UNIT_HEALTH", "player")
expect({ "awareness-player", "values:nil" }, "player health did not refresh Threat Control")

reset()
dispatch("UNIT_DISPLAYPOWER", "player")
expect({ "shortcut:false", "awareness-player", "layout" }, "player display-power handling changed")
reset()
dispatch("UNIT_DISPLAYPOWER", "party1")
expect({ "layout" }, "adaptive party display-power handling changed")

reset()
dispatch("UNIT_MAXPOWER", "player")
expect({ "shortcut:false", "awareness-player", "layout" }, "player max-power layout handling changed")
reset()
dispatch("UNIT_POWER_UPDATE", "player")
expect({ "shortcut:false", "awareness-player", "values:player" }, "player power update handling changed")

reset()
dispatch("UNIT_CONNECTION", "party1")
expect({ "layout" }, "connection changes stopped requesting layout")
reset()
dispatch("UNIT_CONNECTION", "player")
expect({ "awareness-player", "layout" }, "player connection did not refresh Threat Control")
reset()
dispatch("UNIT_TARGET", "party1")
dispatch("UNIT_TARGET", "target")
dispatch("UNIT_TARGET", "other")
expect({ "layout", "layout" }, "unit-target filtering changed")

reset()
dispatch("NAME_PLATE_UNIT_ADDED", "nameplate7")
dispatch("NAME_PLATE_UNIT_REMOVED", "nameplate7")
expect({
    "plate+:nameplate7", "awareness:nil",
    "plate-:nameplate7", "awareness:nil",
}, "nameplate lifecycle did not remain exclusive to Threat Awareness")

reset()
deps.ResolvePanelUnit = function() error("expected unit failure") end
dispatch("UNIT_AURA", "party1")
assert(calls[#calls]:find("print:event error (UNIT_AURA):", 1, true),
    "unit subscriber lost its event error bridge")

print("PASS runtime unit events")
