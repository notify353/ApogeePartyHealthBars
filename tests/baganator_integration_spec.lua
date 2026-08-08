dofile("Core/Namespace.lua")
dofile("Integrations/Baganator.lua")

local integration = ApogeePartyHealthBars.Require("Integrations", "Baganator")
local visibility = {}
assert(integration.Register(function(active)
    visibility[#visibility + 1] = active
end) == false, "integration registered before Baganator was available")

local function registry()
    local result = { callbacks = {}, registrations = 0 }
    function result:RegisterCallback(event, callback, owner)
        assert(owner ~= nil, "integration did not use stable callback ownership")
        self.registrations = self.registrations + 1
        self.callbacks[event] = { callback = callback, owner = owner }
    end
    function result:Trigger(event)
        local entry = assert(self.callbacks[event])
        entry.callback(entry.owner, "ignored callback payload")
    end
    return result
end

local first = registry()
Baganator = { CallbackRegistry = first }
assert(integration.OnAddonLoaded("Unrelated") == false
    and first.registrations == 0, "unrelated add-on load registered Baganator")
assert(integration.OnAddonLoaded("Baganator") == true
    and first.registrations == 2, "load-after registration failed")
first:Trigger("BagShow")
first:Trigger("BagHide")
assert(visibility[1] == true and visibility[2] == false,
    "public visibility callbacks were not translated")

local showOwner = first.callbacks.BagShow.owner
assert(integration.OnLifecycleEvent() == true and first.registrations == 4,
    "lifecycle retry did not restore callbacks on the same registry")
assert(first.callbacks.BagShow.owner == showOwner,
    "lifecycle retry did not replace callbacks through stable ownership")

local replacement = registry()
Baganator.CallbackRegistry = replacement
assert(integration.IsRegistered() == false,
    "registry replacement retained stale registered state")
assert(integration.OnLifecycleEvent() == true and replacement.registrations == 2,
    "registry replacement was not reconnected")
replacement:Trigger("BagShow")
assert(visibility[3] == true, "replacement registry callback did not fire")

Baganator = nil
assert(integration.IsRegistered() == false,
    "missing registry retained registered state")

print("PASS load-safe Baganator integration")
