local Sounds = ApogeePartyHealthBars_Sounds
local Items = ApogeePartyHealthBars_ShortcutItems

ApogeePartyHealthBars_ActionMacros = {}
local A = ApogeePartyHealthBars_ActionMacros

A.MAX_BODY_BYTES = 255

local function validId(value)
    return type(value) == "number" and value > 0 and math.floor(value) == value and value or nil
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

local function validName(value)
    return type(value) == "string" and value:find("%S") and value or nil
end

function A.BuildDefaultSpellMacro(spellName)
    if type(spellName) ~= "string" or not spellName:find("%S") then return nil end
    return "/targetenemy [noexists][dead][help]\n/startattack\n/cast " .. spellName
end

function A.BuildDefaultItemMacro(itemName)
    if type(itemName) ~= "string" or not itemName:find("%S") then return nil end
    return "/use " .. itemName
end

function A.BuildDefaultMacro(entry)
    if type(entry) ~= "table" then return nil end
    if entry.kind == "item" then return A.BuildDefaultItemMacro(entry.itemName) end
    return A.BuildDefaultSpellMacro(entry.spellName)
end

function A.GetName(entry)
    if type(entry) ~= "table" then return nil end
    return entry.kind == "item" and entry.itemName or entry.spellName
end

function A.ResolveDisplay(entry)
    if type(entry) ~= "table" then return nil, nil, nil, false end
    if entry.kind == "item" then
        local priorDefault = A.BuildDefaultMacro(entry)
        local name, icon, itemId
        if Items then name, icon, itemId = Items.GetInfo(entry.itemId) end
        if name and entry.itemName ~= name then
            local generated = entry.macroText == priorDefault
            entry.itemName = name
            if generated then entry.macroText = A.BuildDefaultMacro(entry) end
        end
        return name or entry.itemName, icon, itemId or entry.itemId,
            Items and Items.GetCount(entry.itemId) > 0 or false
    end

    local identifier = entry.spellId or entry.spellName
    local name, icon, spellId
    if identifier and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(identifier)
        if info then name, icon, spellId = info.name, info.iconID or info.iconFileID, info.spellID end
    end
    if identifier and not name and GetSpellInfo then
        name, _, icon, _, _, _, spellId = GetSpellInfo(identifier)
    end
    return name or entry.spellName, icon, spellId or entry.spellId, name ~= nil
end

function A.CreateSpell(spellId, spellName, soundKey)
    spellId = validId(spellId)
    spellName = validName(spellName) or resolveSpellName(spellId)
    if not validName(spellName) then return nil end
    return {
        kind = "spell",
        spellId = spellId,
        spellName = spellName,
        macroText = A.BuildDefaultSpellMacro(spellName),
        soundKey = Sounds.NormalizeKey(soundKey, "none", true),
    }
end

function A.CreateItem(itemId, itemName, soundKey)
    itemId = validId(itemId)
    if itemId and not validName(itemName) and Items then itemName = Items.GetInfo(itemId) end
    itemName = validName(itemName)
    if not itemId or not itemName then return nil end
    return {
        kind = "item",
        itemId = itemId,
        itemName = itemName,
        macroText = A.BuildDefaultItemMacro(itemName),
        soundKey = Sounds.NormalizeKey(soundKey, "none", true),
    }
end

function A.Normalize(entry)
    if type(entry) ~= "table" or entry.cleared == true then return nil end
    local macroText = type(entry.macroText) == "string" and entry.macroText or nil
    local soundKey = Sounds.NormalizeKey(entry.soundKey, "none", true)
    local isItem = entry.kind == "item" or entry.itemId ~= nil or entry.itemName ~= nil
    local kind = isItem and "item" or "spell"
    if kind == "item" then
        local itemId = validId(entry.itemId)
        local itemName = validName(entry.itemName) or validName(entry.name)
        if itemId and not itemName and Items then itemName = Items.GetInfo(itemId) end
        if not itemId or not validName(itemName) then return nil end
        local normalized = { kind = "item", itemId = itemId, itemName = itemName, soundKey = soundKey }
        normalized.macroText = macroText and macroText:find("%S") and macroText or A.BuildDefaultMacro(normalized)
        return normalized
    end

    local spellId = validId(entry.spellId) or validId(entry.displaySpellId) or validId(entry.id)
    local spellName = validName(entry.spellName) or validName(entry.displaySpellName)
        or validName(entry.name) or resolveSpellName(spellId)
    if not validName(spellName) then return nil end
    local normalized = { kind = "spell", spellId = spellId, spellName = spellName, soundKey = soundKey }
    normalized.macroText = macroText and macroText:find("%S") and macroText or A.BuildDefaultMacro(normalized)
    return normalized
end

function A.Clone(entry)
    local normalized = A.Normalize(entry)
    if not normalized then return nil end
    if normalized.kind == "item" then
        return { kind = "item", itemId = normalized.itemId, itemName = normalized.itemName,
            macroText = normalized.macroText, soundKey = normalized.soundKey }
    end
    return { kind = "spell", spellId = normalized.spellId, spellName = normalized.spellName,
        macroText = normalized.macroText, soundKey = normalized.soundKey }
end

function A.ValidateMacro(entry, body)
    local normalized = A.Normalize(entry)
    if not normalized then return false, "Choose a Spellbook spell or bag item first." end
    if type(body) ~= "string" then return false, "Macro text must be text." end
    if not body:find("%S") then return false, "Macro cannot be blank. Use Clear to remove the action." end
    if #body > A.MAX_BODY_BYTES then
        return false, "Macro exceeds " .. A.MAX_BODY_BYTES .. " bytes."
    end
    return true
end

function A.ResetMacro(entry)
    local normalized = A.Normalize(entry)
    return normalized and A.BuildDefaultMacro(normalized) or nil
end

function A.IsCustomized(entry)
    local normalized = A.Normalize(entry)
    if not normalized then return false end
    return normalized.macroText ~= A.BuildDefaultMacro(normalized)
end
