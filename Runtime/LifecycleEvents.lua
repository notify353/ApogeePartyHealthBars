local S = ApogeePartyHealthBars_S
local E = ApogeePartyHealthBars_Effects
local T = ApogeePartyHealthBars_ShortcutBar
local W = ApogeePartyHealthBars_MouseWheelActions
local K = ApogeePartyHealthBars_KeyboardActions
local B = ApogeePartyHealthBars_MouseButtonActions
local CB = ApogeePartyHealthBars_ConsumableBar
local M = ApogeePartyHealthBars_RaidMarkers
local N = ApogeePartyHealthBars_TargetNameplateHud
local H = ApogeePartyHealthBars_Threat
local F = ApogeePartyHealthBars_SecureFrames
local U = ApogeePartyHealthBars_CombatUIFader
local ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities

ApogeePartyHealthBars_LifecycleEvents = {}
local L = ApogeePartyHealthBars_LifecycleEvents

function L.Register(eventRouter, deps)
    for _, key in ipairs({
        "Print", "InitPlayerSpells", "RestorePosition", "UpdateHeader",
        "EnsureMinimapButton",
        "SeedShieldTrackerFromAuras", "ForceRefresh", "IsShieldEnabled",
        "OnShieldCombatLog", "SetConfigMode", "ClaimBoundActionBindings",
        "ReleaseBoundActionBindings", "ReconcileBoundActionBindings",
    }) do
        assert(deps[key] ~= nil, "LifecycleEvents missing dependency: " .. key)
    end

    local function RunStep(owner, callback)
        local ok, err = pcall(callback)
        if not ok and ClientCapabilities then
            ClientCapabilities.RecordRuntimeFailure(owner, err)
        end
        return ok, err
    end

    local function ReconcilePhysicalBindings()
        local reconciled, code, detail = deps.ReconcileBoundActionBindings()
        if reconciled then return end
        if type(code) == "table" then code = table.concat(code, "; ") end
        error(detail or code or "Could not reconcile physical bindings.")
    end

    local function HandleEvent(event, isInitialLogin, isReloadingUi)
        local ok, err = pcall(function()
            if event == "PLAYER_LOGIN" then
                if type(ApogeePartyHealthCharSV) ~= "table" then
                    ApogeePartyHealthCharSV = {}
                end
                S.sv, S.charSv = ApogeePartyHealthSV, ApogeePartyHealthCharSV

                local storageReady, storageError = RunStep("Profile storage", function()
                    if ApogeePartyHealthBars_ProfileStore
                        and ApogeePartyHealthBars_ProfileStore.Initialize then
                        local playerClass = UnitClass and select(2, UnitClass("player"))
                        local playerName, playerRealm
                        if UnitFullName then playerName, playerRealm = UnitFullName("player") end
                        if not playerName and UnitName then playerName = UnitName("player") end
                        playerRealm = playerRealm or (GetRealmName and GetRealmName()) or "Unknown Realm"
                        local profileAuthor = tostring(playerName or "Unknown")
                            .. " - " .. tostring(playerRealm)
                        ApogeePartyHealthBars_ProfileStore.Initialize(
                            ApogeePartyHealthSV, ApogeePartyHealthCharSV,
                            playerClass, profileAuthor)
                    end
                    E.InitializeSavedVariables(S.sv, S.charSv)
                    ApogeePartyHealthBars_BindingStore.Initialize()
                end)
                if not storageReady then error(storageError, 0) end

                RunStep("Combat UI fading", function()
                    U.Initialize(S.sv and S.sv.combatUIAutoHide)
                end)
                RunStep("Macro library", function()
                    local macrosValid, macroErrors = ApogeePartyHealthBars_MacroLibrary.ValidateAll()
                    if not macrosValid then
                        for _, message in ipairs(macroErrors) do
                            deps.Print("macro validation: " .. message)
                        end
                    end
                end)
                RunStep("Party Frame Clicks", S.InitializeClassDefaultBindings)
                RunStep("Shortcuts", T.Initialize)
                RunStep("Mouse Wheel", W.InitializeSaved)
                RunStep("Keyboard", K.InitializeSaved)
                RunStep("Mouse Buttons", B.InitializeSaved)
                RunStep("Consumables", CB.Initialize)
                RunStep("Raid markers", M.Initialize)
                RunStep("Physical bindings", function()
                    local bindingsOk, bindingsCode, bindingsDetail
                    if S.sv and S.sv.enabled then
                        bindingsOk, bindingsCode, bindingsDetail = deps.ClaimBoundActionBindings()
                    else
                        bindingsOk, bindingsCode, bindingsDetail = deps.ReleaseBoundActionBindings()
                    end
                    if not bindingsOk then
                        error(bindingsDetail or bindingsCode or "could not update action bindings.")
                    end
                end)

                RunStep("Spell discovery", deps.InitPlayerSpells)
                RunStep("Bar position", deps.RestorePosition)
                RunStep("Bar header", deps.UpdateHeader)
                RunStep("Minimap button", deps.EnsureMinimapButton)
                RunStep("Shield tracking", deps.SeedShieldTrackerFromAuras)
                RunStep("Initial refresh", deps.ForceRefresh)

                if ClientCapabilities then
                    local unavailable = ClientCapabilities.ListUnavailableFeatures()
                    local failures = ClientCapabilities.ListRuntimeFailures()
                    if #unavailable > 0 or #failures > 0 then
                        deps.Print("Compatibility: " .. tostring(#unavailable)
                            .. " optional feature(s) unavailable and " .. tostring(#failures)
                            .. " initialization failure(s) isolated. See Manage > Maintenance.")
                    end
                end

            elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
                if deps.IsShieldEnabled() then
                    RunStep("Shield tracking", deps.OnShieldCombatLog)
                end

            elseif event == "PLAYER_REGEN_DISABLED" then
                RunStep("Combat UI fading", U.OnCombatStart)
                RunStep("Mouse Wheel", W.OnCombatStarted)
                RunStep("Keyboard", K.OnCombatStarted)
                RunStep("Mouse Buttons", B.OnCombatStarted)
                if S.configMode then
                    deps.Print("config closed - combat started.")
                    deps.SetConfigMode(false)
                end
                RunStep("Combat refresh", deps.ForceRefresh)

            elseif event == "PLAYER_REGEN_ENABLED" then
                RunStep("Combat UI fading", U.OnCombatEnd)
                RunStep("Secure frames", F.FlushDeferredUpdates)
                RunStep("Shortcuts", T.RefreshSecureActions)
                RunStep("Mouse Wheel", W.OnCombatEnded)
                RunStep("Keyboard", K.OnCombatEnded)
                RunStep("Mouse Buttons", B.OnCombatEnded)
                RunStep("Consumables", CB.OnCombatEnded)
                RunStep("Physical bindings", ReconcilePhysicalBindings)
                RunStep("Threat", H.Refresh)
                RunStep("Combat refresh", deps.ForceRefresh)

            elseif event == "PLAYER_TARGET_CHANGED" then
                RunStep("Target nameplate HUD", N.OnTargetChanged)
                RunStep("Raid markers", M.Refresh)
                RunStep("Shortcuts", T.Rebaseline)
                RunStep("Mouse Wheel", W.Refresh)
                RunStep("Keyboard", K.Refresh)
                RunStep("Mouse Buttons", B.Refresh)
                RunStep("Threat", H.Refresh)
                S.RequestUpdate()

            elseif event == "PLAYER_ENTERING_WORLD"
                or event == "GROUP_ROSTER_UPDATE" then
                if event == "PLAYER_ENTERING_WORLD" then
                    RunStep("Shortcuts", T.Rebaseline)
                    RunStep("Consumables", CB.OnBagUpdate)
                    if isReloadingUi == true and C_Timer and C_Timer.After then
                        C_Timer.After(0, function()
                            RunStep("Consumables reload", CB.OnBagUpdate)
                        end)
                    end
                    RunStep("Physical bindings", ReconcilePhysicalBindings)
                end
                RunStep("Spell discovery", deps.InitPlayerSpells)
                RunStep("Minimap button", deps.EnsureMinimapButton)
                RunStep("Shield tracking", deps.SeedShieldTrackerFromAuras)
                RunStep("Threat", H.Refresh)
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
    }) do
        eventRouter.Subscribe(event, "Bootstrap", HandleEvent)
    end
    eventRouter.RegisterOptional("COMBAT_LOG_EVENT_UNFILTERED", "Bootstrap", HandleEvent)
end
