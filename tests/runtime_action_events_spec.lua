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

local wheelLayoutsChanged, keyLayoutsChanged = false, false
ApogeePartyHealthBars_S = {
    InitializeClassDefaultBindings = function() record("class-bindings") end,
    RequestUpdate = function() record("request-update") end,
    RequestLayoutUpdate = function() record("layout") end,
}
ApogeePartyHealthBars_ShortcutBar = {
    Refresh = function(full) record("shortcut-refresh:" .. tostring(full)) end,
    ResolveAndRefresh = function() record("shortcut-resolve") end,
    RefreshItemInfo = function() record("shortcut-item-info") end,
}
ApogeePartyHealthBars_WheelMacros = {
    Refresh = function() record("wheel-refresh") end,
    RefreshItemInfo = function() record("wheel-item-info") end,
    OnActiveSpecChanged = function() record("wheel-spec") end,
    RefreshLayouts = function()
        record("wheel-layouts")
        return wheelLayoutsChanged
    end,
    ReconcileBindings = function() record("wheel-reconcile") end,
    OnStanceChanged = function() record("wheel-stance") end,
}
ApogeePartyHealthBars_KeyActions = {
    Refresh = function() record("keys-refresh") end,
    RefreshItemInfo = function() record("keys-item-info") end,
    OnActiveSpecChanged = function() record("keys-spec") end,
    RefreshLayouts = function()
        record("keys-layouts")
        return keyLayoutsChanged
    end,
    ReconcileBindings = function() record("keys-reconcile") end,
    OnStanceChanged = function() record("keys-stance") end,
}

local ui = {
    RefreshShortcutPanel = function() record("ui-shortcuts") end,
    RefreshKeyPanel = function() record("ui-keys") end,
    RefreshWheelPanel = function() record("ui-wheel") end,
    RefreshBindPanel = function() record("ui-healing") end,
    RefreshMacroPanel = function() record("ui-macros") end,
}

local optional = {}
local router = {}
function router.RegisterOptional(event, owner, callback)
    optional[event] = { owner = owner, callback = callback }
end
local function dispatch(event, ...)
    local subscription = assert(optional[event], "missing subscription: " .. event)
    subscription.callback(event, ...)
end

local deps = {
    Print = function(message) record("print:" .. message) end,
    InitPlayerSpells = function() record("player-spells") end,
    GetConfigUI = function() return ui end,
}

dofile("ApogeePartyHealthBars_RuntimeActionEvents.lua")
local events = ApogeePartyHealthBars_RuntimeActionEvents

local valid, validationError = pcall(events.Register, router, {})
assert(not valid and tostring(validationError):find("Print", 1, true),
    "action subscriber accepted incomplete dependencies")
events.Register(router, deps)

for _, event in ipairs({
    "SPELLS_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED", "UPDATE_BINDINGS",
    "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS",
}) do
    assert(optional[event] and optional[event].owner == "Bootstrap",
        "action transition changed registration: " .. event)
end
assert(optional.SPELL_UPDATE_COOLDOWN.owner == "ShortcutBar"
        and optional.UNIT_FLAGS.owner == "ShortcutBarTarget"
        and optional.BAG_UPDATE_DELAYED.owner == "ShortcutItems"
        and optional.GET_ITEM_INFO_RECEIVED.owner == "ShortcutItemInfo"
        and optional.UNIT_PET.owner == "MacroLibraryPet",
    "action refresh owner labels changed")

dispatch("SPELL_UPDATE_COOLDOWN")
expect({ "shortcut-refresh:false", "wheel-refresh", "keys-refresh" },
    "cooldown refresh fan-out changed")

reset()
dispatch("UNIT_FLAGS", "party1")
dispatch("UNIT_FLAGS", "target")
expect({ "shortcut-refresh:false" }, "target flag filtering changed")

reset()
dispatch("BAG_UPDATE_DELAYED")
expect({
    "shortcut-refresh:false", "wheel-refresh", "keys-refresh",
    "ui-shortcuts", "ui-keys", "ui-wheel",
}, "bag update fan-out changed")

reset()
dispatch("GET_ITEM_INFO_RECEIVED", 1251, true)
expect({
    "shortcut-item-info", "wheel-item-info", "keys-item-info",
    "ui-shortcuts", "ui-keys", "ui-wheel", "ui-healing",
}, "item-info fan-out changed")

reset()
dispatch("UNIT_PET", "party1")
dispatch("UNIT_PET", "player")
dispatch("PET_BAR_UPDATE")
expect({ "ui-macros", "ui-macros" }, "pet requirement filtering changed")

reset()
dispatch("ACTIVE_TALENT_GROUP_CHANGED", 2, 1)
expect({ "wheel-spec", "keys-spec", "ui-keys", "ui-wheel" },
    "active-spec transition order changed")

reset()
wheelLayoutsChanged, keyLayoutsChanged = false, false
dispatch("SPELLS_CHANGED")
expect({
    "class-bindings", "player-spells", "shortcut-resolve", "wheel-layouts",
    "keys-layouts", "wheel-refresh", "keys-refresh", "ui-macros", "request-update",
}, "stable spell-layout refresh order changed")

reset()
wheelLayoutsChanged, keyLayoutsChanged = true, true
dispatch("SPELLS_CHANGED")
expect({
    "class-bindings", "player-spells", "shortcut-resolve", "wheel-layouts",
    "keys-layouts", "ui-keys", "ui-wheel", "ui-macros", "request-update",
}, "changed spell-layout refresh order changed")

reset()
dispatch("UPDATE_BINDINGS")
expect({ "wheel-reconcile", "keys-reconcile", "ui-keys", "ui-wheel" },
    "binding reconciliation order changed")

reset()
dispatch("UPDATE_SHAPESHIFT_FORM")
expect({ "shortcut-refresh:false", "wheel-stance", "keys-stance", "layout" },
    "stance transition order changed")

reset()
dispatch("UPDATE_SHAPESHIFT_FORMS")
expect({ "wheel-layouts", "keys-layouts", "ui-keys", "ui-wheel", "layout" },
    "stance registry refresh order changed")

reset()
local originalSpecChanged = ApogeePartyHealthBars_WheelMacros.OnActiveSpecChanged
ApogeePartyHealthBars_WheelMacros.OnActiveSpecChanged = function()
    error("expected action failure")
end
dispatch("ACTIVE_TALENT_GROUP_CHANGED")
assert(calls[#calls]:find("print:event error (ACTIVE_TALENT_GROUP_CHANGED):", 1, true),
    "action subscriber lost its event error bridge")
ApogeePartyHealthBars_WheelMacros.OnActiveSpecChanged = originalSpecChanged

print("PASS runtime action events")
