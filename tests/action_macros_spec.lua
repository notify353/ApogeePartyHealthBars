ApogeePartyHealthBars_Sounds = {
    NormalizeKey = function(key)
        if key == "toast" then return key end
        return "none"
    end,
}
local normalMeleeFamilies = {
    { 78, "Heroic Strike" }, { 845, "Cleave" }, { 772, "Rend" },
    { 1715, "Hamstring" }, { 7386, "Sunder Armor" }, { 7384, "Overpower" },
    { 6572, "Revenge" }, { 5308, "Execute" }, { 1464, "Slam" },
    { 1680, "Whirlwind" }, { 12294, "Mortal Strike" }, { 23881, "Bloodthirst" },
    { 23922, "Shield Slam" }, { 20243, "Devastate" },
    { 100, "Charge" }, { 20252, "Intercept" },
    { 6343, "Thunder Clap" }, { 72, "Shield Bash" }, { 6552, "Pummel" },
    { 694, "Mocking Blow" }, { 12809, "Concussion Blow" }, { 34428, "Victory Rush" },
    { 2973, "Raptor Strike" }, { 1495, "Mongoose Bite" },
    { 19306, "Counterattack" }, { 2974, "Wing Clip" },
    { 35395, "Crusader Strike" }, { 17364, "Stormstrike" },
}
local distanceFamilies = { { 20271, "Judgement" } }
local stealthSafeFamilies = {
    { 1752, "Sinister Strike" }, { 53, "Backstab" }, { 2098, "Eviscerate" },
    { 1943, "Rupture" }, { 16511, "Hemorrhage" }, { 14278, "Ghostly Strike" },
    { 5938, "Shiv" }, { 1329, "Mutilate" }, { 32645, "Envenom" },
    { 8647, "Expose Armor" }, { 1082, "Claw" }, { 1822, "Rake" },
    { 5221, "Shred" }, { 33876, "Mangle (Cat)" }, { 33878, "Mangle (Bear)" },
    { 1079, "Rip" }, { 22568, "Ferocious Bite" }, { 6807, "Maul" },
    { 33745, "Lacerate" }, { 779, "Swipe" }, { 16979, "Feral Charge" },
}
local excludedFamilies = {
    { 14914, "Holy Fire" }, { 6770, "Sap" }, { 1776, "Gouge" },
    { 1833, "Cheap Shot" }, { 408, "Kidney Shot" },
    { 1766, "Kick" }, { 118, "Polymorph" },
    { 1784, "Stealth" }, { 5215, "Prowl" },
    { 8676, "Ambush" }, { 703, "Garrote" }, { 6785, "Ravage" }, { 9005, "Pounce" },
    { 6673, "Battle Shout" }, { 2061, "Flash Heal" },
    { 4987, "Cleanse" }, { 355, "Taunt" }, { 2649, "Growl" },
    { 3044, "Arcane Shot" }, { 19434, "Aimed Shot" }, { 2643, "Multi-Shot" },
    { 34120, "Steady Shot" }, { 1978, "Serpent Sting" }, { 17253, "Bite" },
    { 10, "Blizzard" },
}
local warriorShieldRequiredFamilies = {
    { 72, "Shield Bash" },
    { 871, "Shield Wall" },
    { 2565, "Shield Block" },
    { 20243, "Devastate" },
    { 23920, "Spell Reflection" },
    { 23922, "Shield Slam" },
}
local standardShieldRequiredFamilies = {
    { 20925, "Holy Shield" },
    { 31935, "Avenger's Shield" },
}
local spellNames = {
    [133] = "Fireball", [15407] = "Mind Flay", [5019] = "Shoot",
    [75] = "Auto Shot", [6603] = "Attack",
}
for _, family in ipairs(normalMeleeFamilies) do spellNames[family[1]] = family[2] end
for _, family in ipairs(distanceFamilies) do spellNames[family[1]] = family[2] end
for _, family in ipairs(stealthSafeFamilies) do spellNames[family[1]] = family[2] end
for _, family in ipairs(excludedFamilies) do spellNames[family[1]] = family[2] end
for _, family in ipairs(warriorShieldRequiredFamilies) do spellNames[family[1]] = family[2] end
for _, family in ipairs(standardShieldRequiredFamilies) do spellNames[family[1]] = family[2] end
local function spellIdByName(name)
    if type(name) == "string" then
        name = name:gsub("%s*%(Rank %d+%)$", ""):gsub("%s*%(Rango %d+%)$", "")
    end
    for id, knownName in pairs(spellNames) do
        if knownName == name then return id end
    end
end
-- Independent rank data keeps the production canonical table from defining its
-- own expected names: 14271 is Mongoose Bite, not Ghostly Strike.
spellNames[14271] = "Mongoose Bite"
function GetSpellInfo(identifier)
    local id = type(identifier) == "number" and identifier or spellIdByName(identifier)
    local name = spellNames[id]
    if name then return name, nil, nil, nil, nil, nil, id end
end
C_Spell = {
    GetSpellInfo = function(identifier)
        local spellID = type(identifier) == "number" and identifier or spellIdByName(identifier)
        local name = spellNames[spellID]
        return name and { name = name, spellID = spellID } or nil
    end,
    IsRangedAutoAttackSpell = function() return false end,
    IsAutoRepeatSpell = function() return false end,
    IsAutoAttackSpell = function() return false end,
}
ApogeePartyHealthBars_ShortcutItems = {
    GetInfo = function(id) if id == 1251 then return "Linen Bandage", 134436 end end,
    GetCount = function(id) return id == 1251 and 1 or 0 end,
    IsPlayerGroundExplosive = function(id) return id == 4358 end,
}
dofile("Actions/ActionData.lua")
dofile("Actions/ActionMacros.lua")
local actions = ApogeePartyHealthBars_ActionMacros

local expected = "/use Fireball(Rank 1)"
assert(actions.BuildDefaultSpellMacro("Fireball(Rank 1)", 133) == expected,
    "shared default action macro changed")
assert(actions.BuildDefaultSpellMacro("") == nil, "blank spell generated a macro")

local mindFlay = actions.CreateSpell(15407, "Mind Flay(Rank 1)", "none")
assert(mindFlay.macroText
    == "/use Mind Flay(Rank 1)",
    "ordinary spell received an unexpected generated condition")
local shoot = actions.CreateSpell(5019, "Shoot", "none")
assert(shoot.macroText
    == "/targetenemy\n/use !Shoot",
    "ranged auto-attack was not spam-safe with unconditional enemy targeting")
local autoShot = actions.CreateSpell(75, "Auto Shot", "none")
assert(autoShot.macroText
    == "/targetenemy\n/use !Auto Shot",
    "Auto Shot was not classified as a ranged auto-attack")
assert(actions.BuildDefaultSpellMacro("Shoot", nil)
        == "/targetenemy\n/use !Shoot",
    "name-only Shoot was not protected when the client predicate returned false")
assert(actions.CreateSpell(6603, "Attack", "none").macroText
    == "/startattack",
    "melee Attack did not receive its dedicated non-toggle template")
assert(actions.GetSpellTemplateId("Fireball(Rank 1)", 133) == "standard-spell"
        and actions.GetSpellTemplateId("Shoot", 5019) == "ranged-auto"
        and actions.GetSpellTemplateId("Auto Shot", 75) == "ranged-auto"
        and actions.GetSpellTemplateId("Judgement", 20271) == "distance-attack"
        and actions.GetSpellTemplateId("Attack", 6603) == "melee-auto",
    "spell template classification lost a smart macro family")

local targetPrefix = "/targetenemy\n/use "
local attackPrefix = "/startattack\n/use "
for _, family in ipairs(normalMeleeFamilies) do
    local castName = family[2] .. "(Rank 9)"
    local templateId = family[1] == 100
        and "warrior-charge-hamstring" or "melee-attack"
    local expectedMacro = family[1] == 100
        and "/startattack\n/use [combat] Hamstring; " .. castName
        or attackPrefix .. castName
    assert(actions.GetSpellTemplateId(castName, family[1]) == templateId,
        family[2] .. " did not receive the curated melee policy")
    assert(actions.BuildDefaultSpellMacro(castName, family[1]) == expectedMacro,
        family[2] .. " lost target, attack, cast, or rank behavior")
end

for _, family in ipairs(distanceFamilies) do
    local useName = family[2] .. "(Rank 9)"
    assert(actions.GetSpellTemplateId(useName, family[1]) == "distance-attack"
            and actions.BuildDefaultSpellMacro(useName, family[1])
                == targetPrefix .. useName,
        family[2] .. " did not receive the reviewed distance policy")
end

local charge = actions.CreateSpell(100, "Charge(Rank 2)", "none")
assert(charge.macroText
        == "/startattack\n/use [combat] Hamstring; Charge(Rank 2)",
    "Charge did not generate the contextual Hamstring template")
local affectingCombat = false
function UnitAffectingCombat() return affectingCombat end
spellNames[7372] = "Hamstring"
ApogeePartyHealthBars_PlayerSpells = {
    BuildKnownSpellMap = function()
        return { [7372] = { id = 7372, name = "Hamstring(Rank 3)", baseName = "Hamstring" } }, {
            Hamstring = { id = 7372, name = "Hamstring(Rank 3)", baseName = "Hamstring" },
        }
    end,
}
local activeName, _, activeId, _, contextual = actions.ResolveRuntimeSpell(charge)
assert(activeName == "Charge" and activeId == 100 and not contextual,
    "contextual Charge did not remain the active out-of-combat HUD spell")
affectingCombat = true
activeName, _, activeId, _, contextual = actions.ResolveRuntimeSpell(charge)
assert(activeName == "Hamstring" and activeId == 7372 and contextual,
    "contextual Charge did not resolve the highest learned in-combat Hamstring")
charge.macroText = "/cast [mod:shift] Charge(Rank 2)"
activeName, _, activeId, _, contextual = actions.ResolveRuntimeSpell(charge)
assert(activeName == "Charge" and activeId == 100 and not contextual,
    "custom Charge macro was treated as a generated contextual action")
affectingCombat = false

local stealthPrefix = "/startattack [nostealth]\n/use "
for _, family in ipairs(stealthSafeFamilies) do
    local castName = family[2] .. "(Rank 9)"
    assert(actions.GetSpellTemplateId(castName, family[1]) == "stealth-safe-melee-attack",
        family[2] .. " did not receive the stealth-safe melee policy")
    assert(actions.BuildDefaultSpellMacro(castName, family[1]) == stealthPrefix .. castName,
        family[2] .. " lost stealth-safe attack or rank behavior")
end
assert(actions.BuildDefaultSpellMacro("Mongoose Bite(Rank 4)", 14271)
    == attackPrefix .. "Mongoose Bite(Rank 4)",
    "a higher Mongoose Bite rank was mistaken for Ghostly Strike")

spellNames[1715] = nil
assert(actions.GetSpellTemplateId("Charge(Rank 2)", 100) == "melee-attack"
        and actions.BuildDefaultSpellMacro("Charge(Rank 2)", 100)
            == attackPrefix .. "Charge(Rank 2)",
    "missing Hamstring metadata did not fail closed to the reviewed Charge template")
spellNames[1715] = "Hamstring"

spellNames[100], spellNames[1715] = "Carga", "Seccionar"
assert(actions.BuildDefaultSpellMacro("Carga(Rango 2)", 100)
        == "/startattack\n/use [combat] Seccionar; Carga(Rango 2)",
    "contextual Charge/Hamstring template did not use localized canonical names")
spellNames[100], spellNames[1715] = "Charge", "Hamstring"

for _, family in ipairs(excludedFamilies) do
    local castName = family[2] .. "(Rank 3)"
    assert(actions.GetSpellTemplateId(castName, family[1]) == "standard-spell"
        and actions.BuildDefaultSpellMacro(castName, family[1]) == "/use " .. castName,
        family[2] .. " unexpectedly received automatic attack behavior")
end

for _, family in ipairs({
    { 71, "Defensive Stance" },
    { 6673, "Battle Shout" },
    { 355, "Taunt" },
}) do
    spellNames[family[1]] = family[2]
    assert(actions.GetSpellTemplateId(family[2], family[1]) == "standard-spell"
            and actions.BuildDefaultSpellMacro(family[2], family[1])
                == "/use " .. family[2],
        family[2] .. " did not remain a direct utility cast")
end
for _, family in ipairs(warriorShieldRequiredFamilies) do
    local castName = family[2] .. "(Rank 1)"
    local expectedPrefix = actions.GetSpellTemplateId(castName, family[1]) == "melee-attack"
            and attackPrefix or "/use "
    assert(actions.BuildDefaultSpellMacro(castName, family[1])
            == expectedPrefix .. castName,
        family[2] .. " lost its cast or attack policy")
end
local warriorItem = actions.CreateItem(1251, "Linen Bandage", "none")
assert(warriorItem.macroText == "/use Linen Bandage",
    "attack-family policy added attack behavior to an item")
assert(actions.BuildDefaultItemMacro("Dynamita localizada", 4358)
        == "/use [@player] Dynamita localizada"
        and actions.BuildDefaultItemMacro("Dynamita localizada")
            == "/use Dynamita localizada"
        and actions.BuildDefaultItemMacro("Ordinary Item", 99999)
            == "/use Ordinary Item",
    "item defaults did not apply the ID-based player-ground policy")
for _, family in ipairs(standardShieldRequiredFamilies) do
    local castName = family[2] .. "(Rank 1)"
    assert(actions.BuildDefaultSpellMacro(castName, family[1])
            == "/use " .. castName,
        family[2] .. " did not receive a direct use action")
end

spellNames[90001] = "Heroic Strike"
assert(actions.BuildDefaultSpellMacro("Heroic Strike(Rank 12)", 90001)
    == attackPrefix .. "Heroic Strike(Rank 12)",
    "another rank did not match the localized canonical family name")
spellNames[1752], spellNames[90002] = "Golpe siniestro", "Golpe siniestro"
assert(actions.BuildDefaultSpellMacro("Golpe siniestro(Rango 9)", 90002)
    == stealthPrefix .. "Golpe siniestro(Rango 9)",
    "localized family names did not receive the stealth-safe policy")
spellNames[1752] = "Sinister Strike"
spellNames[78] = nil
assert(actions.BuildDefaultSpellMacro("Heroic Strike(Rank 1)", 90001)
    == "/use Heroic Strike(Rank 1)",
    "missing canonical spell metadata did not fail closed to a direct use action")
spellNames[78] = "Heroic Strike"
assert(actions.BuildDefaultSpellMacro("Polymorph(Rank 1)", 78)
        == "/use Polymorph(Rank 1)"
    and actions.BuildDefaultSpellMacro("Polymorph(Rank 1)", 75)
        == "/use Polymorph(Rank 1)",
    "mismatched saved spell identity injected attack behavior into crowd control")

local curated = actions.CreateSpell(78, "Heroic Strike(Rank 1)", "none")
assert(curated.macroText == attackPrefix .. "Heroic Strike(Rank 1)"
    and not curated.macroText:find("!Heroic Strike", 1, true),
    "next-swing default prevented deliberate queue cancellation")
curated.macroText = "/cast [mod:shift] Heroic Strike(Rank 1)"
assert(actions.Normalize(curated).macroText == curated.macroText
    and actions.ResetMacro(curated) == attackPrefix .. "Heroic Strike(Rank 1)",
    "curated custom macro was overwritten or Reset did not adopt the latest policy")

local shieldAction = actions.CreateSpell(72, "Shield Bash(Rank 1)", "none")
assert(shieldAction.macroText
        == attackPrefix .. "Shield Bash(Rank 1)",
    "new Shield Bash action did not receive a direct use after the attack policy")
shieldAction.macroText = "/cast Shield Bash(Rank 1)"
assert(actions.Normalize(shieldAction).macroText == "/cast Shield Bash(Rank 1)"
        and actions.ResetMacro(shieldAction)
            == attackPrefix .. "Shield Bash(Rank 1)",
    "custom shield macro was changed or Reset did not restore the generated cast")

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
local explosive = actions.CreateItem(4358, "Dynamita localizada", "none")
assert(explosive.macroText == "/use [@player] Dynamita localizada"
        and actions.BuildDefaultMacro(explosive) == explosive.macroText,
    "new explosive item did not receive its player-ground default")
local missingExplosiveMacro = actions.Normalize({
    kind = "item", itemId = 4358, itemName = "Dynamita localizada",
})
assert(missingExplosiveMacro.macroText == "/use [@player] Dynamita localizada",
    "explosive item without saved macro did not receive the current default")
explosive.macroText = "/use Dynamita localizada"
assert(actions.Normalize(explosive).macroText == "/use Dynamita localizada"
        and actions.Clone(explosive).macroText == "/use Dynamita localizada"
        and actions.ResetMacro(explosive) == "/use [@player] Dynamita localizada",
    "existing explosive macro was rewritten or Reset missed the smart default")
local renamedGenerated = actions.CreateItem(1251, "Old Bandage", "none")
assert(actions.ResolveDisplay(renamedGenerated) == "Linen Bandage"
    and renamedGenerated.itemName == "Linen Bandage"
    and renamedGenerated.macroText == "/use Old Bandage"
    and actions.ResetMacro(renamedGenerated) == "/use Linen Bandage",
    "localized item display resolution rewrote a saved macro without Reset")
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

assert(actions.GetTemplateTopics == nil,
    "removed Macro Library topic exporter was still exposed")

print("PASS shared action macros")
