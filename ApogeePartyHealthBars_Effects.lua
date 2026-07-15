-- Spellbook-driven effect selection shared by party buffs, self buffs, HoTs,
-- and class-specific starter bindings.
local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_Effects = {}

local E = ApogeePartyHealthBars_Effects

local FEATURE_DEFAULTS = {
    enabled = true,
    combatUIAutoHide = false,
    showAllSlots = false,
    partyBuffEnabled = true,
    selfBuffEnabled = true,
    clickableBuffIcons = true,
    shieldEnabled = true,
    incomingHealEnabled = true,
    rangeCheckEnabled = true,
    showUnitTargets = true,
    hotEnabled = true,
    spellTrackerEnabled = true,
    spellTrackerSoundsEnabled = true,
    lowHealthSoundKey = C.LOW_HEALTH_DEFAULT_SOUND,
    lowHealthThreshold = C.LOW_HEALTH_DEFAULT_THRESHOLD,
    threatEnabled = true,
    threatPercentEnabled = true,
}

function E.InitializeSavedVariables(saved, characterSaved)
    local version = tonumber(saved.schemaVersion) or 0

    if version < 1 then
        if saved.partyBuffEnabled == nil then
            saved.partyBuffEnabled = saved.fortEnabled
        end
        if saved.selfBuffEnabled == nil then
            saved.selfBuffEnabled = saved.innerFireEnabled
        end

        if type(characterSaved.bindings) ~= "table" then
            characterSaved.bindings = {}
        end
        if next(characterSaved.bindings) == nil and type(saved.bindings) == "table" then
            for _, slot in ipairs(C.BINDING_SLOTS) do
                local value = saved.bindings[slot.key]
                if value ~= nil then
                    characterSaved.bindings[slot.key] = value
                end
            end
        end
    end

    if version < 3 and saved.lowHealthSoundEnabled == false then
        saved.lowHealthSoundKey = "none"
    end
    saved.lowHealthSoundEnabled = nil

    for key, defaultValue in pairs(FEATURE_DEFAULTS) do
        if saved[key] == nil then
            saved[key] = defaultValue
        end
    end
    if type(saved.hotDisabled) ~= "table" then
        saved.hotDisabled = {}
    end

    if type(characterSaved.bindings) ~= "table" then
        characterSaved.bindings = {}
    end
    if type(characterSaved.trackedSpells) ~= "table" then
        characterSaved.trackedSpells = {}
    end
    if type(characterSaved.selfBuffSelections) ~= "table" then
        characterSaved.selfBuffSelections = {}
    end
    if type(characterSaved.wheelMacros) ~= "table" then
        characterSaved.wheelMacros = {}
    end

    saved.schemaVersion = math.max(version, C.SAVED_VARIABLES_VERSION)
end

function E.ResolveKnownSpell(canonicalName, namePattern)
    if not GetNumSpellTabs then return false, nil end

    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        if offset and numSpells then
            for slot = offset + 1, offset + numSpells do
                local name = GetSpellBookItemName(slot, BOOKTYPE_SPELL)
                if name and name:find(namePattern) then
                    return true, name
                end
            end
        end
    end

    return false, nil
end

function E.ForEachDefinition(definitions, callback)
    for _, definition in ipairs(definitions) do
        local known, spellName = E.ResolveKnownSpell(
            definition.canonical,
            definition.pattern
        )
        callback(definition, known, spellName)
    end
end

function E.ResolveFirstKnown(definitions, fallbackIcon)
    for _, definition in ipairs(definitions) do
        local known, spellName = E.ResolveKnownSpell(
            definition.canonical,
            definition.pattern
        )
        if known then
            return {
                known = true,
                spellName = spellName,
                icon = definition.icon or fallbackIcon,
                auraIds = definition.auraIds,
                auraNames = definition.auraNames,
                definition = definition,
            }
        end
    end

    return {
        known = false,
        icon = fallbackIcon,
    }
end

function E.SeedClassBindings(bindings, classToken)
    local defaults = classToken and C.CLASS_HEALER_BINDING_DEFAULTS[classToken]
    if not defaults then return true, 0 end

    local added = 0
    for _, definition in ipairs(defaults) do
        local known, spellName = E.ResolveKnownSpell(
            definition.canonical,
            definition.pattern
        )
        if known and spellName then
            bindings[definition.key] = { name = spellName }
            added = added + 1
        end
    end

    -- False tells the caller that the spellbook may still be loading.
    return added > 0, added
end
