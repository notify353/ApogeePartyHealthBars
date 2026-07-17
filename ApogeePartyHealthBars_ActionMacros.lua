local Sounds = ApogeePartyHealthBars_Sounds
local Data = ApogeePartyHealthBars_ActionData

ApogeePartyHealthBars_ActionMacros = {}
local A = ApogeePartyHealthBars_ActionMacros

A.MAX_BODY_BYTES = 255

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
    return Data.GetName(entry)
end

function A.ResolveDisplay(entry)
    local normalized = Data.Normalize(entry)
    if not normalized then return nil, nil, nil, false end
    if normalized.kind == "item" then
        local priorDefault = A.BuildDefaultMacro(normalized)
        local priorName = entry.itemName
        local name, icon, itemId, available = Data.ResolveDisplay(entry)
        if name and priorName ~= name then
            local generated = entry.macroText == priorDefault
            if generated then entry.macroText = A.BuildDefaultMacro(entry) end
        end
        return name, icon, itemId, available
    end
    return Data.ResolveDisplay(entry)
end

function A.CreateSpell(spellId, spellName, soundKey)
    local entry = Data.CreateSpell(spellId, spellName)
    if not entry then return nil end
    entry.macroText = A.BuildDefaultSpellMacro(entry.spellName)
    entry.soundKey = Sounds.NormalizeKey(soundKey, "none", true)
    return entry
end

function A.CreateItem(itemId, itemName, soundKey)
    local entry = Data.CreateItem(itemId, itemName)
    if not entry then return nil end
    entry.macroText = A.BuildDefaultItemMacro(entry.itemName)
    entry.soundKey = Sounds.NormalizeKey(soundKey, "none", true)
    return entry
end

function A.Normalize(entry)
    local normalized = Data.Normalize(entry)
    if not normalized then return nil end
    local source = type(entry) == "table" and entry or {}
    local macroText = type(source.macroText) == "string" and source.macroText or nil
    local soundKey = Sounds.NormalizeKey(source.soundKey, "none", true)
    normalized.soundKey = soundKey
    normalized.macroText = macroText and macroText:find("%S") and macroText or A.BuildDefaultMacro(normalized)
    return normalized
end

function A.Clone(entry)
    local normalized = A.Normalize(entry)
    if not normalized then return nil end
    local clone = Data.Clone(normalized)
    clone.macroText = normalized.macroText
    clone.soundKey = normalized.soundKey
    return clone
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
