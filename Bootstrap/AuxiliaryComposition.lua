local Composition = {}
ApogeePartyHealthBars.Define("Bootstrap", "AuxiliaryComposition", Composition)

function Composition.Initialize(deps)
    for _, key in ipairs({
        "ThreatObserver", "ThreatObserverDependencies", "ThreatAwareness",
        "ThreatAwarenessDependencies",
    }) do
        assert(deps and deps[key], "AuxiliaryComposition missing dependency: " .. key)
    end
    deps.ThreatObserver.Initialize(deps.ThreatObserverDependencies)
    deps.ThreatAwareness.Initialize(deps.ThreatAwarenessDependencies)
    deps.ThreatAwareness.Build()
end

