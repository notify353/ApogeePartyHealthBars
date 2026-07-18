local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S

ApogeePartyHealthBars_ProfileStore = {}
local Store = ApogeePartyHealthBars_ProfileStore

local SETTINGS_KEYS = {
    "schemaVersion", "enabled", "combatUIAutoHide", "showAllSlots",
    "partyBuffEnabled", "selfBuffEnabled", "clickableBuffIcons", "shieldEnabled",
    "incomingHealEnabled", "rangeCheckEnabled", "showUnitTargets", "hotEnabled",
    "lowHealthSoundKey", "lowHealthThreshold", "threatEnabled", "threatPercentEnabled",
    "hotDisabled", "point", "relPoint", "x", "y", "configPoint", "configRelPoint",
    "configX", "configY", "minimapAngle",
}
local ACTION_KEYS = {
    "bindings", "bindingSchemaVersion", "bindingDefaultsInitialized",
    "shortcuts", "shortcutSchemaVersion", "shortcutDefaultsVersion",
    "selfBuffSelections", "wheelMacros", "keyActions", "mouseActions",
}
local LEGACY_SETTINGS_KEYS = {
    "schemaVersion", "enabled", "combatUIAutoHide", "showAllSlots",
    "partyBuffEnabled", "selfBuffEnabled", "clickableBuffIcons", "shieldEnabled",
    "incomingHealEnabled", "rangeCheckEnabled", "showUnitTargets", "hotEnabled",
    "lowHealthSoundKey", "lowHealthThreshold", "threatEnabled", "threatPercentEnabled",
    "hotDisabled", "point", "relPoint", "x", "y", "configPoint", "configRelPoint",
    "configX", "configY", "minimapAngle", "fortEnabled", "innerFireEnabled",
    "lowHealthSoundEnabled", "spellTrackerEnabled", "spellTrackerSoundsEnabled", "bindings",
}
local ORDERED_COLLECTIONS = { bindings = true, shortcuts = true, slots = true }
local SETTINGS_TYPES = {
    schemaVersion = "number", enabled = "boolean", combatUIAutoHide = "boolean",
    showAllSlots = "boolean", partyBuffEnabled = "boolean", selfBuffEnabled = "boolean",
    clickableBuffIcons = "boolean", shieldEnabled = "boolean", incomingHealEnabled = "boolean",
    rangeCheckEnabled = "boolean", showUnitTargets = "boolean", hotEnabled = "boolean",
    lowHealthSoundKey = "string", lowHealthThreshold = "number", threatEnabled = "boolean",
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

local function profileCount()
    local count = 0
    for _ in pairs(store.profiles) do count = count + 1 end
    return count
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

local function hasLegacyActions(root)
    for _, key in ipairs(ACTION_KEYS) do
        if root[key] ~= nil then return true end
    end
    return false
end

local function mergeLegacyActions(template, character)
    local result = copyKeys(template, ACTION_KEYS, ACTION_TYPES)
    local saved = copyKeys(character, ACTION_KEYS, ACTION_TYPES)
    for key, value in pairs(saved) do
        local keepTemplateBindings = key == "bindings" and next(value) == nil
            and type(result.bindings) == "table" and next(result.bindings) ~= nil
        if not keepTemplateBindings then result[key] = value end
    end
    return result
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
    local profile = store.profiles[characterRoot.activeProfileId]
    if not profile or profile.classToken ~= classToken then
        for _, id in ipairs(store.order) do
            local candidate = store.profiles[id]
            if candidate and candidate.classToken == classToken then profile = candidate; break end
        end
    end
    if not profile then profile = addProfile("Default", classToken, {}, author) end
    characterRoot.activeProfileId = profile.id
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
    classToken = currentClass or "UNKNOWN"
    author = currentAuthor or "Unknown"
    S.accountRoot, S.characterRoot = accountRoot, characterRoot

    local characterVersion = tonumber(characterRoot.profileStateVersion) or 0
    if characterVersion > C.PROFILE_STORE_VERSION then
        error("Character profile state was created by a newer addon version.")
    end

    if type(accountRoot.profileStore) ~= "table" then
        local legacyDataPresent = false
        for _, key in ipairs(LEGACY_SETTINGS_KEYS) do
            if accountRoot[key] ~= nil then legacyDataPresent = true; break end
        end
        local legacySettings = copyKeys(accountRoot, LEGACY_SETTINGS_KEYS, LEGACY_SETTINGS_TYPES)
        local legacyActionTemplate = {}
        ApogeePartyHealthBars_Effects.InitializeSavedVariables(legacySettings, legacyActionTemplate)
        accountRoot.profileStore = {
            schemaVersion = C.PROFILE_STORE_VERSION,
            nextId = 1,
            profiles = {},
            order = {},
            legacyDataPresent = legacyDataPresent,
            legacySettingsTemplate = copyKeys(legacySettings, SETTINGS_KEYS, SETTINGS_TYPES),
            legacyActionTemplate = copyKeys(legacyActionTemplate, ACTION_KEYS, ACTION_TYPES),
        }
    end
    store = accountRoot.profileStore
    local storedVersion = tonumber(store.schemaVersion) or 0
    if storedVersion > C.PROFILE_STORE_VERSION then
        error("Profile storage was created by a newer addon version.")
    end
    store.schemaVersion = C.PROFILE_STORE_VERSION
    if type(store.profiles) ~= "table" then store.profiles = {} end
    if type(store.order) ~= "table" then store.order = {} end
    if not isFiniteNumber(store.nextId) or store.nextId < 1 then
        store.nextId = 1
    else
        store.nextId = math.floor(store.nextId)
    end
    if type(store.legacySettingsTemplate) ~= "table" then
        store.legacySettingsTemplate = copyKeys(accountRoot, SETTINGS_KEYS, SETTINGS_TYPES)
    end
    if type(store.legacyActionTemplate) ~= "table" then store.legacyActionTemplate = {} end
    if store.legacyDataPresent == nil then
        store.legacyDataPresent = next(store.legacySettingsTemplate) ~= nil
    end

    for _, profile in pairs(store.profiles) do
        if type(profile) == "table" then
            local normalized = tryNormalizePayload(profile.payload)
            if normalized then profile.payload = normalized end
        end
    end

    characterRoot.bindingRuntime = captureBindingRuntime(characterRoot, characterRoot.bindingRuntime)
    if characterVersion ~= C.PROFILE_STORE_VERSION then
        local legacyActions = mergeLegacyActions(store.legacyActionTemplate, characterRoot)
        local migrated = hasLegacyActions(characterRoot) or store.legacyDataPresent == true
        local name = migrated and author or "Default"
        local profile = addProfile(name, classToken, {
            settings = store.legacySettingsTemplate,
            actions = legacyActions,
        }, author)
        characterRoot.activeProfileId = profile.id
        characterRoot.profileStateVersion = C.PROFILE_STORE_VERSION
        clearLegacy(characterRoot, ACTION_KEYS)
    end
    if type(characterRoot.bindingRuntime) ~= "table" then characterRoot.bindingRuntime = {} end
    clearLegacy(accountRoot, SETTINGS_KEYS)
    accountRoot.schemaVersion = C.PROFILE_STORE_VERSION
    return bindActiveProfile()
end

function Store.GetActiveProfile() return store and store.profiles[characterRoot.activeProfileId] end
function Store.GetActiveId() return characterRoot and characterRoot.activeProfileId end
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
    if id == characterRoot.activeProfileId then return false, "Switch profiles before deleting the active profile." end
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
    characterRoot.activeProfileId = id
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
    if targetId == characterRoot.activeProfileId then bindActiveProfile() end
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
    if targetId == characterRoot.activeProfileId then bindActiveProfile() end
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
    if targetId == characterRoot.activeProfileId then bindActiveProfile() end
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
