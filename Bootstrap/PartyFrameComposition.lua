local Composition = {}
ApogeePartyHealthBars.Define("Bootstrap", "PartyFrameComposition", Composition)

function Composition.Initialize(deps)
    for _, key in ipairs({
        "ClickBindings", "ClickBindingDependencies", "Layout", "LayoutDependencies",
    }) do
        assert(deps and deps[key], "PartyFrameComposition missing dependency: " .. key)
    end
    assert(type(deps.ClickBindings.Initialize) == "function",
        "PartyFrameComposition requires ClickBindings.Initialize")
    assert(type(deps.Layout.Register) == "function",
        "PartyFrameComposition requires Layout.Register")

    deps.ClickBindings.Initialize(deps.ClickBindingDependencies)
    deps.LayoutDependencies.ApplyAllBindings = deps.ClickBindings.ApplyAll
    deps.Layout.Register(deps.LayoutDependencies)
    return {
        ApplyAllBindings = deps.ClickBindings.ApplyAll,
        Layout = deps.Layout,
    }
end

function Composition.RegisterSecureReconciler(secureFrames, callback)
    assert(secureFrames and type(secureFrames.InitializeReconciler) == "function",
        "PartyFrameComposition requires secure frame reconciler")
    assert(type(callback) == "function",
        "PartyFrameComposition requires reconcile callback")
    secureFrames.InitializeReconciler(callback)
end

