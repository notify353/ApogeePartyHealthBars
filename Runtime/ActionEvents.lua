local S = ApogeePartyHealthBars_S
local T = ApogeePartyHealthBars_ShortcutBar
local W = ApogeePartyHealthBars_MouseWheelActions
local K = ApogeePartyHealthBars_KeyboardActions
local B = ApogeePartyHealthBars_MouseButtonActions
local CB = ApogeePartyHealthBars_ConsumableBar
local AssignmentSources = ApogeePartyHealthBars_ActionAssignmentSources

ApogeePartyHealthBars_ActionEvents = {}
local A = ApogeePartyHealthBars_ActionEvents

function A.Register(eventRouter, deps)
    for _, key in ipairs({
        "Print", "InitPlayerSpells", "GetSettingsUI", "ReconcileBoundActionBindings",
    }) do
        assert(deps[key] ~= nil, "ActionEvents missing dependency: " .. key)
    end

    local function RefreshManualActionCooldowns()
        T.Refresh(false); W.Refresh(); K.Refresh(); B.Refresh()
    end

    local function RefreshEquipmentLoadouts()
        T.RefreshSecureActions()
        W.RefreshSecureActions()
        K.RefreshSecureActions()
        B.RefreshSecureActions()
        local ui = deps.GetSettingsUI()
        if ui.RefreshShortcutPanel then ui.RefreshShortcutPanel() end
        if ui.RefreshKeyboardPage then ui.RefreshKeyboardPage() end
        if ui.RefreshMouseWheelPage then ui.RefreshMouseWheelPage() end
        if ui.RefreshMouseButtonsPage then ui.RefreshMouseButtonsPage() end
        if ui.RefreshLoadoutsPage then ui.RefreshLoadoutsPage() end
    end

    local function ProtectedRefreshManualActionCooldowns()
        local ok, err = pcall(RefreshManualActionCooldowns)
        if not ok then
            deps.Print("event error (delayed cooldown sampling): " .. tostring(err))
        end
    end

    local spellbook = _G.SpellBookFrame
    local function RefreshAssignmentAffordances(changed)
        if changed and (not InCombatLockdown or not InCombatLockdown()) then
            T.RefreshAssignmentAffordances()
        end
    end
    if spellbook and spellbook.HookScript then
        spellbook:HookScript("OnShow", function()
            RefreshAssignmentAffordances(AssignmentSources.SetSpellbookOpen(true))
        end)
        spellbook:HookScript("OnHide", function()
            RefreshAssignmentAffordances(AssignmentSources.SetSpellbookOpen(false))
        end)
        RefreshAssignmentAffordances(AssignmentSources.SetSpellbookOpen(spellbook:IsShown()))
    end

    -- Classic's normal ToggleBag implementation shows and hides reusable
    -- ContainerFrames directly. Observe only their visibility lifecycle so the
    -- Shortcut add target can relayout; never hook or replace item-button input.
    for index = 1, tonumber(NUM_CONTAINER_FRAMES) or 13 do
        local container = _G["ContainerFrame" .. index]
        if container and container.HookScript then
            container:HookScript("OnShow", function(self)
                RefreshAssignmentAffordances(
                    AssignmentSources.SetPlayerBagOpen(self:GetID(), true))
            end)
            container:HookScript("OnHide", function(self)
                RefreshAssignmentAffordances(
                    AssignmentSources.SetPlayerBagOpen(self:GetID(), false))
            end)
            if container.IsShown and container:IsShown() then
                AssignmentSources.SetPlayerBagOpen(container:GetID(), true)
            end
        end
    end

    -- Both supported generated API exports document these as synchronous
    -- events with a bagID payload. Register them as required assignment-source
    -- signals; native ContainerFrame visibility remains an independent signal
    -- for Classic's direct ToggleBag path.
    eventRouter.Subscribe("BAG_OPEN", "ActionAssignmentSources", function(_, bagId)
        RefreshAssignmentAffordances(AssignmentSources.SetPlayerBagOpen(bagId, true))
    end)
    eventRouter.Subscribe("BAG_CLOSED", "ActionAssignmentSources", function(_, bagId)
        RefreshAssignmentAffordances(AssignmentSources.SetPlayerBagOpen(bagId, false))
    end)
    eventRouter.RegisterOptional("CURSOR_CHANGED", "ActionAssignmentSources", function()
        -- Replacement bag UIs may not show stock ContainerFrames or emit bag
        -- visibility events. Re-evaluate the Shortcut target when an actual
        -- item cursor appears or clears; assignment validation remains in the
        -- BindingController mutation boundary.
        RefreshAssignmentAffordances(true)
    end)

    -- Baganator replaces Blizzard's bag toggles and does not show stock
    -- ContainerFrames. Its public callback registry is the authoritative view
    -- lifecycle for its combined backpack. Keep this adapter optional and do
    -- not inspect or hook Baganator item buttons.
    local baganatorCallbacksRegistered = false
    local function RegisterBaganatorCallbacks()
        if baganatorCallbacksRegistered then return true end
        local registry = _G.Baganator and _G.Baganator.CallbackRegistry
        if not registry or type(registry.RegisterCallback) ~= "function" then
            return false
        end
        registry:RegisterCallback("BagShow", function()
            RefreshAssignmentAffordances(
                AssignmentSources.SetExternalPlayerBagsOpen(true))
        end)
        registry:RegisterCallback("BagHide", function()
            RefreshAssignmentAffordances(
                AssignmentSources.SetExternalPlayerBagsOpen(false))
        end)
        baganatorCallbacksRegistered = true
        return true
    end
    RegisterBaganatorCallbacks()
    eventRouter.Subscribe("ADDON_LOADED", "ActionAssignmentSources", function(_, addonName)
        if addonName == "Baganator" then RegisterBaganatorCallbacks() end
    end)

    local function HandleEvent(event, ...)
        local firstArgument = ...
        local ok, err = pcall(function()
            if event == "ACTIVE_TALENT_GROUP_CHANGED" then
                W.OnActiveSpecChanged()
                K.OnActiveSpecChanged()
                B.OnActiveSpecChanged()
                if deps.GetSettingsUI().RefreshKeyboardPage then deps.GetSettingsUI().RefreshKeyboardPage() end
                if deps.GetSettingsUI().RefreshMouseWheelPage then deps.GetSettingsUI().RefreshMouseWheelPage() end
                if deps.GetSettingsUI().RefreshMouseButtonsPage then deps.GetSettingsUI().RefreshMouseButtonsPage() end

            elseif event == "SPELLS_CHANGED" then
                S.InitializeClassDefaultBindings()
                deps.InitPlayerSpells()
                if ApogeePartyHealthBars_ActionMacros
                        and ApogeePartyHealthBars_ActionMacros.InvalidateRuntimeSpellCache then
                    ApogeePartyHealthBars_ActionMacros.InvalidateRuntimeSpellCache()
                end
                T.ResolveAndRefresh()
                local wheelLayoutsChanged = W.RefreshLayouts()
                local keyLayoutsChanged = K.RefreshLayouts()
                local buttonLayoutsChanged = B.RefreshLayouts()
                if not wheelLayoutsChanged then W.Refresh() end
                if not keyLayoutsChanged then K.Refresh() end
                if not buttonLayoutsChanged then B.Refresh() end
                if keyLayoutsChanged and deps.GetSettingsUI().RefreshKeyboardPage then
                    deps.GetSettingsUI().RefreshKeyboardPage()
                end
                if wheelLayoutsChanged and deps.GetSettingsUI().RefreshMouseWheelPage then
                    deps.GetSettingsUI().RefreshMouseWheelPage()
                end
                if buttonLayoutsChanged and deps.GetSettingsUI().RefreshMouseButtonsPage then
                    deps.GetSettingsUI().RefreshMouseButtonsPage()
                end
                S.RequestUpdate()

            elseif event == "UPDATE_BINDINGS" then
                deps.ReconcileBoundActionBindings()
                if deps.GetSettingsUI().RefreshKeyboardPage then deps.GetSettingsUI().RefreshKeyboardPage() end
                if deps.GetSettingsUI().RefreshMouseWheelPage then deps.GetSettingsUI().RefreshMouseWheelPage() end
                if deps.GetSettingsUI().RefreshMouseButtonsPage then deps.GetSettingsUI().RefreshMouseButtonsPage() end

            elseif event == "CVAR_UPDATE" then
                local cvarName = type(firstArgument) == "string"
                    and string.lower(firstArgument) or ""
                if cvarName == "actionbuttonusekeydown" then
                    W.RefreshPhysicalClickRegistration()
                    K.RefreshPhysicalClickRegistration()
                    B.RefreshPhysicalClickRegistration()
                end

            elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_STEALTH" then
                T.Refresh(false)
                W.OnStateChanged()
                K.OnStateChanged()
                B.OnStateChanged()
                local ui = deps.GetSettingsUI()
                if ui.RefreshKeyboardPage then ui.RefreshKeyboardPage() end
                if ui.RefreshMouseWheelPage then ui.RefreshMouseWheelPage() end
                if ui.RefreshMouseButtonsPage then ui.RefreshMouseButtonsPage() end
                S.RequestLayoutUpdate()

            elseif event == "UPDATE_SHAPESHIFT_FORMS" then
                W.RefreshLayouts()
                K.RefreshLayouts()
                B.RefreshLayouts()
                if deps.GetSettingsUI().RefreshKeyboardPage then deps.GetSettingsUI().RefreshKeyboardPage() end
                if deps.GetSettingsUI().RefreshMouseWheelPage then deps.GetSettingsUI().RefreshMouseWheelPage() end
                if deps.GetSettingsUI().RefreshMouseButtonsPage then deps.GetSettingsUI().RefreshMouseButtonsPage() end
                S.RequestLayoutUpdate()
            end
        end)
        if not ok then
            deps.Print("event error (" .. tostring(event) .. "): " .. tostring(err))
        end
    end

    for _, event in ipairs({
        "SPELLS_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED", "UPDATE_BINDINGS",
        "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS", "UPDATE_STEALTH",
        "CVAR_UPDATE",
    }) do
        eventRouter.RegisterOptional(event, "Bootstrap", HandleEvent)
    end

    for _, event in ipairs({
        "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_CHARGES", "SPELL_UPDATE_USABLE",
        "ACTIONBAR_UPDATE_USABLE", "ACTIONBAR_UPDATE_COOLDOWN", "ACTIONBAR_UPDATE_STATE",
        "CURRENT_SPELL_CAST_CHANGED", "PLAYER_EQUIPMENT_CHANGED",
    }) do
        local actionEvent = event
        eventRouter.RegisterOptional(actionEvent, "ShortcutBar", function()
            RefreshManualActionCooldowns()
            CB.Refresh(false)
            if actionEvent == "PLAYER_EQUIPMENT_CHANGED" then
                T.RefreshSecureActions()
                W.RefreshSecureActions()
                K.RefreshSecureActions()
                B.RefreshSecureActions()
                local ui = deps.GetSettingsUI()
                if ui.RefreshShortcutPanel then ui.RefreshShortcutPanel() end
                if ui.RefreshKeyboardPage then ui.RefreshKeyboardPage() end
                if ui.RefreshMouseWheelPage then ui.RefreshMouseWheelPage() end
                if ui.RefreshMouseButtonsPage then ui.RefreshMouseButtonsPage() end
                if ui.RefreshLoadoutsFromInventory then
                    ui.RefreshLoadoutsFromInventory()
                elseif ui.RefreshLoadoutsPage then
                    ui.RefreshLoadoutsPage()
                end
            end
        end)
    end

    eventRouter.RegisterOptional("UNIT_SPELLCAST_SUCCEEDED", "ActionCooldownSampling", function(_, unit)
        if unit ~= "player" or not C_Timer or not C_Timer.After then return end
        -- Classic can initially expose only start recovery, then publish the
        -- spell's real cooldown. Doom Cooldown Pulse uses the same half-second
        -- post-cast sampling window before it starts tracking a cooldown.
        C_Timer.After(0.5, ProtectedRefreshManualActionCooldowns)
    end)

    eventRouter.RegisterOptional("UNIT_FLAGS", "ShortcutBarTarget", function(_, unit)
        if unit == "target" then T.Refresh(false) end
    end)

    eventRouter.RegisterOptional("BAG_UPDATE_DELAYED", "ShortcutItems", function()
        CB.OnBagUpdate()
        T.Refresh(false)
        W.Refresh()
        K.Refresh()
        B.Refresh()
        local ui = deps.GetSettingsUI()
        if ui.RefreshShortcutPanel then ui.RefreshShortcutPanel() end
        if ui.RefreshKeyboardPage then ui.RefreshKeyboardPage() end
        if ui.RefreshMouseWheelPage then ui.RefreshMouseWheelPage() end
        if ui.RefreshMouseButtonsPage then ui.RefreshMouseButtonsPage() end
    end)
    eventRouter.RegisterOptional("BAG_UPDATE_COOLDOWN", "ShortcutItems", function()
        T.Refresh(false)
        W.Refresh()
        K.Refresh()
        B.Refresh()
        CB.Refresh(false)
    end)
    eventRouter.RegisterOptional("GET_ITEM_INFO_RECEIVED", "ShortcutItemInfo", function()
        T.RefreshItemInfo()
        W.RefreshItemInfo()
        K.RefreshItemInfo()
        B.RefreshItemInfo()
        CB.RefreshItemInfo()
        local ui = deps.GetSettingsUI()
        if ui.RefreshShortcutPanel then ui.RefreshShortcutPanel() end
        if ui.RefreshKeyboardPage then ui.RefreshKeyboardPage() end
        if ui.RefreshMouseWheelPage then ui.RefreshMouseWheelPage() end
        if ui.RefreshMouseButtonsPage then ui.RefreshMouseButtonsPage() end
        if ui.RefreshPartyFrameClicksPage then ui.RefreshPartyFrameClicksPage() end
    end)

    eventRouter.RegisterOptional("EQUIPMENT_SETS_CHANGED", "EquipmentLoadouts", function()
        RefreshEquipmentLoadouts()
    end)

    eventRouter.RegisterOptional("UNIT_PET", "PlayerPetActions", function(_, unit)
        if unit == "player" then
            T.ResolveAndRefresh()
        end
    end)
    eventRouter.RegisterOptional("PET_BAR_UPDATE", "PlayerPetActions", function()
        T.ResolveAndRefresh()
    end)
    for _, event in ipairs({ "PET_BAR_UPDATE_COOLDOWN", "PET_BAR_UPDATE_USABLE" }) do
        eventRouter.RegisterOptional(event, "PlayerPetActionState", function()
            T.Refresh(false)
        end)
    end
end
