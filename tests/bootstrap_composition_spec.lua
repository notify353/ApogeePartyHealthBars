dofile("Core/Namespace.lua")
dofile("Bootstrap/ActionComposition.lua")
dofile("Bootstrap/PartyFrameComposition.lua")
dofile("Bootstrap/AuxiliaryComposition.lua")
dofile("Bootstrap/SettingsComposition.lua")
dofile("Bootstrap/EventRegistration.lua")

local calls = {}
local function called(name) calls[#calls + 1] = name end

local actionDeps = {}
local actionResult = ApogeePartyHealthBars.Bootstrap.ActionComposition.Initialize({
    Coordinator = {
        Initialize = function(deps)
            called("actions")
            assert(deps == actionDeps)
            return "coordinator"
        end,
    },
    Dependencies = actionDeps,
})
assert(actionResult == "coordinator")

local layoutDeps = {}
local applyAll = function() end
local party = ApogeePartyHealthBars.Bootstrap.PartyFrameComposition.Initialize({
    ClickBindings = {
        Initialize = function() called("clicks") end,
        ApplyAll = applyAll,
    },
    ClickBindingDependencies = {},
    Layout = {
        Register = function(deps)
            called("layout")
            assert(deps.ApplyAllBindings == applyAll,
                "party composition did not connect click binding application")
        end,
    },
    LayoutDependencies = layoutDeps,
})
assert(party.ApplyAllBindings == applyAll)
ApogeePartyHealthBars.Bootstrap.PartyFrameComposition.RegisterSecureReconciler({
    InitializeReconciler = function(callback)
        called("reconciler")
        assert(type(callback) == "function")
    end,
}, function() end)

ApogeePartyHealthBars.Bootstrap.AuxiliaryComposition.Initialize({
    ThreatObserver = { Initialize = function() called("observer") end },
    ThreatObserverDependencies = {},
    ThreatAwareness = {
        Initialize = function() called("awareness") end,
        Build = function() called("awareness-build") end,
    },
    ThreatAwarenessDependencies = {},
})

local controller = {
    Initialize = function() called("settings-controller") end,
    Exit = function() end, SetAddonEnabled = function() end, SetMode = function() end,
    FactoryReset = function() end, ActivateProfile = function() end,
    MutateActiveProfile = function() end, CreateAndActivateProfile = function() end,
}
local settings = ApogeePartyHealthBars.Bootstrap.SettingsComposition.Initialize({
    Controller = controller,
    ControllerDependencies = {},
    BuildUI = function(runtime)
        called("settings-ui")
        assert(runtime.SetConfigMode == controller.SetMode,
            "settings controller facade was not ready before UI construction")
        return { Refresh = function() end }
    end,
})
assert(settings.UI.Refresh)

local router = {}
ApogeePartyHealthBars.Bootstrap.EventRegistration.Register({
    EventRouter = router,
    RuntimeEvents = {
        Register = function(actualRouter) called("runtime-events"); assert(actualRouter == router) end,
    },
    RuntimeDependencies = {},
    HealthAlerts = {
        Register = function(actualRouter) called("health-alerts"); assert(actualRouter == router) end,
    },
})

local board, guide, messages = 0, 0, 0
ApogeePartyHealthBars.Bootstrap.EventRegistration.RegisterSlashCommands({
    DungeonBoardUI = { Toggle = function() board = board + 1 end },
    DungeonGuideUI = { Toggle = function() guide = guide + 1 end },
    Print = function() messages = messages + 1 end,
})
SlashCmdList.APOGEEPARTYHEALTHBARS("board")
SlashCmdList.APOGEEPARTYHEALTHBARS("guide")
SlashCmdList.APOGEEPARTYHEALTHBARS("")
assert(board == 1 and guide == 1 and messages == 1,
    "slash command routing changed during bootstrap extraction")

assert(table.concat(calls, ",") == table.concat({
    "actions", "clicks", "layout", "reconciler", "observer", "awareness",
    "awareness-build", "settings-controller", "settings-ui", "runtime-events",
    "health-alerts",
}, ","), "bootstrap composition order changed: " .. table.concat(calls, ","))

local ok, err = pcall(
    ApogeePartyHealthBars.Bootstrap.ActionComposition.Initialize, {})
assert(not ok and tostring(err):find("Coordinator", 1, true),
    "bootstrap stage accepted a missing required dependency")

print("PASS bootstrap composition contracts")

