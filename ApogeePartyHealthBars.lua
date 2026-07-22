-- =============================================================================
-- ApogeePartyHealthBars.lua
-- =============================================================================
-- Party HP bars for healing (player + party1-4, aligned two-level unit targets).
-- Class-agnostic: click-cast, range, mana, shields, and buff icons use your spellbook.
-- Configure via minimap button (left-click).
-- =============================================================================
local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local A = ApogeePartyHealthBars_Auras
local E = ApogeePartyHealthBars_Effects
local T = ApogeePartyHealthBars_ShortcutBar
local W = ApogeePartyHealthBars_WheelMacros
local K = ApogeePartyHealthBars_KeyActions
local B = ApogeePartyHealthBars_MouseButtonActions
local CB = ApogeePartyHealthBars_ConsumableBar
local AH = ApogeePartyHealthBars_ActionHud
local M = ApogeePartyHealthBars_RaidMarkers
local H = ApogeePartyHealthBars_Threat
local rowGeometry = ApogeePartyHealthBars_RowGeometry
local visualTicker = ApogeePartyHealthBars_VisualTicker
local buffReminders = ApogeePartyHealthBars_BuffReminders
local shieldTracker = ApogeePartyHealthBars_ShieldTracker
local incomingHeals = ApogeePartyHealthBars_IncomingHeals
local hotTracker = ApogeePartyHealthBars_HotTracker
local unitTopology = ApogeePartyHealthBars_UnitTopology
local unitAPI = ApogeePartyHealthBars_UnitAPI
local unitBar = ApogeePartyHealthBars_UnitBar
local playerUtility = ApogeePartyHealthBars_PlayerUtility

local panel, configUI, minimapController
local rows = {}

local throttleFrame = CreateFrame("Frame")
throttleFrame:Hide()

local valuesFlushFrame = CreateFrame("Frame")
valuesFlushFrame:Hide()

local function CancelValuesFlush()
    valuesFlushFrame:Hide()
end

function S.RequestUpdate()
    CancelValuesFlush()
    S.layoutDirty = true
    S.valuesDirty = true
    S.valuesDirtyUnits = nil
    throttleFrame:Show()
end

function S.RequestLayoutUpdate()
    CancelValuesFlush()
    S.layoutDirty = true
    S.valuesDirty = true
    S.valuesDirtyUnits = nil
    throttleFrame:Show()
end

function S.RequestValuesUpdate(unitId)
    S.valuesDirty = true
    if unitId then
        S.valuesDirtyUnits = S.valuesDirtyUnits or {}
        S.valuesDirtyUnits[unitId] = true
    else
        S.valuesDirtyUnits = nil
    end
    if S.layoutDirty then
        CancelValuesFlush()
        throttleFrame:Show()
    else
        valuesFlushFrame:Show()
    end
end

local UpdateUI
local UpdateHeader
local UpdateRowValues
local LayoutRows
local unitToRow = {}
local ApplyAllPartyBuffBindings
local ApplyAllSelfBuffBindings
local HideAllSecureOverlays
local SyncCastOverlays
local UpdateRowContent
local SetConfigMode
local ExitConfigMode
local SetAddonEnabled
local FactoryReset
local SetSavedFeature
local RefreshConfigPanel
local ApplyAllBindings
local RefreshBindPanel
local ApplyAllSecureBindings
local ReconcileBoundActionBindings
local EnsureMinimapButton
local InitHotSpells

local function SyncVisualTicker()
    visualTicker.Sync()
end

local secureFrames = ApogeePartyHealthBars_SecureFrames
local DeferSecureUpdate = secureFrames.RequestSecureUpdate
local HideSecureFrame = secureFrames.Hide
local ShowSecureFrame = secureFrames.Show
local SetSecureMouseEnabled = secureFrames.SetMouseEnabled
local PositionSecureOverlay = secureFrames.PositionOverlay

local function IsSavedFeatureEnabled(svKey)
    return S.sv and S.sv[svKey] ~= false
end

local SUPPORT_FEATURE_BY_SETTING = {
    partyBuffEnabled = "auraReminders",
    selfBuffEnabled = "auraReminders",
    clickableBuffIcons = "auraReminders",
    shieldEnabled = "shieldOverlay",
    incomingHealEnabled = "incomingHeals",
    rangeCheckEnabled = "rangeFade",
    threatEnabled = "threat",
    threatPercentEnabled = "threat",
    hotEnabled = "hotTracking",
}

local function IsEffectiveFeatureEnabled(svKey)
    if not IsSavedFeatureEnabled(svKey) then return false end
    local featureKey = SUPPORT_FEATURE_BY_SETTING[svKey]
    return not featureKey
        or ApogeePartyHealthBars_ClientCapabilities.IsFeatureAvailable(featureKey)
end

local function IsUnitTargetsEnabled()
    return IsSavedFeatureEnabled("showUnitTargets")
end

local function GetTargetColumnWidth()
    if not IsUnitTargetsEnabled() then return 0 end
    return 2 * (C.UNIT_BAR_W + C.UNIT_COLUMN_GAP)
end

local function GetRowBtnWidth(row)
    return C.ROW_CONTENT_W + GetTargetColumnWidth(row)
end

local function IsPanelTrackedUnit(unit)
    return unitTopology.IsTracked(unit)
end

-- =============================================================================
-- Effect runtimes
-- =============================================================================

local function GetAllSurfaces()
    local surfaces = {}
    for _, row in ipairs(rows) do
        if row.surfaces then
            for _, surface in ipairs(row.surfaces) do surfaces[#surfaces + 1] = surface end
        end
    end
    return surfaces
end

hotTracker.Initialize({
    Auras = A,
    Effects = E,
    GetSurfaces = GetAllSurfaces,
    SyncVisualTicker = SyncVisualTicker,
    IsSavedFeatureEnabled = IsEffectiveFeatureEnabled,
    GetSavedVariables = function() return S.sv end,
})
local IsHotEnabled = hotTracker.IsEnabled
local GetHotStripHeight = hotTracker.GetStripHeight
local GetActiveHotTrackCount = hotTracker.GetActiveTrackCount
InitHotSpells = hotTracker.RefreshKnownSpells
local HasActiveHotVisuals = hotTracker.HasActiveVisuals
local TickHotVisuals = hotTracker.TickVisuals
local UpdateRowHotVisuals = hotTracker.UpdateRowVisuals

buffReminders.Initialize({
    Auras = A,
    Effects = E,
    GetSurfaces = GetAllSurfaces,
    IsSavedFeatureEnabled = IsEffectiveFeatureEnabled,
    IsConfigMode = function() return S.configMode end,
    GetCharacterSavedVariables = function() return S.charSv end,
    ApplyAllSelfBuffBindings = function() ApplyAllSelfBuffBindings() end,
    RequestLayoutUpdate = S.RequestLayoutUpdate,
    SetSelfBuffIconTexture = function(texture)
        ApogeePartyHealthBars_PlayerUtility.SetIconTexture(texture)
    end,
})
local ShouldShowPartyBuffIcon = buffReminders.ShouldShowPartyIcon
local ShouldShowSelfBuffIcon = buffReminders.ShouldShowSelfIcon
local GetSelfBuffPreferenceOptions = buffReminders.GetSelfPreferenceOptions
local GetSelfBuffPreferenceKey = buffReminders.GetSelfPreferenceKey
local SetSelfBuffPreference = buffReminders.SetSelfPreference

local function InitPlayerSpells()
    buffReminders.RefreshKnownSpells()
    InitHotSpells()
    if S.configMode then RefreshConfigPanel() end
end

shieldTracker.Initialize({
    Auras = A,
    IsSavedFeatureEnabled = IsEffectiveFeatureEnabled,
    IsConfigMode = function() return S.configMode end,
    RequestUpdate = S.RequestUpdate,
    IsTrackedUnit = IsPanelTrackedUnit,
    GetTrackedUnits = unitTopology.GetTrackedTokens,
})
local IsShieldEnabled = shieldTracker.IsEnabled
local ShouldTrackShieldUnit = shieldTracker.ShouldTrackUnit
local ShieldTrackerSyncUnit = shieldTracker.SyncUnit
local OnShieldCombatLog = shieldTracker.OnCombatLog
local SeedShieldTrackerFromAuras = shieldTracker.SeedFromAuras
local GetUnitShieldRemaining = shieldTracker.GetRemaining
local UpdateRowShieldVisual = shieldTracker.UpdateRowVisual

incomingHeals.Initialize({
    IsSavedFeatureEnabled = IsEffectiveFeatureEnabled,
    IsConfigMode = function() return S.configMode end,
    IsTrackedUnit = IsPanelTrackedUnit,
})
local UpdateIncomingHealBarVisual = incomingHeals.UpdateBarVisual
local UpdateRowIncomingHealVisual = incomingHeals.UpdateRowVisual

local function IsUnitInPrimaryActionRange(unitId)
    if not IsEffectiveFeatureEnabled("rangeCheckEnabled") or S.configMode then return true end
    if not unitAPI.Exists(unitId) or unitAPI.IsDead(unitId) then return true end
    local action = ApogeePartyHealthBars_ActionData.Normalize(S.GetBinding("1"))
    if not action or action.kind ~= "spell" or not IsSpellInRange then
        return unitAPI.GetDefaultRange(unitId)
    end
    local spellName = action.spellName or (action.spellId and GetSpellInfo(action.spellId))
    if not spellName then return unitAPI.GetDefaultRange(unitId) end
    local inRange = IsSpellInRange(spellName, unitId)
    if inRange == nil then return unitAPI.GetDefaultRange(unitId) end
    return inRange == 1 or inRange == true
end

rowGeometry.Initialize({
    GetHotStripHeight = GetHotStripHeight,
    PlayerUtility = playerUtility,
    ShortcutBar = T,
    RaidMarkers = M,
    WheelMacros = W,
    KeyActions = K,
    MouseButtonActions = B,
    ConsumableBar = CB,
})
local GetActionAreaHeight = rowGeometry.GetActionAreaHeight

unitBar.Initialize({
    GetHotStripHeight = GetHotStripHeight,
    GetActiveHotTrackCount = GetActiveHotTrackCount,
    IsUnitInPrimaryActionRange = IsUnitInPrimaryActionRange,
    ShouldShowPartyBuffIcon = ShouldShowPartyBuffIcon,
    IsShieldEnabled = IsShieldEnabled,
    ShouldTrackShieldUnit = ShouldTrackShieldUnit,
    GetUnitShieldRemaining = GetUnitShieldRemaining,
    UpdateShieldVisual = UpdateRowShieldVisual,
    UpdateIncomingVisual = UpdateRowIncomingHealVisual,
    UpdateHotVisuals = UpdateRowHotVisuals,
    RequestLayoutUpdate = S.RequestLayoutUpdate,
})

-- =============================================================================

local function Print(msg)
    print(C.ADDON_PREFIX .. " " .. msg)
end

local function IsEnabled()
    return IsSavedFeatureEnabled("enabled")
end

local function RunUpdate()
    local ok, err = pcall(UpdateUI)
    if not ok then
        Print("update error: " .. tostring(err))
    end
    return ok
end

local function RunValuesOnlyUpdate()
    if not IsEnabled() then
        S.valuesDirty = false
        S.valuesDirtyUnits = nil
        return true
    end
    A.BeginAuraCacheGeneration()
    local ok, err = pcall(UpdateRowValues)
    if not ok then
        Print("values update error: " .. tostring(err))
        return false
    end
    S.valuesDirty = false
    S.valuesDirtyUnits = nil
    return true
end

local function ClearDirtyFlags()
    S.layoutDirty = false
    S.valuesDirty = false
    S.valuesDirtyUnits = nil
end

local function ForceRefresh()
    CancelValuesFlush()
    S.layoutDirty = true
    S.valuesDirty = true
    S.valuesDirtyUnits = nil
    if RunUpdate() then
        ClearDirtyFlags()
        throttleFrame:Hide()
    end
end

visualTicker.Initialize({
    IsAddonEnabled = IsEnabled,
    IsRangeCheckEnabled = function() return IsEffectiveFeatureEnabled("rangeCheckEnabled") end,
    IsConfigMode = function() return S.configMode end,
    HasActiveHotVisuals = HasActiveHotVisuals,
    TickHotVisuals = TickHotVisuals,
    RefreshUnitChains = function() S.RefreshUnitChains() end,
    RefreshRangeAlpha = function() S.RefreshRangeAlpha() end,
    ShortcutBar = T,
    WheelMacros = W,
    KeyActions = K,
    MouseButtonActions = B,
    ConsumableBar = CB,
    Threat = H,
    DotTracker = ApogeePartyHealthBars_DotTracker,
})
local targetChainGUIDs = {}

function S.RefreshUnitChains()
    if not IsEnabled() then return end

    local targetChainChanged = false
    local visibleSurfaces = {}
    if IsSavedFeatureEnabled("showUnitTargets") then
        for _, row in ipairs(rows) do
            if row.btn:IsShown() then
                for _, surface in ipairs({ row.target, row.targetOfTarget }) do
                    local guid = unitAPI.GetGUID(surface.unitId) or false
                    if targetChainGUIDs[surface.unitId] ~= guid then
                        targetChainGUIDs[surface.unitId] = guid
                        targetChainChanged = true
                    end
                    if surface.visible then
                        visibleSurfaces[#visibleSurfaces + 1] = surface
                    end
                end
            end
        end
    else
        targetChainGUIDs = {}
    end

    if targetChainChanged then
        S.RequestLayoutUpdate()
        return
    end

    if #visibleSurfaces > 0 then
        A.BeginAuraCacheGeneration()
        for _, surface in ipairs(visibleSurfaces) do surface:RefreshValues() end
    end
end

function S.RefreshRangeAlpha()
    if not IsEnabled() then return end
    for _, surface in ipairs(GetAllSurfaces()) do
        if surface.visible then surface:RefreshAlpha() end
    end
    if T.IsActive() then T.Refresh(false) end
end
local StyleReadableText = unitBar.StyleReadableText


local function ShouldShowRow(slotIndex, unitId)
    if S.configMode then return true end
    if S.sv and S.sv.showAllSlots then return true end
    if slotIndex == 1 then return true end
    return UnitExists("party1") and UnitExists(unitId)
end

local bindingStore = ApogeePartyHealthBars_BindingStore
local KeyToActionAttrs = bindingStore.KeyToActionAttrs
local GetBindingAction = bindingStore.GetAction
local GetBindingDisplay = bindingStore.GetDisplay
local GetBindingsTable = bindingStore.GetTable

local function AssignCursorDrop(feature, slot, layoutKey)
    local controller = ApogeePartyHealthBars_BindingController
    return controller and controller.AssignCursor
        and controller.AssignCursor(feature, slot, layoutKey) or false
end

W.Configure({
    Print = Print,
    RequestLayout = S.RequestLayoutUpdate,
    SyncTicker = SyncVisualTicker,
    PositionSecureOverlay = PositionSecureOverlay,
    ShowSecureFrame = ShowSecureFrame,
    HideSecureFrame = HideSecureFrame,
    SetSecureMouseEnabled = SetSecureMouseEnabled,
    AssignCursorDrop = AssignCursorDrop,
})
K.Configure({
    Print = Print,
    RequestLayout = S.RequestLayoutUpdate,
    SyncTicker = SyncVisualTicker,
    PositionSecureOverlay = PositionSecureOverlay,
    ShowSecureFrame = ShowSecureFrame,
    HideSecureFrame = HideSecureFrame,
    SetSecureMouseEnabled = SetSecureMouseEnabled,
    AssignCursorDrop = AssignCursorDrop,
})
B.Configure({
    Print = Print,
    RequestLayout = S.RequestLayoutUpdate,
    SyncTicker = SyncVisualTicker,
    PositionSecureOverlay = PositionSecureOverlay,
    ShowSecureFrame = ShowSecureFrame,
    HideSecureFrame = HideSecureFrame,
    SetSecureMouseEnabled = SetSecureMouseEnabled,
    AssignCursorDrop = AssignCursorDrop,
})
CB.Configure({
    RequestLayout = S.RequestLayoutUpdate,
    SyncTicker = SyncVisualTicker,
    GetLeftOffset = function()
        return math.max(C.ROW_CONTENT_W, B.GetWidth("player"))
            + C.SHORTCUT_ICON_SIZE + C.SHORTCUT_ICON_GAP
    end,
    IsAddonEnabled = IsEnabled,
    PositionSecureOverlay = PositionSecureOverlay,
    ShowSecureFrame = ShowSecureFrame,
    HideSecureFrame = HideSecureFrame,
    SetSecureMouseEnabled = SetSecureMouseEnabled,
    DeferSecureUpdate = DeferSecureUpdate,
})


local unitFrames = ApogeePartyHealthBars_UnitFrames.Build({
    rows = rows,
    StyleReadableText = StyleReadableText,
    SyncVisualTicker = SyncVisualTicker,
    PositionSecureOverlay = PositionSecureOverlay,
    ShowSecureFrame = ShowSecureFrame,
    HideSecureFrame = HideSecureFrame,
    SetSecureMouseEnabled = SetSecureMouseEnabled,
    DeferSecureUpdate = DeferSecureUpdate,
    AssignCursorDrop = AssignCursorDrop,
})
panel = unitFrames.panel
rows = unitFrames.rows
local titleFS = unitFrames.titleFS
local sepTex = unitFrames.sepTex
local rowAnchor = unitFrames.rowAnchor
local shortcutFooterAnchor = unitFrames.shortcutFooterAnchor
local SavePosition = unitFrames.SavePosition
local ApplyDefaultPosition = unitFrames.ApplyDefaultPosition
local RestorePosition = unitFrames.RestorePosition
local ApplyBackdrop = unitFrames.ApplyBackdrop
local ApplyPanelChrome = unitFrames.ApplyPanelChrome
playerUtility.Attach(rows[1].primary, {
    ShouldShowSelfBuffIcon = ShouldShowSelfBuffIcon,
    IsSelfBuffKnown = buffReminders.IsSelfKnown,
    GetSelfBuffCastSpellName = buffReminders.GetSelfCastSpellName,
    IsSavedFeatureEnabled = IsEffectiveFeatureEnabled,
    DeferSecureUpdate = DeferSecureUpdate,
    PositionSecureOverlay = PositionSecureOverlay,
    ShowSecureFrame = ShowSecureFrame,
    HideSecureFrame = HideSecureFrame,
    SetSecureMouseEnabled = SetSecureMouseEnabled,
})

-- Layout & update


local function RebuildUnitToRow()
    wipe(unitToRow)
    for i = 1, C.MAX_ROWS do
        local row = rows[i]
        if row.btn:IsShown() then
            for _, surface in ipairs(row.surfaces) do
                unitToRow[surface.unitId] = row
            end
        end
    end
end

local function FindRowForUnit(unitId)
    if not unitId then return nil end
    local row = unitToRow[unitId]
    if row then return row end
    for i = 1, C.MAX_ROWS do
        if unitTopology.GetOwner(unitId) == rows[i].unitId then return rows[i] end
    end
    return nil
end

local function ResolvePanelUnit(unitId)
    return unitTopology.GetOwner(unitId) or unitId
end

local function AuraEventNeedsLayout(unitId)
    local row = FindRowForUnit(unitId)
    return row ~= nil and row.btn:IsShown()
end

-- Layout functions live in ApogeePartyHealthBars_Layout.lua (registered after bindings init).

UpdateUI = function()
    if not minimapController.IsCreated() then
        EnsureMinimapButton()
    end

    if not IsEnabled() then
        panel:Hide()
        configUI:Hide()
        HideAllSecureOverlays()
        if not InCombatLockdown() then
            ApplyAllSecureBindings()
        end
        ClearDirtyFlags()
        return
    end

    A.BeginAuraCacheGeneration()

    local doLayout = S.layoutDirty
    local doValues = S.valuesDirty
    if not doLayout and not doValues then
        doLayout = true
        doValues = true
    end

    if doLayout then
        if LayoutRows() ~= false then
            UpdateRowContent()
            SyncCastOverlays()
            W.RefreshSecureActions()
            K.RefreshSecureActions()
            B.RefreshSecureActions()
        end
    elseif doValues then
        UpdateRowValues()
    end

    M.Refresh()

    ClearDirtyFlags()
end


-- =============================================================================
-- Throttle
-- =============================================================================

valuesFlushFrame:SetScript("OnUpdate", function(self)
    self:Hide()
    if not S.valuesDirty or S.layoutDirty then return end
    RunValuesOnlyUpdate()
end)

throttleFrame:SetScript("OnUpdate", function(_, elapsed)
    if not S.layoutDirty and not S.valuesDirty then return end
    S.uiTimer = S.uiTimer - elapsed
    if S.uiTimer <= 0 then
        S.uiTimer = C.UPDATE_RATE
        if RunUpdate() then
            ClearDirtyFlags()
            if not S.layoutDirty and not S.valuesDirty then
                throttleFrame:Hide()
            end
        end
    end
end)

-- =============================================================================
-- Click-cast bindings
-- =============================================================================

local clickBindings = ApogeePartyHealthBars_ClickBindings
clickBindings.Initialize({
    rows = rows,
    KeyToActionAttrs = KeyToActionAttrs,
    GetBindingsTable = GetBindingsTable,
    GetBindingAction = GetBindingAction,
})
ApplyAllBindings = clickBindings.ApplyAll


local L = ApogeePartyHealthBars_Layout
L.Register({
    rows = rows,
    panel = panel,
    titleFS = titleFS,
    sepTex = sepTex,
    rowAnchor = rowAnchor,
    shortcutFooterAnchor = shortcutFooterAnchor,
    DeferSecureUpdate = DeferSecureUpdate,
    HideSecureFrame = HideSecureFrame,
    ShowSecureFrame = ShowSecureFrame,
    SetSecureMouseEnabled = SetSecureMouseEnabled,
    PositionSecureOverlay = PositionSecureOverlay,
    ApplyPanelChrome = ApplyPanelChrome,
    ShouldShowRow = ShouldShowRow,
    GetRowBtnWidth = GetRowBtnWidth,
    GetActionAreaHeight = GetActionAreaHeight,
    GetActionHudGeometry = rowGeometry.GetActionHudGeometry,
    GetPlayerActionWidth = function()
        return math.max(C.ROW_CONTENT_W, B.GetWidth("player"), CB.GetWidth("player"))
    end,
    LayoutPlayerActions = function(actionGeometry)
        W.Layout(actionGeometry.offsets.wheel)
        K.Layout(actionGeometry.offsets.keys)
        B.Layout(actionGeometry.offsets.buttons)
        CB.Layout(actionGeometry.offsets.consumables)
        AH.Layout(actionGeometry.iconHeight)
    end,
    GetShortcutFooterHeight = T.GetFooterHeight,
    LayoutShortcutFooter = T.Layout,
    GetThreatGutterWidth = H.GetGutterWidth,
    RefreshThreat = H.Refresh,
    IsUnitTargetsEnabled = IsUnitTargetsEnabled,
    GetPartyBuffCastSpellName = buffReminders.GetPartyCastSpellName,
    IsSavedFeatureEnabled = IsEffectiveFeatureEnabled,
    ApplyAllBindings = ApplyAllBindings,
    IsEnabled = IsEnabled,
    RebuildUnitToRow = RebuildUnitToRow,
    PlayerUtility = playerUtility,
})

UpdateHeader = L.UpdateHeader
LayoutRows = L.LayoutRows
UpdateRowValues = L.UpdateRowValues
UpdateRowContent = L.UpdateRowContent
SyncCastOverlays = L.SyncCastOverlays
HideAllSecureOverlays = L.HideAllSecureOverlays
ApplyAllPartyBuffBindings = L.ApplyAllPartyBuffBindings
ApplyAllSelfBuffBindings = L.ApplyAllSelfBuffBindings

ApplyAllSecureBindings = function()
    ApplyAllBindings()
    ApplyAllPartyBuffBindings()
    ApplyAllSelfBuffBindings()
end

local function ReconcileAllSecureOverlays()
    SyncCastOverlays()
    ApplyAllPartyBuffBindings()
    ApplyAllSelfBuffBindings()
    T.RefreshSecureActions()
    W.RefreshSecureActions()
    K.RefreshSecureActions()
    B.RefreshSecureActions()
    CB.RefreshSecureActions()
    ReconcileBoundActionBindings()
end

secureFrames.InitializeReconciler(ReconcileAllSecureOverlays)

local playerSpells = ApogeePartyHealthBars_PlayerSpells
local GetSpellFromCursor = playerSpells.GetSpellFromCursor


local bindingController = ApogeePartyHealthBars_BindingController
bindingController.Initialize({
    AssignBindingSpell = bindingStore.AssignSpell,
    AssignBindingItem = bindingStore.AssignItem,
    ClearBindingAction = bindingStore.Clear,
    MoveBindingAction = bindingStore.Move,
    RefreshBindPanel = function() RefreshBindPanel() end,
    ForceRefresh = ForceRefresh,
    Print = Print,
    SyncVisualTicker = SyncVisualTicker,
    GetSpellFromCursor = GetSpellFromCursor,
    GetConfigUI = function() return configUI end,
    ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities,
})
local ClearBinding = bindingController.ClearBinding
local MoveBinding = bindingController.MoveBinding

-- Minimap controller
minimapController = ApogeePartyHealthBars_MinimapController
minimapController.Initialize({
    IsEnabled = IsEnabled,
    SetAddonEnabled = function(enabled) SetAddonEnabled(enabled) end,
    SetConfigMode = function(active) SetConfigMode(active) end,
})
EnsureMinimapButton = minimapController.Ensure
local UpdateMinimapButtonStyle = minimapController.UpdateStyle
local ApplyDefaultMinimapPosition = minimapController.ResetPosition



-- =============================================================================
-- Config UI (General settings + click bindings)
-- =============================================================================

SetSavedFeature = function(svKey, enabled, onChange)
    S.sv[svKey] = enabled
    if onChange then onChange() end
    ForceRefresh()
end

SetHotTrackEnabled = function(key, enabled)
    S.sv.hotDisabled = S.sv.hotDisabled or {}
    if enabled then
        S.sv.hotDisabled[key] = nil
    else
        S.sv.hotDisabled[key] = true
    end
    InitHotSpells()
    ForceRefresh()
end

local function GetBoundActionManagers()
    local managers = {}
    for _, feature in ipairs({ W, K, B }) do
        local manager = feature.GetBindingManager and feature.GetBindingManager()
        if manager then managers[#managers + 1] = manager end
    end
    return managers
end

local function ClaimBoundActionBindings()
    if not ApogeePartyHealthBars_ClientCapabilities.IsFeatureAvailable("boundActions") then
        return true, "unsupported",
            ApogeePartyHealthBars_ClientCapabilities.GetFeatureReason("boundActions")
    end
    return ApogeePartyHealthBars_BoundActionBindings.ClaimAll(GetBoundActionManagers())
end

local function ReleaseBoundActionBindings()
    if not ApogeePartyHealthBars_ClientCapabilities.IsFeatureAvailable("boundActions") then
        return true, "unsupported",
            ApogeePartyHealthBars_ClientCapabilities.GetFeatureReason("boundActions")
    end
    return ApogeePartyHealthBars_BoundActionBindings.ReleaseAll(GetBoundActionManagers())
end

ReconcileBoundActionBindings = function()
    if not S.sv or S.sv.enabled ~= true then return true, "disabled" end
    if not ApogeePartyHealthBars_ClientCapabilities.IsFeatureAvailable("boundActions") then
        return true, "unsupported"
    end
    return ApogeePartyHealthBars_BoundActionBindings.ReconcileAll(GetBoundActionManagers())
end

local configController = ApogeePartyHealthBars_ConfigController
configController.Initialize({
    panel = panel,
    GetConfigUI = function() return configUI end,
    ForceRefresh = ForceRefresh,
    ClearDirtyFlags = ClearDirtyFlags,
    StopUpdateFrames = function() throttleFrame:Hide(); visualTicker.Stop() end,
    HideAllSecureOverlays = function() HideAllSecureOverlays() end,
    SavePosition = SavePosition,
    UpdateHeader = function() UpdateHeader() end,
    UpdateMinimapButtonStyle = UpdateMinimapButtonStyle,
    ScheduleSecureReconcile = secureFrames.RequestReconcile,
    ClaimBoundActionBindings = ClaimBoundActionBindings,
    ReleaseBoundActionBindings = ReleaseBoundActionBindings,
    ReconcileBoundActionBindings = ReconcileBoundActionBindings,
    ProfileStore = ApogeePartyHealthBars_ProfileStore,
    DotTracker = ApogeePartyHealthBars_DotTracker,
    DotHud = ApogeePartyHealthBars_DotHud,
    Print = Print,
})
ExitConfigMode = configController.Exit
SetAddonEnabled = configController.SetAddonEnabled
SetConfigMode = configController.SetMode
FactoryReset = configController.FactoryReset
local ActivateProfile = configController.ActivateProfile
local MutateActiveProfile = configController.MutateActiveProfile
local CreateAndActivateProfile = configController.CreateAndActivateProfile

configUI = ApogeePartyHealthBars_ConfigUI.Build({
    ApplyBackdrop               = ApplyBackdrop,
    SetConfigMode              = SetConfigMode,
    GetBindingDisplay           = GetBindingDisplay,
    GetBinding                  = S.GetBinding,
    ClearBinding                = ClearBinding,
    MoveBinding                 = MoveBinding,
    Sounds                     = ApogeePartyHealthBars_Sounds,
    AssignCursorDrop           = AssignCursorDrop,
    ShortcutBar               = T,
    KeyActions                = K,
    WheelMacros                = W,
    MouseButtonActions         = B,
    ProfileStore              = ApogeePartyHealthBars_ProfileStore,
    ProfileCodec              = ApogeePartyHealthBars_ProfileCodec,
    ActivateProfile           = ActivateProfile,
    MutateActiveProfile       = MutateActiveProfile,
    CreateAndActivateProfile = CreateAndActivateProfile,
    AddonVersion              = ApogeePartyHealthBars_ClientCapabilities.GetAddonVersion(
        "ApogeePartyHealthBars"),
    ClientCapabilities       = ApogeePartyHealthBars_ClientCapabilities,
    DotTracker               = ApogeePartyHealthBars_DotTracker,
    DotHud                   = ApogeePartyHealthBars_DotHud,
    GetSavedVariables        = function() return S.sv end,
        GeneralConfig = {
        ForceRefresh                = ForceRefresh,
        InitHotSpells               = InitHotSpells,
        SetAddonEnabled             = SetAddonEnabled,
        Print                       = Print,
        FactoryReset                = FactoryReset,
        SetSavedFeature             = SetSavedFeature,
        ActionHud                   = ApogeePartyHealthBars_ActionHud,
        ConsumableBar               = CB,
        ApplyAllSecureBindings      = ApplyAllSecureBindings,
        GetSelfBuffPreferenceOptions = GetSelfBuffPreferenceOptions,
        GetSelfBuffPreferenceKey    = GetSelfBuffPreferenceKey,
        SetSelfBuffPreference       = SetSelfBuffPreference,
        IsPartyBuffKnown            = buffReminders.IsPartyKnown,
        IsSelfBuffKnown             = buffReminders.IsSelfKnown,
        HasKnownBuffReminder        = buffReminders.HasKnownReminder,
        SetHotTrackEnabled          = SetHotTrackEnabled,
        ApplyDefaultPosition        = ApplyDefaultPosition,
        ApplyDefaultMinimapPosition = ApplyDefaultMinimapPosition,
        IsSavedFeatureEnabled       = IsSavedFeatureEnabled,
        IsHotEnabled                = IsHotEnabled,
        IsHotTrackKnown             = hotTracker.IsTrackKnown,
        GetSavedVariables           = function() return S.sv end,
        Sounds                      = ApogeePartyHealthBars_Sounds,
        HealthAlerts                = ApogeePartyHealthBars_HealthAlerts,
        Threat                      = H,
        CombatUIFader               = ApogeePartyHealthBars_CombatUIFader,
        SyncVisualTicker            = SyncVisualTicker,
        ClientCapabilities          = ApogeePartyHealthBars_ClientCapabilities,
    },
})

RefreshConfigPanel = configUI.RefreshConfigPanel
RefreshBindPanel = configUI.RefreshBindPanel


-- =============================================================================
-- Events
-- =============================================================================

ApogeePartyHealthBars_RuntimeEvents.Register(ApogeePartyHealthBars_EventRouter, {
    Print = Print,
    InitPlayerSpells = InitPlayerSpells,
    RestorePosition = RestorePosition,
    UpdateHeader = UpdateHeader,
    EnsureMinimapButton = EnsureMinimapButton,
    SeedShieldTrackerFromAuras = SeedShieldTrackerFromAuras,
    ForceRefresh = ForceRefresh,
    IsShieldEnabled = IsShieldEnabled,
    OnShieldCombatLog = OnShieldCombatLog,
    SetConfigMode = SetConfigMode,
    ClaimBoundActionBindings = ClaimBoundActionBindings,
    ReleaseBoundActionBindings = ReleaseBoundActionBindings,
    ReconcileBoundActionBindings = ReconcileBoundActionBindings,
    IsPanelTrackedUnit = IsPanelTrackedUnit,
    ResolvePanelUnit = ResolvePanelUnit,
    ShieldTrackerSyncUnit = ShieldTrackerSyncUnit,
    AuraEventNeedsLayout = AuraEventNeedsLayout,
    GetConfigUI = function() return configUI end,
})
ApogeePartyHealthBars_HealthAlerts.Register(ApogeePartyHealthBars_EventRouter)
