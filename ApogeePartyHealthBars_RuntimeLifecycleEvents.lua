local S = ApogeePartyHealthBars_S
local E = ApogeePartyHealthBars_Effects
local T = ApogeePartyHealthBars_ShortcutBar
local W = ApogeePartyHealthBars_WheelMacros
local K = ApogeePartyHealthBars_KeyActions
local M = ApogeePartyHealthBars_RaidMarkers
local H = ApogeePartyHealthBars_Threat
local F = ApogeePartyHealthBars_SecureFrames
local U = ApogeePartyHealthBars_CombatUIFader

ApogeePartyHealthBars_RuntimeLifecycleEvents = {}
local L = ApogeePartyHealthBars_RuntimeLifecycleEvents

function L.Register(eventRouter, deps)
    for _, key in ipairs({
        "Print", "InitPlayerSpells", "RestorePosition", "UpdateHeader",
        "EnsureMinimapButton",
        "SeedShieldTrackerFromAuras", "ForceRefresh", "IsShieldEnabled",
        "OnShieldCombatLog", "SetConfigMode", "ClaimBoundActionBindings",
        "ReleaseBoundActionBindings", "ReconcileBoundActionBindings",
    }) do
        assert(deps[key] ~= nil, "RuntimeLifecycleEvents missing dependency: " .. key)
    end

    local function HandleEvent(event, unit)
        local ok, err = pcall(function()
            if event == "PLAYER_LOGIN" then
                if type(ApogeePartyHealthSV) ~= "table" then
                    ApogeePartyHealthSV = {}
                end
                if type(ApogeePartyHealthCharSV) ~= "table" then
                    ApogeePartyHealthCharSV = {}
                end
                if ApogeePartyHealthBars_ProfileStore and ApogeePartyHealthBars_ProfileStore.Initialize then
                    local _, playerClass = UnitClass and UnitClass("player")
                    local playerName, playerRealm
                    if UnitFullName then playerName, playerRealm = UnitFullName("player") end
                    if not playerName and UnitName then playerName = UnitName("player") end
                    playerRealm = playerRealm or (GetRealmName and GetRealmName()) or "Unknown Realm"
                    local profileAuthor = tostring(playerName or "Unknown") .. " - " .. tostring(playerRealm)
                    ApogeePartyHealthBars_ProfileStore.Initialize(
                        ApogeePartyHealthSV, ApogeePartyHealthCharSV, playerClass, profileAuthor
                    )
                else
                    S.sv, S.charSv = ApogeePartyHealthSV, ApogeePartyHealthCharSV
                end
                E.InitializeSavedVariables(S.sv, S.charSv)
                ApogeePartyHealthBars_BindingStore.Initialize()
                U.Initialize(S.sv.combatUIAutoHide)
                local macrosValid, macroErrors = ApogeePartyHealthBars_MacroLibrary.ValidateAll()
                if not macrosValid then
                    for _, message in ipairs(macroErrors) do
                        deps.Print("macro validation: " .. message)
                    end
                end
                S.InitializeClassDefaultBindings()
                T.Initialize()
                W.InitializeSaved()
                K.InitializeSaved()
                local bindingsOk, bindingsCode, bindingsDetail
                if S.sv.enabled then
                    bindingsOk, bindingsCode, bindingsDetail = deps.ClaimBoundActionBindings()
                else
                    bindingsOk, bindingsCode, bindingsDetail = deps.ReleaseBoundActionBindings()
                end
                if not bindingsOk then
                    deps.Print(bindingsDetail or bindingsCode
                        or "could not update Keys and Wheel bindings.")
                end

                deps.InitPlayerSpells()
                deps.RestorePosition()
                deps.UpdateHeader()
                deps.EnsureMinimapButton()
                deps.SeedShieldTrackerFromAuras()
                deps.ForceRefresh()

            elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
                M.OnCombatLogEvent()
                if deps.IsShieldEnabled() then
                    deps.OnShieldCombatLog()
                end

            elseif event == "PLAYER_REGEN_DISABLED" then
                U.OnCombatStart()
                W.OnCombatStarted()
                K.OnCombatStarted()
                if S.configMode then
                    deps.Print("config closed - combat started.")
                    deps.SetConfigMode(false)
                end
                deps.ForceRefresh()

            elseif event == "PLAYER_REGEN_ENABLED" then
                U.OnCombatEnd()
                F.FlushDeferredUpdates()
                T.RefreshSecureActions()
                W.OnCombatEnded()
                K.OnCombatEnded()
                deps.ReconcileBoundActionBindings()
                H.Refresh()
                deps.ForceRefresh()

            elseif event == "PLAYER_TARGET_CHANGED" then
                T.Rebaseline()
                W.Refresh()
                K.Refresh()
                H.Refresh()
                S.RequestUpdate()

            elseif event == "PLAYER_ENTERING_WORLD"
                or event == "GROUP_ROSTER_UPDATE" then
                if event == "PLAYER_ENTERING_WORLD" then
                    T.Rebaseline()
                    deps.ReconcileBoundActionBindings()
                end
                deps.InitPlayerSpells()
                deps.EnsureMinimapButton()
                deps.SeedShieldTrackerFromAuras()
                H.Refresh()
                S.RequestUpdate()
            end
        end)
        if not ok then
            deps.Print("event error (" .. tostring(event) .. "): " .. tostring(err))
        end
    end

    for _, event in ipairs({
        "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE",
        "PLAYER_TARGET_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "COMBAT_LOG_EVENT_UNFILTERED",
    }) do
        eventRouter.Subscribe(event, "Bootstrap", HandleEvent)
    end
end
