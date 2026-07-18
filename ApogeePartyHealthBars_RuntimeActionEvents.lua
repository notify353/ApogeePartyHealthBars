local S = ApogeePartyHealthBars_S
local T = ApogeePartyHealthBars_ShortcutBar
local W = ApogeePartyHealthBars_WheelMacros
local K = ApogeePartyHealthBars_KeyActions

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

    local function HandleEvent(event)
        local ok, err = pcall(function()
            if event == "ACTIVE_TALENT_GROUP_CHANGED" then
                W.OnActiveSpecChanged()
                K.OnActiveSpecChanged()
                if deps.GetConfigUI().RefreshKeyPanel then deps.GetConfigUI().RefreshKeyPanel() end
                if deps.GetConfigUI().RefreshWheelPanel then deps.GetConfigUI().RefreshWheelPanel() end

            elseif event == "SPELLS_CHANGED" then
                S.InitializeClassDefaultBindings()
                deps.InitPlayerSpells()
                T.ResolveAndRefresh()
                local wheelLayoutsChanged = W.RefreshLayouts()
                local keyLayoutsChanged = K.RefreshLayouts()
                if not wheelLayoutsChanged then W.Refresh() end
                if not keyLayoutsChanged then K.Refresh() end
                if keyLayoutsChanged and deps.GetConfigUI().RefreshKeyPanel then
                    deps.GetConfigUI().RefreshKeyPanel()
                end
                if wheelLayoutsChanged and deps.GetConfigUI().RefreshWheelPanel then
                    deps.GetConfigUI().RefreshWheelPanel()
                end
                RefreshMacroRequirements()
                S.RequestUpdate()

            elseif event == "UPDATE_BINDINGS" then
                deps.ReconcileBoundActionBindings()
                if deps.GetConfigUI().RefreshKeyPanel then deps.GetConfigUI().RefreshKeyPanel() end
                if deps.GetConfigUI().RefreshWheelPanel then deps.GetConfigUI().RefreshWheelPanel() end

            elseif event == "UPDATE_SHAPESHIFT_FORM" then
                T.Refresh(false)
                W.OnStanceChanged()
                K.OnStanceChanged()
                S.RequestLayoutUpdate()

            elseif event == "UPDATE_SHAPESHIFT_FORMS" then
                W.RefreshLayouts()
                K.RefreshLayouts()
                if deps.GetConfigUI().RefreshKeyPanel then deps.GetConfigUI().RefreshKeyPanel() end
                if deps.GetConfigUI().RefreshWheelPanel then deps.GetConfigUI().RefreshWheelPanel() end
                S.RequestLayoutUpdate()
            end
        end)
        if not ok then
            deps.Print("event error (" .. tostring(event) .. "): " .. tostring(err))
        end
    end

    for _, event in ipairs({
        "SPELLS_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED", "UPDATE_BINDINGS",
        "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS",
    }) do
        eventRouter.RegisterOptional(event, "Bootstrap", HandleEvent)
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
            local ui = deps.GetConfigUI()
            if ui.RefreshShortcutPanel then ui.RefreshShortcutPanel() end
            if ui.RefreshKeyPanel then ui.RefreshKeyPanel() end
            if ui.RefreshWheelPanel then ui.RefreshWheelPanel() end
        end)
    end
    eventRouter.RegisterOptional("GET_ITEM_INFO_RECEIVED", "ShortcutItemInfo", function()
        T.RefreshItemInfo()
        W.RefreshItemInfo()
        K.RefreshItemInfo()
        local ui = deps.GetConfigUI()
        if ui.RefreshShortcutPanel then ui.RefreshShortcutPanel() end
        if ui.RefreshKeyPanel then ui.RefreshKeyPanel() end
        if ui.RefreshWheelPanel then ui.RefreshWheelPanel() end
        if ui.RefreshBindPanel then ui.RefreshBindPanel() end
    end)

    eventRouter.RegisterOptional("UNIT_PET", "MacroLibraryPet", function(_, unit)
        if unit == "player" then RefreshMacroRequirements() end
    end)
    eventRouter.RegisterOptional("PET_BAR_UPDATE", "MacroLibraryPetBar", RefreshMacroRequirements)
end
