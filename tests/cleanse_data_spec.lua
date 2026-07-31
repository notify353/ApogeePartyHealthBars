BOOKTYPE_SPELL, BOOKTYPE_PET = "spell", "pet"

dofile("Reminders/CleanseData.lua")
local Data = ApogeePartyHealthBars_CleanseData

local capabilities = Data.ResolveCapabilities({
    { id = 1152, name = "Purify(Rank 1)", baseName = "Purify", sourceBook = "spell" },
    { id = 4987, name = "Cleanse(Rank 2)", baseName = "Cleanse", sourceBook = "spell" },
})
assert(capabilities.Magic.spellId == 4987
        and capabilities.Disease.spellId == 4987
        and capabilities.Poison.spellId == 4987
        and not capabilities.Curse,
    "broader learned cleanse did not take precedence")

capabilities = Data.ResolveCapabilities({
    { id = 19505, name = "Devour Magic(Rank 3)", baseName = "Devour Magic",
        sourceBook = "pet" },
})
assert(capabilities.Magic and capabilities.Magic.pet
        and not capabilities.Curse and not capabilities.Disease and not capabilities.Poison,
    "pet cleanse capability was not isolated to Magic")

capabilities = Data.ResolveCapabilities({
    { id = 8946, name = "Cure Poison", baseName = "Cure Poison", sourceBook = "spell" },
    { id = 2893, name = "Abolish Poison", baseName = "Abolish Poison", sourceBook = "spell" },
    { id = 2782, name = "Remove Curse", baseName = "Remove Curse", sourceBook = "spell" },
})
assert(capabilities.Poison.spellId == 2893 and capabilities.Curse.spellId == 2782,
    "improved Druid cleanse preference changed")

local classMatrix = {
    DRUID = {
        known = {
            { id = 2782, baseName = "Remove Curse", sourceBook = "spell" },
            { id = 8946, baseName = "Cure Poison", sourceBook = "spell" },
            { id = 2893, baseName = "Abolish Poison", sourceBook = "spell" },
        },
        expected = { Curse = "Remove Curse", Poison = "Abolish Poison" },
    },
    HUNTER = { known = {}, expected = {} },
    MAGE = {
        known = {
            { id = 475, baseName = "Remove Lesser Curse", sourceBook = "spell" },
        },
        expected = { Curse = "Remove Lesser Curse" },
    },
    PALADIN = {
        known = {
            { id = 1152, baseName = "Purify", sourceBook = "spell" },
            { id = 4987, baseName = "Cleanse", sourceBook = "spell" },
        },
        expected = {
            Magic = "Cleanse", Disease = "Cleanse", Poison = "Cleanse",
        },
    },
    PRIEST = {
        known = {
            { id = 527, baseName = "Dispel Magic", sourceBook = "spell" },
            { id = 528, baseName = "Cure Disease", sourceBook = "spell" },
            { id = 552, baseName = "Abolish Disease", sourceBook = "spell" },
        },
        expected = {
            Magic = "Dispel Magic", Disease = "Abolish Disease",
        },
    },
    ROGUE = { known = {}, expected = {} },
    SHAMAN = {
        known = {
            { id = 526, baseName = "Cure Poison", sourceBook = "spell" },
            { id = 2870, baseName = "Cure Disease", sourceBook = "spell" },
        },
        expected = { Disease = "Cure Disease", Poison = "Cure Poison" },
    },
    WARLOCK = {
        known = {
            { id = 19505, baseName = "Devour Magic", sourceBook = "pet" },
        },
        expected = { Magic = "Devour Magic" },
    },
    WARRIOR = { known = {}, expected = {} },
}

for _, client in ipairs({ "Classic Era", "TBC Anniversary" }) do
    for classToken, case in pairs(classMatrix) do
        local resolved = Data.ResolveCapabilities(case.known)
        for _, dispelType in ipairs(Data.TYPE_ORDER) do
            local expected = case.expected[dispelType]
            local actual = resolved[dispelType]
            assert((not expected and not actual)
                    or (actual and actual.baseName == expected),
                client .. " " .. classToken .. " " .. dispelType
                    .. " cleanse coverage changed")
        end
        assert(Data.HasCapability(resolved) == (next(case.expected) ~= nil),
            client .. " " .. classToken .. " fail-closed behavior changed")
    end
end

capabilities = Data.ResolveCapabilities({
    { id = 19505, baseName = "Devour Magic", sourceBook = "spell" },
    { id = 2893, baseName = "Abolish Poison", sourceBook = "pet" },
})
assert(not Data.HasCapability(capabilities),
    "cleanse catalog accepted a spell from the wrong player or pet book")

local snapshot = Data.BuildUnitSnapshot({ auras = {
    { name = "Slow Magic", icon = 1, applications = 1, dispelName = "Magic",
        duration = 20, expirationTime = 18, spellId = 11 },
    { name = "Fast Magic", icon = 2, applications = 2, dispelName = "Magic",
        duration = 10, expirationTime = 13, spellId = 12 },
    { name = "Curse", icon = 3, dispelName = "Curse", expirationTime = 20 },
    { name = "Permanent Magic", icon = 5, dispelName = "Magic",
        duration = nil, expirationTime = nil, spellId = 13 },
    { name = "Bleed", icon = 4, dispelName = nil, expirationTime = 30 },
}}, {
    Magic = { spellName = "Dispel Magic" },
}, 10)
assert(snapshot.count == 3 and snapshot.byType.Magic.count == 3
        and snapshot.byType.Magic.primary.name == "Fast Magic"
        and snapshot.byType.Magic.primary.remaining == 3
        and snapshot.byType.Magic.auras[3].remaining == math.huge
        and not snapshot.byType.Curse,
    "removable aura grouping or shortest-duration priority changed")

print("PASS cleanse capability and debuff policy")
