local calls = {}
local scheduledTimers = {}
local function record(value) calls[#calls + 1] = value end
local function reset() calls = {} end
local function expect(expected, message)
    assert(#calls == #expected, message .. " count: " .. table.concat(calls, ","))
    for index, value in ipairs(expected) do
        assert(calls[index] == value,
            message .. " at " .. index .. ": " .. tostring(calls[index]))
    end
end

local wheelLayoutsChanged, keyLayoutsChanged, buttonLayoutsChanged = false, false, false
C_Timer = {
    After = function(delay, callback)
        scheduledTimers[#scheduledTimers + 1] = { delay = delay, callback = callback }
    end,
}
ApogeePartyHealthBars_S = {
    InitializeClassDefaultBindings = function() record("class-bindings") end,
    RequestUpdate = function() record("request-update") end,
    RequestLayoutUpdate = function() record("layout") end,
}
ApogeePartyHealthBars_ShortcutBar = {
    Refresh = function(full) record("shortcut-refresh:" .. tostring(full)) end,
    RefreshSecureActions = function() record("shortcut-secure") end,
    ResolveAndRefresh = function() record("shortcut-resolve") end,
    RefreshItemInfo = function() record("shortcut-item-info") end,
    RefreshAssignmentAffordances = function() record("assignment-refresh") end,
}
local spellbookOpen = false
local openBags = {}
ApogeePartyHealthBars_ActionAssignmentSources = {
    SetSpellbookOpen = function(active)
        active = active == true
        if spellbookOpen == active then return false end
        spellbookOpen = active
        record("spellbook-open:" .. tostring(active))
        return true
    end,
    SetPlayerBagOpen = function(bagId, active)
        active = active == true
        if not not openBags[bagId] == active then return false end
        openBags[bagId] = active and true or nil
        record("bag-open:" .. tostring(bagId) .. ":" .. tostring(active))
        return true
    end,
    SetExternalPlayerBagsOpen = function(active)
        record("external-bags-open:" .. tostring(active == true))
        return true
    end,
}
ApogeePartyHealthBars_MouseWheelActions = {
    Refresh = function() record("wheel-refresh") end,
    RefreshSecureActions = function() record("wheel-secure") end,
    RefreshItemInfo = function() record("wheel-item-info") end,
    OnActiveSpecChanged = function() record("wheel-spec") end,
    RefreshLayouts = function()
        record("wheel-layouts")
        return wheelLayoutsChanged
    end,
    ReconcileBindings = function() record("wheel-reconcile") end,
    OnStateChanged = function() record("wheel-state") end,
    RefreshPhysicalClickRegistration = function() record("wheel-click-phase") end,
}
ApogeePartyHealthBars_KeyboardActions = {
    Refresh = function() record("keys-refresh") end,
    RefreshSecureActions = function() record("keys-secure") end,
    RefreshItemInfo = function() record("keys-item-info") end,
    OnActiveSpecChanged = function() record("keys-spec") end,
    RefreshLayouts = function()
        record("keys-layouts")
        return keyLayoutsChanged
    end,
    ReconcileBindings = function() record("keys-reconcile") end,
    OnStateChanged = function() record("keys-state") end,
    RefreshPhysicalClickRegistration = function() record("keys-click-phase") end,
}
ApogeePartyHealthBars_MouseButtonActions = {
    Refresh = function() record("buttons-refresh") end,
    RefreshSecureActions = function() record("buttons-secure") end,
    RefreshItemInfo = function() record("buttons-item-info") end,
    OnActiveSpecChanged = function() record("buttons-spec") end,
    RefreshLayouts = function()
        record("buttons-layouts")
        return buttonLayoutsChanged
    end,
    OnStateChanged = function() record("buttons-state") end,
    RefreshPhysicalClickRegistration = function() record("buttons-click-phase") end,
}
ApogeePartyHealthBars_ConsumableBar = {
    Refresh = function(full) record("consumable-refresh:" .. tostring(full)) end,
    OnBagUpdate = function() record("consumable-bags") end,
    RefreshItemInfo = function() record("consumable-item-info") end,
}

local ui = {
    RefreshShortcutPanel = function() record("ui-shortcuts") end,
    RefreshKeyboardPage = function() record("ui-keys") end,
    RefreshMouseWheelPage = function() record("ui-wheel") end,
    RefreshMouseButtonsPage = function() record("ui-buttons") end,
    RefreshPartyFrameClicksPage = function() record("ui-healing") end,
    RefreshLoadoutsPage = function() record("ui-loadouts") end,
    RefreshLoadoutsFromInventory = function() record("ui-loadouts-inventory") end,
}

local optional = {}
NUM_CONTAINER_FRAMES = 2
local function containerFrame(id)
    return {
        id = id,
        shown = false,
        scripts = {},
        HookScript = function(self, script, callback) self.scripts[script] = callback end,
        GetID = function(self) return self.id end,
        IsShown = function(self) return self.shown end,
    }
end
ContainerFrame1 = containerFrame(0)
ContainerFrame2 = containerFrame(1)
SpellBookFrame = {
    shown = false,
    scripts = {},
    HookScript = function(self, script, callback) self.scripts[script] = callback end,
    IsShown = function(self) return self.shown end,
}
local router = {}
function router.RegisterOptional(event, owner, callback)
    optional[event] = { owner = owner, callback = callback }
end
function router.Subscribe(event, owner, callback)
    optional[event] = { owner = owner, callback = callback, required = true }
end
local function dispatch(event, ...)
    local subscription = assert(optional[event], "missing subscription: " .. event)
    subscription.callback(event, ...)
end

local deps = {
    Print = function(message) record("print:" .. message) end,
    InitPlayerSpells = function() record("player-spells") end,
    GetSettingsUI = function() return ui end,
    ReconcileBoundActionBindings = function() record("bindings-reconcile"); return true end,
}

dofile("Runtime/ActionEvents.lua")
local events = ApogeePartyHealthBars_ActionEvents

local valid, validationError = pcall(events.Register, router, {})
assert(not valid and tostring(validationError):find("Print", 1, true),
    "action subscriber accepted incomplete dependencies")
events.Register(router, deps)
reset()

for _, event in ipairs({
    "SPELLS_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED", "UPDATE_BINDINGS",
    "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS", "UPDATE_STEALTH",
    "CVAR_UPDATE",
}) do
    assert(optional[event] and optional[event].owner == "Bootstrap",
        "action transition changed registration: " .. event)
end
assert(optional.SPELL_UPDATE_COOLDOWN.owner == "ShortcutBar"
        and optional.UNIT_SPELLCAST_SUCCEEDED.owner == "ActionCooldownSampling"
        and optional.UNIT_FLAGS.owner == "ShortcutBarTarget"
        and optional.BAG_UPDATE_DELAYED.owner == "ShortcutItems"
        and optional.GET_ITEM_INFO_RECEIVED.owner == "ShortcutItemInfo"
        and optional.EQUIPMENT_SETS_CHANGED.owner == "EquipmentLoadouts"
        and optional.UNIT_PET.owner == "PlayerPetActions"
        and optional.PET_BAR_UPDATE.owner == "PlayerPetActions"
        and optional.PET_BAR_UPDATE_COOLDOWN.owner == "PlayerPetActionState"
        and optional.PET_BAR_UPDATE_USABLE.owner == "PlayerPetActionState"
        and optional.BAG_OPEN.owner == "ActionAssignmentSources" and optional.BAG_OPEN.required
        and optional.BAG_CLOSED.owner == "ActionAssignmentSources" and optional.BAG_CLOSED.required
        and optional.CURSOR_CHANGED.owner == "ActionAssignmentSources"
        and optional.ADDON_LOADED.owner == "ActionAssignmentSources"
        and optional.ADDON_LOADED.required,
    "action refresh owner labels changed")
assert(SpellBookFrame.scripts.OnShow and SpellBookFrame.scripts.OnHide,
    "Spellbook visibility hooks were not installed")
assert(ContainerFrame1.scripts.OnShow and ContainerFrame1.scripts.OnHide
        and ContainerFrame2.scripts.OnShow and ContainerFrame2.scripts.OnHide,
    "native container visibility hooks were not installed")

SpellBookFrame.scripts.OnShow()
expect({ "spellbook-open:true", "assignment-refresh" },
    "opening the Spellbook did not activate the Shortcut drop target")
reset()
SpellBookFrame.scripts.OnHide()
expect({ "spellbook-open:false", "assignment-refresh" },
    "closing the Spellbook did not deactivate its Shortcut drop source")

reset()
dispatch("BAG_OPEN", 0)
expect({ "bag-open:0:true", "assignment-refresh" },
    "opening a player bag did not activate assignment affordances")
reset()
dispatch("BAG_CLOSED", 0)
expect({ "bag-open:0:false", "assignment-refresh" },
    "closing a player bag did not deactivate assignment affordances")

reset()
ContainerFrame1.scripts.OnShow(ContainerFrame1)
expect({ "bag-open:0:true", "assignment-refresh" },
    "showing the native backpack frame did not activate assignment affordances")
reset()
ContainerFrame1.scripts.OnHide(ContainerFrame1)
expect({ "bag-open:0:false", "assignment-refresh" },
    "hiding the native backpack frame did not deactivate assignment affordances")

reset()
dispatch("CURSOR_CHANGED")
expect({ "assignment-refresh" },
    "cursor changes did not re-evaluate replacement-bag assignment affordances")

local baganatorCallbacks = {}
Baganator = {
    CallbackRegistry = {
        RegisterCallback = function(_, event, callback)
            baganatorCallbacks[event] = callback
        end,
    },
}
reset()
dispatch("ADDON_LOADED", "Baganator")
assert(baganatorCallbacks.BagShow and baganatorCallbacks.BagHide,
    "Baganator public visibility callbacks were not registered")
baganatorCallbacks.BagShow()
expect({ "external-bags-open:true", "assignment-refresh" },
    "Baganator bag show did not activate assignment affordances")
reset()
baganatorCallbacks.BagHide()
expect({ "external-bags-open:false", "assignment-refresh" },
    "Baganator bag hide did not deactivate assignment affordances")

reset()
dispatch("SPELL_UPDATE_COOLDOWN")
expect({ "shortcut-refresh:false", "wheel-refresh", "keys-refresh", "buttons-refresh",
    "consumable-refresh:false" },
    "cooldown refresh fan-out changed")

reset()
dispatch("PLAYER_EQUIPMENT_CHANGED", 16, true)
expect({
    "shortcut-refresh:false", "wheel-refresh", "keys-refresh", "buttons-refresh",
    "consumable-refresh:false",
    "shortcut-secure", "wheel-secure", "keys-secure", "buttons-secure",
    "ui-shortcuts", "ui-keys", "ui-wheel", "ui-buttons", "ui-loadouts-inventory",
}, "equipment inventory changes did not rebuild every secure action")

reset()
dispatch("EQUIPMENT_SETS_CHANGED")
expect({
    "shortcut-secure", "wheel-secure", "keys-secure", "buttons-secure",
    "ui-shortcuts", "ui-keys", "ui-wheel", "ui-buttons", "ui-loadouts",
}, "native equipment-set changes did not rebuild every secure action")

reset()
scheduledTimers = {}
dispatch("UNIT_SPELLCAST_SUCCEEDED", "party1", "cast-guid", 8092)
assert(#scheduledTimers == 0, "another unit's successful cast scheduled cooldown sampling")
dispatch("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-guid", 8092)
assert(#scheduledTimers == 1 and scheduledTimers[1].delay == 0.5,
    "player cast did not schedule delayed cooldown sampling")
expect({}, "delayed cooldown sampling refreshed actions immediately")
scheduledTimers[1].callback()
expect({ "shortcut-refresh:false", "wheel-refresh", "keys-refresh", "buttons-refresh" },
    "delayed cooldown sampling did not refresh every manual action feature")

reset()
scheduledTimers = {}
local refreshWheel = ApogeePartyHealthBars_MouseWheelActions.Refresh
ApogeePartyHealthBars_MouseWheelActions.Refresh = function()
    error("delayed refresh failure")
end
dispatch("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-guid", 8092)
local callbackSucceeded = pcall(scheduledTimers[1].callback)
ApogeePartyHealthBars_MouseWheelActions.Refresh = refreshWheel
assert(callbackSucceeded, "delayed cooldown sampling leaked an asynchronous error")
assert(calls[1] == "shortcut-refresh:false"
        and calls[2]
        and calls[2]:find("print:event error (delayed cooldown sampling):", 1, true)
        and calls[2]:find("delayed refresh failure", 1, true),
    "delayed cooldown sampling did not report its asynchronous error")

reset()
dispatch("UNIT_FLAGS", "party1")
dispatch("UNIT_FLAGS", "target")
expect({ "shortcut-refresh:false" }, "target flag filtering changed")

reset()
dispatch("BAG_UPDATE_DELAYED")
expect({
    "consumable-bags", "shortcut-refresh:false", "wheel-refresh", "keys-refresh", "buttons-refresh",
    "ui-shortcuts", "ui-keys", "ui-wheel", "ui-buttons",
}, "bag update fan-out changed")

reset()
dispatch("GET_ITEM_INFO_RECEIVED", 1251, true)
expect({
    "shortcut-item-info", "wheel-item-info", "keys-item-info", "buttons-item-info",
    "consumable-item-info",
    "ui-shortcuts", "ui-keys", "ui-wheel", "ui-buttons", "ui-healing",
}, "item-info fan-out changed")

reset()
dispatch("UNIT_PET", "party1")
dispatch("UNIT_PET", "player")
dispatch("PET_BAR_UPDATE")
expect({ "shortcut-resolve", "shortcut-resolve" },
    "pet action refresh filtering changed after Macro Library removal")

reset()
dispatch("PET_BAR_UPDATE_COOLDOWN")
dispatch("PET_BAR_UPDATE_USABLE")
expect({ "shortcut-refresh:false", "shortcut-refresh:false" },
    "pet action state refresh changed")

reset()
dispatch("ACTIVE_TALENT_GROUP_CHANGED", 2, 1)
expect({ "wheel-spec", "keys-spec", "buttons-spec", "ui-keys", "ui-wheel", "ui-buttons" },
    "active-spec transition order changed")

reset()
wheelLayoutsChanged, keyLayoutsChanged, buttonLayoutsChanged = false, false, false
dispatch("SPELLS_CHANGED")
expect({
    "class-bindings", "player-spells", "shortcut-resolve", "wheel-layouts",
    "keys-layouts", "buttons-layouts", "wheel-refresh", "keys-refresh", "buttons-refresh",
    "request-update",
}, "stable spell-layout refresh order changed")

reset()
wheelLayoutsChanged, keyLayoutsChanged, buttonLayoutsChanged = true, true, true
dispatch("SPELLS_CHANGED")
expect({
    "class-bindings", "player-spells", "shortcut-resolve", "wheel-layouts",
    "keys-layouts", "buttons-layouts", "ui-keys", "ui-wheel", "ui-buttons",
    "request-update",
}, "changed spell-layout refresh order changed")

reset()
dispatch("UPDATE_BINDINGS")
expect({ "bindings-reconcile", "ui-keys", "ui-wheel", "ui-buttons" },
    "binding reconciliation order changed")

reset()
dispatch("CVAR_UPDATE", "ActionButtonUseKeyDown", "1")
expect({ "wheel-click-phase", "keys-click-phase", "buttons-click-phase" },
    "action-button click timing refresh changed")
reset()
dispatch("CVAR_UPDATE", "unrelatedCVar", "1")
expect({}, "unrelated CVar refreshed physical click timing")

reset()
dispatch("UPDATE_SHAPESHIFT_FORM")
expect({ "shortcut-refresh:false", "wheel-state", "keys-state", "buttons-state",
    "ui-keys", "ui-wheel", "ui-buttons", "layout" },
    "form-state transition order changed")

reset()
dispatch("UPDATE_STEALTH")
expect({ "shortcut-refresh:false", "wheel-state", "keys-state", "buttons-state",
    "ui-keys", "ui-wheel", "ui-buttons", "layout" },
    "stealth-state transition order changed")

reset()
dispatch("UPDATE_SHAPESHIFT_FORMS")
expect({ "wheel-layouts", "keys-layouts", "buttons-layouts", "ui-keys", "ui-wheel", "ui-buttons", "layout" },
    "form-state registry refresh order changed")

reset()
local originalSpecChanged = ApogeePartyHealthBars_MouseWheelActions.OnActiveSpecChanged
ApogeePartyHealthBars_MouseWheelActions.OnActiveSpecChanged = function()
    error("expected action failure")
end
dispatch("ACTIVE_TALENT_GROUP_CHANGED")
assert(calls[#calls]:find("print:event error (ACTIVE_TALENT_GROUP_CHANGED):", 1, true),
    "action subscriber lost its event error bridge")
ApogeePartyHealthBars_MouseWheelActions.OnActiveSpecChanged = originalSpecChanged

print("PASS runtime action events")
