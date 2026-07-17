ApogeePartyHealthBars_WheelData = {}
local D = ApogeePartyHealthBars_WheelData

D.SLOTS = {
    { id = "normalUp",   key = "MOUSEWHEELUP",         label = "Normal Up",   buttonName = "ApogeePartyHealthBarsWheelNormalUp" },
    { id = "normalDown", key = "MOUSEWHEELDOWN",       label = "Normal Down", buttonName = "ApogeePartyHealthBarsWheelNormalDown" },
    { id = "shiftUp",    key = "SHIFT-MOUSEWHEELUP",   label = "Shift Up",    buttonName = "ApogeePartyHealthBarsWheelShiftUp" },
    { id = "shiftDown",  key = "SHIFT-MOUSEWHEELDOWN", label = "Shift Down",  buttonName = "ApogeePartyHealthBarsWheelShiftDown" },
    { id = "ctrlUp",     key = "CTRL-MOUSEWHEELUP",    label = "Ctrl Up",     buttonName = "ApogeePartyHealthBarsWheelCtrlUp" },
    { id = "ctrlDown",   key = "CTRL-MOUSEWHEELDOWN",  label = "Ctrl Down",   buttonName = "ApogeePartyHealthBarsWheelCtrlDown" },
}
D.DISPLAY_ORDER = {
    "ctrlUp", "shiftUp", "normalUp", "normalDown", "shiftDown", "ctrlDown",
}

function D.ValidateAll()
    local errors, seenKeys, seenIds, seenOrder = {}, {}, {}, {}
    for index, slot in ipairs(D.SLOTS) do
        if seenKeys[slot.key] then errors[#errors + 1] = "duplicate wheel key: " .. slot.key end
        if seenIds[slot.id] then errors[#errors + 1] = "duplicate wheel slot: " .. slot.id end
        seenKeys[slot.key], seenIds[slot.id] = true, true
        if not slot.buttonName or slot.buttonName == "" then errors[#errors + 1] = "slot " .. index .. " has no button name" end
    end
    for _, slotId in ipairs(D.DISPLAY_ORDER) do
        if seenOrder[slotId] then errors[#errors + 1] = "duplicate wheel display slot: " .. slotId end
        if not seenIds[slotId] then errors[#errors + 1] = "unknown wheel display slot: " .. slotId end
        seenOrder[slotId] = true
    end
    if #D.DISPLAY_ORDER ~= #D.SLOTS then errors[#errors + 1] = "wheel display order is incomplete" end
    return #errors == 0, errors
end
