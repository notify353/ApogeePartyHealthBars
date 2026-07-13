local S = ApogeePartyHealthBars_S
local A = ApogeePartyHealthBars_Auras
local E = ApogeePartyHealthBars_Effects
local T = ApogeePartyHealthBars_SpellTracker
local H = ApogeePartyHealthBars_Threat
local F = ApogeePartyHealthBars_SecureFrames

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
        "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_PREDICTION", "UNIT_POWER_UPDATE",
        "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
        "UPDATE_SHAPESHIFT_FORM", "UNIT_TARGET", "UNIT_CONNECTION",
    }) do
        eventRouter.RegisterOptional(event, "Bootstrap", RouteMainEvent)
    end
    
    for _, event in ipairs({
        "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_CHARGES", "SPELL_UPDATE_USABLE",
        "ACTIONBAR_UPDATE_USABLE", "ACTIONBAR_UPDATE_COOLDOWN", "ACTIONBAR_UPDATE_STATE",
        "CURRENT_SPELL_CAST_CHANGED", "PLAYER_EQUIPMENT_CHANGED",
    }) do
        eventRouter.RegisterOptional(event, "SpellTracker", function() T.Refresh(false) end)
    end
    
    for _, event in ipairs({ "UNIT_THREAT_SITUATION_UPDATE", "UNIT_THREAT_LIST_UPDATE" }) do
        eventRouter.RegisterOptional(event, "Threat", H.Refresh)
    end
    
    for _, event in ipairs({ "PLAYER_LEVEL_UP", "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE" }) do
        eventRouter.RegisterOptional(event, "MacroLibrary", function()
            if D.GetConfigUI().RefreshMacroPanel then D.GetConfigUI().RefreshMacroPanel(true) end
        end)
    end
    
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
            ApogeePartyHealthBars_MacroInstaller.Initialize(S.charSv)
            local macrosValid, macroErrors = ApogeePartyHealthBars_MacroLibrary.ValidateAll()
            if not macrosValid then
                for _, message in ipairs(macroErrors) do D.Print("macro validation: " .. message) end
            end
            S.InitializeClassDefaultBindings()
            T.Initialize()
    
            D.InitPlayerSpells()
            D.RestorePosition()
            D.UpdateHeader()
            D.HookSpellbook()
            D.EnsureMinimapButton()
            D.SeedShieldTrackerFromAuras()
            D.ForceRefresh()
    
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            if D.IsShieldEnabled() then
                D.OnShieldCombatLog()
            end
    
        elseif event == "PLAYER_REGEN_DISABLED" then
            if S.configMode then
                D.Print("config closed - combat started.")
                D.SetConfigMode(false)
            end
            D.ForceRefresh()
    
        elseif event == "PLAYER_REGEN_ENABLED" then
            F.FlushDeferredUpdates()
            T.RefreshSecureActions()
            H.Refresh()
            if D.GetConfigUI().RefreshMacroPanel then D.GetConfigUI().RefreshMacroPanel() end
            D.ForceRefresh()
    
        elseif event == "PLAYER_TARGET_CHANGED" then
            T.Rebaseline()
            H.Refresh()
            S.RequestUpdate()
    
        elseif event == "PLAYER_ENTERING_WORLD"
            or event == "GROUP_ROSTER_UPDATE" then
            if event == "PLAYER_ENTERING_WORLD" then T.Rebaseline() end
            D.InitPlayerSpells()
            D.EnsureMinimapButton()
            D.SeedShieldTrackerFromAuras()
            H.Refresh()
            S.RequestUpdate()
    
        elseif event == "SPELLS_CHANGED" then
            S.InitializeClassDefaultBindings()
            D.InitPlayerSpells()
            T.ResolveAndRefresh()
            if D.GetConfigUI().RefreshMacroPanel then D.GetConfigUI().RefreshMacroPanel(true) end
            S.RequestUpdate()
    
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
            if unit == "player" then
                T.Refresh(false)
                S.RequestLayoutUpdate()
            end
    
        elseif event == "UPDATE_SHAPESHIFT_FORM" then
            T.Refresh(false)
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
            if unit == "player" or (unit and unit:match("^party%d$")) then
                S.RequestLayoutUpdate()
            end
        end
        end)
        if not ok then
            D.Print("event error (" .. tostring(event) .. "): " .. tostring(err))
        end
    end
end
