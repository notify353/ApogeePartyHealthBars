local Sounds = ApogeePartyHealthBars_Sounds
local Data = ApogeePartyHealthBars_ActionData

ApogeePartyHealthBars_ActionMacros = {}
local A = ApogeePartyHealthBars_ActionMacros

A.MAX_BODY_BYTES = 255

local TARGET_ENEMY = "/targetenemy [noexists][dead][help]"
local MELEE_AUTO_ATTACK_IDS = { [6603] = true }
local AUTO_SHOT_IDS = { [75] = true }
local WAND_SHOOT_IDS = { [5019] = true }

local function fallbackBaseName(spellName)
    if type(spellName) ~= "string" then return nil end
    return spellName:match("^(.-)%s*%([^()]+%)$") or spellName
end

local function resolveBaseName(spellId, spellName)
    local identifier = spellId or spellName
    if identifier and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(identifier)
        if info and type(info.name) == "string" and info.name:find("%S") then return info.name end
    end
    return fallbackBaseName(spellName)
end

local function resolveSpellId(spellId, spellName)
    if spellId then return spellId end
    if spellName and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellName)
        return info and info.spellID
    end
end

local function spellPredicate(name, identifier)
    return identifier ~= nil and C_Spell and type(C_Spell[name]) == "function"
        and C_Spell[name](identifier) == true
end

local function classifySpell(spellId, spellName)
    local identifier = spellId or spellName
    local resolvedId = resolveSpellId(spellId, spellName)
    -- The client predicate is equipment-sensitive and returns false for Shoot
    -- when a wand is not currently equipped, even though the assignment must
    -- remain spam-safe after the player equips one.
    if WAND_SHOOT_IDS[resolvedId] then return "wand-shoot" end
    if AUTO_SHOT_IDS[resolvedId] then return "ranged-auto" end
    if MELEE_AUTO_ATTACK_IDS[resolvedId] or spellPredicate("IsAutoAttackSpell", identifier) then
        return "melee-auto"
    end
    if spellPredicate("IsRangedAutoAttackSpell", identifier)
            or spellPredicate("IsAutoRepeatSpell", identifier) then
        return "ranged-auto"
    end
    return "standard-spell"
end

local function renderSpellTemplate(spellName, baseName, templateId)
    if type(spellName) ~= "string" or not spellName:find("%S") then return nil end
    baseName = type(baseName) == "string" and baseName:find("%S") and baseName or fallbackBaseName(spellName)
    if templateId == "melee-auto" then return TARGET_ENEMY .. "\n/startattack" end
    if templateId == "wand-shoot" then
        return TARGET_ENEMY .. "\n/castsequence [nochanneling:" .. baseName
            .. "] reset=target/2 !" .. spellName .. ", null\n/startattack"
    end
    local castLine = "/cast [nochanneling:" .. baseName .. "] "
        .. (templateId == "ranged-auto" and "!" or "") .. spellName
    if templateId == "ranged-auto" then return TARGET_ENEMY .. "\n" .. castLine .. "\n/startattack" end
    return castLine
end

function A.BuildDefaultSpellMacro(spellName, spellId)
    return renderSpellTemplate(spellName, resolveBaseName(spellId, spellName),
        classifySpell(spellId, spellName))
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
            explanation = "Casts the assigned spell without clipping another cast of that same spell while it is channeling.",
            applied = "New spell assignments in Shortcuts, Keys, and Wheel, plus Reset in their macro editors.",
            why = "The neutral default does not retarget, begin combat, break crowd control, or interfere with friendly and utility spells.",
            tradeoffs = "Add explicit target, mouseover, focus, or attack behavior in a custom macro when the spell needs it.",
            body = renderSpellTemplate("Fireball(Rank 1)", "Fireball", "standard-spell"), copyable = true,
        },
        {
            id = "generated-channel-spell", category = "generated", kind = "template",
            title = "Channel-Safe Spell Example",
            explanation = "Shows the standard template applied to Mind Flay. Spamming the same binding cannot restart Mind Flay before its current channel finishes.",
            applied = "Automatically through the standard spell template; no channel-spell catalog or manual option is required.",
            why = "The spell-specific nochanneling condition protects the active channel while allowing a different ability to interrupt it normally.",
            tradeoffs = "This protects only Mind Flay from itself and prevents queuing another Mind Flay during the active channel.",
            body = renderSpellTemplate("Mind Flay(Rank 7)", "Mind Flay", "standard-spell"), copyable = true,
        },
        {
            id = "generated-melee-auto", category = "generated", kind = "template",
            title = "Melee Auto-Attack",
            explanation = "Keeps a living hostile target or acquires one when needed, then starts melee auto-attack without toggling it off.",
            applied = "New assignments of WoW's melee Attack action, plus Reset.",
            why = "Attack is the one spell family where target acquisition and /startattack are always the requested behavior.",
            tradeoffs = "It intentionally engages a target and contains no cast command.",
            body = renderSpellTemplate("Attack", "Attack", "melee-auto"), copyable = true,
        },
        {
            id = "generated-ranged-auto", category = "generated", kind = "template",
            title = "Spam-Safe Auto Shot",
            explanation = "Uses ! to start Auto Shot and other client-confirmed ranged auto-attacks without toggling them off when the binding is spammed.",
            applied = "New Auto Shot or client-confirmed ranged auto-attack assignments, plus Reset.",
            why = "The exclamation prefix preserves the repeating attack, while /startattack provides a melee fallback at close range.",
            tradeoffs = "The melee fallback can engage a nearby target when the ranged attack cannot fire; remove /startattack in a custom macro if that is unwanted.",
            body = renderSpellTemplate("Auto Shot", "Auto Shot", "ranged-auto"), copyable = true,
        },
        {
            id = "generated-wand-shoot", category = "generated", kind = "template",
            title = "Spam-Safe Wand Shoot",
            explanation = "Starts Shoot once, then holds the sequence on an intentionally invalid step while the key is spammed so another press cannot toggle wand fire off.",
            applied = "New assignments of the wand Shoot spell, plus Reset.",
            why = "Classic clients have handled !Shoot inconsistently; the short target-or-time reset is the established wand-specific safeguard.",
            tradeoffs = "After Shoot starts, release the key for two seconds or change targets before starting it again. Use a custom !Shoot macro if the current client proves reliable with it.",
            body = renderSpellTemplate("Shoot", "Shoot", "wand-shoot"), copyable = true,
        },
        {
            id = "generated-item", category = "generated", kind = "template",
            title = "Item Template",
            explanation = "Uses the localized item name through WoW's /use command.",
            applied = "New bag-item assignments in Shortcuts, Keys, and Wheel, plus Reset.",
            why = "A direct /use line preserves normal item targeting, cooldown, and inventory behavior.",
            tradeoffs = "Items that need a unit, cursor, modifier, or equipment slot require a custom macro.",
            body = A.BuildDefaultItemMacro("Linen Bandage"), copyable = true,
        },
    }
end
