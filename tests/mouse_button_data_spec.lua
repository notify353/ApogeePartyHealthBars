dofile("ApogeePartyHealthBars_MouseButtonData.lua")
local data = ApogeePartyHealthBars_MouseButtonData

local valid, errors = data.ValidateAll()
assert(valid and #errors == 0, "Buttons definitions failed validation")
assert(#data.SLOTS == 9 and #data.DISPLAY_ORDER == 9,
    "Buttons did not define exactly nine ordered slots")

local expectedKeys = {
    "BUTTON3", "BUTTON4", "BUTTON5",
    "SHIFT-BUTTON3", "SHIFT-BUTTON4", "SHIFT-BUTTON5",
    "CTRL-BUTTON3", "CTRL-BUTTON4", "CTRL-BUTTON5",
}
local byId = {}
for index, slot in ipairs(data.SLOTS) do
    byId[slot.id] = slot
    assert(slot.key == expectedKeys[index], "physical mouse key order changed at slot " .. index)
    assert(slot.row == math.floor((index - 1) / 3) + 1
            and slot.column == ((index - 1) % 3) + 1,
        "Buttons grid position changed at slot " .. index)
end
for index, slotId in ipairs(data.DISPLAY_ORDER) do
    assert(byId[slotId] == data.SLOTS[index], "Buttons display order changed at slot " .. index)
end

print("PASS fixed Buttons action layout")
