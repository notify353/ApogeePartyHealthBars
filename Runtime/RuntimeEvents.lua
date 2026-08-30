local LifecycleEvents = ApogeePartyHealthBars_LifecycleEvents
local UnitEvents = ApogeePartyHealthBars_UnitEvents
local ActionEvents = ApogeePartyHealthBars_ActionEvents
local ActionAssignmentEvents = ApogeePartyHealthBars_ActionAssignmentEvents
local DotEvents = ApogeePartyHealthBars_TargetEffectEvents
local CooldownEvents = ApogeePartyHealthBars_CooldownEvents
local DungeonBoardEvents = ApogeePartyHealthBars_DungeonBoardEvents
local CleanseEvents = ApogeePartyHealthBars_CleanseEvents
local BuffThanksEvents = ApogeePartyHealthBars_BuffThanksEvents
local MentionAlerts = ApogeePartyHealthBars_MentionAlerts
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
    if DotEvents then DotEvents.Register(eventRouter, deps) end
    if CooldownEvents then CooldownEvents.Register(eventRouter, deps) end
    if DungeonBoardEvents then DungeonBoardEvents.Register(eventRouter, deps) end
    if CleanseEvents then CleanseEvents.Register(eventRouter, deps) end
    if BuffThanksEvents then BuffThanksEvents.Register(eventRouter, deps) end
    if MentionAlerts then MentionAlerts.Register(eventRouter) end
    GroupHelperEvents.Register(eventRouter, deps)
end
