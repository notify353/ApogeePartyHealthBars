ApogeePartyHealthBars_CleanseData = {}
local Data = ApogeePartyHealthBars_CleanseData

Data.TYPE_ORDER = { "Magic", "Curse", "Disease", "Poison" }
Data.TYPE_COLORS = {
    Magic = { 0.20, 0.60, 1.00 },
    Curse = { 0.60, 0.00, 1.00 },
    Disease = { 0.60, 0.40, 0.00 },
    Poison = { 0.00, 0.60, 0.00 },
}

-- Real Classic/TBC effects used only while configuration is open so every
-- supported lane can demonstrate its live icon, copy, timing, and actions.
Data.CONFIG_PREVIEW_DEBUFFS = {
    Magic = {
        {
            spellId = 118,
            name = "Polymorph",
            fallbackDescription =
                "Transforms the target into a sheep, preventing actions but rapidly regenerating health.",
        },
    },
    Curse = {
        {
            spellId = 980,
            name = "Curse of Agony",
            fallbackDescription = "Inflicts increasing Shadow damage over time.",
        },
    },
    Disease = {
        {
            spellId = 2944,
            name = "Devouring Plague",
            fallbackDescription = "Causes Shadow damage over time and heals the caster.",
        },
    },
    Poison = {
        {
            spellId = 2818,
            name = "Deadly Poison",
            fallbackDescription = "Deals periodic Nature damage and can stack.",
        },
    },
}

-- Era/TBC coverage: Druid Curse/Poison, Mage Curse, Paladin
-- Magic/Disease/Poison, Priest Magic/Disease, Shaman Disease/Poison, and
-- Warlock Felhunter Magic. Hunter, Rogue, and Warrior intentionally fail
-- closed. Higher entries win for every type they cover. Availability remains
-- driven by the live player and pet Spellbooks so one catalog serves both
-- clients and excludes unlearned or unavailable abilities automatically.
Data.SPELLS = {
    { canonical = "Cleanse", pattern = "^Cleanse", types = {
        Magic = true, Disease = true, Poison = true,
    }},
    { canonical = "Purify", pattern = "^Purify", types = {
        Disease = true, Poison = true,
    }},
    { canonical = "Dispel Magic", pattern = "^Dispel Magic", types = {
        Magic = true,
    }},
    { canonical = "Abolish Disease", pattern = "^Abolish Disease", types = {
        Disease = true,
    }},
    { canonical = "Cure Disease", pattern = "^Cure Disease", types = {
        Disease = true,
    }},
    { canonical = "Abolish Poison", pattern = "^Abolish Poison", types = {
        Poison = true,
    }},
    { canonical = "Cure Poison", pattern = "^Cure Poison", types = {
        Poison = true,
    }},
    { canonical = "Remove Lesser Curse", pattern = "^Remove Lesser Curse", types = {
        Curse = true,
    }},
    { canonical = "Remove Curse", pattern = "^Remove Curse", types = {
        Curse = true,
    }},
    { canonical = "Devour Magic", pattern = "^Devour Magic", types = {
        Magic = true,
    }, pet = true },
}

local function matches(known, definition)
    local name = known and (known.baseName or known.name)
    if not name then return false end
    return name == definition.canonical or name:find(definition.pattern) ~= nil
end

function Data.ResolveCapabilities(knownList)
    local result = {}
    for _, definition in ipairs(Data.SPELLS) do
        for _, known in ipairs(knownList or {}) do
            local isPet = known.sourceBook == (BOOKTYPE_PET or "pet")
            if isPet == (definition.pet == true) and matches(known, definition) then
                for _, dispelType in ipairs(Data.TYPE_ORDER) do
                    if definition.types[dispelType] and not result[dispelType] then
                        result[dispelType] = {
                            dispelType = dispelType,
                            spellId = known.id,
                            spellName = known.name or known.baseName,
                            baseName = known.baseName or known.name,
                            pet = definition.pet == true,
                        }
                    end
                end
                break
            end
        end
    end
    return result
end

function Data.HasCapability(capabilities)
    for _, dispelType in ipairs(Data.TYPE_ORDER) do
        if capabilities and capabilities[dispelType] then return true end
    end
    return false
end

function Data.BuildUnitSnapshot(auraSnapshot, capabilities, now)
    now = tonumber(now) or 0
    local grouped = {}
    for _, aura in ipairs(auraSnapshot and auraSnapshot.auras or {}) do
        local dispelType = aura.dispelName
        if capabilities and capabilities[dispelType] then
            local entry = {
                name = aura.name,
                icon = aura.icon,
                applications = tonumber(aura.applications) or 0,
                dispelName = dispelType,
                duration = tonumber(aura.duration) or 0,
                expirationTime = tonumber(aura.expirationTime) or 0,
                spellId = aura.spellId,
            }
            entry.remaining = entry.expirationTime > 0
                and math.max(0, entry.expirationTime - now) or math.huge
            grouped[dispelType] = grouped[dispelType] or {}
            grouped[dispelType][#grouped[dispelType] + 1] = entry
        end
    end

    local result = { byType = {}, count = 0 }
    for _, dispelType in ipairs(Data.TYPE_ORDER) do
        local entries = grouped[dispelType]
        if entries then
            table.sort(entries, function(left, right)
                if left.remaining ~= right.remaining then
                    return left.remaining < right.remaining
                end
                return tostring(left.name or "") < tostring(right.name or "")
            end)
            result.byType[dispelType] = {
                primary = entries[1],
                auras = entries,
                count = #entries,
            }
            result.count = result.count + #entries
        end
    end
    return result
end
