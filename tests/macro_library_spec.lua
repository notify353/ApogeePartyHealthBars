dofile("ApogeePartyHealthBars_ActionData.lua")
dofile("ApogeePartyHealthBars_ActionMacros.lua")
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
assert(L.GetRecipe("wand-safe-shoot").body
    == "/targetenemy [noexists][dead][help]\n/cast !Shoot\n/startattack")
assert(L.GetRecipe("hunter-safe-auto-shot").body
    == "/targetenemy [noexists][dead][help]\n/cast !Auto Shot\n/startattack")
assert(L.GetRecipe("hunter-force-auto-shot").body
    == "/cast !Auto Shot\n/cast Arcane Shot")
local mageTopics = L.GetTopicsForClass("MAGE", "all")
assert(#L.GetTopicsForClass("MAGE", "generated") == 6, "generated macro glossary is incomplete")
assert(#L.GetTopicsForClass("MAGE", "syntax") == 17, "macro syntax glossary is incomplete")
assert(#mageTopics == 6 + 17 + #L.GetRecipesForClass("MAGE", "all"),
    "combined macro documentation lost generated, syntax, or class recipe topics")
for _, topic in ipairs(mageTopics) do
    assert(topic.lineDetails and topic.lineDetails ~= "", topic.id .. " lacks line-by-line documentation")
    assert(L.ValidateTopic(topic), topic.id .. " is not valid documentation")
end
for _, classToken in ipairs(classes) do
    for _, recipe in ipairs(L.GetRecipesForClass(classToken, "interrupt")) do
        assert(recipe.body:find("^/stopcasting\n/cast %[@focus,harm,nodead%]%[%] "),
            recipe.id .. " has incorrect focus-fallback stopcasting order")
    end
end
assert(L.GetRecipe("mage-safe-polymorph").body:find("^/stopattack", 1),
    "crowd-control safety recipe is missing")
assert(L.GetRecipe("druid-spam-safe-prowl").body == "/cast [nostealth] !Prowl",
    "spam-safe stealth-state recipe is missing")
assert(L.GetRecipe("warrior-queued-heroic-strike").body:find("!Heroic Strike", 1, true),
    "queued next-swing recipe is missing")
assert(not L.ValidateBody("  \n\t"), "blank macro was accepted")
assert(not L.ValidateBody(string.rep("x", 256)), "oversized macro was accepted")
assert(not L.ValidateRecipe({ id = "bad", category = "attack", title = "Bad", explanation = "Bad", body = "/cast Bad", classes = "MAGE" }), "invalid class metadata was accepted")

BOOKTYPE_PET = "pet"
local petSpells = {}
function HasPetSpells() return #petSpells end
function GetSpellBookItemName(slot, bookType) if bookType == BOOKTYPE_PET then return petSpells[slot] end end
dofile("ApogeePartyHealthBars_PlayerSpells.lua")
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

local originalDocumentationCategories = data.DocumentationCategories
data.DocumentationCategories = { { id = "all", label = "All Topics" } }
local documentationCategoryCallOk, malformedDocumentationCategoriesOk = pcall(L.ValidateAll)
assert(documentationCategoryCallOk and not malformedDocumentationCategoriesOk,
    "missing documentation categories crashed or passed validation")
data.DocumentationCategories = originalDocumentationCategories

local originalRecipes = data.Recipes
data.Recipes = { false }
local recipeCallOk, malformedRecipesOk = pcall(L.ValidateAll)
assert(recipeCallOk and not malformedRecipesOk, "malformed recipe metadata crashed or was accepted")
data.Recipes = originalRecipes

local originalSyntaxTopics = data.SyntaxTopics
data.SyntaxTopics = { false }
local syntaxCallOk, malformedSyntaxOk = pcall(L.ValidateAll)
assert(syntaxCallOk and not malformedSyntaxOk, "malformed syntax topic crashed or passed validation")
data.SyntaxTopics = originalSyntaxTopics

assert(not L.ValidateRecipe({
    id = "bad-spells", category = "attack", title = "Bad", explanation = "Bad",
    requirements = "Bad.", requiredSpells = { false }, body = "/cast Bad",
}), "invalid required-spell metadata was accepted")
assert(not L.ValidateRecipe({
    id = "mapped-spells", category = "attack", title = "Bad", explanation = "Bad",
    requirements = "Bad.", requiredSpells = { primary = "Bad" }, body = "/cast Bad",
}), "non-array required-spell metadata was accepted")
print("PASS combat macro library")
