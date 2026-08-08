-- Composition boundary for the four live action families, consumables, cursor
-- assignment, and permanent binding ownership. Feature modules retain their
-- existing facades; this module owns only shared wiring and fan-in policy.
local C = {}
ApogeePartyHealthBars.Define("Actions", "ActionCoordinator", C)

local D

local REQUIRED = {
    "ShortcutBar", "KeyboardActions", "MouseWheelActions", "MouseButtonActions",
    "ConsumableBar", "BindingController", "BindingStore", "BoundActionBindings",
    "ClientCapabilities", "Print", "RequestLayout", "SyncTicker",
    "PositionSecureOverlay", "ShowSecureFrame", "HideSecureFrame",
    "SetSecureMouseEnabled", "DeferSecureUpdate", "ForceRefresh",
    "GetSpellFromCursor", "GetSettingsUI", "RefreshPartyFrameClicksPage",
    "IsAddonEnabled", "GetConsumableLeftOffset",
}

local function managers()
    local result = {}
    for _, feature in ipairs({
        D.MouseWheelActions, D.KeyboardActions, D.MouseButtonActions,
    }) do
        local manager = feature.GetBindingManager and feature.GetBindingManager()
        if manager then result[#result + 1] = manager end
    end
    return result
end

function C.IsItemAssigned(itemId)
    if not D then return false end
    for _, entry in pairs(D.ShortcutBar.GetSlots() or {}) do
        if type(entry) == "table" and entry.kind == "item"
            and entry.itemId == itemId then return true end
    end
    for _, feature in ipairs({
        D.MouseWheelActions, D.KeyboardActions, D.MouseButtonActions,
    }) do
        local layoutKey = feature.GetActiveLayoutKey()
        for _, entry in pairs(feature.GetSlots(layoutKey) or {}) do
            if type(entry) == "table" and entry.kind == "item"
                and entry.itemId == itemId then return true end
        end
    end
    return false
end

function C.AssignCursorDrop(feature, slot, layoutKey)
    return D and D.BindingController.AssignCursor
        and D.BindingController.AssignCursor(feature, slot, layoutKey) or false
end

local function boundActionsAvailable()
    return D.ClientCapabilities.IsFeatureAvailable("boundActions")
end

function C.ClaimBoundActionBindings()
    if not boundActionsAvailable() then
        return true, "unsupported",
            D.ClientCapabilities.GetFeatureReason("boundActions")
    end
    return D.BoundActionBindings.ClaimAll(managers())
end

function C.ReleaseBoundActionBindings()
    if not boundActionsAvailable() then
        return true, "unsupported",
            D.ClientCapabilities.GetFeatureReason("boundActions")
    end
    return D.BoundActionBindings.ReleaseAll(managers())
end

function C.ReconcileBoundActionBindings()
    if not D.IsAddonEnabled() then return true, "disabled" end
    if not boundActionsAvailable() then return true, "unsupported" end
    return D.BoundActionBindings.ReconcileAll(managers())
end

function C.Initialize(deps)
    assert(not D, "ActionCoordinator already initialized")
    for _, key in ipairs(REQUIRED) do
        assert(deps and deps[key] ~= nil,
            "ActionCoordinator missing dependency: " .. key)
    end
    D = deps

    local common = {
        Print = D.Print,
        RequestLayout = D.RequestLayout,
        SyncTicker = D.SyncTicker,
        PositionSecureOverlay = D.PositionSecureOverlay,
        ShowSecureFrame = D.ShowSecureFrame,
        HideSecureFrame = D.HideSecureFrame,
        SetSecureMouseEnabled = D.SetSecureMouseEnabled,
        AssignCursorDrop = C.AssignCursorDrop,
    }
    D.MouseWheelActions.Configure(common)
    D.KeyboardActions.Configure(common)
    D.MouseButtonActions.Configure(common)

    D.ConsumableBar.Configure({
        RequestLayout = D.RequestLayout,
        SyncTicker = D.SyncTicker,
        GetLeftOffset = D.GetConsumableLeftOffset,
        IsAddonEnabled = D.IsAddonEnabled,
        IsItemAssigned = C.IsItemAssigned,
        PositionSecureOverlay = D.PositionSecureOverlay,
        ShowSecureFrame = D.ShowSecureFrame,
        HideSecureFrame = D.HideSecureFrame,
        SetSecureMouseEnabled = D.SetSecureMouseEnabled,
        DeferSecureUpdate = D.DeferSecureUpdate,
    })

    D.BindingController.Initialize({
        AssignBindingSpell = D.BindingStore.AssignSpell,
        AssignBindingItem = D.BindingStore.AssignItem,
        ClearBindingAction = D.BindingStore.Clear,
        MoveBindingAction = D.BindingStore.Move,
        RefreshPartyFrameClicksPage = D.RefreshPartyFrameClicksPage,
        ForceRefresh = D.ForceRefresh,
        Print = D.Print,
        SyncVisualTicker = D.SyncTicker,
        GetSpellFromCursor = D.GetSpellFromCursor,
        GetSettingsUI = D.GetSettingsUI,
        ClientCapabilities = D.ClientCapabilities,
    })
    return C
end

