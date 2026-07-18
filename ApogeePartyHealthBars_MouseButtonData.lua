ApogeePartyHealthBars_MouseButtonData = {}
local D = ApogeePartyHealthBars_MouseButtonData

D.SLOTS = {
    { id = "normal3", key = "BUTTON3",       label = "Middle Button",          displayKey = "M3", row = 1, column = 1, buttonName = "ApogeePartyHealthBarsMouseNormal3" },
    { id = "normal4", key = "BUTTON4",       label = "Mouse Button 4",         displayKey = "M4", row = 1, column = 2, buttonName = "ApogeePartyHealthBarsMouseNormal4" },
    { id = "normal5", key = "BUTTON5",       label = "Mouse Button 5",         displayKey = "M5", row = 1, column = 3, buttonName = "ApogeePartyHealthBarsMouseNormal5" },
    { id = "shift3",  key = "SHIFT-BUTTON3", label = "Shift + Middle Button",  displayKey = "S3", row = 2, column = 1, buttonName = "ApogeePartyHealthBarsMouseShift3" },
    { id = "shift4",  key = "SHIFT-BUTTON4", label = "Shift + Mouse Button 4", displayKey = "S4", row = 2, column = 2, buttonName = "ApogeePartyHealthBarsMouseShift4" },
    { id = "shift5",  key = "SHIFT-BUTTON5", label = "Shift + Mouse Button 5", displayKey = "S5", row = 2, column = 3, buttonName = "ApogeePartyHealthBarsMouseShift5" },
    { id = "ctrl3",   key = "CTRL-BUTTON3",  label = "Ctrl + Middle Button",   displayKey = "C3", row = 3, column = 1, buttonName = "ApogeePartyHealthBarsMouseCtrl3" },
    { id = "ctrl4",   key = "CTRL-BUTTON4",  label = "Ctrl + Mouse Button 4",  displayKey = "C4", row = 3, column = 2, buttonName = "ApogeePartyHealthBarsMouseCtrl4" },
    { id = "ctrl5",   key = "CTRL-BUTTON5",  label = "Ctrl + Mouse Button 5",  displayKey = "C5", row = 3, column = 3, buttonName = "ApogeePartyHealthBarsMouseCtrl5" },
}

D.DISPLAY_ORDER = {
    "normal3", "normal4", "normal5",
    "shift3", "shift4", "shift5",
    "ctrl3", "ctrl4", "ctrl5",
}

function D.ValidateAll()
    local errors, seenKeys, seenIds, seenButtons, seenCells, seenOrder = {}, {}, {}, {}, {}, {}
    for index, slot in ipairs(D.SLOTS) do
        if seenKeys[slot.key] then errors[#errors + 1] = "duplicate mouse key: " .. slot.key end
        if seenIds[slot.id] then errors[#errors + 1] = "duplicate mouse slot: " .. slot.id end
        if seenButtons[slot.buttonName] then errors[#errors + 1] = "duplicate secure button: " .. slot.buttonName end
        local cell = tostring(slot.row) .. ":" .. tostring(slot.column)
        if seenCells[cell] then errors[#errors + 1] = "duplicate mouse grid cell: " .. cell end
        seenKeys[slot.key], seenIds[slot.id] = true, true
        seenButtons[slot.buttonName], seenCells[cell] = true, true
        if not slot.buttonName or slot.buttonName == "" then errors[#errors + 1] = "slot " .. index .. " has no button name" end
    end
    for _, slotId in ipairs(D.DISPLAY_ORDER) do
        if seenOrder[slotId] then errors[#errors + 1] = "duplicate mouse display slot: " .. slotId end
        if not seenIds[slotId] then errors[#errors + 1] = "unknown mouse display slot: " .. slotId end
        seenOrder[slotId] = true
    end
    if #D.SLOTS ~= 9 then errors[#errors + 1] = "Buttons must define exactly 9 slots" end
    if #D.DISPLAY_ORDER ~= #D.SLOTS then errors[#errors + 1] = "mouse display order is incomplete" end
    return #errors == 0, errors
end
