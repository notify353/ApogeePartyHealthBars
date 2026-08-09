local registered, script, messages = {}, nil, {}

function CreateFrame()
    return {
        RegisterEvent = function(_, event) registered[event] = true end,
        SetScript = function(_, _, callback) script = callback end,
    }
end

C_EventUtils = { IsEventValid = function(event) return event ~= "INVALID_EVENT" end }

dofile("Core/EventRouter.lua")
local R = ApogeePartyHealthBars_EventRouter
R.Initialize(function(message) messages[#messages + 1] = message end)

local order = {}
assert(R.Subscribe("PLAYER_LOGIN", "one", function(event, value) order[#order + 1] = event .. value end))
assert(R.Subscribe("PLAYER_LOGIN", "two", function() order[#order + 1] = "two" end))
assert(not R.RegisterOptional("INVALID_EVENT", "invalid", function() end))
assert(registered.PLAYER_LOGIN and not registered.INVALID_EVENT)

-- Both supported generated exports document BAG_OPEN. Required subscriptions
-- must attempt native registration for assignment-source events.
assert(R.Subscribe("BAG_OPEN", "bags", function() order[#order + 1] = "bag" end))
assert(registered.BAG_OPEN, "required internal event was rejected by optional metadata")

script(nil, "PLAYER_LOGIN", "!")
assert(order[1] == "PLAYER_LOGIN!" and order[2] == "two", "dispatch order changed")

R.Subscribe("PLAYER_ENTERING_WORLD", "broken", function() error("expected failure") end)
R.Dispatch("PLAYER_ENTERING_WORLD")
assert(#messages == 1 and messages[1]:find("broken/PLAYER_ENTERING_WORLD", 1, true), "owner error was not isolated")
print("PASS event router")
