ApogeePartyHealthBars_Sounds = {
    NormalizeKey = function(key)
        if key == "toast" then return key end
        return "none"
    end,
}
function GetSpellInfo(id) if id == 133 then return "Fireball" end end
C_Spell = {
    GetSpellInfo = function(identifier)
        local names = { [133] = "Fireball", [15407] = "Mind Flay", [5019] = "Shoot", [75] = "Auto Shot", [6603] = "Attack" }
        local ids = { Fireball = 133, ["Mind Flay"] = 15407, Shoot = 5019, ["Auto Shot"] = 75, Attack = 6603 }
        local spellID = type(identifier) == "number" and identifier or ids[identifier]
        local name = names[spellID]
        return name and { name = name, spellID = spellID } or nil
    end,
    IsRangedAutoAttackSpell = function() return false end,
    IsAutoRepeatSpell = function() return false end,
    IsAutoAttackSpell = function() return false end,
}
ApogeePartyHealthBars_ShortcutItems = {
    GetInfo = function(id) if id == 1251 then return "Linen Bandage", 134436 end end,
    GetCount = function(id) return id == 1251 and 1 or 0 end,
}

dofile("ApogeePartyHealthBars_ActionData.lua")
dofile("ApogeePartyHealthBars_ActionMacros.lua")
local actions = ApogeePartyHealthBars_ActionMacros

local expected = "/cast [nochanneling:Fireball] Fireball(Rank 1)"
assert(actions.BuildDefaultSpellMacro("Fireball(Rank 1)", 133) == expected,
    "shared default action macro changed")
assert(actions.BuildDefaultSpellMacro("") == nil, "blank spell generated a macro")

local mindFlay = actions.CreateSpell(15407, "Mind Flay(Rank 1)", "none")
assert(mindFlay.macroText
    == "/cast [nochanneling:Mind Flay] Mind Flay(Rank 1)",
    "channel spell did not use its localized base name for self-channel protection")
local shoot = actions.CreateSpell(5019, "Shoot", "none")
assert(shoot.macroText
    == "/targetenemy [noexists][dead][help]\n/castsequence [nochanneling:Shoot] reset=target/2 !Shoot, null\n/startattack",
    "ranged auto-attack was not spam-safe with a melee fallback")
local autoShot = actions.CreateSpell(75, "Auto Shot", "none")
assert(autoShot.macroText
    == "/targetenemy [noexists][dead][help]\n/cast [nochanneling:Auto Shot] !Auto Shot\n/startattack",
    "Auto Shot was not classified as a ranged auto-attack")
assert(actions.BuildDefaultSpellMacro("Shoot", nil):find("castsequence", 1, true),
    "name-only Shoot was not protected when the client predicate returned false")
assert(actions.CreateSpell(6603, "Attack", "none").macroText
    == "/targetenemy [noexists][dead][help]\n/startattack",
    "melee Attack did not receive its dedicated non-toggle template")
assert(actions.GetSpellTemplateId("Fireball(Rank 1)", 133) == "standard-spell"
        and actions.GetSpellTemplateId("Shoot", 5019) == "wand-shoot"
        and actions.GetSpellTemplateId("Auto Shot", 75) == "ranged-auto"
        and actions.GetSpellTemplateId("Attack", 6603) == "melee-auto",
    "spell template classification lost a smart macro family")

local created = actions.CreateSpell(133, "Fireball(Rank 1)", "toast")
assert(created.kind == "spell" and created.spellId == 133 and created.spellName == "Fireball(Rank 1)"
    and created.macroText == expected and created.soundKey == "toast",
    "canonical action creation lost spell metadata")
assert(actions.CreateSpell(133, "", "none").spellName == "Fireball",
    "canonical action creation did not recover an empty spell name from its ID")

local item = actions.CreateItem(1251, nil, "toast")
assert(item.kind == "item" and item.itemId == 1251 and item.itemName == "Linen Bandage"
    and item.macroText == "/use Linen Bandage" and item.soundKey == "toast",
    "typed item creation lost item metadata")
assert(actions.BuildDefaultMacro(item) == "/use Linen Bandage", "item default macro changed")
local renamedGenerated = actions.CreateItem(1251, "Old Bandage", "none")
assert(actions.ResolveDisplay(renamedGenerated) == "Linen Bandage"
    and renamedGenerated.itemName == "Linen Bandage"
    and renamedGenerated.macroText == "/use Linen Bandage",
    "localized item display resolution did not refresh its generated macro")
local renamedCustom = actions.CreateItem(1251, "Old Bandage", "none")
renamedCustom.macroText = "/use [@player] Old Bandage"
actions.ResolveDisplay(renamedCustom)
assert(renamedCustom.itemName == "Linen Bandage"
    and renamedCustom.macroText == "/use [@player] Old Bandage",
    "localized item display resolution overwrote a customized macro")

local migrated = actions.Normalize({
    displaySpellId = 133,
    displaySpellName = "Fireball(Rank 1)",
    macroText = "/cast Custom Fireball",
    soundKey = "toast",
    enabled = false,
})
assert(migrated.kind == "spell" and migrated.spellId == 133 and migrated.spellName == "Fireball(Rank 1)"
    and migrated.macroText == "/cast Custom Fireball" and migrated.enabled == nil,
    "legacy action did not normalize without losing its custom macro")
local priorGenerated = "/targetenemy [noexists][dead][help]\n/startattack\n/cast Fireball(Rank 1)"
local preservedGenerated = actions.Normalize({ spellId = 133, spellName = "Fireball(Rank 1)", macroText = priorGenerated })
assert(preservedGenerated.macroText == priorGenerated,
    "existing generated macro was silently upgraded instead of waiting for Reset")
local recovered = actions.Normalize({
    spellId = 0, spellName = "", displaySpellId = 133,
    displaySpellName = "Fireball(Rank 1)", macroText = "/cast Recovered",
})
assert(recovered.spellId == 133 and recovered.spellName == "Fireball(Rank 1)"
    and recovered.macroText == "/cast Recovered",
    "malformed canonical fields masked valid legacy migration fields")

assert(actions.ValidateMacro(created, expected))
assert(not actions.ValidateMacro(created, "  \n\t"), "blank macro was accepted")
assert(not actions.ValidateMacro(created, string.rep("x", 256)), "oversized macro was accepted")
assert(not actions.IsCustomized(created), "generated macro was marked custom")
created.macroText = "/cast Custom Fireball"
assert(actions.IsCustomized(created), "custom macro was not detected")
assert(actions.ResetMacro(created) == expected, "macro reset did not rebuild the default")
item.macroText = "/use [@player] Linen Bandage"
local itemClone = actions.Clone(item)
assert(itemClone.kind == "item" and itemClone.macroText == item.macroText,
    "item clone lost its customized macro")
assert(actions.IsCustomized(item), "custom item macro was not detected")
assert(actions.ResetMacro(item) == "/use Linen Bandage", "item macro reset did not rebuild the default")

local topics = actions.GetTemplateTopics()
assert(#topics == 6 and topics[1].body == expected,
    "generated-template documentation drifted from the runtime renderer")
assert(topics[2].body:find("[nochanneling:Mind Flay]", 1, true)
    and topics[3].body == "/targetenemy [noexists][dead][help]\n/startattack"
    and topics[4].body:find("!Auto Shot", 1, true)
    and topics[5].body:find("castsequence", 1, true)
    and topics[6].body == "/use Linen Bandage",
    "generated-template catalog omitted a smart macro family")

print("PASS shared action macros")
