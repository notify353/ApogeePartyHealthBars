local itemCount = 2
local itemCooldown = 0
local linkUseEffectChecks = 0

local function ResolveTestItemId(itemInfo)
    if type(itemInfo) == "number" then return itemInfo end
    return tonumber(type(itemInfo) == "string" and itemInfo:match("item:(%d+)") or nil)
end

C_Item = {
    GetItemInfo = function(itemInfo)
        local itemId = ResolveTestItemId(itemInfo)
        if itemId == 1251 then
            -- Classic Era ends at the texture slot; newer clients may append fields.
            return "Linen Bandage", nil, nil, 1, 60, nil, nil, nil, nil, 134436
        end
        local data = {
            [100] = { "Minor Potion", 10, 1000 },
            [101] = { "Major Potion", 30, 1001 },
            [102] = { "Greater Mana Potion", 20, 1002 },
            [200] = { "Travel Food", 20, 2000 },
            [300] = { "Quest Draught", 40, 3000 },
            [400] = { "Sword", 50, 4000 },
            [500] = { "Flavor Consumable", 5, 5000 },
        }
        local value = data[itemId]
        if value then return value[1], nil, nil, value[2], 60, nil, nil, nil, nil, value[3] end
    end,
    GetItemInfoInstant = function(itemInfo)
        local itemId = ResolveTestItemId(itemInfo)
        if itemId == 118 then return itemId, nil, nil, nil, 134335 end
        local subclasses = { [100] = 1, [101] = 1, [102] = 1, [200] = 5, [300] = 1,
            [400] = 7, [500] = 8, [1251] = 7 }
        if subclasses[itemId] then
            return itemId, nil, nil, nil, itemId * 10, itemId == 400 and 2 or 0,
                subclasses[itemId]
        end
    end,
    GetItemCount = function(itemId) return itemId == 1251 and itemCount or 0 end,
    IsUsableItem = function(itemId) return itemId == 1251, false end,
    GetItemSpell = function(itemInfo)
        local itemId = ResolveTestItemId(itemInfo)
        if type(itemInfo) == "string" then linkUseEffectChecks = linkUseEffectChecks + 1 end
        if itemId == 500 or itemId == 400 then return nil end
        if itemId == 100 or itemId == 102 then return "Restore Mana", 10000 + itemId end
        if itemId == 101 then return "Restore Health", 10000 + itemId end
        return itemId == 1251 and "First Aid" or "Use Item"
    end,
    IsConsumableItem = function(itemInfo) return ResolveTestItemId(itemInfo) ~= 400 end,
}
local bagItems = {
    [0] = { 100, 1251, 100, 300 },
    [1] = { 400, 200, 500, 101, 102 },
}
C_Container = {
    GetItemCooldown = function(itemId)
        return itemId == 1251 and 10 or 0, itemCooldown, 1
    end,
    GetContainerNumSlots = function(bag) return bagItems[bag] and #bagItems[bag] or 0 end,
    GetContainerItemID = function(bag, slot) return bagItems[bag] and bagItems[bag][slot] end,
    GetContainerItemInfo = function(bag, slot)
        local itemId = bagItems[bag] and bagItems[bag][slot]
        if not itemId then return nil end
        return {
            itemID = itemId,
            hyperlink = "item:" .. itemId,
            itemName = "Bag Item " .. itemId,
            iconFileID = itemId * 10,
        }
    end,
    GetContainerItemQuestInfo = function(bag, slot)
        return { isQuestItem = bag == 0 and slot == 4 }
    end,
}
BACKPACK_CONTAINER = 0
NUM_BAG_SLOTS = 4
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

local candidates, total = items.ScanConsumables(4)
assert(total == 5 and #candidates == 4,
    "bag scan did not deduplicate, filter, or limit automatic consumables")
assert(candidates[1].itemId == 101 and candidates[2].itemId == 102
        and candidates[3].itemId == 100 and candidates[4].itemId == 1251,
    "automatic consumables did not group use-effect families before item-level ordering")
assert(linkUseEffectChecks > 0,
    "automatic consumable scan did not use the bag-resolved item hyperlink")

print("PASS Classic Era item API compatibility")
