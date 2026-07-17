dofile("ApogeePartyHealthBars_KeyData.lua")
local data = ApogeePartyHealthBars_KeyData

local valid, errors = data.ValidateAll()
assert(valid and #errors == 0, "key definitions failed validation")
assert(#data.SLOTS == 15 and #data.DISPLAY_ORDER == 15,
    "Keys did not define exactly 15 ordered slots")

local expected = { "1", "2", "3", "4", "5", "Q", "E", "R", "T", "F", "G", "Z", "X", "C", "V" }
local byId = {}
for index, slot in ipairs(data.SLOTS) do
    byId[slot.id] = slot
    assert(slot.key == expected[index], "physical key order changed at slot " .. index)
    assert(slot.buttonName == "ApogeePartyHealthBarsKey" .. slot.key,
        "secure button name is not stable for " .. slot.key)
end
for index, slotId in ipairs(data.DISPLAY_ORDER) do
    assert(byId[slotId] and byId[slotId].key == expected[index],
        "display order changed at slot " .. index)
end

assert(byId.keyF.row == 3 and byId.keyF.column == 3
    and byId.keyG.row == 3 and byId.keyG.column == 4,
    "F and G are not positioned under R and T")
assert(byId.key1.row == 1 and byId.key5.column == 5
    and byId.keyQ.row == 2 and byId.keyZ.row == 4,
    "keyboard grid anchors changed")

print("PASS fixed Keys action layout")
