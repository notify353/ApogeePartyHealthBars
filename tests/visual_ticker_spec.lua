ApogeePartyHealthBars_C = { RANGE_UPDATE_RATE = 0.2 }

local createdFrame
function CreateFrame()
    local frame = { scripts = {}, shown = true, showCount = 0, hideCount = 0 }
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    function frame:Show() self.shown = true; self.showCount = self.showCount + 1 end
    function frame:Hide() self.shown = false; self.hideCount = self.hideCount + 1 end
    function frame:IsShown() return self.shown end
    createdFrame = frame
    return frame
end

local flags = {
    addon = true,
    range = false,
    config = false,
    hots = false,
    shortcuts = false,
    wheel = false,
    keys = false,
    threat = false,
}
local calls = {
    hotTicks = 0,
    shortcutTicks = 0,
    wheelRefreshes = 0,
    rangeRefreshes = 0,
    threatRefreshes = 0,
    keyRefreshes = 0,
}

dofile("ApogeePartyHealthBars_VisualTicker.lua")
local ticker = ApogeePartyHealthBars_VisualTicker

local valid, validationError = pcall(ticker.Initialize, {})
assert(not valid and tostring(validationError):find("IsAddonEnabled", 1, true),
    "VisualTicker accepted incomplete dependencies")

ticker.Initialize({
    IsAddonEnabled = function() return flags.addon end,
    IsRangeCheckEnabled = function() return flags.range end,
    IsConfigMode = function() return flags.config end,
    HasActiveHotVisuals = function() return flags.hots end,
    TickHotVisuals = function() calls.hotTicks = calls.hotTicks + 1 end,
    RefreshRangeAlpha = function() calls.rangeRefreshes = calls.rangeRefreshes + 1 end,
    ShortcutBar = {
        IsActive = function() return flags.shortcuts end,
        Tick = function() calls.shortcutTicks = calls.shortcutTicks + 1 end,
    },
    WheelMacros = {
        Refresh = function() calls.wheelRefreshes = calls.wheelRefreshes + 1 end,
    },
    KeyActions = {
        Refresh = function() calls.keyRefreshes = calls.keyRefreshes + 1 end,
    },
    Threat = {
        IsActive = function() return flags.threat end,
        Refresh = function() calls.threatRefreshes = calls.threatRefreshes + 1 end,
    },
})

local frame = assert(createdFrame, "VisualTicker did not create its frame")
local update = assert(frame.scripts.OnUpdate, "VisualTicker did not own an update callback")
assert(not frame:IsShown(), "VisualTicker frame did not start hidden")

local function ClearActivationFlags()
    flags.range = false
    flags.config = false
    flags.hots = false
    flags.shortcuts = false
    flags.wheel = false
    flags.keys = false
    flags.threat = false
end

ClearActivationFlags()
ticker.Sync()
assert(frame:IsShown(), "permanent Keys and Wheel did not keep the ticker active")

flags.addon = false
flags.hots = true
flags.shortcuts = true
flags.wheel = true
flags.threat = true
ticker.Sync()
assert(not frame:IsShown(), "disabled addon retained an active visual ticker")

flags.addon = true
ClearActivationFlags()
ticker.Sync()
update(frame, 0.05)
assert(calls.hotTicks == 1 and calls.shortcutTicks == 1 and calls.wheelRefreshes == 1,
    "per-frame visual callbacks did not run exactly once")
assert(calls.rangeRefreshes == 1 and calls.threatRefreshes == 1 and calls.keyRefreshes == 1,
    "initial range-cadence callbacks did not run")

update(frame, 0.10)
assert(calls.hotTicks == 2 and calls.shortcutTicks == 2 and calls.wheelRefreshes == 2,
    "per-frame visual callbacks missed an intermediate tick")
assert(calls.rangeRefreshes == 1 and calls.threatRefreshes == 1 and calls.keyRefreshes == 1,
    "range callbacks ran before the 0.2-second cadence")

update(frame, 0.11)
assert(calls.hotTicks == 3 and calls.shortcutTicks == 3,
    "per-frame callbacks did not continue on the range tick")
assert(calls.rangeRefreshes == 2 and calls.threatRefreshes == 2 and calls.keyRefreshes == 2,
    "range callbacks did not run at the 0.2-second cadence")
assert(calls.wheelRefreshes == 3,
    "Wheel refreshed more than once during a range-cadence tick")

ticker.Stop()
assert(not frame:IsShown(), "Stop did not hide the ticker")
ticker.Sync()
update(frame, 0.01)
assert(calls.rangeRefreshes == 3 and calls.threatRefreshes == 3 and calls.keyRefreshes == 3,
    "Stop did not reset the private range accumulator")

local beforeDisable = {
    calls.hotTicks, calls.shortcutTicks, calls.wheelRefreshes,
    calls.rangeRefreshes, calls.threatRefreshes, calls.keyRefreshes,
}
flags.addon = false
update(frame, 0.25)
assert(not frame:IsShown(), "update after addon disable did not stop the ticker")
assert(calls.hotTicks == beforeDisable[1]
        and calls.shortcutTicks == beforeDisable[2]
        and calls.wheelRefreshes == beforeDisable[3]
        and calls.rangeRefreshes == beforeDisable[4]
        and calls.threatRefreshes == beforeDisable[5]
        and calls.keyRefreshes == beforeDisable[6],
    "disabled addon continued visual ticking")

print("PASS visual ticker")
