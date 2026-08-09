dofile("Core/Namespace.lua")
dofile("Actions/BoundActionDragController.lua")
dofile("Actions/ActionCoordinator.lua")

local configured, initialized = {}, nil
local manager1, manager2 = {}, {}
local function feature(manager, slots, slotIds)
    local values = slots or {}
    local known, refreshes = {}, 0
    for _, slotId in ipairs(slotIds or {}) do known[slotId] = true end
    return {
        Configure = function(deps) configured[#configured + 1] = deps end,
        GetBindingManager = function() return manager end,
        GetActiveLayoutKey = function() return "default" end,
        GetSlots = function() return values end,
        GetSlot = function(layout, slotId)
            if layout == "default" then return values[slotId] end
        end,
        CanMoveSlot = function(layout, slotId)
            return layout == "default" and known[slotId] == true
        end,
        SetSlotForMove = function(layout, slotId, entry)
            if layout ~= "default" or not known[slotId] then return false end
            values[slotId] = entry
            return true
        end,
        RefreshAfterMove = function() refreshes = refreshes + 1 end,
        GetRefreshCount = function() return refreshes end,
    }
end

local wheel = feature(manager1,
    { one = { kind = "item", itemId = 20 } }, { "one", "empty" })
local keyboard = feature(nil,
    { key = { kind = "spell", spellId = 100 } }, { "key" })
local buttons = feature(manager2,
    { button = { kind = "item", itemId = 30 } }, { "button" })
local consumableDeps
local bindingCalls = {}
local inCombat = false
function InCombatLockdown() return inCombat end
local deps = {
    ShortcutBar = { GetSlots = function() return { { kind = "item", itemId = 10 } } end },
    KeyboardActions = keyboard,
    MouseWheelActions = wheel,
    MouseButtonActions = buttons,
    ConsumableBar = { Configure = function(value) consumableDeps = value end },
    BindingController = {
        Initialize = function(value) initialized = value end,
        AssignCursor = function(...) bindingCalls = { ... }; return true end,
    },
    BindingStore = {
        AssignSpell = function() end, AssignItem = function() end,
        Clear = function() end, Move = function() end,
    },
    BoundActionBindings = {
        ClaimAll = function(managers) assert(#managers == 2); return true, "claimed" end,
        ReleaseAll = function(managers) assert(#managers == 2); return true, "released" end,
        ReconcileAll = function(managers) assert(#managers == 2); return true, "reconciled" end,
    },
    ClientCapabilities = {
        IsFeatureAvailable = function() return true end,
        GetFeatureReason = function() return "unsupported" end,
    },
    Print = function() end, RequestLayout = function() end, SyncTicker = function() end,
    PositionSecureOverlay = function() end, ShowSecureFrame = function() end,
    HideSecureFrame = function() end, SetSecureMouseEnabled = function() end,
    DeferSecureUpdate = function() end, ForceRefresh = function() end,
    GetSpellFromCursor = function() end, GetSettingsUI = function() end,
    RefreshPartyFrameClicksPage = function() end,
    IsAddonEnabled = function() return true end,
    GetConsumableLeftOffset = function() return 0 end,
}

local coordinator = ApogeePartyHealthBars.Require("Actions", "ActionCoordinator")
local ok, err = pcall(coordinator.Initialize, {})
assert(not ok and tostring(err):find("ShortcutBar", 1, true),
    "coordinator accepted missing dependencies")
coordinator.Initialize(deps)
assert(#configured == 3 and configured[1] == configured[2]
    and configured[2] == configured[3],
    "bound action families did not receive one shared dependency contract")
assert(consumableDeps and initialized,
    "consumable or cursor assignment lifecycle was not initialized")
assert(coordinator.IsItemAssigned(10) and coordinator.IsItemAssigned(20),
    "coordinator did not fan in assigned-item state")
assert(coordinator.AssignCursorDrop("keyboard", "one", "default") == true
    and bindingCalls[1] == "keyboard", "cursor assignment bypassed its controller")
assert(select(2, coordinator.ClaimBoundActionBindings()) == "claimed")
assert(select(2, coordinator.ReleaseBoundActionBindings()) == "released")
assert(select(2, coordinator.ReconcileBoundActionBindings()) == "reconciled")

local wheelEntry, keyboardEntry = wheel.GetSlot("default", "one"),
    keyboard.GetSlot("default", "key")
assert(coordinator.MoveBoundAction(
    { feature = "mouseWheel", layoutKey = "default", slotId = "one" },
    { feature = "keyboard", layoutKey = "default", slotId = "key" }))
assert(wheel.GetSlot("default", "one") == keyboardEntry
        and keyboard.GetSlot("default", "key") == wheelEntry,
    "coordinator did not swap complete actions across live bound-action HUDs")
assert(wheel.GetRefreshCount() == 1 and keyboard.GetRefreshCount() == 1,
    "cross-feature movement did not refresh each affected family exactly once")

assert(coordinator.MoveBoundAction(
    { feature = "keyboard", layoutKey = "default", slotId = "key" },
    { feature = "mouseWheel", layoutKey = "default", slotId = "empty" }))
assert(keyboard.GetSlot("default", "key") == nil
        and wheel.GetSlot("default", "empty") == wheelEntry,
    "coordinator did not move an action into an empty bound-action slot")

local beforeCombat = buttons.GetSlot("default", "button")
inCombat = true
assert(not coordinator.MoveBoundAction(
    { feature = "mouseButtons", layoutKey = "default", slotId = "button" },
    { feature = "mouseWheel", layoutKey = "default", slotId = "one" })
        and buttons.GetSlot("default", "button") == beforeCombat,
    "combat movement changed a configured bound action")
inCombat = false
assert(not coordinator.MoveBoundAction(
    { feature = "shortcut", layoutKey = "default", slotId = "one" },
    { feature = "keyboard", layoutKey = "default", slotId = "key" }),
    "coordinator accepted a non-bound action family")

print("PASS action coordinator")
