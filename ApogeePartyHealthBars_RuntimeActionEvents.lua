local S = ApogeePartyHealthBars_S
local T = ApogeePartyHealthBars_ShortcutBar
local W = ApogeePartyHealthBars_WheelMacros
local K = ApogeePartyHealthBars_KeyActions
local B = ApogeePartyHealthBars_MouseButtonActions
local CB = ApogeePartyHealthBars_ConsumableBar

ApogeePartyHealthBars_RuntimeActionEvents = {}
local A = ApogeePartyHealthBars_RuntimeActionEvents

function A.Register(eventRouter, deps)
    for _, key in ipairs({
        "Print", "InitPlayerSpells", "GetConfigUI", "ReconcileBoundActionBindings",
    }) do
        assert(deps[key] ~= nil, "RuntimeActionEvents missing dependency: " .. key)
    end

    local function RefreshMacroRequirements()
        local ui = deps.GetConfigUI()
        if ui.RefreshMacroPanel then ui.RefreshMacroPanel() end
    end

    local function RefreshManualActionCooldowns()
        T.Refresh(false); W.Refresh(); K.Refresh(); B.Refresh()
    end

    local function ProtectedRefreshManualActionCooldowns()
        local ok, err = pcall(RefreshManualActionCooldowns)
        if not ok then
            deps.Print("event error (delayed cooldown sampling): " .. tostring(err))
        end
    end

    local spellbook = _G.SpellBookFrame
    if spellbook and spellbook.HookScript then
        spellbook:HookScript("OnShow", function()
            T.SetSpellbookOpen(true)
        end)
        spellbook:HookScript("OnHide", function()
            T.SetSpellbookOpen(false)
        end)
        T.SetSpellbookOpen(spellbook:IsShown())
    end

    local function HandleEvent(event, ...)
        local firstArgument = ...
        local ok, err = pcall(function()
            if event == "ACTIVE_TALENT_GROUP_CHANGED" then
                W.OnActiveSpecChanged()
                K.OnActiveSpecChanged()
                B.OnActiveSpecChanged()
                if deps.GetConfigUI().RefreshKeyPanel then deps.GetConfigUI().RefreshKeyPanel() end
                if deps.GetConfigUI().RefreshWheelPanel then deps.GetConfigUI().RefreshWheelPanel() end
                if deps.GetConfigUI().RefreshMouseButtonPanel then deps.GetConfigUI().RefreshMouseButtonPanel() end

            elseif event == "SPELLS_CHANGED" then
                S.InitializeClassDefaultBindings()
                deps.InitPlayerSpells()
                T.ResolveAndRefresh()
                local wheelLayoutsChanged = W.RefreshLayouts()
                local keyLayoutsChanged = K.RefreshLayouts()
                local buttonLayoutsChanged = B.RefreshLayouts()
                if not wheelLayoutsChanged then W.Refresh() end
                if not keyLayoutsChanged then K.Refresh() end
                if not buttonLayoutsChanged then B.Refresh() end
                if keyLayoutsChanged and deps.GetConfigUI().RefreshKeyPanel then
                    deps.GetConfigUI().RefreshKeyPanel()
                end
                if wheelLayoutsChanged and deps.GetConfigUI().RefreshWheelPanel then
                    deps.GetConfigUI().RefreshWheelPanel()
                end
                if buttonLayoutsChanged and deps.GetConfigUI().RefreshMouseButtonPanel then
                    deps.GetConfigUI().RefreshMouseButtonPanel()
                end
                RefreshMacroRequirements()
                S.RequestUpdate()

            elseif event == "UPDATE_BINDINGS" then
                deps.ReconcileBoundActionBindings()
                if deps.GetConfigUI().RefreshKeyPanel then deps.GetConfigUI().RefreshKeyPanel() end
                if deps.GetConfigUI().RefreshWheelPanel then deps.GetConfigUI().RefreshWheelPanel() end
                if deps.GetConfigUI().RefreshMouseButtonPanel then deps.GetConfigUI().RefreshMouseButtonPanel() end

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
                S.RequestLayoutUpdate()

            elseif event == "UPDATE_SHAPESHIFT_FORMS" then
                W.RefreshLayouts()
                K.RefreshLayouts()
                B.RefreshLayouts()
                if deps.GetConfigUI().RefreshKeyPanel then deps.GetConfigUI().RefreshKeyPanel() end
                if deps.GetConfigUI().RefreshWheelPanel then deps.GetConfigUI().RefreshWheelPanel() end
                if deps.GetConfigUI().RefreshMouseButtonPanel then deps.GetConfigUI().RefreshMouseButtonPanel() end
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
        eventRouter.RegisterOptional(event, "ShortcutBar", function()
            RefreshManualActionCooldowns()
            CB.Refresh(false)
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
        local ui = deps.GetConfigUI()
        if ui.RefreshShortcutPanel then ui.RefreshShortcutPanel() end
        if ui.RefreshKeyPanel then ui.RefreshKeyPanel() end
        if ui.RefreshWheelPanel then ui.RefreshWheelPanel() end
        if ui.RefreshMouseButtonPanel then ui.RefreshMouseButtonPanel() end
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
        local ui = deps.GetConfigUI()
        if ui.RefreshShortcutPanel then ui.RefreshShortcutPanel() end
        if ui.RefreshKeyPanel then ui.RefreshKeyPanel() end
        if ui.RefreshWheelPanel then ui.RefreshWheelPanel() end
        if ui.RefreshMouseButtonPanel then ui.RefreshMouseButtonPanel() end
        if ui.RefreshBindPanel then ui.RefreshBindPanel() end
    end)

    eventRouter.RegisterOptional("UNIT_PET", "PlayerPetActions", function(_, unit)
        if unit == "player" then
            T.ResolveAndRefresh()
            RefreshMacroRequirements()
        end
    end)
    eventRouter.RegisterOptional("PET_BAR_UPDATE", "PlayerPetActions", function()
        T.ResolveAndRefresh()
        RefreshMacroRequirements()
    end)
    for _, event in ipairs({ "PET_BAR_UPDATE_COOLDOWN", "PET_BAR_UPDATE_USABLE" }) do
        eventRouter.RegisterOptional(event, "PlayerPetActionState", function()
            T.Refresh(false)
        end)
    end
end
