local Auras = ApogeePartyHealthBars_Auras
local Watch = ApogeePartyHealthBars_CleanseWatch
local units = ApogeePartyHealthBars_C.SLOT_UNITS

ApogeePartyHealthBars_CleanseEvents = {}
local Events = ApogeePartyHealthBars_CleanseEvents

function Events.Register(eventRouter, deps)
    local function guarded(event, callback)
        local ok, err = pcall(callback)
        if not ok then deps.Print("event error (" .. event .. "): " .. tostring(err)) end
    end

    local function invalidateRosterAuras()
        for _, unitId in ipairs(units) do
            Auras.InvalidateUnitAuraCache(unitId)
        end
    end

    eventRouter.RegisterOptional("UNIT_AURA", "CleanseWatch", function(event, unit)
        guarded(event, function()
            if unit then Auras.InvalidateUnitAuraCache(unit) end
            Watch.Refresh()
        end)
    end)

    for _, event in ipairs({
        "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE",
        "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "UNIT_PET", "PET_BAR_UPDATE",
        "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_REGEN_ENABLED", "SPELL_TEXT_UPDATE",
    }) do
        eventRouter.RegisterOptional(event, "CleanseWatch", function(eventName)
            guarded(eventName, function()
                if eventName == "SPELL_TEXT_UPDATE" then
                    Watch.Refresh()
                    return
                end
                if eventName == "PLAYER_LOGIN"
                    or eventName == "PLAYER_ENTERING_WORLD"
                    or eventName == "GROUP_ROSTER_UPDATE" then
                    invalidateRosterAuras()
                end
                if eventName == "PLAYER_LOGIN"
                    or eventName == "PLAYER_ENTERING_WORLD" then
                    Watch.RestorePosition()
                end
                Watch.RefreshCapabilities()
            end)
        end)
    end
end
