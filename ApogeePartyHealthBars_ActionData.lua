local Items = ApogeePartyHealthBars_ShortcutItems

ApogeePartyHealthBars_ActionData = {}
local A = ApogeePartyHealthBars_ActionData

local function validId(value)
    return type(value) == "number" and value > 0 and math.floor(value) == value and value or nil
end

local function validName(value)
    return type(value) == "string" and value:find("%S") and value or nil
end

local function resolveSpellName(spellId)
    if not spellId then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellId)
        if info and info.name then return info.name end
    end
    if GetSpellInfo then return GetSpellInfo(spellId) end
    return nil
end

function A.CreateSpell(spellId, spellName)
    spellId = validId(spellId)
    spellName = validName(spellName) or resolveSpellName(spellId)
    if not validName(spellName) then return nil end
    return {
        kind = "spell",
        spellId = spellId,
        spellName = spellName,
    }
end

function A.CreateItem(itemId, itemName)
    itemId = validId(itemId)
    if itemId and not validName(itemName) and Items and Items.GetInfo then
        itemName = Items.GetInfo(itemId)
    end
    itemName = validName(itemName)
    if not itemId or not itemName then return nil end
    return {
        kind = "item",
        itemId = itemId,
        itemName = itemName,
    }
end

function A.Normalize(entry)
    if type(entry) == "number" then return A.CreateSpell(entry) end
    if type(entry) == "string" then return A.CreateSpell(nil, entry) end
    if type(entry) ~= "table" or entry.cleared == true then return nil end
    if entry.kind ~= nil and entry.kind ~= "spell" and entry.kind ~= "item" then return nil end

    local isItem = entry.kind == "item" or entry.itemId ~= nil or entry.itemName ~= nil
    if isItem then
        return A.CreateItem(validId(entry.itemId), validName(entry.itemName) or validName(entry.name))
    end

    return A.CreateSpell(
        validId(entry.spellId) or validId(entry.displaySpellId) or validId(entry.id),
        validName(entry.spellName) or validName(entry.displaySpellName) or validName(entry.name))
end

function A.Clone(entry)
    local normalized = A.Normalize(entry)
    if not normalized then return nil end
    if normalized.kind == "item" then
        return A.CreateItem(normalized.itemId, normalized.itemName)
    end
    return A.CreateSpell(normalized.spellId, normalized.spellName)
end

function A.GetName(entry)
    local normalized = A.Normalize(entry)
    if not normalized then return nil end
    return normalized.kind == "item" and normalized.itemName or normalized.spellName
end

function A.ResolveDisplay(entry)
    local normalized = A.Normalize(entry)
    if not normalized then return nil, nil, nil, false end

    if normalized.kind == "item" then
        local name, icon, itemId
        if Items and Items.GetInfo then name, icon, itemId = Items.GetInfo(normalized.itemId) end
        if name and type(entry) == "table" then entry.itemName = name end
        local available = Items and Items.GetCount and Items.GetCount(normalized.itemId) > 0 or false
        return name or normalized.itemName, icon, itemId or normalized.itemId,
            available
    end

    local identifier = normalized.spellId or normalized.spellName
    local name, icon, spellId
    if identifier and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(identifier)
        if info then name, icon, spellId = info.name, info.iconID or info.iconFileID, info.spellID end
    end
    if identifier and not name and GetSpellInfo then
        name, _, icon, _, _, _, spellId = GetSpellInfo(identifier)
    end
    return name or normalized.spellName, icon, spellId or normalized.spellId, name ~= nil
end
