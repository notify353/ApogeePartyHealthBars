-- =============================================================================
-- ApogeePartyHealthBars.lua
-- =============================================================================
-- Party HP bars for healing (player + party1-4, inline unit targets).
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
local M = ApogeePartyHealthBars_RaidMarkers
local H = ApogeePartyHealthBars_Threat
local rowGeometry = ApogeePartyHealthBars_RowGeometry
local visualTicker = ApogeePartyHealthBars_VisualTicker
local buffReminders = ApogeePartyHealthBars_BuffReminders
local shieldTracker = ApogeePartyHealthBars_ShieldTracker
local incomingHeals = ApogeePartyHealthBars_IncomingHeals
local hotTracker = ApogeePartyHealthBars_HotTracker

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
local RefreshRowBuffs
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
local HookSpellbook
local HookContainerItems
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

local function IsUnitTargetsEnabled()
    return IsSavedFeatureEnabled("showUnitTargets")
end

local function GetUnitTargetToken(unitId)
    if unitId == "player" then return "target" end
    return unitId .. "target"
end

local function RowHasTargetPane(row)
    if not row or not row.unitId or not UnitExists(row.unitId) then return false end
    if UnitIsConnected and not UnitIsConnected(row.unitId) then return false end
    if not IsUnitTargetsEnabled() then return false end
    return UnitExists(GetUnitTargetToken(row.unitId))
end

local function GetTargetColumnWidth(rowOrUnit)
    if not IsUnitTargetsEnabled() then return 0 end
    local unitId = type(rowOrUnit) == "table" and rowOrUnit.unitId or rowOrUnit
    local columns = unitId == "player" and 2 or 1
    return columns * (C.TARGET_BAR_W + C.TARGET_GAP)
end

local function GetRowBtnWidth(row)
    return C.ROW_CONTENT_W + GetTargetColumnWidth(row)
end

local function SyncRowTargetPane(row)
    row.showTargetPane = RowHasTargetPane(row)
end

local function IsPanelTrackedUnit(unit)
    if not unit then return false end
    if unit == "player" or unit == "target" or unit == "targettarget" then return true end
    if unit:match("^party%d$") or unit:match("^party%dtarget$") then return true end
    return false
end

-- =============================================================================
-- Effect runtimes
-- =============================================================================

hotTracker.Initialize({
    Auras = A,
    Effects = E,
    rows = rows,
    SyncVisualTicker = SyncVisualTicker,
    IsSavedFeatureEnabled = IsSavedFeatureEnabled,
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
    rows = rows,
    IsSavedFeatureEnabled = IsSavedFeatureEnabled,
    IsConfigMode = function() return S.configMode end,
    GetCharacterSavedVariables = function() return S.charSv end,
    ApplyAllSelfBuffBindings = function() ApplyAllSelfBuffBindings() end,
    RequestLayoutUpdate = S.RequestLayoutUpdate,
})
local CanPlayerHealUnit = buffReminders.CanHealUnit
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
    IsSavedFeatureEnabled = IsSavedFeatureEnabled,
    IsConfigMode = function() return S.configMode end,
    RequestUpdate = S.RequestUpdate,
})
local IsShieldEnabled = shieldTracker.IsEnabled
local ShouldTrackShieldUnit = shieldTracker.ShouldTrackUnit
local ShieldTrackerSyncUnit = shieldTracker.SyncUnit
local OnShieldCombatLog = shieldTracker.OnCombatLog
local SeedShieldTrackerFromAuras = shieldTracker.SeedFromAuras
local GetUnitShieldRemaining = shieldTracker.GetRemaining
local UpdateRowShieldVisual = shieldTracker.UpdateRowVisual

incomingHeals.Initialize({
    IsSavedFeatureEnabled = IsSavedFeatureEnabled,
    IsConfigMode = function() return S.configMode end,
})
local UpdateIncomingHealBarVisual = incomingHeals.UpdateBarVisual
local UpdateRowIncomingHealVisual = incomingHeals.UpdateRowVisual

rowGeometry.Initialize({
    GetHotStripHeight = GetHotStripHeight,
    ShortcutBar = T,
    WheelMacros = W,
    KeyActions = K,
})
local GetPlayerPowerInfo = rowGeometry.GetPlayerPowerInfo
local GetRowPowerChromeHeight = rowGeometry.GetRowPowerChromeHeight
local GetActionAreaHeight = rowGeometry.GetActionAreaHeight
local GetRowTotalHeight = rowGeometry.GetRowTotalHeight

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

local unitDisplay = ApogeePartyHealthBars_UnitDisplay
unitDisplay.Initialize({
    rows = rows,
    GetPlayerPowerInfo = GetPlayerPowerInfo,
    IsSavedFeatureEnabled = IsSavedFeatureEnabled,
    GetUnitTargetToken = GetUnitTargetToken,
    CanPlayerHealUnit = CanPlayerHealUnit,
    IsOppositeFactionPlayer = buffReminders.IsOppositeFactionPlayer,
    IsShieldEnabled = IsShieldEnabled,
    ShouldTrackShieldUnit = ShouldTrackShieldUnit,
    GetUnitShieldRemaining = GetUnitShieldRemaining,
    UpdateRowShieldVisual = UpdateRowShieldVisual,
    UpdateIncomingHealBarVisual = UpdateIncomingHealBarVisual,
    UpdateRowIncomingHealVisual = UpdateRowIncomingHealVisual,
    UpdateRowHotVisuals = UpdateRowHotVisuals,
    ShouldShowPartyBuffIcon = ShouldShowPartyBuffIcon,
})

visualTicker.Initialize({
    IsAddonEnabled = IsEnabled,
    IsRangeCheckEnabled = function() return IsSavedFeatureEnabled("rangeCheckEnabled") end,
    IsConfigMode = function() return S.configMode end,
    HasActiveHotVisuals = HasActiveHotVisuals,
    TickHotVisuals = TickHotVisuals,
    RefreshRangeAlpha = function() S.RefreshRangeAlpha() end,
    ShortcutBar = T,
    WheelMacros = W,
    KeyActions = K,
    Threat = H,
})
local StyleReadableText = unitDisplay.StyleReadableText
local ApplyFlatStatusBar = unitDisplay.ApplyFlatStatusBar
local ApplyFlatBg = unitDisplay.ApplyFlatBg
local UpdateRowPowerVisual = unitDisplay.UpdateRowPowerVisual
local PopulateHealthRow = unitDisplay.PopulateHealthRow
local RefreshTargetPartyBuff = unitDisplay.RefreshTargetPartyBuff


local function ShouldShowRow(slotIndex, unitId)
    if S.configMode then return true end
    if S.sv and S.sv.showAllSlots then return true end
    if slotIndex == 1 then return true end
    return UnitExists("party1") and UnitExists(unitId)
end

local bindingStore = ApogeePartyHealthBars_BindingStore
local KeyToActionAttrs = bindingStore.KeyToActionAttrs
local GetBindingAction = bindingStore.GetAction
local GetBindingDisplayName = bindingStore.GetDisplayName
local GetBindingsTable = bindingStore.GetTable

W.Configure({
    Print = Print,
    RequestLayout = S.RequestLayoutUpdate,
    SyncTicker = SyncVisualTicker,
    PositionSecureOverlay = PositionSecureOverlay,
    ShowSecureFrame = ShowSecureFrame,
    HideSecureFrame = HideSecureFrame,
    SetSecureMouseEnabled = SetSecureMouseEnabled,
})
K.Configure({
    Print = Print,
    RequestLayout = S.RequestLayoutUpdate,
    SyncTicker = SyncVisualTicker,
    PositionSecureOverlay = PositionSecureOverlay,
    ShowSecureFrame = ShowSecureFrame,
    HideSecureFrame = HideSecureFrame,
    SetSecureMouseEnabled = SetSecureMouseEnabled,
})


local unitFrames = ApogeePartyHealthBars_UnitFrames.Build({
    rows = rows,
    StyleReadableText = StyleReadableText,
    ApplyFlatStatusBar = ApplyFlatStatusBar,
    ApplyFlatBg = ApplyFlatBg,
    GetRowTotalHeight = GetRowTotalHeight,
    SyncVisualTicker = SyncVisualTicker,
    PositionSecureOverlay = PositionSecureOverlay,
    ShowSecureFrame = ShowSecureFrame,
    HideSecureFrame = HideSecureFrame,
    SetSecureMouseEnabled = SetSecureMouseEnabled,
    DeferSecureUpdate = DeferSecureUpdate,
})
panel = unitFrames.panel
rows = unitFrames.rows
local titleFS = unitFrames.titleFS
local sepTex = unitFrames.sepTex
local rowAnchor = unitFrames.rowAnchor
local SavePosition = unitFrames.SavePosition
local ApplyDefaultPosition = unitFrames.ApplyDefaultPosition
local RestorePosition = unitFrames.RestorePosition
local ApplyBackdrop = unitFrames.ApplyBackdrop
local ApplyPanelChrome = unitFrames.ApplyPanelChrome

-- Layout & update


local function RebuildUnitToRow()
    wipe(unitToRow)
    for i = 1, C.MAX_ROWS do
        local row = rows[i]
        if row.btn:IsShown() and row.unitId then
            unitToRow[row.unitId] = row
        end
    end
end

local function FindRowForUnit(unitId)
    if not unitId then return nil end
    local row = unitToRow[unitId]
    if row then return row end
    for i = 1, C.MAX_ROWS do
        if rows[i].unitId == unitId then return rows[i] end
    end
    return nil
end

local function ResolvePanelUnit(unitId)
    if FindRowForUnit(unitId) then return unitId end
    if unitId == "target" or unitId == "targettarget" then return "player" end
    local n = unitId and unitId:match("^party(%d)target$")
    if n then return "party" .. n end
    return unitId
end

local function ComputeRowLayoutKey(unitId, row)
    local showPartyBuff = unitId and ShouldShowPartyBuffIcon(unitId) or false
    local showSelfBuff = unitId and ShouldShowSelfBuffIcon(unitId) or false
    local targetReserve = row and GetTargetColumnWidth(row) or 0
    return string.format("%s|%s|%s|%d|%d|%d|%d|%d|%d",
        tostring(showPartyBuff), tostring(showSelfBuff), GetHotStripHeight(), targetReserve,
        GetRowPowerChromeHeight(unitId), T.GetHeight(unitId), W.GetHeight(unitId),
        K.GetHeight(unitId), H.GetGutterWidth())
end

local function AuraEventNeedsLayout(unitId)
    local row = FindRowForUnit(unitId)
    if not row or not row.btn:IsShown() then return false end
    return row._layoutKey ~= ComputeRowLayoutKey(unitId, row)
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
        for i = 1, C.MAX_ROWS do
            if not ShouldShowRow(i, rows[i].unitId) then
                rows[i].showTargetPane = false
            end
        end

        if LayoutRows() ~= false then
            UpdateRowContent()
            SyncCastOverlays()
            W.RefreshSecureActions()
            K.RefreshSecureActions()
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
    GetUnitTargetToken = GetUnitTargetToken,
})
ApplyAllBindings = clickBindings.ApplyAll


local L = ApogeePartyHealthBars_Layout
L.Register({
    rows = rows,
    panel = panel,
    titleFS = titleFS,
    sepTex = sepTex,
    rowAnchor = rowAnchor,
    DeferSecureUpdate = DeferSecureUpdate,
    HideSecureFrame = HideSecureFrame,
    ShowSecureFrame = ShowSecureFrame,
    SetSecureMouseEnabled = SetSecureMouseEnabled,
    PositionSecureOverlay = PositionSecureOverlay,
    ApplyPanelChrome = ApplyPanelChrome,
    ShouldShowRow = ShouldShowRow,
    GetRowBtnWidth = GetRowBtnWidth,
    GetRowTotalHeight = GetRowTotalHeight,
    GetRowPowerChromeHeight = GetRowPowerChromeHeight,
    GetActionAreaHeight = GetActionAreaHeight,
    LayoutShortcuts = function()
        W.Layout(); K.Layout()
        T.Layout(math.max(W.GetHeight("player"), K.GetHeight("player")))
    end,
    GetThreatGutterWidth = H.GetGutterWidth,
    RefreshThreat = H.Refresh,
    GetHotStripHeight = GetHotStripHeight,
    GetActiveHotTrackCount = GetActiveHotTrackCount,
    GetTargetColumnWidth = GetTargetColumnWidth,
    ShouldShowPartyBuffIcon = ShouldShowPartyBuffIcon,
    ShouldShowSelfBuffIcon = ShouldShowSelfBuffIcon,
    GetPartyBuffCastSpellName = buffReminders.GetPartyCastSpellName,
    GetSelfBuffCastSpellName = buffReminders.GetSelfCastSpellName,
    IsSavedFeatureEnabled = IsSavedFeatureEnabled,
    ComputeRowLayoutKey = ComputeRowLayoutKey,
    PopulateHealthRow = PopulateHealthRow,
    SyncRowTargetPane = SyncRowTargetPane,
    RefreshTargetPartyBuff = RefreshTargetPartyBuff,
    UpdateRowPowerVisual = UpdateRowPowerVisual,
    UpdateRowHotVisuals = UpdateRowHotVisuals,
    GetUnitTargetToken = GetUnitTargetToken,
    ApplyAllBindings = ApplyAllBindings,
    IsEnabled = IsEnabled,
    RebuildUnitToRow = RebuildUnitToRow,
})

UpdateHeader = L.UpdateHeader
RefreshRowBuffs = L.RefreshRowBuffs
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
    ReconcileBoundActionBindings()
end

secureFrames.InitializeReconciler(ReconcileAllSecureOverlays)

local playerSpells = ApogeePartyHealthBars_PlayerSpells
local GetSpellFromSpellButton = playerSpells.GetSpellFromButton


local bindingController = ApogeePartyHealthBars_BindingController
bindingController.Initialize({
    AssignBindingSpell = bindingStore.AssignSpell,
    AssignBindingItem = bindingStore.AssignItem,
    ClearBindingAction = bindingStore.Clear,
    RefreshBindPanel = function() RefreshBindPanel() end,
    ForceRefresh = ForceRefresh,
    Print = Print,
    SyncVisualTicker = SyncVisualTicker,
    GetSpellFromSpellButton = GetSpellFromSpellButton,
    GetConfigUI = function() return configUI end,
})
local ClearBinding = bindingController.ClearBinding
HookSpellbook = bindingController.HookSpellbook
HookContainerItems = bindingController.HookContainerItems

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
    for _, feature in ipairs({ W, K }) do
        local manager = feature.GetBindingManager and feature.GetBindingManager()
        if manager then managers[#managers + 1] = manager end
    end
    return managers
end

local function ClaimBoundActionBindings()
    return ApogeePartyHealthBars_BoundActionBindings.ClaimAll(GetBoundActionManagers())
end

local function ReleaseBoundActionBindings()
    return ApogeePartyHealthBars_BoundActionBindings.ReleaseAll(GetBoundActionManagers())
end

ReconcileBoundActionBindings = function()
    if not S.sv or S.sv.enabled ~= true then return true, "disabled" end
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
    HookSpellbook = function() HookSpellbook() end,
    HookContainerItems = function() HookContainerItems() end,
    ScheduleSecureReconcile = secureFrames.RequestReconcile,
    ClaimBoundActionBindings = ClaimBoundActionBindings,
    ReleaseBoundActionBindings = ReleaseBoundActionBindings,
    ReconcileBoundActionBindings = ReconcileBoundActionBindings,
    ProfileStore = ApogeePartyHealthBars_ProfileStore,
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
    GetBindingDisplayName       = GetBindingDisplayName,
    GetBinding                  = S.GetBinding,
    ClearBinding                = ClearBinding,
    Sounds                     = ApogeePartyHealthBars_Sounds,
    ShortcutBar               = T,
    KeyActions                = K,
    WheelMacros                = W,
    ProfileStore              = ApogeePartyHealthBars_ProfileStore,
    ProfileCodec              = ApogeePartyHealthBars_ProfileCodec,
    ActivateProfile           = ActivateProfile,
    MutateActiveProfile       = MutateActiveProfile,
    CreateAndActivateProfile = CreateAndActivateProfile,
    AddonVersion              = C_AddOns.GetAddOnMetadata("ApogeePartyHealthBars", "Version"),
    GeneralConfig = {
        ForceRefresh                = ForceRefresh,
        InitHotSpells               = InitHotSpells,
        SetAddonEnabled             = SetAddonEnabled,
        FactoryReset                = FactoryReset,
        SetSavedFeature             = SetSavedFeature,
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
    HookSpellbook = HookSpellbook,
    HookContainerItems = HookContainerItems,
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
