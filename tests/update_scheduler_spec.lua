dofile("Core/Namespace.lua")

local frames = {}
function CreateFrame()
    local frame = { shown = false, scripts = {} }
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    frames[#frames + 1] = frame
    return frame
end

dofile("Core/UpdateScheduler.lua")
local factory = ApogeePartyHealthBars.Require("Core", "UpdateScheduler")
local state = { uiTimer = 0.1 }
local messages, fullUpdates, valueUpdates = {}, 0, 0
local scheduler = factory.Create({
    State = state,
    Constants = { UPDATE_RATE = 0.1 },
    Print = function(message) messages[#messages + 1] = message end,
})
scheduler.RegisterHandlers({
    FullUpdate = function() fullUpdates = fullUpdates + 1 end,
    ValuesUpdate = function() valueUpdates = valueUpdates + 1 end,
    IsEnabled = function() return true end,
})

scheduler.RequestValuesUpdate("party1")
assert(state.valuesDirtyUnits.party1 == true and frames[2].shown,
    "unit-scoped value request was not queued")
frames[2].scripts.OnUpdate(frames[2])
assert(valueUpdates == 1 and not state.valuesDirty and not frames[2].shown,
    "value-only flush did not complete")

scheduler.RequestLayoutUpdate()
assert(state.layoutDirty and state.valuesDirty and frames[1].shown,
    "layout request did not queue a full refresh")
frames[1].scripts.OnUpdate(frames[1], 0.1)
assert(fullUpdates == 1 and not state.layoutDirty and not frames[1].shown,
    "throttled full refresh did not clear its request")

scheduler.ForceRefresh()
assert(fullUpdates == 2 and not state.layoutDirty and not state.valuesDirty,
    "forced refresh did not run synchronously")
scheduler.RequestValuesUpdate()
scheduler.Stop()
assert(not frames[1].shown and not frames[2].shown,
    "scheduler stop left a flush frame active")

scheduler.RegisterHandlers({
    FullUpdate = function() error("expected failure") end,
    ValuesUpdate = function() end,
    IsEnabled = function() return true end,
})
scheduler.ForceRefresh()
assert(state.layoutDirty and messages[#messages]:find("update error", 1, true),
    "failed full refresh did not preserve dirty state and report the error")

print("PASS update scheduler")

