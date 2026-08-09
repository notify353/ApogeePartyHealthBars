local Composition = {}
ApogeePartyHealthBars.Define("Bootstrap", "ActionComposition", Composition)

function Composition.Initialize(deps)
    assert(deps and type(deps.Coordinator) == "table",
        "ActionComposition requires Coordinator")
    assert(type(deps.Coordinator.Initialize) == "function",
        "ActionComposition requires Coordinator.Initialize")
    assert(type(deps.Dependencies) == "table",
        "ActionComposition requires Dependencies")
    return deps.Coordinator.Initialize(deps.Dependencies)
end

