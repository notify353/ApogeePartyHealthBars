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
    HookSpellbook = function() record("hook-spellbook") end,
    HookContainerItems = function() record("hook-items") end,
    EnsureMinimapButton = function() record("minimap") end,
    SeedShieldTrackerFromAuras = function() record("shield-seed") end,
    ForceRefresh = function() record("force-refresh") end,
    IsShieldEnabled = function() return true end,
    OnShieldCombatLog = function() record("shield-combat-log") end,
    SetConfigMode = function(active) record("config-mode:" .. tostring(active)) end,
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
    "COMBAT_LOG_EVENT_UNFILTERED",
}) do
    assert(required[event] and required[event].owner == "Bootstrap",
        "required lifecycle event changed registration: " .. event)
end
assert(optional.ADDON_LOADED and optional.ADDON_LOADED.owner == "Bootstrap",
    "ADDON_LOADED changed optional registration")

ApogeePartyHealthSV = { combatUIAutoHide = true }
ApogeePartyHealthCharSV = {}
dispatch("PLAYER_LOGIN")
expect({
    "saved-variables", "binding-store", "fader-init:true", "macro-validation",
    "print:macro validation: broken recipe", "class-bindings", "shortcut-init",
    "wheel-init", "keys-init", "player-spells", "restore-position", "update-header",
    "hook-spellbook", "hook-items", "minimap", "shield-seed", "force-refresh",
}, "PLAYER_LOGIN order changed")
assert(ApogeePartyHealthBars_S.sv == ApogeePartyHealthSV
        and ApogeePartyHealthBars_S.charSv == ApogeePartyHealthCharSV,
    "PLAYER_LOGIN did not attach saved-variable roots")

reset()
ApogeePartyHealthBars_S.configMode = true
dispatch("PLAYER_REGEN_DISABLED")
expect({
    "fader-combat-start", "wheel-combat-start", "keys-combat-start",
    "print:config closed - combat started.", "config-mode:false", "force-refresh",
}, "combat-entry order changed")

reset()
dispatch("PLAYER_REGEN_ENABLED")
expect({
    "fader-combat-end", "secure-flush", "shortcut-secure", "wheel-combat-end",
    "keys-combat-end", "threat", "force-refresh",
}, "combat-exit order changed")

reset()
dispatch("PLAYER_ENTERING_WORLD")
expect({
    "shortcut-rebaseline", "wheel-reconcile", "keys-reconcile", "player-spells",
    "minimap", "shield-seed", "threat", "request-update",
}, "world-entry order changed")

reset()
dispatch("GROUP_ROSTER_UPDATE")
expect({ "player-spells", "minimap", "shield-seed", "threat", "request-update" },
    "roster-update order changed")

reset()
dispatch("PLAYER_TARGET_CHANGED")
expect({ "shortcut-rebaseline", "wheel-refresh", "keys-refresh", "threat", "request-update" },
    "target-change order changed")

reset()
dispatch("ADDON_LOADED", "unrelated")
expect({}, "unrelated ADDON_LOADED triggered hooks")
dispatch("ADDON_LOADED", "Blizzard_SpellBook")
expect({ "hook-spellbook", "hook-items" }, "Spellbook load did not restore hooks")

reset()
dispatch("COMBAT_LOG_EVENT_UNFILTERED")
expect({ "raid-combat-log", "shield-combat-log" }, "combat-log fan-out changed")

reset()
local originalInitPlayerSpells = deps.InitPlayerSpells
deps.InitPlayerSpells = function() error("expected lifecycle failure") end
dispatch("GROUP_ROSTER_UPDATE")
assert(calls[#calls]:find("print:event error (GROUP_ROSTER_UPDATE):", 1, true),
    "lifecycle subscriber lost its event error bridge")
deps.InitPlayerSpells = originalInitPlayerSpells

print("PASS runtime lifecycle events")
