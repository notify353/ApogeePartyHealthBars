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
    configMode = false,
    InitializeClassDefaultBindings = function() record("class-bindings") end,
    RequestUpdate = function() record("request-update") end,
}
ApogeePartyHealthBars_Effects = {
    InitializeSavedVariables = function() record("saved-variables") end,
}
ApogeePartyHealthBars_ShortcutBar = {
    Initialize = function() record("shortcut-init") end,
    Rebaseline = function() record("shortcut-rebaseline") end,
    RefreshSecureActions = function() record("shortcut-secure") end,
}
ApogeePartyHealthBars_WheelMacros = {
    InitializeSaved = function() record("wheel-init") end,
    OnCombatStarted = function() record("wheel-combat-start") end,
    OnCombatEnded = function() record("wheel-combat-end") end,
    ReconcileBindings = function() record("wheel-reconcile") end,
    Refresh = function() record("wheel-refresh") end,
}
ApogeePartyHealthBars_KeyActions = {
    InitializeSaved = function() record("keys-init") end,
    OnCombatStarted = function() record("keys-combat-start") end,
    OnCombatEnded = function() record("keys-combat-end") end,
    ReconcileBindings = function() record("keys-reconcile") end,
    Refresh = function() record("keys-refresh") end,
}
ApogeePartyHealthBars_MouseButtonActions = {
    InitializeSaved = function() record("buttons-init") end,
    OnCombatStarted = function() record("buttons-combat-start") end,
    OnCombatEnded = function() record("buttons-combat-end") end,
    Refresh = function() record("buttons-refresh") end,
}
ApogeePartyHealthBars_ConsumableBar = {
    Initialize = function() record("consumable-init") end,
    OnCombatEnded = function() record("consumable-combat-end") end,
    OnBagUpdate = function() record("consumable-bags") end,
}
ApogeePartyHealthBars_RaidMarkers = {
    OnCombatLogEvent = function() record("raid-combat-log") end,
}
ApogeePartyHealthBars_Threat = { Refresh = function() record("threat") end }
ApogeePartyHealthBars_SecureFrames = {
    FlushDeferredUpdates = function() record("secure-flush") end,
}
ApogeePartyHealthBars_CombatUIFader = {
    Initialize = function(enabled) record("fader-init:" .. tostring(enabled)) end,
    OnCombatStart = function() record("fader-combat-start") end,
    OnCombatEnd = function() record("fader-combat-end") end,
}
ApogeePartyHealthBars_BindingStore = {
    Initialize = function() record("binding-store") end,
}
ApogeePartyHealthBars_MacroLibrary = {
    ValidateAll = function()
        record("macro-validation")
        return false, { "broken recipe" }
    end,
}
local runtimeFailures = {}
ApogeePartyHealthBars_ClientCapabilities = {
    RecordRuntimeFailure = function(owner, reason)
        runtimeFailures[owner] = tostring(reason)
    end,
    ListUnavailableFeatures = function() return {} end,
    ListRuntimeFailures = function()
        local result = {}
        for owner, reason in pairs(runtimeFailures) do
            result[#result + 1] = { owner = owner, reason = reason }
        end
        return result
    end,
}
local initializedProfileClass
ApogeePartyHealthBars_ProfileStore = {
    Initialize = function(account, character, currentClass)
        initializedProfileClass = currentClass
        ApogeePartyHealthBars_S.sv = account
        ApogeePartyHealthBars_S.charSv = character
    end,
}
function UnitClass() return "Warrior", "WARRIOR" end
function UnitFullName() return "Bold", "Dreamscythe" end
local reloadTimerDelay, reloadTimerCallback
C_Timer = {
    After = function(delay, callback)
        reloadTimerDelay, reloadTimerCallback = delay, callback
    end,
}

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

local deps = {
    Print = function(message) record("print:" .. message) end,
    InitPlayerSpells = function() record("player-spells") end,
    RestorePosition = function() record("restore-position") end,
    UpdateHeader = function() record("update-header") end,
    EnsureMinimapButton = function() record("minimap") end,
    SeedShieldTrackerFromAuras = function() record("shield-seed") end,
    ForceRefresh = function() record("force-refresh") end,
    IsShieldEnabled = function() return true end,
    OnShieldCombatLog = function() record("shield-combat-log") end,
    SetConfigMode = function(active) record("config-mode:" .. tostring(active)) end,
    ClaimBoundActionBindings = function() record("bindings-claim"); return true end,
    ReleaseBoundActionBindings = function() record("bindings-release"); return true end,
    ReconcileBoundActionBindings = function() record("bindings-reconcile"); return true end,
}

dofile("ApogeePartyHealthBars_RuntimeLifecycleEvents.lua")
local events = ApogeePartyHealthBars_RuntimeLifecycleEvents

local valid, validationError = pcall(events.Register, router, {})
assert(not valid and tostring(validationError):find("Print", 1, true),
    "lifecycle subscriber accepted incomplete dependencies")
events.Register(router, deps)

for _, event in ipairs({
    "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE",
    "PLAYER_TARGET_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
}) do
    assert(required[event] and required[event].owner == "Bootstrap",
        "required lifecycle event changed registration: " .. event)
end
assert(optional.COMBAT_LOG_EVENT_UNFILTERED
        and optional.COMBAT_LOG_EVENT_UNFILTERED.owner == "Bootstrap",
    "combat-log lifecycle event was not optional")
assert(optional.ADDON_LOADED == nil,
    "lifecycle still subscribes to ADDON_LOADED for modified-click hooks")

ApogeePartyHealthSV = { enabled = true, combatUIAutoHide = true }
ApogeePartyHealthCharSV = {}
dispatch("PLAYER_LOGIN")
expect({
    "saved-variables", "binding-store", "fader-init:true", "macro-validation",
    "print:macro validation: broken recipe", "class-bindings", "shortcut-init",
    "wheel-init", "keys-init", "buttons-init", "consumable-init", "bindings-claim", "player-spells", "restore-position", "update-header",
    "minimap", "shield-seed", "force-refresh",
}, "PLAYER_LOGIN order changed")
assert(ApogeePartyHealthBars_S.sv == ApogeePartyHealthSV
        and ApogeePartyHealthBars_S.charSv == ApogeePartyHealthCharSV,
    "PLAYER_LOGIN did not attach saved-variable roots")
assert(initializedProfileClass == "WARRIOR",
    "PLAYER_LOGIN discarded UnitClass's class token")

reset()
ApogeePartyHealthBars_S.configMode = true
dispatch("PLAYER_REGEN_DISABLED")
expect({
    "fader-combat-start", "wheel-combat-start", "keys-combat-start", "buttons-combat-start",
    "print:config closed - combat started.", "config-mode:false", "force-refresh",
}, "combat-entry order changed")

reset()
dispatch("PLAYER_REGEN_ENABLED")
expect({
    "fader-combat-end", "secure-flush", "shortcut-secure", "wheel-combat-end",
    "keys-combat-end", "buttons-combat-end", "consumable-combat-end",
    "bindings-reconcile", "threat", "force-refresh",
}, "combat-exit order changed")

reset()
dispatch("PLAYER_ENTERING_WORLD")
expect({
    "shortcut-rebaseline", "consumable-bags", "bindings-reconcile", "player-spells",
    "minimap", "shield-seed", "threat", "request-update",
}, "world-entry order changed")

reset()
reloadTimerDelay, reloadTimerCallback = nil, nil
dispatch("PLAYER_ENTERING_WORLD", false, true)
expect({
    "shortcut-rebaseline", "consumable-bags", "bindings-reconcile", "player-spells",
    "minimap", "shield-seed", "threat", "request-update",
}, "reload world-entry order changed")
assert(reloadTimerDelay == 0 and type(reloadTimerCallback) == "function",
    "UI reload did not schedule a post-world consumable rescan")
reset()
reloadTimerCallback()
expect({ "consumable-bags" },
    "deferred UI-reload consumable rescan did not run")

reset()
runtimeFailures = {}
local originalReconcile = deps.ReconcileBoundActionBindings
deps.ReconcileBoundActionBindings = function()
    record("bindings-reconcile")
    return false, "binding_failed", "expected reconciliation failure"
end
dispatch("PLAYER_ENTERING_WORLD")
assert(runtimeFailures["Physical bindings"]
        and runtimeFailures["Physical bindings"]:find("expected reconciliation failure", 1, true)
        and calls[#calls] == "request-update",
    "returned binding reconciliation failure was swallowed or blocked later work")
deps.ReconcileBoundActionBindings = originalReconcile

reset()
dispatch("GROUP_ROSTER_UPDATE")
expect({ "player-spells", "minimap", "shield-seed", "threat", "request-update" },
    "roster-update order changed")

reset()
dispatch("PLAYER_TARGET_CHANGED")
expect({ "shortcut-rebaseline", "wheel-refresh", "keys-refresh", "buttons-refresh", "threat", "request-update" },
    "target-change order changed")

reset()
dispatch("COMBAT_LOG_EVENT_UNFILTERED")
expect({ "raid-combat-log", "shield-combat-log" }, "combat-log fan-out changed")

reset()
local originalInitPlayerSpells = deps.InitPlayerSpells
deps.InitPlayerSpells = function() error("expected lifecycle failure") end
dispatch("GROUP_ROSTER_UPDATE")
assert(runtimeFailures["Spell discovery"]
        and calls[#calls] == "request-update",
    "lifecycle feature failure was not isolated from the rest of its event")
deps.InitPlayerSpells = originalInitPlayerSpells
runtimeFailures = {}

reset()
local originalWheelInitialize = ApogeePartyHealthBars_WheelMacros.InitializeSaved
ApogeePartyHealthBars_WheelMacros.InitializeSaved = function()
    error("expected optional startup failure")
end
dispatch("PLAYER_LOGIN")
local sawKeys, sawMinimap, sawCompatibility = false, false, false
for _, value in ipairs(calls) do
    if value == "keys-init" then sawKeys = true end
    if value == "minimap" then sawMinimap = true end
    if value:find("print:Compatibility:", 1, true) then sawCompatibility = true end
end
assert(sawKeys and sawMinimap and sawCompatibility and runtimeFailures.Wheel,
    "optional startup failure blocked later features or was not reported")
ApogeePartyHealthBars_WheelMacros.InitializeSaved = originalWheelInitialize

reset()
runtimeFailures = {}
local originalProfileStore = ApogeePartyHealthBars_ProfileStore
ApogeePartyHealthBars_ProfileStore = {
    Initialize = function() error("expected profile storage failure") end,
}
dispatch("PLAYER_LOGIN")
local continuedAfterStorageFailure, reportedStorageEventError = false, false
for _, value in ipairs(calls) do
    if value == "fader-init:true" or value == "wheel-init" or value == "force-refresh" then
        continuedAfterStorageFailure = true
    end
    if value:find("print:event error (PLAYER_LOGIN):", 1, true) then
        reportedStorageEventError = true
    end
end
assert(runtimeFailures["Profile storage"] and not continuedAfterStorageFailure
        and reportedStorageEventError,
    "profile storage failure did not stop startup before consumers used invalid roots")
ApogeePartyHealthBars_ProfileStore = originalProfileStore

print("PASS runtime lifecycle events")
