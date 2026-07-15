ApogeePartyHealthBars_WheelData = {}
local D = ApogeePartyHealthBars_WheelData

D.MAX_BODY_BYTES = 255
D.SLOTS = {
    { id = "normalUp",   key = "MOUSEWHEELUP",         label = "Normal Up",   buttonName = "ApogeePartyHealthBarsWheelNormalUp" },
    { id = "normalDown", key = "MOUSEWHEELDOWN",       label = "Normal Down", buttonName = "ApogeePartyHealthBarsWheelNormalDown" },
    { id = "shiftUp",    key = "SHIFT-MOUSEWHEELUP",   label = "Shift Up",    buttonName = "ApogeePartyHealthBarsWheelShiftUp" },
    { id = "shiftDown",  key = "SHIFT-MOUSEWHEELDOWN", label = "Shift Down",  buttonName = "ApogeePartyHealthBarsWheelShiftDown" },
    { id = "ctrlUp",     key = "CTRL-MOUSEWHEELUP",    label = "Ctrl Up",     buttonName = "ApogeePartyHealthBarsWheelCtrlUp" },
    { id = "ctrlDown",   key = "CTRL-MOUSEWHEELDOWN",  label = "Ctrl Down",   buttonName = "ApogeePartyHealthBarsWheelCtrlDown" },
}

function D.ValidateAll()
    local errors, seenKeys, seenIds = {}, {}, {}
    for index, slot in ipairs(D.SLOTS) do
        if seenKeys[slot.key] then errors[#errors + 1] = "duplicate wheel key: " .. slot.key end
        if seenIds[slot.id] then errors[#errors + 1] = "duplicate wheel slot: " .. slot.id end
        seenKeys[slot.key], seenIds[slot.id] = true, true
        if not slot.buttonName or slot.buttonName == "" then errors[#errors + 1] = "slot " .. index .. " has no button name" end
    end
    return #errors == 0, errors
end
