ApogeePartyHealthBars_S = {}
local combat = false
function InCombatLockdown() return combat end
UIParent = {}

dofile("ApogeePartyHealthBars_SecureFrames.lua")
local F = ApogeePartyHealthBars_SecureFrames
local calls = {}
local frame = {
    Hide = function() calls[#calls + 1] = "hide" end,
    Show = function() calls[#calls + 1] = "show" end,
    EnableMouse = function(_, value) calls[#calls + 1] = value and "mouse-on" or "mouse-off" end,
}

F.Show(frame); F.Hide(frame); F.SetMouseEnabled(frame, true)
assert(table.concat(calls, ",") == "show,hide,mouse-on")
assert(not F.FlushDeferredUpdates())

combat = true
F.Show(frame); F.Hide(frame); F.SetMouseEnabled(frame, false)
assert(#calls == 3, "secure frames mutated during combat")
assert(F.FlushDeferredUpdates(), "combat mutation was not deferred")
assert(not F.FlushDeferredUpdates(), "deferred flag did not clear")
print("PASS secure frames")

