ApogeePartyHealthBars_Sounds = {
    NormalizeKey = function(key)
        if key == "toast" then return key end
        return "none"
    end,
}
function GetSpellInfo(id) if id == 133 then return "Fireball" end end
ApogeePartyHealthBars_ShortcutItems = {
    GetInfo = function(id) if id == 1251 then return "Linen Bandage", 134436 end end,
    GetCount = function(id) return id == 1251 and 1 or 0 end,
}

dofile("ApogeePartyHealthBars_ActionMacros.lua")
local actions = ApogeePartyHealthBars_ActionMacros

local expected = "/targetenemy [noexists][dead][help]\n/startattack\n/cast Fireball(Rank 1)"
assert(actions.BuildDefaultSpellMacro("Fireball(Rank 1)") == expected,
    "shared default action macro changed")
assert(actions.BuildDefaultSpellMacro("") == nil, "blank spell generated a macro")

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

print("PASS shared action macros")
