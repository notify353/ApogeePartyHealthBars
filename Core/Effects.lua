-- Spellbook-driven effect selection shared by party buffs, self buffs, HoTs,
-- and class-specific starter bindings.
local C = ApogeePartyHealthBars_C
local Actions = ApogeePartyHealthBars_ActionData

ApogeePartyHealthBars_Effects = {}

local E = ApogeePartyHealthBars_Effects

local FEATURE_DEFAULTS = {
    enabled = true,
    combatUIAutoHide = true,
    showAllSlots = true,
    actionFeedbackEnabled = true,
    automaticConsumablesEnabled = true,
    partyBuffEnabled = true,
    selfBuffEnabled = true,
    clickableBuffIcons = true,
    shieldEnabled = true,
    incomingHealEnabled = true,
    rangeCheckEnabled = true,
    showUnitTargets = true,
    hotEnabled = true,
    lowHealthSoundKey = C.LOW_HEALTH_DEFAULT_SOUND,
    lowHealthThreshold = C.LOW_HEALTH_DEFAULT_THRESHOLD,
    mentionAlertsEnabled = true,
    mentionSoundKey = "toast",
    mentionHighlightEnabled = true,
    cleanseWatchEnabled = true,
    cleanseWatchPoint = "TOPRIGHT",
    cleanseWatchRelPoint = "TOPRIGHT",
    cleanseWatchX = 0,
    cleanseWatchY = 0,
    threatEnabled = true,
    threatPercentEnabled = true,
    targetEffectRemindersEnabled = true,
    targetEffectRefreshThreshold = 3,
    dungeonBoardRole = "healer",
    dungeonBoardFeedEnabled = true,
    dungeonBoardSoundKey = "none",
    dungeonBoardLevelsBelow = 10,
    dungeonBoardLevelsAbove = 3,
    dungeonBoardFeedPoint = "CENTER",
    dungeonBoardFeedRelPoint = "CENTER",
    dungeonBoardFeedX = 0,
    dungeonBoardFeedY = 0,
    dungeonBoardPoint = "TOP",
    dungeonBoardRelPoint = "TOP",
    dungeonBoardX = 0,
    dungeonBoardY = -20,
}

local function NormalizeDotThreshold(value, fallback)
    value = tonumber(value)
    if not value or value ~= value then value = fallback end
    value = math.max(0, math.min(30, value))
    return math.floor(value + 0.5)
end

local function NormalizeDungeonBoardLevelOffset(value, fallback)
    value = tonumber(value)
    if not value or value ~= value then value = fallback end
    value = math.max(0, math.min(60, value))
    return math.floor(value + 0.5)
end

local function NormalizeDungeonBoardRole(value)
    if value == "tank" then return "tank" end
    return "healer"
end

-- Compatibility boundary for profiles created before the internal terminology
-- cleanup. Canonical fields win when both names are present.
local RENAMED_SETTINGS_FIELDS = {
    dotRemindersEnabled = "targetEffectRemindersEnabled",
    dotRefreshThreshold = "targetEffectRefreshThreshold",
    dotDisabled = "targetEffectDisabled",
    dotPriority = "targetEffectPriority",
    dotThresholds = "targetEffectThresholds",
    dotHudPoint = "targetEffectHudPoint",
    dotHudRelPoint = "targetEffectHudRelPoint",
    dotHudX = "targetEffectHudX",
    dotHudY = "targetEffectHudY",
}

local RENAMED_ACTION_FIELDS = {
    keyActions = "keyboardActions",
    wheelMacros = "mouseWheelActions",
    mouseActions = "mouseButtonActions",
}

local function MigrateRenamedFields(target, renamedFields)
    if type(target) ~= "table" then return end
    for legacyKey, canonicalKey in pairs(renamedFields) do
        if target[canonicalKey] == nil then target[canonicalKey] = target[legacyKey] end
        target[legacyKey] = nil
    end
end

function E.InitializeSavedVariables(saved, characterSaved)
    local version = tonumber(saved.schemaVersion) or 0
    MigrateRenamedFields(saved, RENAMED_SETTINGS_FIELDS)
    MigrateRenamedFields(characterSaved, RENAMED_ACTION_FIELDS)

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
    saved.spellTrackerEnabled = nil
    saved.spellTrackerSoundsEnabled = nil
    local dungeonBoardRole = saved.dungeonBoardRole
    if dungeonBoardRole ~= "tank" and dungeonBoardRole ~= "healer" then
        dungeonBoardRole = saved.dungeonBoardMode
    end
    saved.dungeonBoardRole = NormalizeDungeonBoardRole(dungeonBoardRole)
    saved.dungeonBoardMode = nil

    for key, defaultValue in pairs(FEATURE_DEFAULTS) do
        if saved[key] == nil then
            saved[key] = defaultValue
        end
    end
    -- Loading the addon is the enable action. The internal flag is only kept
    -- false for the remainder of a session after restoring owned bindings so
    -- the user can safely disable the addon through WoW's AddOns manager.
    saved.enabled = true
    if type(saved.hotDisabled) ~= "table" then
        saved.hotDisabled = {}
    end
    if type(saved.targetEffectDisabled) ~= "table" then saved.targetEffectDisabled = {} end
    if type(saved.targetEffectPriority) ~= "table" then saved.targetEffectPriority = {} end
    if type(saved.targetEffectThresholds) ~= "table" then saved.targetEffectThresholds = {} end
    saved.targetEffectRefreshThreshold = NormalizeDotThreshold(saved.targetEffectRefreshThreshold, 3)
    saved.dungeonBoardLevelsBelow = NormalizeDungeonBoardLevelOffset(
        saved.dungeonBoardLevelsBelow, 10)
    saved.dungeonBoardLevelsAbove = NormalizeDungeonBoardLevelOffset(
        saved.dungeonBoardLevelsAbove, 3)
    for key, value in pairs(saved.targetEffectThresholds) do
        if type(key) ~= "string" or type(value) ~= "number" or value ~= value then
            saved.targetEffectThresholds[key] = nil
        else
            saved.targetEffectThresholds[key] = NormalizeDotThreshold(value, 3)
        end
    end
    for key, value in pairs(saved.targetEffectDisabled) do
        if type(key) ~= "string" or value ~= true then saved.targetEffectDisabled[key] = nil end
    end
    local seenPriority, normalizedPriority = {}, {}
    for _, key in ipairs(saved.targetEffectPriority) do
        if type(key) == "string" and not seenPriority[key] then
            seenPriority[key] = true
            normalizedPriority[#normalizedPriority + 1] = key
        end
    end
    saved.targetEffectPriority = normalizedPriority

    if type(characterSaved.bindings) ~= "table" then
        characterSaved.bindings = {}
    end
    local legacyShortcuts = type(characterSaved.trackedSpells) == "table"
        and characterSaved.trackedSpells or nil
    if type(characterSaved.shortcuts) ~= "table"
        or (next(characterSaved.shortcuts) == nil and legacyShortcuts and next(legacyShortcuts) ~= nil) then
        characterSaved.shortcuts = legacyShortcuts or {}
    end
    if characterSaved.shortcutDefaultsVersion == nil then
        characterSaved.shortcutDefaultsVersion = characterSaved.trackerDefaultsVersion
    end
    characterSaved.trackedSpells = nil
    characterSaved.trackedSpellsSchemaVersion = nil
    characterSaved.trackerDefaultsVersion = nil
    if type(characterSaved.selfBuffSelections) ~= "table" then
        characterSaved.selfBuffSelections = {}
    end
    if type(characterSaved.mouseWheelActions) ~= "table" then
        characterSaved.mouseWheelActions = {}
    end
    if type(characterSaved.keyboardActions) ~= "table" then
        characterSaved.keyboardActions = {}
    end
    if type(characterSaved.mouseButtonActions) ~= "table" then
        characterSaved.mouseButtonActions = {}
    end

    saved.schemaVersion = math.max(version, C.SAVED_VARIABLES_VERSION)
end

function E.ResolveKnownSpell(canonicalName, namePattern)
    local spells = ApogeePartyHealthBars_PlayerSpells
    if spells and spells.ResolveKnownSpell then
        return spells.ResolveKnownSpell(canonicalName, namePattern)
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
            bindings[definition.key] = Actions.CreateSpell(nil, spellName)
            added = added + 1
        end
    end

    -- False tells the caller that the spellbook may still be loading.
    return added > 0, added
end
