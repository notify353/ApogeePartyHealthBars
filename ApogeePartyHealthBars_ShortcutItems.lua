ApogeePartyHealthBars_ShortcutItems = {}
local I = ApogeePartyHealthBars_ShortcutItems

local function validItemId(value)
    return type(value) == "number" and value > 0 and math.floor(value) == value and value or nil
end

local function getSpellCooldown(identifier)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(identifier)
        if info then return info.startTime or 0, info.duration or 0 end
    end
    if GetSpellCooldown then
        local start, duration = GetSpellCooldown(identifier)
        return start or 0, duration or 0
    end
    return 0, 0
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

function I.HasUseEffect(itemId)
    itemId = validItemId(itemId)
    if not itemId then return false end
    if C_Item and C_Item.GetItemSpell then return C_Item.GetItemSpell(itemId) ~= nil end
    if GetItemSpell then return GetItemSpell(itemId) ~= nil end
    return true
end

function I.IsGlobalCooldown(start, duration)
    if not duration or duration <= 0 then return false end
    local gcdStart, gcdDuration = getSpellCooldown(61304)
    return gcdDuration > 0
        and math.abs((start or 0) - gcdStart) < 0.05
        and math.abs(duration - gcdDuration) < 0.05
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
