local C = ApogeePartyHealthBars_C
local Factory = ApogeePartyHealthBars_BoundActionRuntime
local Data = ApogeePartyHealthBars_KeyData
local Layouts = ApogeePartyHealthBars_KeyLayouts

local GRID_HEIGHT = C.SHORTCUT_ICON_SIZE * 4 + C.SHORTCUT_ICON_GAP * 3
local FEEDBACK_HEIGHT = 18
local PANEL_HEIGHT = GRID_HEIGHT + C.SHORTCUT_ICON_GAP + FEEDBACK_HEIGHT

ApogeePartyHealthBars_KeyActions = Factory.Create({
    data = Data,
    layouts = Layouts,
    stateKey = "keyActions",
    featureId = "keys",
    featureLabel = "Keys",
    slotNoun = "key",
    feedbackGlobal = "ApogeeKeysFeedback",
    feedbackLabel = function(slot) return slot.displayKey end,
    secureState = "keystate",
    secureMacroPrefix = "key-macro-",
    hud = {
        panelHeight = PANEL_HEIGHT,
        totalHeight = PANEL_HEIGHT + 10,
        iconHeight = GRID_HEIGHT,
        positionIcon = function(icon, container, slot)
            local stride = C.SHORTCUT_ICON_SIZE + C.SHORTCUT_ICON_GAP
            icon:SetPoint("TOPLEFT", container, "TOPLEFT",
                (slot.column - 1) * stride, -(slot.row - 1) * stride)
        end,
    },
    bindings = {
        label = "Keys bindings",
        claimedMessage = "Keys bindings claimed.",
        releasedMessage = "Keys bindings restored.",
    },
    allSlotsMessage = "All 15 Keys are assigned. Drop onto a key to replace it or clear one.",
})
