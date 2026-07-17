ApogeePartyHealthBars_KeyData = {}
local D = ApogeePartyHealthBars_KeyData

D.SLOTS = {
    { id = "key1", key = "1", label = "Key 1", displayKey = "1", row = 1, column = 1, buttonName = "ApogeePartyHealthBarsKey1" },
    { id = "key2", key = "2", label = "Key 2", displayKey = "2", row = 1, column = 2, buttonName = "ApogeePartyHealthBarsKey2" },
    { id = "key3", key = "3", label = "Key 3", displayKey = "3", row = 1, column = 3, buttonName = "ApogeePartyHealthBarsKey3" },
    { id = "key4", key = "4", label = "Key 4", displayKey = "4", row = 1, column = 4, buttonName = "ApogeePartyHealthBarsKey4" },
    { id = "key5", key = "5", label = "Key 5", displayKey = "5", row = 1, column = 5, buttonName = "ApogeePartyHealthBarsKey5" },
    { id = "keyQ", key = "Q", label = "Key Q", displayKey = "Q", row = 2, column = 1, buttonName = "ApogeePartyHealthBarsKeyQ" },
    { id = "keyE", key = "E", label = "Key E", displayKey = "E", row = 2, column = 2, buttonName = "ApogeePartyHealthBarsKeyE" },
    { id = "keyR", key = "R", label = "Key R", displayKey = "R", row = 2, column = 3, buttonName = "ApogeePartyHealthBarsKeyR" },
    { id = "keyT", key = "T", label = "Key T", displayKey = "T", row = 2, column = 4, buttonName = "ApogeePartyHealthBarsKeyT" },
    { id = "keyF", key = "F", label = "Key F", displayKey = "F", row = 3, column = 3, buttonName = "ApogeePartyHealthBarsKeyF" },
    { id = "keyG", key = "G", label = "Key G", displayKey = "G", row = 3, column = 4, buttonName = "ApogeePartyHealthBarsKeyG" },
    { id = "keyZ", key = "Z", label = "Key Z", displayKey = "Z", row = 4, column = 1, buttonName = "ApogeePartyHealthBarsKeyZ" },
    { id = "keyX", key = "X", label = "Key X", displayKey = "X", row = 4, column = 2, buttonName = "ApogeePartyHealthBarsKeyX" },
    { id = "keyC", key = "C", label = "Key C", displayKey = "C", row = 4, column = 3, buttonName = "ApogeePartyHealthBarsKeyC" },
    { id = "keyV", key = "V", label = "Key V", displayKey = "V", row = 4, column = 4, buttonName = "ApogeePartyHealthBarsKeyV" },
}

D.DISPLAY_ORDER = {
    "key1", "key2", "key3", "key4", "key5",
    "keyQ", "keyE", "keyR", "keyT", "keyF", "keyG",
    "keyZ", "keyX", "keyC", "keyV",
}

function D.ValidateAll()
    local errors, seenKeys, seenIds, seenButtons, seenCells, seenOrder = {}, {}, {}, {}, {}, {}
    for index, slot in ipairs(D.SLOTS) do
        if seenKeys[slot.key] then errors[#errors + 1] = "duplicate physical key: " .. slot.key end
        if seenIds[slot.id] then errors[#errors + 1] = "duplicate key slot: " .. slot.id end
        if seenButtons[slot.buttonName] then errors[#errors + 1] = "duplicate secure button: " .. slot.buttonName end
        local cell = tostring(slot.row) .. ":" .. tostring(slot.column)
        if seenCells[cell] then errors[#errors + 1] = "duplicate key grid cell: " .. cell end
        seenKeys[slot.key], seenIds[slot.id] = true, true
        seenButtons[slot.buttonName], seenCells[cell] = true, true
        if not slot.buttonName or slot.buttonName == "" then errors[#errors + 1] = "slot " .. index .. " has no button name" end
    end
    for _, slotId in ipairs(D.DISPLAY_ORDER) do
        if seenOrder[slotId] then errors[#errors + 1] = "duplicate key display slot: " .. slotId end
        if not seenIds[slotId] then errors[#errors + 1] = "unknown key display slot: " .. slotId end
        seenOrder[slotId] = true
    end
    if #D.SLOTS ~= 15 then errors[#errors + 1] = "Keys must define exactly 15 slots" end
    if #D.DISPLAY_ORDER ~= #D.SLOTS then errors[#errors + 1] = "key display order is incomplete" end
    return #errors == 0, errors
end
