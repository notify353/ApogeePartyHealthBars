local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S

ApogeePartyHealthBars_ProfileStore = {}
local Store = ApogeePartyHealthBars_ProfileStore

local SETTINGS_KEYS = {
    "schemaVersion", "enabled", "combatUIAutoHide", "showAllSlots", "actionFeedbackEnabled",
    "automaticConsumablesEnabled",
    "partyBuffEnabled", "selfBuffEnabled", "clickableBuffIcons", "shieldEnabled",
    "incomingHealEnabled", "rangeCheckEnabled", "showUnitTargets", "hotEnabled",
    "lowHealthSoundKey", "lowHealthThreshold", "threatEnabled", "threatPercentEnabled",
    "dotRemindersEnabled", "dotRefreshThreshold", "dotDisabled", "dotPriority", "dotThresholds",
    "dotHudPoint", "dotHudRelPoint", "dotHudX", "dotHudY",
    "hotDisabled", "point", "relPoint", "x", "y", "configPoint", "configRelPoint",
    "configX", "configY", "minimapAngle",
}
local ACTION_KEYS = {
    "bindings", "bindingSchemaVersion", "bindingDefaultsInitialized",
    "shortcuts", "shortcutSchemaVersion", "shortcutDefaultsVersion",
    "selfBuffSelections", "wheelMacros", "keyActions", "mouseActions",
}
local LEGACY_ACTION_KEYS = {
    "bindings", "bindingSchemaVersion", "bindingDefaultsInitialized",
    "shortcuts", "shortcutSchemaVersion", "shortcutDefaultsVersion",
    "selfBuffSelections", "wheelMacros", "keyActions", "mouseActions",
    "trackedSpells", "trackedSpellsSchemaVersion", "trackerDefaultsVersion",
}
local LEGACY_ACTION_CONTENT_KEYS = {
    "bindings", "shortcuts", "selfBuffSelections", "wheelMacros", "keyActions",
    "mouseActions", "trackedSpells",
}
local LEGACY_SETTINGS_KEYS = {
    "schemaVersion", "enabled", "combatUIAutoHide", "showAllSlots", "actionFeedbackEnabled",
    "automaticConsumablesEnabled",
    "partyBuffEnabled", "selfBuffEnabled", "clickableBuffIcons", "shieldEnabled",
    "incomingHealEnabled", "rangeCheckEnabled", "showUnitTargets", "hotEnabled",
    "lowHealthSoundKey", "lowHealthThreshold", "threatEnabled", "threatPercentEnabled",
    "dotRemindersEnabled", "dotRefreshThreshold", "dotDisabled", "dotPriority", "dotThresholds",
    "dotHudPoint", "dotHudRelPoint", "dotHudX", "dotHudY",
    "hotDisabled", "point", "relPoint", "x", "y", "configPoint", "configRelPoint",
    "configX", "configY", "minimapAngle", "fortEnabled", "innerFireEnabled",
    "lowHealthSoundEnabled", "spellTrackerEnabled", "spellTrackerSoundsEnabled", "bindings",
}
local ORDERED_COLLECTIONS = { bindings = true, shortcuts = true, slots = true, dotPriority = true }
local SETTINGS_TYPES = {
    schemaVersion = "number", enabled = "boolean", combatUIAutoHide = "boolean",
    showAllSlots = "boolean", actionFeedbackEnabled = "boolean", automaticConsumablesEnabled = "boolean",
    partyBuffEnabled = "boolean", selfBuffEnabled = "boolean",
    clickableBuffIcons = "boolean", shieldEnabled = "boolean", incomingHealEnabled = "boolean",
    rangeCheckEnabled = "boolean", showUnitTargets = "boolean", hotEnabled = "boolean",
    lowHealthSoundKey = "string", lowHealthThreshold = "number", threatEnabled = "boolean",
    dotRemindersEnabled = "boolean", dotRefreshThreshold = "number", dotDisabled = "table",
    dotPriority = "table", dotThresholds = "table", dotHudPoint = "string",
    dotHudRelPoint = "string", dotHudX = "number", dotHudY = "number",
    threatPercentEnabled = "boolean", hotDisabled = "table", point = "string",
    relPoint = "string", x = "number", y = "number", configPoint = "string",
    configRelPoint = "string", configX = "number", configY = "number", minimapAngle = "number",
}
local ACTION_TYPES = {
    bindings = "table", bindingSchemaVersion = "number", bindingDefaultsInitialized = "boolean",
    shortcuts = "table", shortcutSchemaVersion = "number", shortcutDefaultsVersion = "number",
    selfBuffSelections = "table", wheelMacros = "table", keyActions = "table", mouseActions = "table",
}
local LEGACY_SETTINGS_TYPES = {}
for key, valueType in pairs(SETTINGS_TYPES) do LEGACY_SETTINGS_TYPES[key] = valueType end
LEGACY_SETTINGS_TYPES.fortEnabled = "boolean"
LEGACY_SETTINGS_TYPES.innerFireEnabled = "boolean"
LEGACY_SETTINGS_TYPES.lowHealthSoundEnabled = "boolean"
LEGACY_SETTINGS_TYPES.spellTrackerEnabled = "boolean"
LEGACY_SETTINGS_TYPES.spellTrackerSoundsEnabled = "boolean"
LEGACY_SETTINGS_TYPES.bindings = "table"
local accountRoot, characterRoot, store, classToken, author
local LEGACY_ACCOUNT_STORE_VERSION = 1

local function isFiniteNumber(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function deepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do result[deepCopy(key, seen)] = deepCopy(child, seen) end
    return result
end

local function copyKeys(source, keys, expectedTypes)
    local result = {}
    source = type(source) == "table" and source or {}
    for _, key in ipairs(keys) do
        local expected = expectedTypes and expectedTypes[key]
        local validType = not expected or type(source[key]) == expected
        if expected == "number" then validType = isFiniteNumber(source[key]) end
        if source[key] ~= nil and validType then
            result[key] = deepCopy(source[key])
        end
    end
    return result
end

local function stripBoundActionRuntime(actions)
    for _, key in ipairs({ "wheelMacros", "keyActions", "mouseActions" }) do
        local state = actions[key]
        if type(state) == "table" then
            state.enabled = nil
            state.ownership = nil
            state.bindingVersion = nil
        end
    end
end

local function normalizePayload(payload)
    payload = type(payload) == "table" and payload or {}
    local payloadVersion = tonumber(payload.schemaVersion) or 0
    if payloadVersion > C.PROFILE_PAYLOAD_VERSION then
        error("Profile payload was created by a newer addon version.")
    end
    local settingsSource = payload.settings or payload.account or {}
    local actionsSource = payload.actions or payload.character or {}
    local result = {
        schemaVersion = C.PROFILE_PAYLOAD_VERSION,
        settings = copyKeys(settingsSource, SETTINGS_KEYS, SETTINGS_TYPES),
        actions = copyKeys(actionsSource, ACTION_KEYS, ACTION_TYPES),
    }
    stripBoundActionRuntime(result.actions)
    ApogeePartyHealthBars_Effects.InitializeSavedVariables(result.settings, result.actions)
    result.schemaVersion = C.PROFILE_PAYLOAD_VERSION
    return result
end

local function tryNormalizePayload(payload)
    local ok, normalized = pcall(normalizePayload, payload)
    if not ok then return nil, tostring(normalized) end
    return normalized
end

local function trimmedName(value)
    return type(value) == "string" and value:match("^%s*(.-)%s*$") or ""
end

local function characterCount(value)
    local count = 0
    for index = 1, #value do
        local byte = value:byte(index)
        if byte < 128 or byte >= 192 then count = count + 1 end
    end
    return count
end

local function truncateCharacters(value, maximum)
    local count, last = 0, 0
    for index = 1, #value do
        local byte = value:byte(index)
        if byte < 128 or byte >= 192 then
            count = count + 1
            if count > maximum then break end
        end
        last = index
    end
    return value:sub(1, last)
end

local function nameExists(name, exceptId, forClass)
    local lowered = name:lower()
    for id, profile in pairs(store.profiles) do
        if id ~= exceptId and profile.classToken == (forClass or classToken)
            and type(profile.name) == "string" and profile.name:lower() == lowered then
            return true
        end
    end
    return false
end

local function validateNameShape(name)
    name = trimmedName(name)
    local length = characterCount(name)
    if length < 1 or length > 40 then return nil, "Profile names must be 1-40 characters." end
    if name:find("[%c]") then return nil, "Profile names cannot contain control characters." end
    return name
end

local function validateName(name, exceptId, forClass)
    local valid, message = validateNameShape(name)
    if not valid then return nil, message end
    name = valid
    if nameExists(name, exceptId, forClass) then return nil, "A profile with that name already exists." end
    return name
end

local function uniqueName(base, forClass)
    base = trimmedName(base)
    if base == "" then base = "Profile" end
    base = truncateCharacters(base, 40)
    if not nameExists(base, nil, forClass) then return base end
    local index = 2
    while true do
        local suffix = " (" .. index .. ")"
        local candidate = truncateCharacters(base, 40 - characterCount(suffix)) .. suffix
        if not nameExists(candidate, nil, forClass) then return candidate end
        index = index + 1
    end
end

local function safeAuthor(value)
    value = trimmedName(value):gsub("[%c]", "")
    if value == "" then value = "Unknown" end
    return truncateCharacters(value, 80)
end

local function nextId()
    local candidate = store.nextId
    if not isFiniteNumber(candidate) or candidate < 1 then
        candidate = 1
    else
        candidate = math.floor(candidate)
    end
    store.nextId = candidate
    local id
    repeat
        id = "p" .. tostring(store.nextId)
        store.nextId = store.nextId + 1
    until store.profiles[id] == nil
    return id
end

local hasLegacyActions

local function hasMeaningfulLegacySettings(root)
    root = type(root) == "table" and root or {}
    for _, key in ipairs(LEGACY_SETTINGS_KEYS) do
        if key ~= "schemaVersion" and key ~= "bindings" and root[key] ~= nil then
            return true
        end
    end
    return false
end

local function addProfile(name, profileClass, payload, profileAuthor)
    local normalized, message = tryNormalizePayload(payload)
    if not normalized then return nil, message end
    local id = nextId()
    store.profiles[id] = {
        id = id,
        name = uniqueName(name, profileClass),
        classToken = profileClass,
        author = safeAuthor(profileAuthor or author),
        createdAt = time and time() or 0,
        modifiedAt = time and time() or 0,
        payload = normalized,
    }
    store.order[#store.order + 1] = id
    return store.profiles[id]
end

local function newStore()
    return {
        schemaVersion = C.PROFILE_STORE_VERSION,
        nextId = 1,
        profiles = {},
        order = {},
        activeProfileId = nil,
    }
end

local function copyProfile(target, id, source, targetClass, settingsOnly)
    if type(id) ~= "string" or not id:match("^p%d+$") or type(source) ~= "table" then
        return nil, "Profile identity is malformed."
    end
    if target.profiles[id] then return nil, "Profile identity is duplicated." end
    local payloadSource = source.payload
    if settingsOnly then
        local safeSettings = deepCopy(
            type(source.payload) == "table" and source.payload.settings or {})
        safeSettings.hotDisabled = nil
        payloadSource = {
            settings = safeSettings,
            actions = {},
        }
    end
    local normalized, message = tryNormalizePayload(payloadSource)
    if not normalized then return nil, message end
    local profileName = settingsOnly and "Default"
        or truncateCharacters(trimmedName(source.name), 40)
    if profileName == "" then profileName = "Default" end
    local baseName, suffix = profileName, 2
    local duplicate = true
    while duplicate do
        duplicate = false
        for _, existing in pairs(target.profiles) do
            if existing.name:lower() == profileName:lower() then duplicate = true; break end
        end
        if duplicate then
            local tail = " (" .. suffix .. ")"
            profileName = truncateCharacters(baseName, 40 - characterCount(tail)) .. tail
            suffix = suffix + 1
        end
    end
    local profile = {
        id = id,
        name = profileName,
        classToken = targetClass,
        author = settingsOnly and author or safeAuthor(source.author),
        createdAt = isFiniteNumber(source.createdAt) and source.createdAt or 0,
        modifiedAt = isFiniteNumber(source.modifiedAt) and source.modifiedAt or 0,
        payload = normalized,
    }
    target.profiles[id] = profile
    target.order[#target.order + 1] = id
    return profile
end

local function finishStore(candidate)
    local maximum = 0
    for id in pairs(candidate.profiles) do
        local numeric = tonumber(id:match("^p(%d+)$"))
        if numeric and numeric > maximum then maximum = numeric end
    end
    local requested = isFiniteNumber(candidate.nextId) and math.floor(candidate.nextId) or 1
    candidate.nextId = math.max(1, requested, maximum + 1)
    candidate.schemaVersion = C.PROFILE_STORE_VERSION
    return candidate
end

local function normalizeCharacterStore(source)
    local version = tonumber(source and source.schemaVersion) or 0
    if version > C.PROFILE_STORE_VERSION then
        error("Character profile storage was created by a newer addon version.")
    end
    if version ~= C.PROFILE_STORE_VERSION then return nil end
    if type(source.profiles) ~= "table" or type(source.order) ~= "table" then
        error("Character profile storage is malformed.")
    end

    local candidate = newStore()
    candidate.nextId = source.nextId
    local seen = {}
    for _, id in ipairs(source.order) do
        local profile = source.profiles[id]
        if seen[id] or not profile or profile.id ~= id then
            error("Character profile storage order is malformed.")
        end
        if profile.classToken ~= classToken then
            error("Character profile storage contains a profile for another class.")
        end
        local copied, message = copyProfile(candidate, id, profile, classToken, false)
        if not copied then error(message or "Character profile storage is malformed.") end
        seen[id] = true
    end
    for id in pairs(source.profiles) do
        if not seen[id] then error("Character profile storage contains an unordered profile.") end
    end
    candidate.activeProfileId = source.activeProfileId
    if candidate.activeProfileId and not candidate.profiles[candidate.activeProfileId] then
        error("Character profile storage has an invalid active profile.")
    end
    return finishStore(candidate)
end

local function migrateLegacyStore(savedAccountRoot, savedCharacterRoot)
    local candidate = newStore()
    local legacyStore = type(savedAccountRoot) == "table" and savedAccountRoot.profileStore or nil
    local legacyVersion = tonumber(legacyStore and legacyStore.schemaVersion) or 0
    if legacyVersion > LEGACY_ACCOUNT_STORE_VERSION then
        error("Legacy account profile storage was created by a newer addon version.")
    end

    local selectedId = savedCharacterRoot.activeProfileId
    local selectedSource
    if type(legacyStore) == "table" then
        if type(legacyStore.profiles) ~= "table" or type(legacyStore.order) ~= "table" then
            error("Legacy account profile storage is malformed.")
        end
        selectedSource = legacyStore.profiles[selectedId]
        candidate.nextId = legacyStore.nextId
        local seen = {}
        for _, id in ipairs(legacyStore.order) do
            local profile = legacyStore.profiles[id]
            if seen[id] or type(profile) ~= "table" or profile.id ~= id then
                error("Legacy account profile storage order is malformed.")
            end
            seen[id] = true
            local ownedUnknown = author ~= "Unknown" and profile.classToken == "UNKNOWN"
                and safeAuthor(profile.author) == author
            if profile.classToken == classToken or ownedUnknown then
                local copied, message = copyProfile(candidate, id, profile, classToken, false)
                if not copied then error(message or "Legacy profile could not be migrated.") end
            end
        end
        for id in pairs(legacyStore.profiles) do
            if not seen[id] then error("Legacy account profile storage contains an unordered profile.") end
        end
        if candidate.profiles[selectedId] then
            candidate.activeProfileId = selectedId
        elseif type(selectedSource) == "table" then
            local copied, message = copyProfile(candidate, selectedId, selectedSource, classToken, true)
            if not copied then error(message or "Legacy profile settings could not be migrated.") end
            candidate.activeProfileId = copied.id
        end
    end

    if #candidate.order == 0 then
        local settingsSource = type(legacyStore) == "table"
            and legacyStore.legacySettingsTemplate or savedAccountRoot
        local legacySettings = copyKeys(settingsSource, LEGACY_SETTINGS_KEYS, LEGACY_SETTINGS_TYPES)
        legacySettings.bindings = nil
        legacySettings.hotDisabled = nil
        local legacyActions = deepCopy(savedCharacterRoot)
        local migratedActions = hasLegacyActions(savedCharacterRoot)
        local migratedSettings = type(legacyStore) ~= "table"
            and hasMeaningfulLegacySettings(legacySettings)
        ApogeePartyHealthBars_Effects.InitializeSavedVariables(legacySettings, legacyActions)
        local id = "p1"
        local profile, message = copyProfile(candidate, id, {
            id = id,
            name = (migratedActions or migratedSettings) and author or "Default",
            classToken = classToken,
            author = author,
            payload = { settings = legacySettings, actions = legacyActions },
        }, classToken, false)
        if not profile then error(message or "Legacy character data could not be migrated.") end
        candidate.activeProfileId = id
    elseif not candidate.activeProfileId then
        candidate.activeProfileId = candidate.order[1]
    end

    return finishStore(candidate)
end

local function hasNestedActionContent(value)
    if type(value) ~= "table" then return value ~= nil end
    for key, nested in pairs(value) do
        if key ~= "schemaVersion" and key ~= "defaultsVersion"
            and hasNestedActionContent(nested) then
            return true
        end
    end
    return false
end

hasLegacyActions = function(root)
    for _, key in ipairs(LEGACY_ACTION_CONTENT_KEYS) do
        if hasNestedActionContent(root[key]) then return true end
    end
    return false
end

local function clearLegacy(root, keys)
    for _, key in ipairs(keys) do root[key] = nil end
end

local function captureBindingRuntime(source, target)
    source = type(source) == "table" and source or {}
    target = type(target) == "table" and target or {}
    for _, stateKey in ipairs({ "wheelMacros", "keyActions", "mouseActions" }) do
        local saved = source[stateKey]
        if type(saved) == "table" then
            local runtime = type(target[stateKey]) == "table" and target[stateKey] or {}
            if type(runtime.ownership) ~= "table" and type(saved.ownership) == "table" then
                runtime.ownership = deepCopy(saved.ownership)
            end
            if runtime.bindingVersion == nil and saved.bindingVersion ~= nil then
                runtime.bindingVersion = saved.bindingVersion
            end
            if next(runtime) ~= nil then target[stateKey] = runtime end
        end
    end
    return target
end

local function bindActiveProfile()
    local profile = store.profiles[store.activeProfileId]
    if not profile then profile = addProfile("Default", classToken, {}, author) end
    if profile.classToken ~= classToken then
        error("Active profile belongs to another class.")
    end
    store.activeProfileId = profile.id
    profile.payload = normalizePayload(profile.payload)
    S.sv = profile.payload.settings
    S.charSv = profile.payload.actions
    return profile
end

local function deepMerge(target, source, keyName)
    if type(source) ~= "table" then return deepCopy(source) end
    if ORDERED_COLLECTIONS[keyName] then return deepCopy(source) end
    local result = type(target) == "table" and deepCopy(target) or {}
    for key, value in pairs(source) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = deepMerge(result[key], value, key)
        else
            result[key] = deepCopy(value)
        end
    end
    return result
end

function Store.Initialize(savedAccountRoot, savedCharacterRoot, currentClass, currentAuthor)
    accountRoot = type(savedAccountRoot) == "table" and savedAccountRoot or {}
    characterRoot = type(savedCharacterRoot) == "table" and savedCharacterRoot or {}
    if type(currentClass) ~= "string" or not currentClass:match("^[A-Z]+$")
        or currentClass == "UNKNOWN" then
        error("Player class is unavailable; profile storage was not initialized.")
    end
    classToken = currentClass
    author = safeAuthor(currentAuthor)

    local candidate = normalizeCharacterStore(characterRoot.profileStore)
        or migrateLegacyStore(accountRoot, characterRoot)
    local bindingRuntime = captureBindingRuntime(characterRoot, characterRoot.bindingRuntime)

    characterRoot.profileStore = candidate
    characterRoot.bindingRuntime = bindingRuntime
    characterRoot.profileStateVersion = nil
    characterRoot.activeProfileId = nil
    clearLegacy(characterRoot, LEGACY_ACTION_KEYS)
    store = candidate
    S.accountRoot, S.characterRoot = accountRoot, characterRoot
    return bindActiveProfile()
end

function Store.GetActiveProfile() return store and store.profiles[store.activeProfileId] end
function Store.GetActiveId() return store and store.activeProfileId end
function Store.GetAuthor() return author end
function Store.GetClassToken() return classToken end

function Store.GetBindingRuntime(stateKey)
    if not characterRoot then return nil end
    characterRoot.bindingRuntime = characterRoot.bindingRuntime or {}
    if type(characterRoot.bindingRuntime[stateKey]) ~= "table" then
        characterRoot.bindingRuntime[stateKey] = {}
    end
    return characterRoot.bindingRuntime[stateKey]
end

function Store.List()
    local result = {}
    if not store then return result end
    for _, id in ipairs(store.order) do
        local profile = store.profiles[id]
        if profile and profile.classToken == classToken then result[#result + 1] = profile end
    end
    return result
end

function Store.Get(id) return store and store.profiles[id] end
function Store.NormalizePayload(payload) return normalizePayload(payload) end
function Store.DeepCopy(value) return deepCopy(value) end
function Store.ValidateName(name, exceptId) return validateName(name, exceptId, classToken) end

function Store.Create(name)
    local valid, message = validateName(name, nil, classToken)
    if not valid then return nil, message end
    return addProfile(valid, classToken, {}, author)
end

function Store.Duplicate(id, name)
    local source = store.profiles[id]
    if not source or source.classToken ~= classToken then return nil, "Profile not found." end
    local valid, message = validateName(name, nil, classToken)
    if not valid then return nil, message end
    return addProfile(valid, classToken, source.payload, author)
end

function Store.Rename(id, name)
    local profile = store.profiles[id]
    if not profile or profile.classToken ~= classToken then return false, "Profile not found." end
    local valid, message = validateName(name, id, classToken)
    if not valid then return false, message end
    profile.name, profile.modifiedAt = valid, time and time() or 0
    return true
end

function Store.Delete(id)
    local profile = store.profiles[id]
    if not profile or profile.classToken ~= classToken then return false, "Profile not found." end
    if id == store.activeProfileId then return false, "Switch profiles before deleting the active profile." end
    if #Store.List() <= 1 then return false, "The last profile cannot be deleted." end
    store.profiles[id] = nil
    for index, orderedId in ipairs(store.order) do
        if orderedId == id then table.remove(store.order, index); break end
    end
    return true
end

function Store.SetActive(id)
    local profile = store.profiles[id]
    if not profile or profile.classToken ~= classToken then return false, "Profile not found for this class." end
    local normalized, message = tryNormalizePayload(profile.payload)
    if not normalized then return false, message end
    profile.payload = normalized
    store.activeProfileId = id
    bindActiveProfile()
    return true
end

function Store.ValidateProfile(id)
    local profile = store and store.profiles[id]
    if not profile or profile.classToken ~= classToken then
        return false, "Profile not found for this class."
    end
    local normalized, message = tryNormalizePayload(profile.payload)
    return normalized ~= nil, message
end

function Store.CopyFrom(sourceId, targetId)
    local source, target = store.profiles[sourceId], store.profiles[targetId]
    if not source or not target or source.classToken ~= classToken or target.classToken ~= classToken then
        return false, "Profile not found."
    end
    local normalized, message = tryNormalizePayload(source.payload)
    if not normalized then return false, message end
    target.payload = normalized
    target.author, target.modifiedAt = author, time and time() or 0
    if targetId == store.activeProfileId then bindActiveProfile() end
    return true
end

function Store.AddImported(envelope)
    if envelope.classToken ~= classToken then return nil, "This profile belongs to another class." end
    local valid, message = validateNameShape(envelope.profileName)
    if not valid then return nil, message end
    return addProfile(valid, classToken, envelope.payload, envelope.author)
end

function Store.ReplaceImported(targetId, envelope)
    local target = store.profiles[targetId]
    if not target or target.classToken ~= classToken then return false, "Profile not found." end
    if envelope.classToken ~= classToken then return false, "This profile belongs to another class." end
    local normalized, message = tryNormalizePayload(envelope.payload)
    if not normalized then return false, message end
    target.payload = normalized
    target.author = safeAuthor(envelope.author)
    target.modifiedAt = time and time() or 0
    if targetId == store.activeProfileId then bindActiveProfile() end
    return true
end

function Store.MergeImported(targetId, envelope)
    local target = store.profiles[targetId]
    if not target or target.classToken ~= classToken then return false, "Profile not found." end
    if envelope.classToken ~= classToken then return false, "This profile belongs to another class." end
    local normalized, message = tryNormalizePayload(deepMerge(target.payload, envelope.payload))
    if not normalized then return false, message end
    target.payload = normalized
    target.author, target.modifiedAt = author, time and time() or 0
    if targetId == store.activeProfileId then bindActiveProfile() end
    return true
end

function Store.Exportable(id)
    local profile = store.profiles[id]
    if not profile or profile.classToken ~= classToken then return nil end
    local copy = deepCopy(profile)
    local normalized = tryNormalizePayload(copy.payload)
    if not normalized then return nil end
    copy.payload = normalized
    return copy
end

function Store.ResetCharacter()
    if not characterRoot or not classToken then return nil, "Profile storage is not ready." end
    local freshStore = newStore()
    local previousStore = store
    store = freshStore
    local profile, message = addProfile("Default", classToken, {}, author)
    if not profile then store = previousStore; return nil, message end
    freshStore.activeProfileId = profile.id
    local freshRoot = {
        profileStore = finishStore(freshStore),
        bindingRuntime = {},
    }
    characterRoot, store = freshRoot, freshStore
    S.characterRoot = freshRoot
    bindActiveProfile()
    return freshRoot
end
