local Events = {}
ApogeePartyHealthBars.Define("Runtime", "GroupHelperEvents", Events)

local tracked = { player = true, party1 = true, party2 = true, party3 = true, party4 = true }

function Events.Register(eventRouter, deps)
    assert(eventRouter and deps and deps.GroupHelperRuntime,
        "GroupHelperEvents requires runtime dependencies")
    local runtime = deps.GroupHelperRuntime

    eventRouter.Subscribe("PLAYER_LOGIN", "GroupHelper", function()
        runtime.ResetSession()
    end)
    eventRouter.Subscribe("PLAYER_ENTERING_WORLD", "GroupHelper", function()
        runtime.ResetSession()
    end)
    eventRouter.Subscribe("GROUP_ROSTER_UPDATE", "GroupHelper", function()
        runtime.OnRosterChanged()
    end)
    eventRouter.Subscribe("PLAYER_REGEN_DISABLED", "GroupHelper", function()
        runtime.OnCombatStarted()
    end)
    eventRouter.Subscribe("PLAYER_REGEN_ENABLED", "GroupHelper", function()
        runtime.OnCombatEnded()
    end)

    local function unitRefresh(_, unitId)
        if tracked[unitId] then runtime.ScheduleRefresh(0) end
    end
    local function auraRefresh(_, unitId)
        if tracked[unitId] then runtime.ScheduleAuraRefresh(0.15) end
    end
    for _, event in ipairs({
        "UNIT_POWER_UPDATE", "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER",
        "UNIT_CONNECTION", "UNIT_HEALTH", "UNIT_MAXHEALTH",
    }) do
        eventRouter.RegisterOptional(event, "GroupHelper", unitRefresh)
    end
    eventRouter.RegisterOptional("UNIT_AURA", "GroupHelper", auraRefresh)
end
