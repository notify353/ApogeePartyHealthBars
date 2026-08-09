dofile("Core/Namespace.lua")
local modifierFrame
function CreateFrame()
    modifierFrame = { scripts = {} }
    function modifierFrame:RegisterEvent(event) self.event = event end
    function modifierFrame:SetScript(name, callback) self.scripts[name] = callback end
    return modifierFrame
end
dofile("Actions/BoundActionDragController.lua")

local inCombat, cursorType, shiftDown = false, nil, false
local setCursor, setCursorCount, resetCursor = nil, 0, nil
function InCombatLockdown() return inCombat end
function GetCursorInfo() return cursorType end
function IsShiftKeyDown() return shiftDown end
function SetCursor(value) setCursor = value; setCursorCount = setCursorCount + 1 end
function ResetCursor() resetCursor = (resetCursor or 0) + 1 end

local controller = ApogeePartyHealthBars.Require(
    "Actions", "BoundActionDragController")
local moves = {}
controller.Configure(function(source, destination)
    moves[#moves + 1] = { source = source, destination = destination }
    return true
end)

local destination = { shown = true, hovered = false }
local destinationMovable = true
function destination:IsShown() return self.shown end
function destination:IsMouseOver() return self.hovered end
controller.RegisterDestination(destination, function()
    return { feature = "keyboard", layoutKey = "default", slotId = "key" }
end, function() return destinationMovable end)
assert(modifierFrame and modifierFrame.event == "MODIFIER_STATE_CHANGED",
    "bound-action drag did not install its shared modifier listener")

local source = {
    feature = "mouseWheel", layoutKey = "default", slotId = "wheelUp",
}
assert(controller.Begin(source) and controller.IsActive()
        and setCursor == "UI_MOVE_CURSOR",
    "bound-action drag did not start with session-only move state")
destination.hovered = true
assert(controller.Finish() and not controller.IsActive() and #moves == 1
        and moves[1].source.feature == "mouseWheel"
        and moves[1].destination.feature == "keyboard",
    "bound-action drag did not resolve the hovered cross-HUD destination")

destination.hovered = false
assert(controller.Begin(source))
assert(controller.Finish() and #moves == 1 and not controller.IsActive(),
    "releasing outside a destination did not cancel without mutation")

cursorType = "spell"
assert(not controller.Begin(source),
    "internal movement replaced a Blizzard cursor payload")
cursorType = nil
inCombat = true
assert(not controller.Begin(source), "internal movement started during combat")
inCombat = false
assert(controller.Begin(source) and controller.Cancel() and not controller.IsActive(),
    "explicit cancellation left bound-action drag state active")
assert(resetCursor == 3,
    "bound-action drag did not reset only its own move cursor")

assert(controller.Begin(source) and controller.IsActive(),
    "pre-combat drag did not enter active state")
inCombat = true
assert(controller.Cancel() and not controller.IsActive() and #moves == 1
        and resetCursor == 4,
    "combat transition did not cancel an active drag without mutation")
inCombat = false

destination.hovered, shiftDown = true, true
local cursorCountBeforeHover = setCursorCount
assert(controller.RefreshHoverCursor() and setCursor == "UI_MOVE_CURSOR"
        and setCursorCount == cursorCountBeforeHover + 1,
    "Shift-hover over an assigned action did not show WoW's move cursor")
shiftDown = false
modifierFrame.scripts.OnEvent(modifierFrame, "MODIFIER_STATE_CHANGED", "LSHIFT", 0)
assert(resetCursor == 5,
    "releasing Shift while hovering did not restore the normal cursor")
shiftDown, destinationMovable = true, false
assert(not controller.RefreshHoverCursor() and resetCursor == 5,
    "an empty action destination showed the move cursor")
destinationMovable = true
assert(controller.RefreshHoverCursor(),
    "assigned action did not restore its Shift-hover move cursor")
inCombat = true
assert(not controller.Cancel() and resetCursor == 6
        and not controller.RefreshHoverCursor(),
    "entering combat did not clear the Shift-hover movement affordance")

print("PASS bound-action drag controller")
