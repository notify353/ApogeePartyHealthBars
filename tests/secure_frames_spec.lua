ApogeePartyHealthBars_S = {}
local combat = false
function InCombatLockdown() return combat end
UIParent = {}
local reconcileDriver = { scripts = {}, shown = false }
function reconcileDriver:SetScript(name, callback) self.scripts[name] = callback end
function reconcileDriver:Show() self.shown = true end
function reconcileDriver:Hide() self.shown = false end
function CreateFrame() return reconcileDriver end

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

combat = false
local anchorRect = { 10, 20, 30, 40 }
local overlay = {
    shown = true,
    IsShown = function(self) return self.shown end,
    Hide = function(self) self.shown = false end,
    Show = function(self) self.shown = true end,
    ClearAllPoints = function() end,
    SetPoint = function(self, _, _, _, left, bottom) self.left, self.bottom = left, bottom end,
    SetSize = function(self, width, height) self.width, self.height = width, height end,
}
local anchor = {
    IsShown = function() return true end,
    GetRect = function() return unpack(anchorRect) end,
}
local reconciliations = 0
F.InitializeReconciler(function()
    reconciliations = reconciliations + 1
    F.PositionOverlay(overlay, anchor)
end)
F.RequestReconcile()
F.RequestReconcile()
assert(reconcileDriver.shown and reconciliations == 0,
    "secure reconciliation did not wait for the next frame")
anchorRect = { 50, 60, 70, 80 }
reconcileDriver.scripts.OnUpdate(reconcileDriver)
assert(not reconcileDriver.shown and reconciliations == 1,
    "next-frame secure reconciliation did not coalesce requests")
assert(overlay.left == 50 and overlay.bottom == 60
        and overlay.width == 70 and overlay.height == 80,
    "secure reconciliation used stale overlay geometry")

combat = true
local beforeCombatReconcile = reconciliations
F.RequestReconcile()
reconcileDriver.scripts.OnUpdate(reconcileDriver)
assert(reconciliations == beforeCombatReconcile,
    "secure reconciliation mutated overlays during combat")
assert(F.FlushDeferredUpdates(), "combat reconciliation was not deferred")
print("PASS secure frames")
