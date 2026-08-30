local Tracker = ApogeePartyHealthBars_CooldownTracker

ApogeePartyHealthBars_CooldownEvents = {}
local E = ApogeePartyHealthBars_CooldownEvents
local delayedSampleGeneration = 0

function E.Register(eventRouter, deps)
    local function protect(owner, callback)
        local ok, err = pcall(callback)
        if not ok then deps.Print("event error (" .. owner .. "): " .. tostring(err)) end
    end
    eventRouter.Subscribe("PLAYER_LOGIN", "AbilityCooldowns", function()
        protect("Ability cooldowns", Tracker.Initialize)
    end)
    for _, event in ipairs({
        "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_CHARGES", "SPELL_UPDATE_USABLE",
        "ACTIONBAR_UPDATE_COOLDOWN", "PET_BAR_UPDATE_COOLDOWN", "PET_BAR_UPDATE_USABLE",
    }) do
        eventRouter.RegisterOptional(event, "AbilityCooldowns", function()
            protect("Ability cooldown state", Tracker.Refresh)
        end)
    end
    for _, event in ipairs({
        "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "PLAYER_LEVEL_UP",
        "PLAYER_TALENT_UPDATE", "CHARACTER_POINTS_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED",
        "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS", "UNIT_PET", "PET_BAR_UPDATE",
    }) do
        eventRouter.RegisterOptional(event, "AbilityCooldownContext", function(_, unit)
            if event == "UNIT_PET" and unit ~= "player" then return end
            protect("Ability cooldown context", Tracker.OnContextChanged)
        end)
    end
    eventRouter.RegisterOptional("UNIT_SPELLCAST_SUCCEEDED", "AbilityCooldownSampling",
        function(_, unit)
            if unit ~= "player" and unit ~= "pet" then return end
            if C_Timer and C_Timer.After then
                delayedSampleGeneration = delayedSampleGeneration + 1
                local generation = delayedSampleGeneration
                C_Timer.After(0.5, function()
                    if generation == delayedSampleGeneration then
                        protect("Ability cooldown delayed sampling", Tracker.Refresh)
                    end
                end)
            end
        end)
end
