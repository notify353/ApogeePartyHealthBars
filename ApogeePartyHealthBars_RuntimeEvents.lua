local LifecycleEvents = ApogeePartyHealthBars_RuntimeLifecycleEvents
local UnitEvents = ApogeePartyHealthBars_RuntimeUnitEvents
local ActionEvents = ApogeePartyHealthBars_RuntimeActionEvents
local DotEvents = ApogeePartyHealthBars_RuntimeDotEvents
local DungeonBoardEvents = ApogeePartyHealthBars_RuntimeDungeonBoardEvents
local CleanseEvents = ApogeePartyHealthBars_RuntimeCleanseEvents
local MentionAlerts = ApogeePartyHealthBars_MentionAlerts

ApogeePartyHealthBars_RuntimeEvents = {}
local R = ApogeePartyHealthBars_RuntimeEvents

function R.Register(eventRouter, deps)
    assert(type(eventRouter) == "table", "RuntimeEvents requires an event router")
    assert(type(deps) == "table" and type(deps.Print) == "function",
        "RuntimeEvents requires a Print dependency")
    eventRouter.Initialize(deps.Print)
    LifecycleEvents.Register(eventRouter, deps)
    UnitEvents.Register(eventRouter, deps)
    ActionEvents.Register(eventRouter, deps)
    if DotEvents then DotEvents.Register(eventRouter, deps) end
    if DungeonBoardEvents then DungeonBoardEvents.Register(eventRouter, deps) end
    if CleanseEvents then CleanseEvents.Register(eventRouter, deps) end
    if MentionAlerts then MentionAlerts.Register(eventRouter) end
end
