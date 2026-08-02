local Thanks = ApogeePartyHealthBars_BuffThanks

ApogeePartyHealthBars_BuffThanksEvents = {}
local Events = ApogeePartyHealthBars_BuffThanksEvents

function Events.Register(eventRouter, deps)
    eventRouter.RegisterOptional("COMBAT_LOG_EVENT_UNFILTERED", "BuffThanks", function(event)
        local ok, err = pcall(Thanks.OnCombatLog)
        if not ok then deps.Print("event error (" .. event .. "): " .. tostring(err)) end
    end)
    eventRouter.RegisterOptional("UNIT_AURA", "BuffThanks", function(event, unit)
        if unit ~= "player" then return end
        local ok, err = pcall(Thanks.VerifyPending)
        if not ok then deps.Print("event error (" .. event .. "): " .. tostring(err)) end
    end)
    for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD" }) do
        eventRouter.RegisterOptional(event, "BuffThanks", function(eventName)
            local ok, err = pcall(function()
                Thanks.BeginWorldSession()
                Thanks.RestorePosition()
            end)
            if not ok then deps.Print("event error (" .. eventName .. "): " .. tostring(err)) end
        end)
    end
end
