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
        "HookSpellbook", "HookContainerItems", "EnsureMinimapButton",
        "SeedShieldTrackerFromAuras", "ForceRefresh", "IsShieldEnabled",
        "OnShieldCombatLog", "SetConfigMode",
    }) do
        assert(deps[key] ~= nil, "RuntimeLifecycleEvents missing dependency: " .. key)
    end

    local function HandleEvent(event, unit)
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
                    for _, message in ipairs(macroErrors) do
                        deps.Print("macro validation: " .. message)
                    end
                end
                S.InitializeClassDefaultBindings()
                T.Initialize()
                W.InitializeSaved()
                K.InitializeSaved()

                deps.InitPlayerSpells()
                deps.RestorePosition()
                deps.UpdateHeader()
                deps.HookSpellbook()
                deps.HookContainerItems()
                deps.EnsureMinimapButton()
                deps.SeedShieldTrackerFromAuras()
                deps.ForceRefresh()

            elseif event == "ADDON_LOADED" then
                if unit == "Blizzard_UIPanels_Game" or unit == "Blizzard_SpellBook" then
                    deps.HookSpellbook()
                    deps.HookContainerItems()
                end

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
                    W.ReconcileBindings()
                    K.ReconcileBindings()
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
    eventRouter.RegisterOptional("ADDON_LOADED", "Bootstrap", HandleEvent)
end
