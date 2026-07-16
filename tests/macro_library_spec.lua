dofile("ApogeePartyHealthBars_MacroData.lua")
dofile("ApogeePartyHealthBars_MacroLibrary.lua")

local L = ApogeePartyHealthBars_MacroLibrary
local classes = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" }
local ok, errors = L.ValidateAll()
assert(ok, table.concat(errors, "\n"))

for _, classToken in ipairs(classes) do
    local all = L.GetRecipesForClass(classToken, "all")
    assert(#all >= 2, classToken .. " needs universal and class recipes")
    assert(all[1].id == "universal-safe-attack", classToken .. " did not receive the universal recipe first")
    for _, recipe in ipairs(all) do
        assert(not recipe.classes or recipe.classes[classToken], classToken .. " received another class's recipe")
        assert(#recipe.body <= L.MAX_BODY_BYTES, recipe.id .. " exceeds the client limit")
        assert(L.GetRecipe(recipe.id) == recipe, recipe.id .. " did not resolve by ID")
        assert(recipe.macroName == nil and recipe.iconSpell == nil and recipe.fallbackIcon == nil,
            recipe.id .. " retained installer-only metadata")
    end
end

assert(#L.GetRecipesForClass("MAGE", "pet") == 0, "mage unexpectedly received a pet recipe")
assert(#L.GetRecipesForClass("HUNTER", "pet") == 1, "hunter pet recipe missing")
assert(L.GetRecipe("wand-safe-shoot").body == "/targetenemy [noexists][dead][help]\n/cast !Shoot")
assert(L.GetRecipe("hunter-safe-auto-shot").body == "/targetenemy [noexists][dead][help]\n/cast !Auto Shot")
for _, classToken in ipairs(classes) do
    for _, recipe in ipairs(L.GetRecipesForClass(classToken, "interrupt")) do
        assert(recipe.body:find("^/stopcasting\n/cast "), recipe.id .. " has incorrect stopcasting order")
    end
end
assert(not L.ValidateBody("  \n\t"), "blank macro was accepted")
assert(not L.ValidateBody(string.rep("x", 256)), "oversized macro was accepted")
assert(not L.ValidateRecipe({ id = "bad", category = "attack", title = "Bad", explanation = "Bad", body = "/cast Bad", classes = "MAGE" }), "invalid class metadata was accepted")

BOOKTYPE_PET = "pet"
local petSpells = {}
function HasPetSpells() return #petSpells end
function GetSpellBookItemName(slot, bookType) if bookType == BOOKTYPE_PET then return petSpells[slot] end end
local spellLock = L.GetRecipe("warlock-stop-spell-lock")
assert(L.GetUnavailableReason(spellLock):find("Summon a pet", 1, true), "missing pet spell was not reported")
petSpells[1] = "Spell Lock"
assert(L.GetUnavailableReason(spellLock) == nil, "known pet spell was reported missing")
local data = ApogeePartyHealthBars_MacroData
local originalCategories = data.Categories
data.Categories = { 42 }
local categoryCallOk, malformedOk = pcall(L.ValidateAll)
assert(categoryCallOk and not malformedOk, "malformed category metadata crashed or was accepted")
data.Categories = originalCategories

local originalRecipes = data.Recipes
data.Recipes = { false }
local recipeCallOk, malformedRecipesOk = pcall(L.ValidateAll)
assert(recipeCallOk and not malformedRecipesOk, "malformed recipe metadata crashed or was accepted")
data.Recipes = originalRecipes

assert(not L.ValidateRecipe({
    id = "bad-spells", category = "attack", title = "Bad", explanation = "Bad",
    requirements = "Bad.", requiredSpells = { false }, body = "/cast Bad",
}), "invalid required-spell metadata was accepted")
assert(not L.ValidateRecipe({
    id = "mapped-spells", category = "attack", title = "Bad", explanation = "Bad",
    requirements = "Bad.", requiredSpells = { primary = "Bad" }, body = "/cast Bad",
}), "non-array required-spell metadata was accepted")
print("PASS combat macro library")
