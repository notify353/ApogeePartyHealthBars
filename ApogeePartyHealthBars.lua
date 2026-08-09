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
local W = ApogeePartyHealthBars_MouseWheelActions
local K = ApogeePartyHealthBars_KeyboardActions
local B = ApogeePartyHealthBars_MouseButtonActions
local CB = ApogeePartyHealthBars_ConsumableBar
local AH = ApogeePartyHealthBars_ActionHud
local M = ApogeePartyHealthBars_RaidMarkers
local H = ApogeePartyHealthBars_Threat
local threatObserver = ApogeePartyHealthBars_ThreatObserver
local threatAwareness = ApogeePartyHealthBars_ThreatAwareness
local rowGeometry = ApogeePartyHealthBars_RowGeometry
local visualTicker = ApogeePartyHealthBars_VisualTicker
local buffReminders = ApogeePartyHealthBars_BuffReminders
local shieldTracker = ApogeePartyHealthBars_ShieldTracker
local incomingHeals = ApogeePartyHealthBars_IncomingHeals
local hotTracker = ApogeePartyHealthBars_HotTracker
local unitTopology = ApogeePartyHealthBars_UnitTopology
local unitAPI = ApogeePartyHealthBars_UnitAPI
local unitBar = ApogeePartyHealthBars_UnitBar
local playerStatusHud = ApogeePartyHealthBars_PlayerStatusHud
local playerUtility = ApogeePartyHealthBars_PlayerUtility

local panel, configUI, minimapController, dungeonBoardUI, dungeonGuideUI
local rows = {}

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
local RefreshPartyFrameClicksPage
local ApplyAllSecureBindings
local ReconcileBoundActionBindings
local EnsureMinimapButton
local InitHotSpells
local Print

local updateScheduler = ApogeePartyHealthBars.Require(
    "Core", "UpdateScheduler").Create({
        State = S,
        Constants = C,
        Print = function(message) Print(message) end,
    })
S.RequestUpdate = updateScheduler.RequestUpdate
S.RequestLayoutUpdate = updateScheduler.RequestLayoutUpdate
S.RequestValuesUpdate = updateScheduler.RequestValuesUpdate

local function SyncVisualTicker()
    visualTicker.Sync()
end

local secureFrames = ApogeePartyHealthBars_SecureFrames
local DeferSecureUpdate = secureFrames.RequestSecureUpdate
local HideSecureFrame = secureFrames.Hide
local ShowSecureFrame = secureFrames.Show
local SetSecureMouseEnabled = secureFrames.SetMouseEnabled
local PositionSecureOverlay = secureFrames.PositionOverlay

local featurePolicy = ApogeePartyHealthBars.Require("Core", "FeaturePolicy").Create(
    S, ApogeePartyHealthBars_ClientCapabilities)
local IsSavedFeatureEnabled = featurePolicy.IsSavedFeatureEnabled
local IsEffectiveFeatureEnabled = featurePolicy.IsEffectiveFeatureEnabled

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
local IsIncomingHealEnabled = incomingHeals.IsEnabled
local ShouldTrackIncomingUnit = incomingHeals.ShouldTrackUnit
local GetIncomingHealAmount = incomingHeals.GetAmount

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
    MouseWheelActions = W,
    KeyboardActions = K,
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
playerStatusHud.Initialize({
    IsShieldEnabled = IsShieldEnabled,
    ShouldTrackShieldUnit = ShouldTrackShieldUnit,
    GetShieldRemaining = GetUnitShieldRemaining,
    IsIncomingHealEnabled = IsIncomingHealEnabled,
    ShouldTrackIncomingUnit = ShouldTrackIncomingUnit,
    GetIncomingAmount = GetIncomingHealAmount,
})

-- =============================================================================

Print = function(msg)
    print(C.ADDON_PREFIX .. " " .. msg)
end

local function IsEnabled()
    return IsSavedFeatureEnabled("enabled")
end

local ClearDirtyFlags = updateScheduler.Clear
local ForceRefresh = updateScheduler.ForceRefresh

visualTicker.Initialize({
    IsAddonEnabled = IsEnabled,
    IsRangeCheckEnabled = function() return IsEffectiveFeatureEnabled("rangeCheckEnabled") end,
    IsConfigMode = function() return S.configMode end,
    HasActiveHotVisuals = HasActiveHotVisuals,
    TickHotVisuals = TickHotVisuals,
    RefreshUnitChains = function() S.RefreshUnitChains() end,
    RefreshRangeAlpha = function() S.RefreshRangeAlpha() end,
    ShortcutBar = T,
    MouseWheelActions = W,
    KeyboardActions = K,
    MouseButtonActions = B,
    ConsumableBar = CB,
    Threat = H,
    ThreatAwareness = threatAwareness,
    TargetEffectTracker = ApogeePartyHealthBars_TargetEffectTracker,
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
local GetBindingsTable = bindingStore.GetPagele
local bindingController = ApogeePartyHealthBars_BindingController
local playerSpells = ApogeePartyHealthBars_PlayerSpells
local actionCoordinator = ApogeePartyHealthBars.Require("Actions", "ActionCoordinator")
local AssignCursorDrop = actionCoordinator.AssignCursorDrop

ApogeePartyHealthBars.Require("Bootstrap", "ActionComposition").Initialize({
    Coordinator = actionCoordinator,
    Dependencies = {
        ShortcutBar = T,
    KeyboardActions = K,
    MouseWheelActions = W,
    MouseButtonActions = B,
    ConsumableBar = CB,
    BindingController = bindingController,
    BindingStore = bindingStore,
    BoundActionBindings = ApogeePartyHealthBars_BoundActionBindings,
    ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities,
    Print = Print,
    RequestLayout = S.RequestLayoutUpdate,
    SyncTicker = SyncVisualTicker,
    PositionSecureOverlay = PositionSecureOverlay,
    ShowSecureFrame = ShowSecureFrame,
    HideSecureFrame = HideSecureFrame,
    SetSecureMouseEnabled = SetSecureMouseEnabled,
    DeferSecureUpdate = DeferSecureUpdate,
    ForceRefresh = ForceRefresh,
    GetSpellFromCursor = playerSpells.GetSpellFromCursor,
    GetSettingsUI = function() return configUI end,
    RefreshPartyFrameClicksPage = function() RefreshPartyFrameClicksPage() end,
    IsAddonEnabled = IsEnabled,
    GetConsumableLeftOffset = function()
        return math.max(C.ROW_CONTENT_W, B.GetWidth("player"))
            + C.SHORTCUT_ICON_SIZE + C.SHORTCUT_ICON_GAP
        end,
    },
})


local configSurfaces = ApogeePartyHealthBars_SettingsSurfaces
ApogeePartyHealthBars.Require("Bootstrap", "AuxiliaryComposition").Initialize({
    ThreatObserver = threatObserver,
    ThreatObserverDependencies = {
        Now = function() return GetTime and GetTime() or 0 end,
    },
    ThreatAwareness = threatAwareness,
    ThreatAwarenessDependencies = {
        Observer = threatObserver,
        Sounds = ApogeePartyHealthBars_Sounds,
        SettingsSurfaces = configSurfaces,
        Now = function() return GetTime and GetTime() or 0 end,
        IsSupported = function()
            return ApogeePartyHealthBars_ClientCapabilities.IsFeatureAvailable("threat")
        end,
    },
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
    SettingsSurfaces = configSurfaces,
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
local ApplyBackdrop = ApogeePartyHealthBars_UIHelpers.ApplyBackdrop
local ApplyPanelChrome = unitFrames.ApplyPanelChrome

local function GetDungeonBoardClientFlavor()
    local info = ApogeePartyHealthBars_ClientCapabilities.GetClientInfo()
    return info and info.flavor or "unsupported"
end

local function GetDungeonBoardPlayerLevel()
    return tonumber(UnitLevel and UnitLevel("player")) or 0
end

local dungeonBoardSettings = ApogeePartyHealthBars_DungeonBoardSettings
dungeonBoardSettings.Initialize({
    GetSavedVariables = function() return S.sv end,
    Sounds = ApogeePartyHealthBars_Sounds,
})

local dungeonGuideSettings = ApogeePartyHealthBars_DungeonGuideSettings
dungeonGuideSettings.Initialize({ GetSavedVariables = function() return S.sv end })
local dungeonGuidePolicy = ApogeePartyHealthBars_DungeonGuidePolicy
dungeonGuidePolicy.Initialize({
    Catalog = ApogeePartyHealthBars_DungeonGuideCatalog,
    GetClientFlavor = GetDungeonBoardClientFlavor,
    GetInstanceId = function()
        if not GetInstanceInfo then return nil end
        return select(8, GetInstanceInfo())
    end,
})
M.Initialize({ Policy = dungeonGuidePolicy, Settings = dungeonGuideSettings })

local mentionAlerts = ApogeePartyHealthBars_MentionAlerts
mentionAlerts.Initialize({
    GetSavedVariables = function() return S.sv end,
    GetPlayerName = function() return UnitName and UnitName("player") end,
    GetPlayerGUID = function() return UnitGUID and UnitGUID("player") end,
    Sounds = ApogeePartyHealthBars_Sounds,
})

local dungeonBoardGroupFinder = ApogeePartyHealthBars_DungeonBoardGroupFinder
dungeonBoardGroupFinder.Initialize({
    Runtime = ApogeePartyHealthBars_DungeonBoardRuntime,
    ActivityData = ApogeePartyHealthBars_DungeonBoardActivityData,
    Catalog = ApogeePartyHealthBars_DungeonBoardCatalog,
    ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities,
    Settings = dungeonBoardSettings,
    API = {
        Search = function(...) return C_LFGList.Search(...) end,
        GetSearchResults = function() return C_LFGList.GetSearchResults() end,
        GetSearchResultInfo = function(resultID)
            return C_LFGList.GetSearchResultInfo(resultID)
        end,
        GetSearchResultMemberCounts = function(resultID)
            return C_LFGList.GetSearchResultMemberCounts(resultID)
        end,
        GetActivityInfoTable = function(activityID)
            return C_LFGList.GetActivityInfoTable(activityID)
        end,
        CanPlayerUsePremadeGroup = function()
            return C_LFGInfo.CanPlayerUsePremadeGroup()
        end,
    },
    GetClientFlavor = GetDungeonBoardClientFlavor,
    GetPlayerLevel = GetDungeonBoardPlayerLevel,
    Now = function() return GetTime() end,
    HookSearch = function(callback)
        hooksecurefunc(C_LFGList, "Search", callback)
    end,
})

local dungeonBoardActions = ApogeePartyHealthBars_DungeonBoardActions

local dungeonBoardFeed = ApogeePartyHealthBars_DungeonBoardFeed
dungeonBoardFeed.Initialize({
    Runtime = ApogeePartyHealthBars_DungeonBoardRuntime,
    Settings = dungeonBoardSettings,
    Eligibility = ApogeePartyHealthBars_DungeonBoardEligibility,
    Catalog = ApogeePartyHealthBars_DungeonBoardCatalog,
    Sounds = ApogeePartyHealthBars_Sounds,
    Helpers = ApogeePartyHealthBars_UIHelpers,
    SettingsSurfaces = configSurfaces,
    Actions = ApogeePartyHealthBars_DungeonBoardActions,
    GetPlayerLevel = GetDungeonBoardPlayerLevel,
    Now = function() return GetTime() end,
})
dungeonBoardFeed.Build()

local cleanseWatch = ApogeePartyHealthBars_CleanseWatch
cleanseWatch.Initialize({
    Auras = ApogeePartyHealthBars_Auras,
    PlayerSpells = ApogeePartyHealthBars_PlayerSpells,
    SecureFrames = ApogeePartyHealthBars_SecureFrames,
    SettingsSurfaces = configSurfaces,
    CreateBorder = ApogeePartyHealthBars_AccessoryLayout.CreateBorder,
    Now = function() return GetTime() end,
})
cleanseWatch.Build()

local buffThanks = ApogeePartyHealthBars_BuffThanks
buffThanks.Initialize({
    Auras = A,
    ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities,
    SettingsSurfaces = configSurfaces,
    Now = function() return GetTime and GetTime() or 0 end,
})
buffThanks.Build()

dungeonBoardUI = ApogeePartyHealthBars_DungeonBoardUI.Build({
    Runtime = ApogeePartyHealthBars_DungeonBoardRuntime,
    Catalog = ApogeePartyHealthBars_DungeonBoardCatalog,
    Eligibility = ApogeePartyHealthBars_DungeonBoardEligibility,
    Settings = dungeonBoardSettings,
    GroupFinder = dungeonBoardGroupFinder,
    Actions = dungeonBoardActions,
    GetClientFlavor = GetDungeonBoardClientFlavor,
    GetPlayerLevel = GetDungeonBoardPlayerLevel,
    Now = function() return GetTime() end,
    ApplyBackdrop = ApplyBackdrop,
    Print = Print,
})
dungeonGuideUI = ApogeePartyHealthBars_DungeonGuideUI.Build({
    Catalog = ApogeePartyHealthBars_DungeonGuideCatalog,
    Policy = dungeonGuidePolicy,
    Settings = dungeonGuideSettings,
    GetClientFlavor = GetDungeonBoardClientFlavor,
    ApplyBackdrop = ApplyBackdrop,
})
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

-- Layout functions live in PartyFrames/Layout.lua (registered after bindings init).

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
    playerStatusHud.Refresh()

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

    ClearDirtyFlags()
end


-- =============================================================================
-- Throttle
-- =============================================================================

updateScheduler.RegisterHandlers({
    FullUpdate = UpdateUI,
    ValuesUpdate = function()
        A.BeginAuraCacheGeneration()
        playerStatusHud.Refresh()
        UpdateRowValues()
    end,
    IsEnabled = IsEnabled,
})

-- =============================================================================
-- Click-cast bindings
-- =============================================================================

local clickBindings = ApogeePartyHealthBars_PartyFrameClickBindings
local L = ApogeePartyHealthBars_Layout
local partyFrameRuntime = ApogeePartyHealthBars.Require(
    "Bootstrap", "PartyFrameComposition").Initialize({
        ClickBindings = clickBindings,
        ClickBindingDependencies = {
            rows = rows,
            KeyToActionAttrs = KeyToActionAttrs,
            GetBindingsTable = GetBindingsTable,
            GetBindingAction = GetBindingAction,
        },
        Layout = L,
        LayoutDependencies = {
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
                W.Layout(actionGeometry.offsets.mouseWheel)
                K.Layout(actionGeometry.offsets.keyboard)
                B.Layout(actionGeometry.offsets.mouseButtons)
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
            IsEnabled = IsEnabled,
            RebuildUnitToRow = RebuildUnitToRow,
            PlayerUtility = playerUtility,
        },
})
ApplyAllBindings = partyFrameRuntime.ApplyAllBindings

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
    cleanseWatch.ReconcileSecure()
    ReconcileBoundActionBindings()
end

ApogeePartyHealthBars.Require("Bootstrap", "PartyFrameComposition")
    .RegisterSecureReconciler(secureFrames, ReconcileAllSecureOverlays)

local ClearBinding = bindingController.ClearBinding
local MoveBinding = bindingController.MoveBinding

-- Minimap controller
minimapController = ApogeePartyHealthBars_MinimapController
minimapController.Initialize({
    IsEnabled = IsEnabled,
    SetAddonEnabled = function(enabled) SetAddonEnabled(enabled) end,
    SetConfigMode = function(active) SetConfigMode(active) end,
    ToggleDungeonBoard = dungeonBoardUI.Toggle,
    ShowDungeonGuide = dungeonGuideUI.Show,
})
EnsureMinimapButton = minimapController.Ensure
local UpdateMinimapButtonStyle = minimapController.UpdateStyle
local ApplyDefaultMinimapPosition = minimapController.ResetPosition

ApogeePartyHealthBars.Require("Bootstrap", "EventRegistration")
    .RegisterSlashCommands({
        DungeonBoardUI = dungeonBoardUI,
        DungeonGuideUI = dungeonGuideUI,
        Print = Print,
    })



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

local ClaimBoundActionBindings = actionCoordinator.ClaimBoundActionBindings
local ReleaseBoundActionBindings = actionCoordinator.ReleaseBoundActionBindings
ReconcileBoundActionBindings = actionCoordinator.ReconcileBoundActionBindings

local configController = ApogeePartyHealthBars_SettingsController
local settingsRuntime = ApogeePartyHealthBars.Require(
    "Bootstrap", "SettingsComposition").Initialize({
    Controller = configController,
    ControllerDependencies = {
        panel = panel,
    GetSettingsUI = function() return configUI end,
    ForceRefresh = ForceRefresh,
    ClearDirtyFlags = ClearDirtyFlags,
    StopUpdateFrames = function() updateScheduler.Stop(); visualTicker.Stop() end,
    HideAllSecureOverlays = function() HideAllSecureOverlays() end,
    SavePosition = SavePosition,
    UpdateHeader = function() UpdateHeader() end,
    UpdateMinimapButtonStyle = UpdateMinimapButtonStyle,
    ScheduleSecureReconcile = secureFrames.RequestReconcile,
    ClaimBoundActionBindings = ClaimBoundActionBindings,
    ReleaseBoundActionBindings = ReleaseBoundActionBindings,
    ReconcileBoundActionBindings = ReconcileBoundActionBindings,
    ProfileStore = ApogeePartyHealthBars_ProfileStore,
    TargetEffectTracker = ApogeePartyHealthBars_TargetEffectTracker,
    TargetEffectHud = ApogeePartyHealthBars_TargetEffectHud,
    PlayerStatusHud = playerStatusHud,
    DungeonBoardFeed = dungeonBoardFeed,
    CleanseWatch = cleanseWatch,
    BuffThanks = buffThanks,
    ThreatAwareness = threatAwareness,
    SettingsSurfaces = configSurfaces,
        Print = Print,
    },
    BuildUI = function(settings)
        ExitConfigMode = settings.ExitConfigMode
        SetAddonEnabled = settings.SetAddonEnabled
        SetConfigMode = settings.SetConfigMode
        FactoryReset = settings.FactoryReset
        local ActivateProfile = settings.ActivateProfile
        local MutateActiveProfile = settings.MutateActiveProfile
        local CreateAndActivateProfile = settings.CreateAndActivateProfile
        return ApogeePartyHealthBars_SettingsUI.Build({
    ApplyBackdrop               = ApplyBackdrop,
    SettingsSurfaces             = configSurfaces,
    SetConfigMode              = SetConfigMode,
    GetBindingDisplay           = GetBindingDisplay,
    GetBinding                  = S.GetBinding,
    ClearBinding                = ClearBinding,
    MoveBinding                 = MoveBinding,
    Sounds                     = ApogeePartyHealthBars_Sounds,
    AssignCursorDrop           = AssignCursorDrop,
    ShortcutBar               = T,
    KeyboardActions                = K,
    MouseWheelActions                = W,
    MouseButtonActions         = B,
    ProfileStore              = ApogeePartyHealthBars_ProfileStore,
    ProfileCodec              = ApogeePartyHealthBars_ProfileCodec,
    EquipmentSets            = ApogeePartyHealthBars_EquipmentSets,
    ActivateProfile           = ActivateProfile,
    MutateActiveProfile       = MutateActiveProfile,
    CreateAndActivateProfile = CreateAndActivateProfile,
    AddonVersion              = ApogeePartyHealthBars_ClientCapabilities.GetAddonVersion(
        "ApogeePartyHealthBars"),
    ClientCapabilities       = ApogeePartyHealthBars_ClientCapabilities,
    TargetEffectTracker               = ApogeePartyHealthBars_TargetEffectTracker,
    TargetEffectHud                   = ApogeePartyHealthBars_TargetEffectHud,
    PlayerStatusHud                   = playerStatusHud,
    DungeonBoardFeed         = dungeonBoardFeed,
    CleanseWatch             = cleanseWatch,
    BuffThanks               = buffThanks,
    ThreatAwareness          = threatAwareness,
    DungeonGuideSettings    = dungeonGuideSettings,
    DungeonGuideUI          = dungeonGuideUI,
    RaidMarkers             = M,
    GetSavedVariables        = function() return S.sv end,
        CoreSettingsPages = {
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
        MentionAlerts               = mentionAlerts,
        DungeonBoardSettings        = dungeonBoardSettings,
        DungeonBoardFeed            = dungeonBoardFeed,
        DungeonBoardUI              = dungeonBoardUI,
        CleanseWatch                 = cleanseWatch,
        BuffThanks                   = buffThanks,
        Threat                      = H,
        ThreatAwareness             = threatAwareness,
        CombatUIFader               = ApogeePartyHealthBars_CombatUIFader,
        UIErrorSuppressor           = ApogeePartyHealthBars_UIErrorSuppressor,
        SyncVisualTicker            = SyncVisualTicker,
        ClientCapabilities          = ApogeePartyHealthBars_ClientCapabilities,
        },
        })
    end,
})
configUI = settingsRuntime.UI

RefreshConfigPanel = configUI.RefreshConfigPanel
RefreshPartyFrameClicksPage = configUI.RefreshPartyFrameClicksPage


-- =============================================================================
-- Events
-- =============================================================================

ApogeePartyHealthBars.Require("Bootstrap", "EventRegistration").Register({
    EventRouter = ApogeePartyHealthBars_EventRouter,
    RuntimeEvents = ApogeePartyHealthBars_RuntimeEvents,
    RuntimeDependencies = {
        Print = Print,
    RefreshAssignmentAffordances = T.RefreshAssignmentAffordances,
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
        GetSettingsUI = function() return configUI end,
    },
    HealthAlerts = ApogeePartyHealthBars_HealthAlerts,
})
