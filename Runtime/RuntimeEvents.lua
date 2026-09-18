local LifecycleEvents = ApogeePartyHealthBars_LifecycleEvents
local UnitEvents = ApogeePartyHealthBars_UnitEvents
local ActionEvents = ApogeePartyHealthBars_ActionEvents
local ActionAssignmentEvents = ApogeePartyHealthBars_ActionAssignmentEvents
local CleanseEvents = ApogeePartyHealthBars_CleanseEvents
local GroupHelperEvents = ApogeePartyHealthBars.Require("Runtime", "GroupHelperEvents")

ApogeePartyHealthBars_RuntimeEvents = {}
local R = ApogeePartyHealthBars_RuntimeEvents

function R.Register(eventRouter, deps)
    assert(type(eventRouter) == "table", "RuntimeEvents requires an event router")
    assert(type(deps) == "table" and type(deps.Print) == "function",
        "RuntimeEvents requires a Print dependency")
    eventRouter.Initialize(deps.Print)
    LifecycleEvents.Register(eventRouter, deps)
    UnitEvents.Register(eventRouter, deps)
    ActionAssignmentEvents.Register(eventRouter, {
        RefreshAssignmentAffordances = deps.RefreshAssignmentAffordances,
    })
    ActionEvents.Register(eventRouter, deps)
    if CleanseEvents then CleanseEvents.Register(eventRouter, deps) end
    GroupHelperEvents.Register(eventRouter, deps)
end
