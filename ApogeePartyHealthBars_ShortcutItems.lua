ApogeePartyHealthBars_ShortcutItems = {}
local I = ApogeePartyHealthBars_ShortcutItems
local Cooldowns = ApogeePartyHealthBars_ActionCooldowns

local function validItemId(value)
    return type(value) == "number" and value > 0 and math.floor(value) == value and value or nil
end

local function validItemInfo(value)
    return validItemId(value)
        or (type(value) == "string" and value ~= "" and value)
        or nil
end

function I.GetInfo(itemId)
    itemId = validItemId(itemId)
    if not itemId then return nil, nil, nil end

    local name, icon
    if C_Item and C_Item.GetItemInfo then
        local itemName, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemId)
        name, icon = itemName, itemTexture
    elseif GetItemInfo then
        local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
        name, icon = itemName, itemTexture
    end

    if not icon then
        if C_Item and C_Item.GetItemInfoInstant then
            local _, _, _, _, instantIcon = C_Item.GetItemInfoInstant(itemId)
            icon = instantIcon
        elseif GetItemInfoInstant then
            local _, _, _, _, instantIcon = GetItemInfoInstant(itemId)
            icon = instantIcon
        end
    end
    return name, icon, itemId
end

function I.GetCount(itemId)
    itemId = validItemId(itemId)
    if not itemId then return 0 end
    if C_Item and C_Item.GetItemCount then
        return tonumber(C_Item.GetItemCount(itemId, false, false, false, false)) or 0
    end
    if GetItemCount then return tonumber(GetItemCount(itemId, false, false)) or 0 end
    return 0
end

function I.GetCooldown(itemId)
    itemId = validItemId(itemId)
    if not itemId then return 0, 0, false end
    if C_Container and C_Container.GetItemCooldown then
        local start, duration, enabled = C_Container.GetItemCooldown(itemId)
        return start or 0, duration or 0, enabled ~= 0 and enabled ~= false
    end
    if GetItemCooldown then
        local start, duration, enabled = GetItemCooldown(itemId)
        return start or 0, duration or 0, enabled ~= 0 and enabled ~= false
    end
    return 0, 0, true
end

function I.IsUsable(itemId)
    itemId = validItemId(itemId)
    if not itemId then return false, false end
    if C_Item and C_Item.IsUsableItem then return C_Item.IsUsableItem(itemId) end
    if IsUsableItem then return IsUsableItem(itemId) end
    return true, false
end

local function getUseEffect(itemInfo)
    itemInfo = validItemInfo(itemInfo)
    if not itemInfo then return nil end
    if C_Item and C_Item.GetItemSpell then return C_Item.GetItemSpell(itemInfo) end
    if GetItemSpell then return GetItemSpell(itemInfo) end
    return true
end

function I.HasUseEffect(itemInfo)
    return getUseEffect(itemInfo) ~= nil
end

local CONSUMABLE_SUBCLASS_PRIORITY = {
    [1] = 1,  -- Potion
    [7] = 2,  -- Bandage
    [5] = 3,  -- Food and drink
    [2] = 4,  -- Elixir
    [3] = 4,  -- Flask
    [4] = 5,  -- Scroll
    [6] = 6,  -- Item enhancement
}

local function getContainerNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    end
    if GetContainerNumSlots then return GetContainerNumSlots(bag) or 0 end
    return 0
end

local function getContainerItem(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then
            return validItemId(info.itemID), info.hyperlink, info.itemName, info.iconFileID
        end
    end
    local itemId
    if C_Container and C_Container.GetContainerItemID then
        itemId = C_Container.GetContainerItemID(bag, slot)
    elseif GetContainerItemID then
        itemId = GetContainerItemID(bag, slot)
    else
        local info = GetContainerItemInfo and { GetContainerItemInfo(bag, slot) } or nil
        itemId = info and info[10] or nil
    end
    local hyperlink
    if C_Container and C_Container.GetContainerItemLink then
        hyperlink = C_Container.GetContainerItemLink(bag, slot)
    elseif GetContainerItemLink then
        hyperlink = GetContainerItemLink(bag, slot)
    end
    return validItemId(itemId), hyperlink, nil, nil
end

local function isQuestItem(bag, slot)
    if C_Container and C_Container.GetContainerItemQuestInfo then
        local info = C_Container.GetContainerItemQuestInfo(bag, slot)
        return info and info.isQuestItem == true
    end
    if GetContainerItemQuestInfo then
        local isQuestItemValue = GetContainerItemQuestInfo(bag, slot)
        return isQuestItemValue == true
    end
    return false
end

local function getInstantClassification(itemId)
    if C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, _, icon, classId, subclassId = C_Item.GetItemInfoInstant(itemId)
        return icon, classId, subclassId
    end
    if GetItemInfoInstant then
        local _, _, _, _, icon, classId, subclassId = GetItemInfoInstant(itemId)
        return icon, classId, subclassId
    end
    return nil, nil, nil
end

function I.IsConsumable(itemInfo)
    itemInfo = validItemInfo(itemInfo)
    if not itemInfo then return false end
    local _, classId = getInstantClassification(itemInfo)
    if classId ~= nil then
        local consumableClass = Enum and Enum.ItemClass and Enum.ItemClass.Consumable or 0
        return classId == consumableClass
    end
    if C_Item and C_Item.IsConsumableItem then
        return C_Item.IsConsumableItem(itemInfo) == true
    end
    if IsConsumableItem then return IsConsumableItem(itemInfo) == true end
    return false
end

function I.ScanConsumables(limit)
    limit = math.max(0, math.floor(tonumber(limit) or 0))
    local candidates, seen = {}, {}
    local firstBag = BACKPACK_CONTAINER or 0
    local lastBag = NUM_BAG_SLOTS or 4
    for bag = firstBag, lastBag do
        for slot = 1, getContainerNumSlots(bag) do
            local itemId, hyperlink, bagName, bagIcon = getContainerItem(bag, slot)
            local itemInfo = hyperlink or itemId
            local useEffectName = getUseEffect(itemInfo)
            if itemId and not seen[itemId] and not isQuestItem(bag, slot)
                and I.IsConsumable(itemInfo) and useEffectName ~= nil then
                seen[itemId] = true
                local name, icon = I.GetInfo(itemId)
                local instantIcon, classId, subclassId = getInstantClassification(itemInfo)
                local itemLevel = 0
                if C_Item and C_Item.GetItemInfo then
                    itemLevel = tonumber((select(4, C_Item.GetItemInfo(itemInfo)))) or 0
                elseif GetItemInfo then
                    itemLevel = tonumber((select(4, GetItemInfo(itemInfo)))) or 0
                end
                candidates[#candidates + 1] = {
                    itemId = itemId,
                    itemName = bagName or name,
                    icon = bagIcon or icon or instantIcon,
                    classId = classId,
                    subclassId = subclassId,
                    itemLevel = itemLevel,
                    priority = CONSUMABLE_SUBCLASS_PRIORITY[subclassId] or 7,
                    groupName = type(useEffectName) == "string" and useEffectName
                        or bagName or name or "",
                }
            end
        end
    end
    table.sort(candidates, function(left, right)
        if left.priority ~= right.priority then return left.priority < right.priority end
        local leftGroup = string.lower(left.groupName)
        local rightGroup = string.lower(right.groupName)
        if leftGroup ~= rightGroup then return leftGroup < rightGroup end
        if left.itemLevel ~= right.itemLevel then return left.itemLevel > right.itemLevel end
        local leftName = string.lower(left.itemName or "")
        local rightName = string.lower(right.itemName or "")
        if leftName ~= rightName then return leftName < rightName end
        return left.itemId < right.itemId
    end)
    local total = #candidates
    while #candidates > limit do table.remove(candidates) end
    return candidates, total
end

function I.IsGlobalCooldown(start, duration)
    return Cooldowns.IsGlobalCooldown(start, duration)
end

-- Return values mirror Wheel's spell evaluator:
-- state, icon, start, duration, count, available, reason, gcdOnly.
function I.Evaluate(entry)
    if type(entry) ~= "table" or entry.kind ~= "item" then
        return "invalid", nil, 0, 0, nil, false, "Invalid item shortcut", false
    end
    local _, icon = I.GetInfo(entry.itemId)
    local count = I.GetCount(entry.itemId)
    local countText = tostring(count)
    if count <= 0 then
        return "unavailable", icon, 0, 0, countText, false, "Not in bags", false
    end

    local start, duration, enabled = I.GetCooldown(entry.itemId)
    local gcdOnly = I.IsGlobalCooldown(start, duration)
    if enabled and duration > 0 and not gcdOnly then
        return "cooldown", icon, start, duration, countText, true, nil, false
    end

    local usable, noResource = I.IsUsable(entry.itemId)
    if noResource then
        return "resource", icon, start, duration, countText, true, nil, gcdOnly
    end
    if not usable then
        return "unusable", icon, start, duration, countText, true, "Not currently usable", gcdOnly
    end
    return "ready", icon, start, duration, countText, true, nil, gcdOnly
end
