ApogeePartyHealthBars_Sounds = {
    NormalizeKey = function(key)
        if key == "toast" then return key end
        return "none"
    end,
}
function GetSpellInfo(id) if id == 133 then return "Fireball" end end

dofile("ApogeePartyHealthBars_ActionMacros.lua")
local actions = ApogeePartyHealthBars_ActionMacros

local expected = "/targetenemy [noexists][dead][help]\n/startattack\n/cast Fireball(Rank 1)"
assert(actions.BuildDefaultMacro("Fireball(Rank 1)") == expected,
    "shared default action macro changed")
assert(actions.BuildDefaultMacro("") == nil, "blank spell generated a macro")

local created = actions.Create(133, "Fireball(Rank 1)", "toast")
assert(created.spellId == 133 and created.spellName == "Fireball(Rank 1)"
    and created.macroText == expected and created.soundKey == "toast",
    "canonical action creation lost spell metadata")
assert(actions.Create(133, "", "none").spellName == "Fireball",
    "canonical action creation did not recover an empty spell name from its ID")

local migrated = actions.Normalize({
    displaySpellId = 133,
    displaySpellName = "Fireball(Rank 1)",
    macroText = "/cast Custom Fireball",
    soundKey = "toast",
    enabled = false,
})
assert(migrated.spellId == 133 and migrated.spellName == "Fireball(Rank 1)"
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

print("PASS shared action macros")
