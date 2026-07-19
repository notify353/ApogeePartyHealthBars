local Sounds = ApogeePartyHealthBars_Sounds
local Data = ApogeePartyHealthBars_ActionData

ApogeePartyHealthBars_ActionMacros = {}
local A = ApogeePartyHealthBars_ActionMacros

A.MAX_BODY_BYTES = 255

local TARGET_ENEMY = "/targetenemy [noexists][dead][help]"
local MELEE_AUTO_ATTACK_IDS = { [6603] = true }
local RANGED_AUTO_ATTACK_IDS = { [75] = true, [5019] = true }

-- Canonical rank-one or talent spell IDs are used only to resolve the client's
-- localized family name. Assigned ranks are matched by that localized name so
-- the policy does not depend on English text or on enumerating every rank.
local MELEE_ATTACK_FAMILY_IDS = {
    -- Warrior
    78, 845, 772, 1715, 7386, 7384, 6572, 5308, 1464, 1680,
    12294, 23881, 23922, 20243,
    -- Hunter
    2973, 1495, 19306, 2974,
    -- Paladin and Shaman
    35395, 20271, 17364,
}

local STEALTH_SAFE_MELEE_ATTACK_FAMILY_IDS = {
    -- Rogue
    1752, 53, 2098, 1943, 16511, 14278, 5938, 1329, 32645, 8647,
    -- Druid
    1082, 1822, 5221, 33876, 33878, 1079, 22568, 6807, 33745, 779,
}

local function getSpellInfo(identifier)
    if identifier == nil then return nil, nil end
    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        local ok, info = pcall(C_Spell.GetSpellInfo, identifier)
        if ok and info and type(info.name) == "string" and info.name:find("%S") then
            return info.name, info.spellID
        end
    end
    if type(GetSpellInfo) == "function" then
        local ok, name, _, _, _, _, _, spellID = pcall(GetSpellInfo, identifier)
        if ok and type(name) == "string" and name:find("%S") then return name, spellID end
    end
    return nil, nil
end

local function resolveSpellId(spellId, spellName)
    if spellId then return spellId end
    local _, resolvedId = getSpellInfo(spellName)
    return resolvedId
end

local function spellPredicate(name, identifier)
    if identifier == nil or not C_Spell or type(C_Spell[name]) ~= "function" then return false end
    local ok, result = pcall(C_Spell[name], identifier)
    return ok and result == true
end

local function matchesFamily(assignedName, canonicalIds)
    if not assignedName then return false end
    for _, canonicalId in ipairs(canonicalIds) do
        local canonicalName = getSpellInfo(canonicalId)
        if canonicalName and canonicalName == assignedName then return true end
    end
    return false
end

local function classifySpell(spellId, spellName)
    local identifier = spellId or spellName
    local assignedName = getSpellInfo(spellName)
    local idName = spellId and getSpellInfo(spellId) or nil
    -- Saved or imported actions can contain stale or mismatched identity fields.
    -- Never let one spell's ID add attack behavior to a different cast name.
    if not assignedName or (spellId and (not idName or idName ~= assignedName)) then
        return "standard-spell"
    end
    local resolvedId = resolveSpellId(spellId, spellName)
    -- The client predicates are equipment-sensitive, so retain stable IDs for
    -- Auto Shot and wand Shoot after the relevant weapon is unequipped.
    if RANGED_AUTO_ATTACK_IDS[resolvedId] then return "ranged-auto" end
    if MELEE_AUTO_ATTACK_IDS[resolvedId] or spellPredicate("IsAutoAttackSpell", identifier) then
        return "melee-auto"
    end
    if spellPredicate("IsRangedAutoAttackSpell", identifier)
            or spellPredicate("IsAutoRepeatSpell", identifier) then
        return "ranged-auto"
    end
    if matchesFamily(assignedName, STEALTH_SAFE_MELEE_ATTACK_FAMILY_IDS) then
        return "stealth-safe-melee-attack"
    end
    if matchesFamily(assignedName, MELEE_ATTACK_FAMILY_IDS) then return "melee-attack" end
    return "standard-spell"
end

local function renderSpellTemplate(spellName, templateId)
    if type(spellName) ~= "string" or not spellName:find("%S") then return nil end
    if templateId == "melee-auto" then return TARGET_ENEMY .. "\n/startattack" end
    local castLine = "/cast " .. (templateId == "ranged-auto" and "!" or "") .. spellName
    if templateId == "ranged-auto" then return TARGET_ENEMY .. "\n" .. castLine .. "\n/startattack" end
    if templateId == "melee-attack" then
        return TARGET_ENEMY .. "\n/startattack\n" .. castLine
    end
    if templateId == "stealth-safe-melee-attack" then
        return TARGET_ENEMY .. "\n/startattack [nostealth]\n" .. castLine
    end
    return castLine
end

function A.BuildDefaultSpellMacro(spellName, spellId)
    return renderSpellTemplate(spellName, classifySpell(spellId, spellName))
end

function A.GetSpellTemplateId(spellName, spellId)
    if type(spellName) ~= "string" or not spellName:find("%S") then return nil end
    return classifySpell(spellId, spellName)
end

function A.BuildDefaultItemMacro(itemName)
    if type(itemName) ~= "string" or not itemName:find("%S") then return nil end
    return "/use " .. itemName
end

function A.BuildDefaultMacro(entry)
    if type(entry) ~= "table" then return nil end
    if entry.kind == "item" then return A.BuildDefaultItemMacro(entry.itemName) end
    return A.BuildDefaultSpellMacro(entry.spellName, entry.spellId)
end

function A.GetName(entry)
    return Data.GetName(entry)
end

function A.ResolveDisplay(entry)
    local normalized = Data.Normalize(entry)
    if not normalized then return nil, nil, nil, false end
    return Data.ResolveDisplay(entry)
end

function A.CreateSpell(spellId, spellName, soundKey)
    local entry = Data.CreateSpell(spellId, spellName)
    if not entry then return nil end
    entry.macroText = A.BuildDefaultSpellMacro(entry.spellName, entry.spellId)
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

function A.GetTemplateTopics()
    return {
        {
            id = "generated-standard-spell", category = "generated", kind = "template",
            title = "Standard Spell Template",
            explanation = "Casts the exact assigned spell and rank with no added targeting or combat behavior.",
            applied = "New spell assignments in Shortcuts, Keys, Wheel, and Buttons, plus Reset in their macro editors.",
            why = "The neutral default does not retarget, begin combat, break crowd control, or interfere with friendly and utility spells.",
            tradeoffs = "Add channel protection, unit targeting, modifiers, or attack behavior only when the assigned spell benefits from it.",
            body = renderSpellTemplate("Fireball(Rank 1)", "standard-spell"), copyable = true,
        },
        {
            id = "generated-melee-attack", category = "generated", kind = "template",
            title = "Melee Combat Ability",
            explanation = "Acquires an enemy only when necessary, keeps auto-attack running, and casts the exact assigned ability and rank.",
            applied = "New assignments and Reset for explicitly reviewed Warrior, Hunter-melee, Paladin, and Shaman combat families.",
            why = "The weapon swing continues even when the ability cannot fire because of resources, stance, range, or cooldown.",
            tradeoffs = "Only curated weapon abilities receive this behavior; uncertain, control, movement, and utility actions remain direct casts.",
            body = renderSpellTemplate("Heroic Strike(Rank 1)", "melee-attack"), copyable = true,
        },
        {
            id = "generated-stealth-safe-melee", category = "generated", kind = "template",
            title = "Stealth-Safe Melee Ability",
            explanation = "Uses the melee combat template but starts auto-attack only while the player is not stealthed.",
            applied = "New assignments and Reset for explicitly reviewed Rogue and Feral Druid combat families.",
            why = "A failed ability press cannot waste Stealth or Prowl; a successful ability breaks stealth through its normal game behavior.",
            tradeoffs = "Stealth openers and control abilities remain direct casts and are not included in this family.",
            body = renderSpellTemplate("Sinister Strike(Rank 1)", "stealth-safe-melee-attack"), copyable = true,
        },
        {
            id = "generated-melee-auto", category = "generated", kind = "template",
            title = "Melee Auto-Attack",
            explanation = "Keeps a living hostile target or acquires one when needed, then starts melee auto-attack without toggling it off.",
            applied = "New assignments of WoW's melee Attack action, plus Reset.",
            why = "Attack is the one spell family where target acquisition and /startattack are always the requested behavior.",
            tradeoffs = "It intentionally engages a target and contains no cast command.",
            body = renderSpellTemplate("Attack", "melee-auto"), copyable = true,
        },
        {
            id = "generated-ranged-auto", category = "generated", kind = "template",
            title = "Spam-Safe Ranged Auto-Attack",
            explanation = "Uses ! to start Auto Shot, wand Shoot, and other client-confirmed repeating attacks without toggling them off when the binding is spammed.",
            applied = "New Auto Shot, Shoot, or client-confirmed ranged auto-attack assignments, plus Reset.",
            why = "The exclamation prefix preserves the repeating attack, while /startattack provides a melee fallback at close range.",
            tradeoffs = "The melee fallback can engage a nearby target when the ranged attack cannot fire; remove /startattack in a custom macro if that is unwanted.",
            body = renderSpellTemplate("Auto Shot", "ranged-auto"), copyable = true,
        },
        {
            id = "generated-item", category = "generated", kind = "template",
            title = "Item Template",
            explanation = "Uses the localized item name through WoW's /use command.",
            applied = "New bag-item assignments in Shortcuts, Keys, Wheel, and Buttons, plus Reset.",
            why = "A direct /use line preserves normal item targeting, cooldown, and inventory behavior.",
            tradeoffs = "Items that need a unit, cursor, modifier, or equipment slot require a custom macro.",
            body = A.BuildDefaultItemMacro("Linen Bandage"), copyable = true,
        },
    }
end
