local files = {
    "Actions/ActionAssignmentSources.lua",
    "Actions/ActionCoordinator.lua",
    "Actions/BindingController.lua",
    "Actions/BoundActionEvaluator.lua",
    "Actions/BoundActionDragController.lua",
    "Actions/BoundActionRuntime.lua",
    "Actions/BoundActionSecureController.lua",
    "Actions/BoundActionView.lua",
    "Actions/ShortcutBar.lua",
    "Actions/ShortcutStore.lua",
    "Core/FeaturePolicy.lua",
    "Core/UpdateScheduler.lua",
    "Integrations/Baganator.lua",
    "Runtime/ActionAssignmentEvents.lua",
    "Bootstrap/ActionComposition.lua",
    "Bootstrap/PartyFrameComposition.lua",
    "Bootstrap/AuxiliaryComposition.lua",
    "Bootstrap/SettingsComposition.lua",
    "Bootstrap/EventRegistration.lua",
}

for _, path in ipairs(files) do
    local handle = assert(io.open(path, "r"))
    local source = handle:read("*a")
    handle:close()
    assert(not source:find("\nApogeePartyHealthBars_[%w_]+%s*="),
        path .. " introduced a direct legacy module global")
    assert(source:find("ApogeePartyHealthBars%.Define", 1) ~= nil,
        path .. " is not registered through the namespace")
end

print("PASS namespace usage guard")
