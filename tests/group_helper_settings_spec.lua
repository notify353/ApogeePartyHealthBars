local saved = {
    enabled = true,
    groupHelperEnabled = true,
    groupHelperPoint = "NOT_AN_ANCHOR",
    groupHelperRelPoint = "ALSO_INVALID",
    groupHelperX = 42,
    groupHelperY = -17,
}
local changes = {}

dofile("Core/Namespace.lua")
dofile("Reminders/GroupHelperSettings.lua")
local Settings = ApogeePartyHealthBars.Require("Runtime", "GroupHelperSettings")
Settings.Initialize({
    GetSavedVariables = function() return saved end,
    OnChanged = function(reason) changes[#changes + 1] = reason end,
})

assert(Settings.GetPosition == nil and Settings.SetPosition == nil
        and saved.groupHelperPoint == "NOT_AN_ANCHOR"
        and saved.groupHelperRelPoint == "ALSO_INVALID"
        and saved.groupHelperX == 42 and saved.groupHelperY == -17,
    "retired Group Helper position data was interpreted or mutated")

assert(Settings.SetEnabled(false) and not Settings.IsEnabled()
        and changes[#changes] == "enabled",
    "Group Helper enablement did not update saved intent")
print("PASS Group Helper settings")
