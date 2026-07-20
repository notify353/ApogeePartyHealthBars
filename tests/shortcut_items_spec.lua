local itemCount = 2
local itemCooldown = 0

C_Item = {
    GetItemInfo = function(itemId)
        if itemId == 1251 then
            -- Classic Era ends at the texture slot; newer clients may append fields.
            return "Linen Bandage", nil, nil, nil, nil, nil, nil, nil, nil, 134436
        end
    end,
    GetItemInfoInstant = function(itemId)
        if itemId == 118 then return itemId, nil, nil, nil, 134335 end
    end,
    GetItemCount = function(itemId) return itemId == 1251 and itemCount or 0 end,
    IsUsableItem = function(itemId) return itemId == 1251, false end,
    GetItemSpell = function(itemId) return itemId == 1251 and "First Aid" or nil end,
}
C_Container = {
    GetItemCooldown = function(itemId)
        return itemId == 1251 and 10 or 0, itemCooldown, 1
    end,
}
C_Spell = {
    GetSpellCooldown = function(spellId)
        assert(spellId == 61304)
        return { startTime = 0, duration = 0 }
    end,
}

dofile("ApogeePartyHealthBars_ShortcutItems.lua")
local items = ApogeePartyHealthBars_ShortcutItems

local name, icon, itemId = items.GetInfo(1251)
assert(name == "Linen Bandage" and icon == 134436 and itemId == 1251,
    "Classic Era's shorter GetItemInfo result was not normalized")
local fallbackName, fallbackIcon = items.GetInfo(118)
assert(fallbackName == nil and fallbackIcon == 134335,
    "instant item information did not provide the Classic Era icon fallback")

local entry = { kind = "item", itemId = 1251, itemName = "Linen Bandage" }
local state, evaluatedIcon, _, _, count, available = items.Evaluate(entry)
assert(state == "ready" and evaluatedIcon == 134436 and count == "2" and available,
    "Classic Era item APIs did not produce a ready shortcut")

itemCooldown = 12
state = items.Evaluate(entry)
assert(state == "cooldown", "Classic Era item cooldown was not normalized")
itemCooldown, itemCount = 0, 0
state, _, _, _, count, available = items.Evaluate(entry)
assert(state == "unavailable" and count == "0" and not available
        and entry.itemId == 1251 and entry.itemName == "Linen Bandage",
    "unavailable Classic Era item assignment was mutated or discarded")

print("PASS Classic Era item API compatibility")
