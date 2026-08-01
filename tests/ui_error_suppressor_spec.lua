local calls = {}
local registered = true

UIErrorsFrame = {
    IsEventRegistered = function(_, event)
        assert(event == "UI_ERROR_MESSAGE")
        return registered
    end,
    RegisterEvent = function(_, event)
        calls[#calls + 1] = "register:" .. event
        registered = true
    end,
    UnregisterEvent = function(_, event)
        calls[#calls + 1] = "unregister:" .. event
        registered = false
    end,
}

dofile("Core/UIErrorSuppressor.lua")
local suppressor = ApogeePartyHealthBars_UIErrorSuppressor

suppressor.Initialize(true)
suppressor.ApplyEnabledState(true)
assert(suppressor.IsEnabled()
        and calls[1] == "unregister:UI_ERROR_MESSAGE"
        and calls[2] == "unregister:UI_ERROR_MESSAGE"
        and #calls == 2,
    "enabled suppression did not safely unregister only the UI error event")

suppressor.ApplyEnabledState(false)
suppressor.ApplyEnabledState(false)
assert(not suppressor.IsEnabled()
        and calls[3] == "register:UI_ERROR_MESSAGE"
        and #calls == 3,
    "disabled suppression did not safely restore only the UI error event")

registered = false
suppressor.ApplyEnabledState(true)
suppressor.ApplyEnabledState(false)
assert(calls[4] == "unregister:UI_ERROR_MESSAGE" and #calls == 4
        and registered == false,
    "disabling suppression overrode another addon's pre-existing event state")

suppressor.Initialize(false)
assert(#calls == 4 and registered == false,
    "disabled initialization changed an event state the addon did not own")

UIErrorsFrame = nil
assert(pcall(suppressor.ApplyEnabledState, true)
        and suppressor.IsEnabled(),
    "missing UIErrorsFrame caused suppression initialization to fail")

print("PASS Blizzard UI error suppression")
