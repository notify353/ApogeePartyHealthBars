dofile("Core/Namespace.lua")
dofile("Actions/ActionCoordinator.lua")

local configured, initialized = {}, nil
local manager1, manager2 = {}, {}
local function feature(manager, slots)
    return {
        Configure = function(deps) configured[#configured + 1] = deps end,
        GetBindingManager = function() return manager end,
        GetActiveLayoutKey = function() return "default" end,
        GetSlots = function() return slots or {} end,
    }
end

local wheel = feature(manager1, { one = { kind = "item", itemId = 20 } })
local keyboard = feature(nil)
local buttons = feature(manager2)
local consumableDeps
local bindingCalls = {}
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

print("PASS action coordinator")

