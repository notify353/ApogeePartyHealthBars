dofile("ApogeePartyHealthBars_Data.lua")

local spellbookSpell
function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return nil, nil, 0, 1 end
function GetSpellBookItemName() return spellbookSpell end
BOOKTYPE_SPELL = "spell"

dofile("ApogeePartyHealthBars_ActionData.lua")
dofile("ApogeePartyHealthBars_PlayerSpells.lua")
dofile("ApogeePartyHealthBars_Effects.lua")

local definitions = ApogeePartyHealthBars_C.PARTY_BUFF_DEFINITIONS
local byCanonical = {}
for _, definition in ipairs(definitions) do
    assert(type(definition.canonical) == "string" and definition.canonical ~= "")
    assert(definition.track == "primary" or definition.track == "spirit")
    assert(type(definition.pattern) == "string" and definition.pattern ~= "")
    assert(type(definition.icon) == "string" and definition.icon ~= "")
    assert(type(definition.auraIds) == "table" and next(definition.auraIds))
    assert(type(definition.auraNames) == "table" and next(definition.auraNames))
    assert(not byCanonical[definition.canonical], "duplicate party buff definition")
    byCanonical[definition.canonical] = definition
end

local supportedClassBuffs = {
    PRIEST = {
        canonical = "Power Word: Fortitude",
        groupAura = "Prayer of Fortitude",
        highestSingleId = 25389,
        highestGroupId = 25392,
    },
    MAGE = {
        canonical = "Arcane Intellect",
        groupAura = "Arcane Brilliance",
        highestSingleId = 27126,
        highestGroupId = 27127,
    },
    DRUID = {
        canonical = "Mark of the Wild",
        groupAura = "Gift of the Wild",
        highestSingleId = 26990,
        highestGroupId = 26991,
    },
    PALADIN = {
        canonical = "Blessing of Might",
        groupAura = "Greater Blessing of Might",
        highestSingleId = 27140,
        highestGroupId = 27141,
    },
}

for classToken, expected in pairs(supportedClassBuffs) do
    local definition = byCanonical[expected.canonical]
    assert(definition, classToken .. " party buff definition is missing")
    assert(definition.auraNames[expected.canonical], classToken .. " single-target aura name is missing")
    assert(definition.auraNames[expected.groupAura], classToken .. " group aura name is missing")
    assert(definition.auraIds[expected.highestSingleId], classToken .. " TBC single-target rank is missing")
    assert(definition.auraIds[expected.highestGroupId], classToken .. " TBC group rank is missing")

    spellbookSpell = expected.canonical
    local selection = ApogeePartyHealthBars_Effects.ResolveFirstKnown(
        definitions,
        ApogeePartyHealthBars_C.PARTY_BUFF_ICON_TEXTURE
    )
    assert(selection.known, classToken .. " party buff was not detected from the spellbook")
    assert(selection.spellName == expected.canonical, classToken .. " selected the wrong cast spell")
    assert(selection.icon == definition.icon, classToken .. " selected the wrong icon")
    assert(selection.auraIds == definition.auraIds, classToken .. " selected the wrong aura IDs")
    assert(selection.auraNames == definition.auraNames, classToken .. " selected the wrong aura names")
end

local intellect = byCanonical["Arcane Intellect"]
for _, spellId in ipairs({ 1459, 1460, 1461, 10156, 10157, 27126, 23028, 27127 }) do
    assert(intellect.auraIds[spellId], "missing Mage intellect aura ID " .. spellId)
end

local spirit = byCanonical["Divine Spirit"]
assert(spirit and spirit.track == "spirit", "Divine Spirit reminder definition is missing")
assert(spirit.auraNames["Divine Spirit"] and spirit.auraNames["Prayer of Spirit"],
    "Divine Spirit single-target or group aura name is missing")
for _, spellId in ipairs({ 14752, 14818, 14819, 27841, 25312, 27681, 32999 }) do
    assert(spirit.auraIds[spellId], "missing Divine Spirit aura ID " .. spellId)
end
for _, classToken in ipairs({ "PRIEST", "MAGE", "DRUID" }) do
    assert(spirit.eligibleClasses[classToken],
        classToken .. " was not eligible for Divine Spirit reminders")
end
for _, classToken in ipairs({
    "WARRIOR", "ROGUE", "HUNTER", "WARLOCK", "PALADIN", "SHAMAN",
}) do
    assert(not spirit.eligibleClasses[classToken],
        classToken .. " was unexpectedly eligible for Divine Spirit reminders")
end

print("PASS party buff definitions")
