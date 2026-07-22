local Tracker = ApogeePartyHealthBars_DotTracker
local Auras = ApogeePartyHealthBars_Auras

ApogeePartyHealthBars_RuntimeDotEvents = {}
local D = ApogeePartyHealthBars_RuntimeDotEvents

function D.Register(eventRouter, deps)
    local function protect(owner, callback)
        local ok, err = pcall(callback)
        if not ok then deps.Print("event error (" .. owner .. "): " .. tostring(err)) end
    end
    eventRouter.Subscribe("PLAYER_LOGIN", "DoTReminders", function()
        protect("DoT reminders", Tracker.Initialize)
    end)
    eventRouter.Subscribe("PLAYER_TARGET_CHANGED", "DoTReminders", function()
        Auras.InvalidateUnitAuraCache("target")
        protect("DoT target", function() Tracker.Refresh(true) end)
    end)
    eventRouter.Subscribe("UNIT_AURA", "DoTReminders", function(_, unit)
        if unit ~= "target" then return end
        Auras.InvalidateUnitAuraCache("target")
        protect("DoT aura", function() Tracker.Refresh(false) end)
    end)
    for _, event in ipairs({
        "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB",
        "PLAYER_LEVEL_UP", "PLAYER_TALENT_UPDATE", "CHARACTER_POINTS_CHANGED",
        "ACTIVE_TALENT_GROUP_CHANGED", "UPDATE_SHAPESHIFT_FORM",
        "UPDATE_SHAPESHIFT_FORMS", "UPDATE_STEALTH",
    }) do
        eventRouter.RegisterOptional(event, "DoTContext", function()
            protect("DoT context", Tracker.OnContextChanged)
        end)
    end
    for _, event in ipairs({
        "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_USABLE", "ACTIONBAR_UPDATE_USABLE",
        "UNIT_DISPLAYPOWER",
    }) do
        eventRouter.RegisterOptional(event, "DoTUsability", function()
            protect("DoT usability", function() Tracker.Refresh(false) end)
        end)
    end
    eventRouter.RegisterOptional("UNIT_POWER_UPDATE", "DoTUsability", function(_, unit)
        if unit == "player" then protect("DoT power", function() Tracker.Refresh(false) end) end
    end)
end

