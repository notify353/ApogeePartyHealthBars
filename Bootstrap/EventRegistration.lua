local Registration = {}
ApogeePartyHealthBars.Define("Bootstrap", "EventRegistration", Registration)

function Registration.Register(deps)
    for _, key in ipairs({
        "EventRouter", "RuntimeEvents", "RuntimeDependencies", "HealthAlerts",
    }) do
        assert(deps and deps[key], "EventRegistration missing dependency: " .. key)
    end
    deps.RuntimeEvents.Register(deps.EventRouter, deps.RuntimeDependencies)
    deps.HealthAlerts.Register(deps.EventRouter)
end

function Registration.RegisterSlashCommands(deps)
    for _, key in ipairs({ "DungeonBoardUI", "DungeonGuideUI", "Print" }) do
        assert(deps and deps[key], "EventRegistration slash commands missing: " .. key)
    end
    SLASH_APOGEEPARTYHEALTHBARS1 = "/aphb"
    SlashCmdList = SlashCmdList or {}
    SlashCmdList.APOGEEPARTYHEALTHBARS = function(message)
        local command = tostring(message or ""):match("^%s*(.-)%s*$"):lower()
        if command == "board" then
            deps.DungeonBoardUI.Toggle()
            return
        end
        if command == "guide" then
            deps.DungeonGuideUI.Toggle()
            return
        end
        deps.Print("use /aphb board for Dungeon Board or /aphb guide for Dungeon Guide.")
    end
end

