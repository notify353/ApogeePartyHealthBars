-- Session-only drag state for moving configured actions between the live
-- Keyboard, Mouse Wheel, and Mouse Buttons HUDs. Persistence and refreshes
-- remain owned by the feature facades and ActionCoordinator.
local C = {}
ApogeePartyHealthBars.Define("Actions", "BoundActionDragController", C)

local moveAction
local activeSource
local destinations = {}
local modifierFrame
local moveCursorShown = false

local function inCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function copyDescriptor(value)
    if type(value) ~= "table"
            or type(value.feature) ~= "string"
            or type(value.layoutKey) ~= "string"
            or type(value.slotId) ~= "string" then
        return nil
    end
    return {
        feature = value.feature,
        layoutKey = value.layoutKey,
        slotId = value.slotId,
    }
end

local function hasCursorPayload()
    return GetCursorInfo and GetCursorInfo() ~= nil
end

local function resetMoveCursor()
    -- Never clear or visually replace a Blizzard payload that appeared after
    -- our internal move began.
    if moveCursorShown and not hasCursorPayload() and ResetCursor then
        ResetCursor()
    end
    moveCursorShown = false
end

local function setMoveCursor()
    if moveCursorShown then return end
    if SetCursor then SetCursor("UI_MOVE_CURSOR") end
    moveCursorShown = true
end

local function hoveredMovableDestination()
    for _, destination in ipairs(destinations) do
        local frame = destination.frame
        local shown = not frame.IsShown or frame:IsShown()
        if shown and frame.IsMouseOver and frame:IsMouseOver()
                and destination.canMove() then
            return destination
        end
    end
end

function C.RefreshHoverCursor()
    if activeSource then
        setMoveCursor()
        return true
    end
    local shouldShow = moveAction and not inCombat() and not hasCursorPayload()
        and IsShiftKeyDown and IsShiftKeyDown()
        and hoveredMovableDestination() ~= nil
    if shouldShow then
        setMoveCursor()
        return true
    end
    resetMoveCursor()
    return false
end

local function ensureModifierFrame()
    if modifierFrame or not CreateFrame then return end
    modifierFrame = CreateFrame("Frame")
    modifierFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
    modifierFrame:SetScript("OnEvent", function()
        C.RefreshHoverCursor()
    end)
end

function C.Configure(callback)
    assert(type(callback) == "function",
        "BoundActionDragController requires a move callback")
    moveAction = callback
    return C
end

function C.RegisterDestination(frame, resolver, canMove)
    assert(frame, "BoundActionDragController requires a destination frame")
    assert(type(resolver) == "function",
        "BoundActionDragController requires a destination resolver")
    assert(type(canMove) == "function",
        "BoundActionDragController requires a movement eligibility resolver")
    destinations[#destinations + 1] = {
        frame = frame,
        resolve = resolver,
        canMove = canMove,
    }
    ensureModifierFrame()
    return frame
end

function C.Begin(source)
    local descriptor = copyDescriptor(source)
    if not moveAction or not descriptor or inCombat() or hasCursorPayload() then
        return false
    end
    activeSource = descriptor
    setMoveCursor()
    return true
end

function C.IsActive()
    return activeSource ~= nil
end

function C.DropOn(destination)
    if not activeSource then return false end
    local target = copyDescriptor(destination)
    if not target or inCombat() then
        C.Cancel()
        return true, false
    end
    local source = activeSource
    activeSource = nil
    resetMoveCursor()
    local ok, detail = moveAction(source, target)
    C.RefreshHoverCursor()
    return true, ok, detail
end

function C.Finish()
    if not activeSource then return false end
    for _, destination in ipairs(destinations) do
        local frame = destination.frame
        local shown = not frame.IsShown or frame:IsShown()
        if shown and frame.IsMouseOver and frame:IsMouseOver() then
            return C.DropOn(destination.resolve())
        end
    end
    C.Cancel()
    return true, false, "cancelled"
end

function C.Cancel()
    local wasActive = activeSource ~= nil
    activeSource = nil
    resetMoveCursor()
    C.RefreshHoverCursor()
    return wasActive
end
