-- Composition boundary for the four live action families, consumables, cursor
-- assignment, and permanent binding ownership. Feature modules retain their
-- existing facades; this module owns only shared wiring and fan-in policy.
local C = {}
ApogeePartyHealthBars.Define("Actions", "ActionCoordinator", C)
local BoundActionDrag = ApogeePartyHealthBars.Require(
    "Actions", "BoundActionDragController")

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

local function boundFeature(feature)
    if feature == "keyboard" then return D.KeyboardActions end
    if feature == "mouseWheel" then return D.MouseWheelActions end
    if feature == "mouseButtons" then return D.MouseButtonActions end
end

function C.MoveBoundAction(source, destination)
    if not D then return false, "Actions are not initialized." end
    if InCombatLockdown and InCombatLockdown() then
        return false, "Leave combat before moving this action."
    end
    if not boundActionsAvailable() then
        return false, D.ClientCapabilities.GetFeatureReason("boundActions")
            or "Bound actions are unavailable."
    end
    local sourceFeature = type(source) == "table" and boundFeature(source.feature)
    local destinationFeature = type(destination) == "table"
        and boundFeature(destination.feature)
    if not sourceFeature or not destinationFeature
            or not sourceFeature.CanMoveSlot
            or not destinationFeature.CanMoveSlot
            or not sourceFeature.CanMoveSlot(source.layoutKey, source.slotId)
            or not destinationFeature.CanMoveSlot(
                destination.layoutKey, destination.slotId) then
        return false, "Unknown action destination."
    end
    local sourceEntry = sourceFeature.GetSlot(source.layoutKey, source.slotId)
    if not sourceEntry then return false, "That action is empty." end
    if source.feature == destination.feature
            and source.layoutKey == destination.layoutKey
            and source.slotId == destination.slotId then
        return true, destination.slotId
    end
    local destinationEntry = destinationFeature.GetSlot(
        destination.layoutKey, destination.slotId)
    if not sourceFeature.SetSlotForMove(
            source.layoutKey, source.slotId, destinationEntry) then
        return false, "Unable to move that action."
    end
    if not destinationFeature.SetSlotForMove(
            destination.layoutKey, destination.slotId, sourceEntry) then
        sourceFeature.SetSlotForMove(source.layoutKey, source.slotId, sourceEntry)
        return false, "Unable to move that action."
    end
    sourceFeature.RefreshAfterMove()
    if destinationFeature ~= sourceFeature then
        destinationFeature.RefreshAfterMove()
    end
    return true, destination.slotId
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
    BoundActionDrag.Configure(C.MoveBoundAction)

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

