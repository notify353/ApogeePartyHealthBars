local C = ApogeePartyHealthBars_C
local Factory = ApogeePartyHealthBars_BoundActionRuntime
local Data = ApogeePartyHealthBars_MouseButtonData
local Layouts = ApogeePartyHealthBars_MouseButtonLayouts

local GRID_HEIGHT = C.SHORTCUT_ICON_SIZE * 3 + C.SHORTCUT_ICON_GAP * 2
local GRID_X = C.ROW_CONTENT_W + C.SHORTCUT_ICON_SIZE + C.SHORTCUT_ICON_GAP * 2

ApogeePartyHealthBars_MouseButtonActions = Factory.Create({
    data = Data,
    layouts = Layouts,
    stateKey = "mouseActions",
    featureId = "mouseButtons",
    featureLabel = "Buttons",
    slotNoun = "mouse button",
    feedbackGlobal = "ApogeeMouseButtonsFeedback",
    feedbackLabel = function(slot) return slot.label end,
    secureState = "mousebuttonstate",
    secureMacroPrefix = "mouse-button-macro-",
    hud = {
        panelHeight = GRID_HEIGHT,
        totalHeight = GRID_HEIGHT,
        iconHeight = GRID_HEIGHT,
        panelWidth = GRID_X + C.SHORTCUT_ICON_SIZE * 3 + C.SHORTCUT_ICON_GAP * 2,
        positionIcon = function(icon, container, slot)
            local stride = C.SHORTCUT_ICON_SIZE + C.SHORTCUT_ICON_GAP
            icon:SetPoint("TOPLEFT", container, "TOPLEFT",
                GRID_X + (slot.column - 1) * stride, -(slot.row - 1) * stride)
        end,
    },
    bindings = {
        reclaimPreviousBindings = true,
        label = "Buttons bindings",
        claimedMessage = "Buttons bindings claimed.",
        releasedMessage = "Buttons bindings restored.",
    },
    allSlotsMessage = "All 9 Buttons are assigned. Drop onto a button to replace it or clear one.",
})
