local S = ApogeePartyHealthBars_S
local A = ApogeePartyHealthBars_Auras
local E = ApogeePartyHealthBars_Effects
local T = ApogeePartyHealthBars_ShortcutBar
local W = ApogeePartyHealthBars_WheelMacros
local K = ApogeePartyHealthBars_KeyActions
local M = ApogeePartyHealthBars_RaidMarkers
local H = ApogeePartyHealthBars_Threat
local F = ApogeePartyHealthBars_SecureFrames
local U = ApogeePartyHealthBars_CombatUIFader

ApogeePartyHealthBars_RuntimeEvents = {}
local R = ApogeePartyHealthBars_RuntimeEvents
local D

function R.Register(eventRouter, deps)
    D = deps
    eventRouter.Initialize(D.Print)
    local HandleEvent
    local function RouteMainEvent(event, ...)
        HandleEvent(event, ...)
    end
    
    for _, event in ipairs({
        "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE",
        "PLAYER_TARGET_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_AURA", "COMBAT_LOG_EVENT_UNFILTERED",
    }) do
        eventRouter.Subscribe(event, "Bootstrap", RouteMainEvent)
    end
    
    for _, event in ipairs({
        "SPELLS_CHANGED",
        "ACTIVE_TALENT_GROUP_CHANGED",
        "UPDATE_BINDINGS",
        "ADDON_LOADED",
        "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_PREDICTION", "UNIT_POWER_UPDATE",
        "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
        "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS", "UNIT_TARGET", "UNIT_CONNECTION",
    }) do
        eventRouter.RegisterOptional(event, "Bootstrap", RouteMainEvent)
    end
    
    for _, event in ipairs({
        "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_CHARGES", "SPELL_UPDATE_USABLE",
        "ACTIONBAR_UPDATE_USABLE", "ACTIONBAR_UPDATE_COOLDOWN", "ACTIONBAR_UPDATE_STATE",
        "CURRENT_SPELL_CAST_CHANGED", "PLAYER_EQUIPMENT_CHANGED",
    }) do
        eventRouter.RegisterOptional(event, "ShortcutBar", function()
            T.Refresh(false); W.Refresh(); K.Refresh()
        end)
    end

    eventRouter.RegisterOptional("UNIT_FLAGS", "ShortcutBarTarget", function(_, unit)
        if unit == "target" then T.Refresh(false) end
    end)

    for _, event in ipairs({ "BAG_UPDATE_DELAYED", "BAG_UPDATE_COOLDOWN" }) do
        eventRouter.RegisterOptional(event, "ShortcutItems", function()
            T.Refresh(false)
            W.Refresh()
            K.Refresh()
            local ui = D.GetConfigUI()
            if ui.RefreshShortcutPanel then ui.RefreshShortcutPanel() end
            if ui.RefreshKeyPanel then ui.RefreshKeyPanel() end
            if ui.RefreshWheelPanel then ui.RefreshWheelPanel() end
        end)
    end
    eventRouter.RegisterOptional("GET_ITEM_INFO_RECEIVED", "ShortcutItemInfo", function()
        T.RefreshItemInfo()
        W.RefreshItemInfo()
        K.RefreshItemInfo()
        local ui = D.GetConfigUI()
        if ui.RefreshShortcutPanel then ui.RefreshShortcutPanel() end
        if ui.RefreshKeyPanel then ui.RefreshKeyPanel() end
        if ui.RefreshWheelPanel then ui.RefreshWheelPanel() end
        if ui.RefreshBindPanel then ui.RefreshBindPanel() end
    end)

    eventRouter.RegisterOptional("RAID_TARGET_UPDATE", "RaidMarkers", M.Refresh)
    
    for _, event in ipairs({ "UNIT_THREAT_SITUATION_UPDATE", "UNIT_THREAT_LIST_UPDATE" }) do
        eventRouter.RegisterOptional(event, "Threat", H.Refresh)
    end

    local function RefreshMacroRequirements()
        if D.GetConfigUI().RefreshMacroPanel then D.GetConfigUI().RefreshMacroPanel() end
    end
    eventRouter.RegisterOptional("UNIT_PET", "MacroLibraryPet", function(_, unit)
        if unit == "player" then RefreshMacroRequirements() end
    end)
    eventRouter.RegisterOptional("PET_BAR_UPDATE", "MacroLibraryPetBar", RefreshMacroRequirements)
    
    HandleEvent = function(event, unit)
        local ok, err = pcall(function()
        if event == "PLAYER_LOGIN" then
            if type(ApogeePartyHealthSV) ~= "table" then
                ApogeePartyHealthSV = {}
            end
            S.sv = ApogeePartyHealthSV
    
            if type(ApogeePartyHealthCharSV) ~= "table" then
                ApogeePartyHealthCharSV = {}
            end
            S.charSv = ApogeePartyHealthCharSV
            E.InitializeSavedVariables(S.sv, S.charSv)
            ApogeePartyHealthBars_BindingStore.Initialize()
            U.Initialize(S.sv.combatUIAutoHide)
            local macrosValid, macroErrors = ApogeePartyHealthBars_MacroLibrary.ValidateAll()
            if not macrosValid then
                for _, message in ipairs(macroErrors) do D.Print("macro validation: " .. message) end
            end
            S.InitializeClassDefaultBindings()
            T.Initialize()
            W.InitializeSaved()
            K.InitializeSaved()
    
            D.InitPlayerSpells()
            D.RestorePosition()
            D.UpdateHeader()
            D.HookSpellbook()
            D.HookContainerItems()
            D.EnsureMinimapButton()
            D.SeedShieldTrackerFromAuras()
            D.ForceRefresh()

        elseif event == "ADDON_LOADED" then
            if unit == "Blizzard_UIPanels_Game" or unit == "Blizzard_SpellBook" then
                D.HookSpellbook()
                D.HookContainerItems()
            end

        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            M.OnCombatLogEvent()
            if D.IsShieldEnabled() then
                D.OnShieldCombatLog()
            end
    
        elseif event == "PLAYER_REGEN_DISABLED" then
            U.OnCombatStart()
            W.OnCombatStarted()
            K.OnCombatStarted()
            if S.configMode then
                D.Print("config closed - combat started.")
                D.SetConfigMode(false)
            end
            D.ForceRefresh()
    
        elseif event == "PLAYER_REGEN_ENABLED" then
            U.OnCombatEnd()
            F.FlushDeferredUpdates()
            T.RefreshSecureActions()
            W.OnCombatEnded()
            K.OnCombatEnded()
            H.Refresh()
            D.ForceRefresh()
    
        elseif event == "PLAYER_TARGET_CHANGED" then
            T.Rebaseline()
            W.Refresh()
            K.Refresh()
            H.Refresh()
            S.RequestUpdate()
    
        elseif event == "PLAYER_ENTERING_WORLD"
            or event == "GROUP_ROSTER_UPDATE" then
            if event == "PLAYER_ENTERING_WORLD" then
                T.Rebaseline(); W.ReconcileBindings(); K.ReconcileBindings()
            end
            D.InitPlayerSpells()
            D.EnsureMinimapButton()
            D.SeedShieldTrackerFromAuras()
            H.Refresh()
            S.RequestUpdate()
    
        elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
            W.OnActiveSpecChanged()
            K.OnActiveSpecChanged()
            if D.GetConfigUI().RefreshKeyPanel then D.GetConfigUI().RefreshKeyPanel() end
            if D.GetConfigUI().RefreshWheelPanel then D.GetConfigUI().RefreshWheelPanel() end

        elseif event == "SPELLS_CHANGED" then
            S.InitializeClassDefaultBindings()
            D.InitPlayerSpells()
            T.ResolveAndRefresh()
            local wheelLayoutsChanged = W.RefreshLayouts()
            local keyLayoutsChanged = K.RefreshLayouts()
            if not wheelLayoutsChanged then W.Refresh() end
            if not keyLayoutsChanged then K.Refresh() end
            if keyLayoutsChanged and D.GetConfigUI().RefreshKeyPanel then
                D.GetConfigUI().RefreshKeyPanel()
            end
            if wheelLayoutsChanged and D.GetConfigUI().RefreshWheelPanel then
                D.GetConfigUI().RefreshWheelPanel()
            end
            RefreshMacroRequirements()
            S.RequestUpdate()

        elseif event == "UPDATE_BINDINGS" then
            W.ReconcileBindings()
            K.ReconcileBindings()
            if D.GetConfigUI().RefreshKeyPanel then D.GetConfigUI().RefreshKeyPanel() end
            if D.GetConfigUI().RefreshWheelPanel then D.GetConfigUI().RefreshWheelPanel() end
    
        elseif event == "UNIT_AURA"
            or event == "UNIT_ABSORB_AMOUNT_CHANGED" then
            if D.IsPanelTrackedUnit(unit) then
                A.InvalidateUnitAuraCache(unit)
                local panelUnit = D.ResolvePanelUnit(unit)
                if panelUnit ~= unit then
                    A.InvalidateUnitAuraCache(panelUnit)
                end
                D.ShieldTrackerSyncUnit(panelUnit)
                if D.AuraEventNeedsLayout(panelUnit) then
                    S.RequestLayoutUpdate()
                else
                    S.RequestValuesUpdate(panelUnit)
                end
            end
    
        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH"
            or event == "UNIT_HEAL_PREDICTION" then
            if D.IsPanelTrackedUnit(unit) then
                -- The event token may be party1 while a target pane displays the
                -- same GUID through "target" or "partyNtarget". Refresh every row
                -- so health and incoming-heal overlays stay correct for aliases.
                S.RequestValuesUpdate()
            end
    
        elseif event == "UNIT_DISPLAYPOWER" then
            if D.IsPanelTrackedUnit(unit) then
                if unit == "player" then
                    T.Refresh(false)
                    S.RequestLayoutUpdate()
                else
                    S.RequestValuesUpdate(D.ResolvePanelUnit(unit))
                end
            end
    
        elseif event == "UPDATE_SHAPESHIFT_FORM" then
            T.Refresh(false)
            W.OnStanceChanged()
            K.OnStanceChanged()
            S.RequestLayoutUpdate()

        elseif event == "UPDATE_SHAPESHIFT_FORMS" then
            W.RefreshLayouts()
            K.RefreshLayouts()
            if D.GetConfigUI().RefreshKeyPanel then D.GetConfigUI().RefreshKeyPanel() end
            if D.GetConfigUI().RefreshWheelPanel then D.GetConfigUI().RefreshWheelPanel() end
            S.RequestLayoutUpdate()
    
        elseif event == "UNIT_MAXPOWER" and unit == "player" then
            T.Refresh(false)
            S.RequestLayoutUpdate()
    
        elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT"
            or event == "UNIT_MAXPOWER" then
            if D.IsPanelTrackedUnit(unit) then
                if unit == "player" then T.Refresh(false) end
                S.RequestValuesUpdate(D.ResolvePanelUnit(unit))
            end
    
        elseif event == "UNIT_CONNECTION" then
            if D.IsPanelTrackedUnit(unit) then
                S.RequestLayoutUpdate()
            end
    
        elseif event == "UNIT_TARGET" then
            if unit == "player" or unit == "target" or (unit and unit:match("^party%d$")) then
                S.RequestLayoutUpdate()
            end
        end
        end)
        if not ok then
            D.Print("event error (" .. tostring(event) .. "): " .. tostring(err))
        end
    end
end
