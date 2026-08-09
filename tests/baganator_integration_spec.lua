local monitor
function CreateFrame()
    monitor = { shown = false, scripts = {} }
    function monitor:SetScript(name, callback) self.scripts[name] = callback end
    function monitor:Show() self.shown = true end
    function monitor:Hide() self.shown = false end
    return monitor
end

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
    and first.registrations == 4, "load-after registration failed")
first:Trigger("BagShow")
first:Trigger("BagHide")
assert(visibility[#visibility - 1] == true and visibility[#visibility] == false,
    "public visibility callbacks were not translated")

local showOwner = first.callbacks.BagShow.owner
assert(integration.OnLifecycleEvent() == true and first.registrations == 8,
    "lifecycle retry did not restore callbacks on the same registry")
assert(first.callbacks.BagShow.owner == showOwner,
    "lifecycle retry did not replace callbacks through stable ownership")

local replacement = registry()
Baganator.CallbackRegistry = replacement
assert(integration.IsRegistered() == false,
    "registry replacement retained stale registered state")
assert(integration.OnLifecycleEvent() == true and replacement.registrations == 4,
    "registry replacement was not reconnected")
replacement:Trigger("BagShow")
assert(visibility[#visibility] == true, "replacement registry callback did not fire")

local backpackShown = true
local backpackVisible = false
Baganator_SingleViewBackpackViewFrameblizzard_black = {
    IsShown = function() return backpackShown end,
    IsVisible = function() return backpackVisible end,
}
monitor.scripts.OnUpdate(monitor, 0.1)
assert(visibility[#visibility] == false,
    "internally shown but effectively hidden backpack kept assignment active")
backpackVisible = true
monitor.scripts.OnUpdate(monitor, 0.1)
assert(visibility[#visibility] == true,
    "visible Baganator backpack frame did not activate assignment")
backpackVisible = false
monitor.scripts.OnUpdate(monitor, 0.1)
assert(visibility[#visibility] == false,
    "hidden Baganator backpack frame did not deactivate assignment")

Baganator = nil
assert(integration.IsRegistered() == false,
    "missing registry retained registered state")

print("PASS load-safe Baganator integration")
