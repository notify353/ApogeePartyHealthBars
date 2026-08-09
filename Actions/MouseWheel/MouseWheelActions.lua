local C = ApogeePartyHealthBars_C
local Factory = ApogeePartyHealthBars_BoundActionRuntime
local Data = ApogeePartyHealthBars_MouseWheelData
local Layouts = ApogeePartyHealthBars_MouseWheelLayouts

local PANEL_HEIGHT = C.SHORTCUT_ICON_SIZE * 6 + C.SHORTCUT_ICON_GAP * 5
local ICON_X = C.ROW_CONTENT_W - C.SHORTCUT_ICON_SIZE
local LABEL_WIDTH = 82

local function defaultPreviousAction(slot)
    if slot.key == "MOUSEWHEELUP" then return "CAMERAZOOMIN" end
    if slot.key == "MOUSEWHEELDOWN" then return "CAMERAZOOMOUT" end
    return ""
end

ApogeePartyHealthBars_MouseWheelActions = Factory.Create({
    data = Data,
    layouts = Layouts,
    stateKey = "mouseWheelActions",
    featureId = "mouseWheel",
    featureLabel = "Mouse Wheel",
    slotNoun = "wheel gesture",
    feedbackGlobal = "ApogeeWheelFeedback",
    feedbackLabel = function(slot) return slot.label end,
    secureState = "wheelstate",
    secureMacroPrefix = "wheel-macro-",
    hud = {
        panelHeight = PANEL_HEIGHT,
        totalHeight = PANEL_HEIGHT + 10,
        iconHeight = PANEL_HEIGHT,
        labelWidth = LABEL_WIDTH,
        labelAlign = "RIGHT",
        positionLabel = function(label, container)
            label:SetPoint("BOTTOMRIGHT", container, "TOPLEFT", C.ROW_CONTENT_W, 0)
        end,
        positionIcon = function(icon, container, _, displayIndex)
            local y = -(displayIndex - 1) * (C.SHORTCUT_ICON_SIZE + C.SHORTCUT_ICON_GAP)
            icon:SetPoint("TOPLEFT", container, "TOPLEFT", ICON_X, y)
        end,
    },
    bindings = {
        defaultPreviousAction = defaultPreviousAction,
        reclaimPreviousBindings = true,
        label = "Mouse Wheel bindings",
        claimedMessage = "Mouse Wheel bindings claimed.",
        releasedMessage = "Mouse Wheel bindings restored.",
    },
    allSlotsMessage = "All wheel gestures are assigned. Drop onto a gesture to replace it or clear one.",
})
