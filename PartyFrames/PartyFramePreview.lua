local Preview = {}
ApogeePartyHealthBars.Define("Runtime", "PartyFramePreview", Preview)

local D
local active = false
local scenarioKey = "mana"
local onChanged

local SCENARIOS = {
    { key = "mana", label = "Out of combat" },
    { key = "combat", label = "Combat" },
}

local BASE_MODELS = {
    {
        guid = "preview-player", unitId = "player", name = "Ironwall",
        classToken = "WARRIOR", health = 4280, healthMax = 5200,
        powerChannels = { { powerType = 1, powerToken = "RAGE", value = 38, maximum = 100 } },
        shield = 260, incoming = 420,
    },
    {
        guid = "preview-healer", unitId = "party1", name = "Elowyn",
        classToken = "PRIEST", health = 2840, healthMax = 3100,
        powerChannels = { { powerType = 0, powerToken = "MANA", value = 2760, maximum = 3400 } },
        hots = { { value = 0.72, color = { 0.36, 0.82, 0.48, 1 } } },
    },
    {
        guid = "preview-mage", unitId = "party2", name = "Spellweave",
        classToken = "MAGE", health = 1980, healthMax = 2700,
        powerChannels = { { powerType = 0, powerToken = "MANA", value = 2260, maximum = 3000 } },
    },
    {
        guid = "preview-rogue", unitId = "party3", name = "Quickshiv",
        classToken = "ROGUE", health = 2380, healthMax = 3000,
        powerChannels = { { powerType = 3, powerToken = "ENERGY", value = 74, maximum = 100 } },
    },
    {
        guid = "preview-druid", unitId = "party4", name = "Mosscaller",
        classToken = "DRUID", health = 2460, healthMax = 3200,
        powerChannels = {
            { powerType = 0, powerToken = "MANA", value = 2100, maximum = 2800 },
            { powerType = 3, powerToken = "ENERGY", value = 52, maximum = 100 },
        },
    },
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

local function modelsForScenario(key)
    local models = copy(BASE_MODELS)
    if key == "mana" then
        models[2].powerChannels[1].value = 2890
        models[3].powerChannels[1].value = 540
        models[1].health, models[1].incoming = 3560, 780
    elseif key == "combat" then
        models[1].health, models[1].incoming = 2480, 860
        models[2].health = 1960
        models[3].health = 1340
        models[4].health = 1620
        models[5].health = 2040
    end
    return models
end

local function snapshotForScenario(key, models)
    local snapshot = {
        eligible = true, visible = key ~= "combat",
        pullVisible = key ~= "combat" and D.Runtime.CanPlayerPull(),
        auraAvailable = true,
        sayAvailable = D.Runtime.CanSendSay() == true,
        manaRows = {},
        buffIssues = {},
    }
    if key == "mana" then
        local now = GetTime and GetTime() or 0
        snapshot.manaRows = {
            {
                guid = models[2].guid, unitId = models[2].unitId,
                name = models[2].name, fullName = models[2].name,
                classToken = models[2].classToken, percent = 85,
                drinkState = "detected",
                drinkAuraSpellId = 430,
                drinkAuraIcon = "Interface\\Icons\\INV_Drink_07",
                drinkAuraDuration = 30,
                drinkAuraExpirationTime = now + 18,
            },
            {
                guid = models[3].guid, unitId = models[3].unitId,
                name = models[3].name, fullName = models[3].name,
                classToken = models[3].classToken, percent = 18,
                drinkState = "notDetected",
            },
        }
        snapshot.buffIssues = {
            {
                key = "fortitude", label = "Fortitude", abbrev = "fort",
                icon = "Interface\\Icons\\Spell_Holy_WordFortitude",
                providerClassToken = "PRIEST",
                providerGuids = { models[2].guid }, missingCount = 4,
                missingNames = {
                    models[1].name, models[3].name, models[4].name, models[5].name,
                },
            },
            {
                key = "spirit", label = "Divine Spirit", abbrev = "spirit",
                icon = "Interface\\Icons\\Spell_Holy_DivineSpirit",
                providerClassToken = "PRIEST",
                providerGuids = { models[2].guid }, missingCount = 3,
                missingNames = { models[3].name, models[4].name, models[5].name },
            },
            {
                key = "intellect", label = "Arcane Intellect", abbrev = "int",
                icon = "Interface\\Icons\\Spell_Holy_MagicalSentry",
                providerClassToken = "MAGE",
                providerGuids = { models[3].guid }, missingCount = 2,
                missingNames = { models[2].name, models[5].name },
            },
            {
                key = "mark", label = "Mark of the Wild", abbrev = "mark",
                icon = "Interface\\Icons\\Spell_Nature_Regeneration",
                providerClassToken = "DRUID",
                providerGuids = { models[5].guid }, missingCount = 5,
                missingNames = {
                    models[1].name, models[2].name, models[3].name,
                    models[4].name, models[5].name,
                },
            },
        }
    end
    return snapshot
end

local function threatSnapshotForScenario(key, models)
    if key ~= "combat" then return { inCombat = false, details = {} } end
    return {
        inCombat = true,
        hasTarget = true,
        details = {
            [models[1].guid] = { isTanking = true, status = 3, scaledPercent = 100 },
            [models[2].guid] = { isTanking = false, status = 1, scaledPercent = 38 },
            [models[3].guid] = { isTanking = false, status = 2, scaledPercent = 76 },
            [models[4].guid] = { isTanking = false, status = 2, scaledPercent = 91 },
            [models[5].guid] = { isTanking = false, status = 1, scaledPercent = 44 },
        },
    }
end

local function notify()
    if onChanged then onChanged(scenarioKey) end
end

local function setModels(models)
    for index, row in ipairs(D.Rows) do
        local model = models[index]
        row.previewGuid = model and model.guid or nil
        row.primary:SetPreviewModel(model)
        row.target:ClearPreviewModel()
    end
end

local function restoreLive()
    for _, row in ipairs(D.Rows) do
        row.previewGuid = nil
        for _, surface in ipairs(row.surfaces) do surface:ClearPreviewModel() end
    end
    D.Presentation.ClearPreview()
    D.Threat.ClearPreview()
    D.RestoreLive()
end

function Preview.SetScenario(key)
    if not active then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    local known = false
    for _, entry in ipairs(SCENARIOS) do
        if entry.key == key then known = true; break end
    end
    if not known then key = "mana" end
    scenarioKey = key
    local models = modelsForScenario(key)
    setModels(models)
    D.Presentation.SetPreview(snapshotForScenario(key, models))
    D.Threat.SetPreview(threatSnapshotForScenario(key, models))
    D.RequestLayoutUpdate()
    notify()
    return true
end

function Preview.SetActive(enabled)
    enabled = enabled == true
    if enabled and InCombatLockdown and InCombatLockdown() then return false end
    if active == enabled then
        if active then Preview.SetScenario(scenarioKey) end
        return false
    end
    active = enabled
    if active then
        D.DisableSecureActions()
        Preview.SetScenario(scenarioKey)
    else
        -- Preview ownership is ordinary Lua state, so clear it immediately even
        -- in combat. RestoreLive uses the combat-safe values path and defers its
        -- protected reconciliation through SecureFrames.
        restoreLive()
        notify()
    end
    return true
end

function Preview.IsActive() return active end
function Preview.GetScenario() return scenarioKey end
function Preview.GetScenarios() return copy(SCENARIOS) end
function Preview.SetChangedCallback(callback) onChanged = callback end
function Preview.RefreshAfterCombat() return false end

function Preview.Initialize(deps)
    for _, key in ipairs({
        "Rows", "Presentation", "Threat", "RequestLayoutUpdate",
        "DisableSecureActions", "RestoreLive", "Runtime",
    }) do
        assert(deps and deps[key] ~= nil, "PartyFramePreview missing dependency: " .. key)
    end
    D = deps
end
