local Composition = {}
ApogeePartyHealthBars.Define("Bootstrap", "SettingsComposition", Composition)

function Composition.Initialize(deps)
    for _, key in ipairs({ "Controller", "ControllerDependencies", "BuildUI" }) do
        assert(deps and deps[key], "SettingsComposition missing dependency: " .. key)
    end
    assert(type(deps.Controller.Initialize) == "function",
        "SettingsComposition requires Controller.Initialize")
    assert(type(deps.BuildUI) == "function",
        "SettingsComposition requires BuildUI")

    deps.Controller.Initialize(deps.ControllerDependencies)
    local runtime = {
        ExitConfigMode = deps.Controller.Exit,
        SetAddonEnabled = deps.Controller.SetAddonEnabled,
        SetConfigMode = deps.Controller.SetMode,
        FactoryReset = deps.Controller.FactoryReset,
        ActivateProfile = deps.Controller.ActivateProfile,
        MutateActiveProfile = deps.Controller.MutateActiveProfile,
        CreateAndActivateProfile = deps.Controller.CreateAndActivateProfile,
    }
    runtime.UI = deps.BuildUI(runtime)
    assert(type(runtime.UI) == "table", "SettingsComposition BuildUI returned no UI")
    return runtime
end

