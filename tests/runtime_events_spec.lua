local calls = {}
ApogeePartyHealthBars_RuntimeLifecycleEvents = {
    Register = function(router, deps)
        calls[#calls + 1] = "lifecycle"
        assert(router.name == "router" and deps.name == "deps")
    end,
}
ApogeePartyHealthBars_RuntimeUnitEvents = {
    Register = function(router, deps)
        calls[#calls + 1] = "unit"
        assert(router.name == "router" and deps.name == "deps")
    end,
}
ApogeePartyHealthBars_RuntimeActionEvents = {
    Register = function(router, deps)
        calls[#calls + 1] = "action"
        assert(router.name == "router" and deps.name == "deps")
    end,
}

dofile("ApogeePartyHealthBars_RuntimeEvents.lua")
local events = ApogeePartyHealthBars_RuntimeEvents

local valid, validationError = pcall(events.Register, nil, {})
assert(not valid and tostring(validationError):find("event router", 1, true),
    "RuntimeEvents accepted a missing router")
valid, validationError = pcall(events.Register, {}, {})
assert(not valid and tostring(validationError):find("Print", 1, true),
    "RuntimeEvents accepted a missing Print dependency")

local printer = function() end
local router = {
    name = "router",
    Initialize = function(callback)
        calls[#calls + 1] = "initialize"
        assert(callback == printer, "coordinator changed the router printer")
    end,
}
events.Register(router, { name = "deps", Print = printer })

assert(table.concat(calls, ",") == "initialize,lifecycle,unit,action",
    "runtime subscriber registration order changed: " .. table.concat(calls, ","))

print("PASS runtime event coordinator")
