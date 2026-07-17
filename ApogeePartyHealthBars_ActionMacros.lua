local Sounds = ApogeePartyHealthBars_Sounds

ApogeePartyHealthBars_ActionMacros = {}
local A = ApogeePartyHealthBars_ActionMacros

A.MAX_BODY_BYTES = 255

local function validSpellId(value)
    return type(value) == "number" and value > 0 and value or nil
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

local function validSpellName(value)
    return type(value) == "string" and value:find("%S") and value or nil
end

function A.BuildDefaultMacro(spellName)
    if type(spellName) ~= "string" or not spellName:find("%S") then return nil end
    return "/targetenemy [noexists][dead][help]\n/startattack\n/cast " .. spellName
end

function A.Create(spellId, spellName, soundKey)
    spellId = validSpellId(spellId)
    spellName = validSpellName(spellName) or resolveSpellName(spellId)
    if not validSpellName(spellName) then return nil end
    return {
        spellId = spellId,
        spellName = spellName,
        macroText = A.BuildDefaultMacro(spellName),
        soundKey = Sounds.NormalizeKey(soundKey, "none", true),
    }
end

function A.Normalize(entry)
    if type(entry) ~= "table" or entry.cleared == true then return nil end
    local spellId = validSpellId(entry.spellId)
        or validSpellId(entry.displaySpellId) or validSpellId(entry.id)
    local spellName = validSpellName(entry.spellName)
        or validSpellName(entry.displaySpellName) or validSpellName(entry.name)
        or resolveSpellName(spellId)
    if not validSpellName(spellName) then return nil end
    local macroText = type(entry.macroText) == "string" and entry.macroText or nil
    if not macroText or not macroText:find("%S") then macroText = A.BuildDefaultMacro(spellName) end
    return {
        spellId = spellId,
        spellName = spellName,
        macroText = macroText,
        soundKey = Sounds.NormalizeKey(entry.soundKey, "none", true),
    }
end

function A.Clone(entry)
    local normalized = A.Normalize(entry)
    if not normalized then return nil end
    return {
        spellId = normalized.spellId,
        spellName = normalized.spellName,
        macroText = normalized.macroText,
        soundKey = normalized.soundKey,
    }
end

function A.ValidateMacro(entry, body)
    local normalized = A.Normalize(entry)
    if not normalized then return false, "Choose a Spellbook spell first." end
    if type(body) ~= "string" then return false, "Macro text must be text." end
    if not body:find("%S") then return false, "Macro cannot be blank. Use Clear to remove the action." end
    if #body > A.MAX_BODY_BYTES then
        return false, "Macro exceeds " .. A.MAX_BODY_BYTES .. " bytes."
    end
    return true
end

function A.ResetMacro(entry)
    local normalized = A.Normalize(entry)
    return normalized and A.BuildDefaultMacro(normalized.spellName) or nil
end

function A.IsCustomized(entry)
    local normalized = A.Normalize(entry)
    if not normalized then return false end
    return normalized.macroText ~= A.BuildDefaultMacro(normalized.spellName)
end
