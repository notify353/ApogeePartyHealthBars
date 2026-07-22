local LifecycleEvents = ApogeePartyHealthBars_RuntimeLifecycleEvents
local UnitEvents = ApogeePartyHealthBars_RuntimeUnitEvents
local ActionEvents = ApogeePartyHealthBars_RuntimeActionEvents
local DotEvents = ApogeePartyHealthBars_RuntimeDotEvents

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
end
