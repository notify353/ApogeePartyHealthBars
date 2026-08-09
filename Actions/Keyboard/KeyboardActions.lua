local C = ApogeePartyHealthBars_C
local Factory = ApogeePartyHealthBars_BoundActionRuntime
local Data = ApogeePartyHealthBars_KeyboardData
local Layouts = ApogeePartyHealthBars_KeyboardLayouts

local GRID_HEIGHT = C.SHORTCUT_ICON_SIZE * 4 + C.SHORTCUT_ICON_GAP * 3
local LABEL_WIDTH = 72
local FEEDBACK_HEIGHT = 18
local PANEL_HEIGHT = GRID_HEIGHT + C.SHORTCUT_ICON_GAP + FEEDBACK_HEIGHT

ApogeePartyHealthBars_KeyboardActions = Factory.Create({
    data = Data,
    layouts = Layouts,
    stateKey = "keyboardActions",
    featureId = "keyboard",
    featureLabel = "Keyboard",
    slotNoun = "key",
    feedbackGlobal = "ApogeeKeysFeedback",
    feedbackLabel = function(slot) return slot.displayKey end,
    secureState = "keystate",
    secureMacroPrefix = "key-macro-",
    hud = {
        panelHeight = PANEL_HEIGHT,
        totalHeight = PANEL_HEIGHT + 10,
        iconHeight = GRID_HEIGHT,
        labelWidth = LABEL_WIDTH,
        positionLabel = function(label, container)
            label:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 0, 0)
        end,
        slotLabel = function(slot) return slot.displayKey end,
        positionIcon = function(icon, container, slot)
            local stride = C.SHORTCUT_ICON_SIZE + C.SHORTCUT_ICON_GAP
            icon:SetPoint("TOPLEFT", container, "TOPLEFT",
                (slot.column - 1) * stride, -(slot.row - 1) * stride)
        end,
    },
    bindings = {
        label = "Keyboard bindings",
        claimedMessage = "Keyboard bindings claimed.",
        releasedMessage = "Keyboard bindings restored.",
    },
    allSlotsMessage = "All 15 Keyboard actions are assigned. Drop onto a key to replace it or clear one.",
})
