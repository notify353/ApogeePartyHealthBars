local Data = {}
ApogeePartyHealthBars.Define("Runtime", "GroupHelperData", Data)

-- Validated Classic/TBC drink effect ranks. IDs remain authoritative when
-- aura records expose them; resolving their client-localized names also covers
-- equivalent drink effects that use the same localized aura name.
local drinkAuraIds = {
    [430] = true, [431] = true, [432] = true,
    [1133] = true, [1135] = true, [1137] = true,
    [10250] = true, [22734] = true, [27089] = true,
}
local drinkAuraNames = {}
local buffFamilies = {}

local FAMILY_ORDER = { "fortitude", "intellect", "mark", "blessing", "spirit" }
local FAMILY_METADATA = {
    fortitude = {
        label = "Fortitude", abbrev = "fort", providerClassToken = "PRIEST",
    },
    intellect = {
        label = "Arcane Intellect", abbrev = "int", providerClassToken = "MAGE",
        manaOnly = true,
    },
    mark = {
        label = "Mark of the Wild", abbrev = "mark", providerClassToken = "DRUID",
    },
    blessing = {
        label = "Paladin blessing", abbrev = "blessing", providerClassToken = "PALADIN",
        auraIds = {
            [19742] = true, [19850] = true, [19852] = true, [19853] = true,
            [19854] = true, [25290] = true, [27142] = true,
            [25894] = true, [25918] = true, [27143] = true,
            [1038] = true, [25895] = true,
            [20911] = true, [20912] = true, [20913] = true, [20914] = true,
            [27168] = true, [25899] = true, [27169] = true,
        },
        auraNames = {
            ["Blessing of Wisdom"] = true,
            ["Greater Blessing of Wisdom"] = true,
            ["Blessing of Salvation"] = true,
            ["Greater Blessing of Salvation"] = true,
            ["Blessing of Sanctuary"] = true,
            ["Greater Blessing of Sanctuary"] = true,
        },
    },
    spirit = {
        label = "Divine Spirit", abbrev = "spirit", providerClassToken = "PRIEST",
        evidenceRequired = true,
        manaOnly = true,
    },
}

local function merge(target, source)
    for key, value in pairs(source or {}) do target[key] = value end
end

local function familyKey(canonical)
    if canonical == "Power Word: Fortitude" then return "fortitude" end
    if canonical == "Arcane Intellect" then return "intellect" end
    if canonical == "Mark of the Wild" then return "mark" end
    if canonical == "Divine Spirit" then return "spirit" end
    if type(canonical) == "string" and canonical:find("^Blessing of ") then
        return "blessing"
    end
end

function Data.ConfigureBuffDefinitions(definitions)
    buffFamilies = {}
    for _, key in ipairs(FAMILY_ORDER) do
        local metadata = FAMILY_METADATA[key]
        buffFamilies[key] = {
            key = key,
            label = metadata.label,
            abbrev = metadata.abbrev,
            providerClassToken = metadata.providerClassToken,
            manaOnly = metadata.manaOnly,
            evidenceRequired = metadata.evidenceRequired,
            eligibleClasses = metadata.eligibleClasses,
            auraIds = {}, auraNames = {},
        }
        merge(buffFamilies[key].auraIds, metadata.auraIds)
        merge(buffFamilies[key].auraNames, metadata.auraNames)
    end
    for _, definition in ipairs(definitions or {}) do
        local key = familyKey(definition.canonical)
        local family = key and buffFamilies[key]
        if family then
            merge(family.auraIds, definition.auraIds)
            merge(family.auraNames, definition.auraNames)
            family.icon = family.icon or definition.icon
        end
    end
end

local function auraMatches(aura, family)
    return aura and family and ((aura.spellId and family.auraIds[aura.spellId])
        or (aura.name and family.auraNames[aura.name])) == true
end

function Data.FindBuffAura(unit, key)
    local family = buffFamilies[key]
    for _, aura in ipairs(unit and unit.auras or {}) do
        if auraMatches(aura, family) then return aura end
    end
    return nil
end

function Data.GetBuffFamilies()
    local result = {}
    for _, key in ipairs(FAMILY_ORDER) do
        if buffFamilies[key] and next(buffFamilies[key].auraIds) then
            result[#result + 1] = buffFamilies[key]
        end
    end
    return result
end

function Data.ConfigureDrinkAuraNames(resolveSpellName)
    drinkAuraNames = {}
    if type(resolveSpellName) ~= "function" then return end
    for spellId in pairs(drinkAuraIds) do
        local name = resolveSpellName(spellId)
        if name and name ~= "" then drinkAuraNames[name] = true end
    end
end

function Data.FindDrinkAura(unit)
    for _, aura in ipairs(unit and unit.auras or {}) do
        if (aura.spellId and drinkAuraIds[aura.spellId])
            or (aura.name and drinkAuraNames[aura.name]) then
            return aura
        end
    end
    return nil
end

function Data.GetDrinkAuraIds()
    return drinkAuraIds
end
