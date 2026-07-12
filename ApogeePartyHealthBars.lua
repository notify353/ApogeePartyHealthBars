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
local T = ApogeePartyHealthBars_SpellTracker
local H = ApogeePartyHealthBars_Threat

local panel, configUI, minimapController
local rows = {}

local throttleFrame = CreateFrame("Frame")
throttleFrame:Hide()

local valuesFlushFrame = CreateFrame("Frame")
valuesFlushFrame:Hide()

local visualTickerFrame = CreateFrame("Frame")
visualTickerFrame:Hide()

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
local SetSavedFeature
local RefreshConfigPanel
local ApplyAllBindings
local RefreshBindPanel
local HookSpellbook
local ApplyAllSecureBindings
local EnsureMinimapButton

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

local function GetTargetColumnWidth()
    if not IsUnitTargetsEnabled() then return 0 end
    return C.TARGET_BAR_W + C.TARGET_GAP
end

local function GetRowBtnWidth(row)
    return C.ROW_CONTENT_W + GetTargetColumnWidth()
end

local function SyncRowTargetPane(row)
    row.showTargetPane = RowHasTargetPane(row)
end

local function IsPanelTrackedUnit(unit)
    if not unit then return false end
    if unit == "player" or unit == "target" then return true end
    if unit:match("^party%d$") or unit:match("^party%dtarget$") then return true end
    return false
end

-- =============================================================================
-- Party buff reminder (class-specific spellbook cast and matching aura)
-- =============================================================================

local effectsTracker = ApogeePartyHealthBars_EffectsTracker
effectsTracker.Initialize({
    rows = rows,
    visualTickerFrame = visualTickerFrame,
    IsSavedFeatureEnabled = IsSavedFeatureEnabled,
    GetUnitTargetToken = GetUnitTargetToken,
    ApplyAllPartyBuffBindings = function() ApplyAllPartyBuffBindings() end,
    ApplyAllSelfBuffBindings = function() ApplyAllSelfBuffBindings() end,
    RefreshConfigPanel = function() RefreshConfigPanel() end,
    SyncCastOverlays = function() SyncCastOverlays() end,
    LayoutRows = function() return LayoutRows() end,
    UpdateRowValues = function() UpdateRowValues() end,
})
local InitPlayerSpells = effectsTracker.InitPlayerSpells
local CanPlayerHealUnit = effectsTracker.CanPlayerHealUnit
local ShouldShowPartyBuffIcon = effectsTracker.ShouldShowPartyBuffIcon
local ShouldShowSelfBuffIcon = effectsTracker.ShouldShowSelfBuffIcon
local IsHotEnabled = effectsTracker.IsHotEnabled
local GetHotStripHeight = effectsTracker.GetHotStripHeight
local GetPlayerPowerInfo = effectsTracker.GetPlayerPowerInfo
local GetRowPowerChromeHeight = effectsTracker.GetRowPowerChromeHeight
local GetRowTotalHeight = effectsTracker.GetRowTotalHeight
InitHotSpells = effectsTracker.InitHotSpells
local SyncVisualTicker = effectsTracker.SyncVisualTicker
local RefreshVisualTicker = effectsTracker.RefreshVisualTicker
local UpdateRowHotVisuals = effectsTracker.UpdateRowHotVisuals
local IsShieldEnabled = effectsTracker.IsShieldEnabled
local ShouldTrackShieldUnit = effectsTracker.ShouldTrackShieldUnit
local ShieldTrackerSyncUnit = effectsTracker.ShieldTrackerSyncUnit
local OnShieldCombatLog = effectsTracker.OnShieldCombatLog
local SeedShieldTrackerFromAuras = effectsTracker.SeedShieldTrackerFromAuras
local GetUnitShieldRemaining = effectsTracker.GetUnitShieldRemaining
local UpdateRowShieldVisual = effectsTracker.UpdateRowShieldVisual
local UpdateRowIncomingHealVisual = effectsTracker.UpdateRowIncomingHealVisual

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
    IsOppositeFactionPlayer = effectsTracker.IsOppositeFactionPlayer,
    IsShieldEnabled = IsShieldEnabled,
    ShouldTrackShieldUnit = ShouldTrackShieldUnit,
    GetUnitShieldRemaining = GetUnitShieldRemaining,
    UpdateRowShieldVisual = UpdateRowShieldVisual,
    UpdateIncomingHealBarVisual = effectsTracker.UpdateIncomingHealBarVisual,
    UpdateRowIncomingHealVisual = UpdateRowIncomingHealVisual,
    UpdateRowHotVisuals = UpdateRowHotVisuals,
    ShouldShowPartyBuffIcon = ShouldShowPartyBuffIcon,
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
local KeyToSpellAttrs = bindingStore.KeyToSpellAttrs
local GetBindingSpellName = bindingStore.GetSpellName
local GetBindingDisplayName = bindingStore.GetDisplayName
local GetBindingsTable = bindingStore.GetTable


local unitFrames = ApogeePartyHealthBars_UnitFrames.Build({
    rows = rows,
    StyleReadableText = StyleReadableText,
    ApplyFlatStatusBar = ApplyFlatStatusBar,
    ApplyFlatBg = ApplyFlatBg,
    GetRowTotalHeight = GetRowTotalHeight,
    SyncVisualTicker = SyncVisualTicker,
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
    local n = unitId and unitId:match("^party(%d)target$")
    if n then return "party" .. n end
    return unitId
end

local function ComputeRowLayoutKey(unitId, row)
    local showPartyBuff = unitId and ShouldShowPartyBuffIcon(unitId) or false
    local showSelfBuff = unitId and ShouldShowSelfBuffIcon(unitId) or false
    local targetReserve = row and GetTargetColumnWidth() or 0
    return string.format("%s|%s|%s|%d|%d|%d|%d",
        tostring(showPartyBuff), tostring(showSelfBuff), GetHotStripHeight(), targetReserve,
        GetRowPowerChromeHeight(unitId), T.GetHeight(unitId), H.GetGutterWidth())
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
        end
    elseif doValues then
        UpdateRowValues()
    end

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

visualTickerFrame:SetScript("OnUpdate", function(_, elapsed)
    RefreshVisualTicker()
    S.rangeTimer = (S.rangeTimer or 0) - elapsed
    if S.rangeTimer <= 0 then
        S.rangeTimer = C.RANGE_UPDATE_RATE
        S.RefreshRangeAlpha()
        H.Refresh()
    end
end)


-- =============================================================================
-- Click-cast bindings
-- =============================================================================

local clickBindings = ApogeePartyHealthBars_ClickBindings
clickBindings.Initialize({
    rows = rows,
    KeyToSpellAttrs = KeyToSpellAttrs,
    GetBindingsTable = GetBindingsTable,
    GetBindingSpellName = GetBindingSpellName,
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
    GetTrackerHeight = T.GetHeight,
    LayoutTracker = T.Layout,
    GetThreatGutterWidth = H.GetGutterWidth,
    RefreshThreat = H.Refresh,
    GetHotStripHeight = GetHotStripHeight,
    GetTargetColumnWidth = GetTargetColumnWidth,
    ShouldShowPartyBuffIcon = ShouldShowPartyBuffIcon,
    ShouldShowSelfBuffIcon = ShouldShowSelfBuffIcon,
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

local playerSpells = ApogeePartyHealthBars_PlayerSpells
local GetSpellFromSpellButton = playerSpells.GetSpellFromButton


local bindingController = ApogeePartyHealthBars_BindingController
bindingController.Initialize({
    GetBindingsTable = GetBindingsTable,
    RefreshBindPanel = function() RefreshBindPanel() end,
    ForceRefresh = ForceRefresh,
    Print = Print,
    SyncVisualTicker = SyncVisualTicker,
    GetSpellFromSpellButton = GetSpellFromSpellButton,
    GetConfigUI = function() return configUI end,
})
local ClearBinding = bindingController.ClearBinding
HookSpellbook = bindingController.HookSpellbook

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

local configController = ApogeePartyHealthBars_ConfigController
configController.Initialize({
    panel = panel,
    GetConfigUI = function() return configUI end,
    ForceRefresh = ForceRefresh,
    ClearDirtyFlags = ClearDirtyFlags,
    StopUpdateFrames = function() throttleFrame:Hide(); visualTickerFrame:Hide() end,
    HideAllSecureOverlays = function() HideAllSecureOverlays() end,
    SavePosition = SavePosition,
    UpdateHeader = function() UpdateHeader() end,
    UpdateMinimapButtonStyle = UpdateMinimapButtonStyle,
    HookSpellbook = function() HookSpellbook() end,
    Print = Print,
})
ExitConfigMode = configController.Exit
SetAddonEnabled = configController.SetAddonEnabled
SetConfigMode = configController.SetMode

configUI = ApogeePartyHealthBars_ConfigUI.Build({
    ApplyBackdrop               = ApplyBackdrop,
    ForceRefresh                = ForceRefresh,
    InitHotSpells               = InitHotSpells,
    SetAddonEnabled             = SetAddonEnabled,
    SetConfigMode              = SetConfigMode,
    SetSavedFeature             = SetSavedFeature,
    SetHotTrackEnabled          = SetHotTrackEnabled,
    ApplyDefaultPosition        = ApplyDefaultPosition,
    ApplyDefaultMinimapPosition = ApplyDefaultMinimapPosition,
    IsSavedFeatureEnabled       = IsSavedFeatureEnabled,
    IsHotEnabled                = IsHotEnabled,
    GetBindingDisplayName       = GetBindingDisplayName,
    GetBinding                  = S.GetBinding,
    ClearBinding                = ClearBinding,
    SpellTracker               = T,
    Threat                     = H,
    SyncVisualTicker           = SyncVisualTicker,
    MacroLibrary               = ApogeePartyHealthBars_MacroLibrary,
    MacroInstaller             = ApogeePartyHealthBars_MacroInstaller,
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
    EnsureMinimapButton = EnsureMinimapButton,
    SeedShieldTrackerFromAuras = SeedShieldTrackerFromAuras,
    ForceRefresh = ForceRefresh,
    IsShieldEnabled = IsShieldEnabled,
    OnShieldCombatLog = OnShieldCombatLog,
    SetConfigMode = SetConfigMode,
    IsPanelTrackedUnit = IsPanelTrackedUnit,
    ResolvePanelUnit = ResolvePanelUnit,
    ShieldTrackerSyncUnit = ShieldTrackerSyncUnit,
    AuraEventNeedsLayout = AuraEventNeedsLayout,
    GetConfigUI = function() return configUI end,
})
