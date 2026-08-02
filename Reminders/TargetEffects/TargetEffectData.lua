ApogeePartyHealthBars_TargetEffectData = {}
local D = ApogeePartyHealthBars_TargetEffectData

local function family(key, classToken, label, ids, options)
    options = options or {}
    options.key, options.classToken, options.label = key, classToken, label
    options.castIds, options.auraIds = ids, options.auraIds or ids
    return options
end

local function ranked(ids, firstStrength)
    local result = {}
    for index, spellId in ipairs(ids) do result[spellId] = (firstStrength or 1) + index - 1 end
    return result
end

local function maintained(key, classToken, label, ids, options)
    options = options or {}
    options.maintainedDebuff = true
    options.ownerPolicy = options.ownerPolicy or "any"
    options.castStrengths = options.castStrengths or ranked(ids)
    options.auraStrengths = options.auraStrengths or ranked(options.auraIds or ids)
    return family(key, classToken, label, ids, options)
end

-- Rank and replacement IDs were checked against the supported Classic Era and
-- TBC Anniversary client spellbooks. Runtime matching is deliberately ID-only.
D.FAMILIES = {
    family("moonfire", "DRUID", "Moonfire", { 8921,8924,8925,8926,8927,8928,8929,9833,9834,9835,26987,26988 }),
    family("rake", "DRUID", "Rake", { 1822,1823,1824,9904,27003 }, { formSpellIds = { [768]=true } }),
    family("rip", "DRUID", "Rip", { 1079,9492,9493,9752,9894,9896,27008 }, { formSpellIds = { [768]=true } }),
    family("pounce", "DRUID", "Pounce", { 9005,9823,9827,27006 }, { formSpellIds = { [768]=true }, requiresStealth = true }),
    family("insectSwarm", "DRUID", "Insect Swarm", { 5570,24974,24975,24976,24977,27013 }),
    family("lacerate", "DRUID", "Lacerate", { 33745 }, { formSpellIds = { [5487]=true, [9634]=true } }),
    family("serpentSting", "HUNTER", "Serpent Sting", { 1978,13549,13550,13551,13552,13553,13554,13555,25295,27016 }),
    family("wyvernSting", "HUNTER", "Wyvern Sting", { 19386,24132,24133,27068 }, {
        auraIds = { 19386,24131,24132,24134,24133,24135,27068,27069 },
    }),
    family("pyroblast", "MAGE", "Pyroblast", { 11366,12505,12522,12523,12524,12525,12526,18809,27132 }),
    family("shadowWordPain", "PRIEST", "Shadow Word: Pain", { 589,594,970,992,2767,10892,10893,10894,25367,25368 }),
    family("holyFire", "PRIEST", "Holy Fire", { 14914,15262,15263,15264,15265,15266,15267,15261,25384 }),
    family("devouringPlague", "PRIEST", "Devouring Plague", { 2944,19276,19277,19278,19279,19280,25467 }, {
        races = { Scourge = true, Undead = true },
    }),
    family("garrote", "ROGUE", "Garrote", { 703,8631,8632,8633,11289,11290,26839,26884 }, { requiresStealth = true }),
    family("rupture", "ROGUE", "Rupture", { 1943,8639,8640,11273,11274,11275,26867 }),
    family("flameShock", "SHAMAN", "Flame Shock", { 8050,8052,8053,10447,10448,29228,25457 }),
    family("corruption", "WARLOCK", "Corruption", { 172,6222,6223,7648,11671,11672,25311,27216 }),
    family("immolate", "WARLOCK", "Immolate", { 348,707,1094,2941,11665,11667,11668,25309,27215 }),
    family("curseOfAgony", "WARLOCK", "Curse of Agony", { 980,1014,6217,11711,11712,11713,27218 }, { exclusiveGroup = "curse" }),
    family("curseOfDoom", "WARLOCK", "Curse of Doom", { 603,30910 }, { exclusiveGroup = "curse", nonPlayerTarget = true }),
    family("siphonLife", "WARLOCK", "Siphon Life", { 18265,18879,18880,18881,27264 }),
    family("unstableAffliction", "WARLOCK", "Unstable Affliction", { 30108,30404,30405 }),
    family("seedOfCorruption", "WARLOCK", "Seed of Corruption", { 27243 }),
    family("rend", "WARRIOR", "Rend", { 772,6546,6547,6548,11572,11573,11574,25208 }),
    maintained("battleShout", "WARRIOR", "Battle Shout",
        { 6673,5242,6192,11549,11550,11551,25289 }, {
            auraUnit = "player", casterCentered = true,
        }),

    maintained("demoralizingShout", "WARRIOR", "Demoralizing Shout",
        { 1160,6190,11554,11555,11556,25202 }, {
            coverageGroup = "attackPowerReduction", casterCentered = true,
        }),
    maintained("thunderClap", "WARRIOR", "Thunder Clap",
        { 6343,8198,8204,8205,11580,11581,25264 }, { casterCentered = true }),
    maintained("sunderArmor", "WARRIOR", "Sunder Armor",
        { 7386,7405,8380,11596,11597,25225 }, {
            -- Sunder strength comes primarily from applications; rank remains
            -- relevant when comparing otherwise equal stacks.
            strengthFromApplications = true,
        }),
    maintained("disarm", "WARRIOR", "Disarm", { 676 }),

    maintained("demoralizingRoar", "DRUID", "Demoralizing Roar",
        { 99,1735,9490,9747,9898,26998 }, {
            coverageGroup = "attackPowerReduction",
            formSpellIds = { [5487]=true, [9634]=true },
            casterCentered = true,
        }),
    maintained("faerieFire", "DRUID", "Faerie Fire",
        { 770,778,9749,9907,26993 }, { exclusiveGroup = "faerieFire" }),
    maintained("faerieFireFeral", "DRUID", "Faerie Fire (Feral)",
        { 16857,17390,17391,17392,27011 }, {
            exclusiveGroup = "faerieFire",
            formSpellIds = { [768]=true, [5487]=true, [9634]=true },
        }),

    maintained("huntersMark", "HUNTER", "Hunter's Mark", { 1130,14323,14324,14325 }),
    maintained("scorpidSting", "HUNTER", "Scorpid Sting", { 3043 }),

    maintained("exposeArmor", "ROGUE", "Expose Armor",
        { 8647,8649,8650,11197,11198,26866 }),

    maintained("curseOfWeakness", "WARLOCK", "Curse of Weakness",
        { 702,1108,6205,7646,11707,11708,27224 }, {
            coverageGroup = "attackPowerReduction", exclusiveGroup = "curse",
        }),
    maintained("curseOfRecklessness", "WARLOCK", "Curse of Recklessness",
        { 704,7658,7659,11717,27226 }, { exclusiveGroup = "curse" }),
    maintained("curseOfElements", "WARLOCK", "Curse of the Elements",
        { 1490,11721,11722,27228 }, { exclusiveGroup = "curse" }),
    maintained("curseOfShadow", "WARLOCK", "Curse of Shadow",
        { 17862,17937,27229 }, { exclusiveGroup = "curse" }),
    maintained("curseOfTongues", "WARLOCK", "Curse of Tongues",
        { 1714,11719 }, { exclusiveGroup = "curse" }),

    maintained("judgementOfLight", "PALADIN", "Judgement of Light",
        { 20165,20347,20348,20349,27160 }, {
            auraIds = { 20185,20344,20345,20346,27162 },
            actionSpellId = 20271, exclusiveGroup = "judgement",
            requiredPlayerAuraIds = { 20165,20347,20348,20349,27160 },
        }),
    maintained("judgementOfWisdom", "PALADIN", "Judgement of Wisdom",
        { 20166,20356,20357,27166 }, {
            auraIds = { 20186,20354,20355,27164 },
            actionSpellId = 20271, exclusiveGroup = "judgement",
            requiredPlayerAuraIds = { 20166,20356,20357,27166 },
        }),
    maintained("judgementOfCrusader", "PALADIN", "Judgement of the Crusader",
        { 21082,20162,20305,20306,20307,20308,27158 }, {
            auraIds = { 21183,20188,20300,20301,20302,20303,27159 },
            actionSpellId = 20271, exclusiveGroup = "judgement",
            requiredPlayerAuraIds = { 21082,20162,20305,20306,20307,20308,27158 },
        }),
    maintained("judgementOfJustice", "PALADIN", "Judgement of Justice",
        { 20164 }, {
            auraIds = { 20184 }, actionSpellId = 20271, exclusiveGroup = "judgement",
            requiredPlayerAuraIds = { 20164 },
        }),

    maintained("stormstrike", "SHAMAN", "Stormstrike", { 17364 }, {
        auraIds = { 17364,32175,32176 },
    }),
}

local byKey = {}
local coverageGroups = {}
for index, definition in ipairs(D.FAMILIES) do
    definition.defaultPriority = index
    definition.auraIdSet = {}
    for _, spellId in ipairs(definition.auraIds) do definition.auraIdSet[spellId] = true end
    if definition.requiredPlayerAuraIds then
        definition.requiredPlayerAuraIdSet = {}
        for _, spellId in ipairs(definition.requiredPlayerAuraIds) do
            definition.requiredPlayerAuraIdSet[spellId] = true
        end
    end
    byKey[definition.key] = definition
    if definition.coverageGroup then
        coverageGroups[definition.coverageGroup] = coverageGroups[definition.coverageGroup] or {}
        coverageGroups[definition.coverageGroup][#coverageGroups[definition.coverageGroup] + 1] = definition
    end
end

function D.Get(key) return byKey[key] end
function D.GetCoverageGroup(key) return coverageGroups[key] or {} end
function D.ForClass(classToken)
    local result = {}
    for _, definition in ipairs(D.FAMILIES) do
        if definition.classToken == classToken then result[#result + 1] = definition end
    end
    return result
end
