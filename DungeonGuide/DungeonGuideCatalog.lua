ApogeePartyHealthBars_DungeonGuideCatalog = {}
local C = ApogeePartyHealthBars_DungeonGuideCatalog

local LIVE_TEXT_LIMIT = 72
local RATIONALE_TEXT_LIMIT = 140
local RESPONSE_TEXT_LIMIT = 140
local CC_TEXT_LIMIT = 110
local ABILITY_TEXT_LIMIT = 60
local EXCEPTION_TEXT_LIMIT = 140
local RULE_TEXT_LIMIT = 180
local MARKERS = {
    skull = { key = "skull", label = "SKULL", index = 8 },
    cross = { key = "cross", label = "CROSS", index = 7 },
    moon = { key = "moon", label = "MOON", index = 5 },
    none = { key = "none", label = "NO MARK" },
}
local guides, guideOrder, instanceIndex = {}, {}, {}
local SUPPORTED_FLAVORS = { classicEra = true, tbcAnniversary = true }

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do result[copy(key, seen)] = copy(child, seen) end
    return result
end

local function nonblank(value)
    return type(value) == "string" and value:match("%S") ~= nil
end

local function validateDenseList(value, label, required)
    assert(type(value) == "table", label .. " must be a list")
    local count = 0
    for key in pairs(value) do
        assert(type(key) == "number" and key >= 1 and key == math.floor(key),
            label .. " contains a non-list key")
        count = count + 1
    end
    assert(count == #value, label .. " must not contain gaps")
    if required then assert(count > 0, label .. " must not be empty") end
end

local function validateStringList(value, label, required, textLimit)
    validateDenseList(value, label, required)
    for index, entry in ipairs(value) do
        assert(nonblank(entry), label .. " contains invalid text at " .. index)
        if textLimit then
            assert(#entry <= textLimit, label .. " contains oversized text at " .. index)
        end
    end
end

local function validateMob(key, mob, ids)
    assert(type(key) == "string" and key ~= "", "guide mob key is required")
    assert(type(mob) == "table" and nonblank(mob.name), "guide mob name is required: " .. key)
    assert(MARKERS[mob.marker], "unsupported guide marker: " .. tostring(mob.marker))
    assert(type(mob.priority) == "number" and mob.priority >= 0, "invalid guide priority: " .. key)
    assert(nonblank(mob.liveReason), "guide live reason is required: " .. key)
    assert(#mob.liveReason <= LIVE_TEXT_LIMIT, "guide live reason is too long: " .. key)
    assert(nonblank(mob.rationale), "guide rationale is required: " .. key)
    assert(nonblank(mob.response), "guide response is required: " .. key)
    assert(nonblank(mob.creatureType), "guide creature type is required: " .. key)
    assert(nonblank(mob.cc), "guide CC guidance is required: " .. key)
    assert(#mob.rationale <= RATIONALE_TEXT_LIMIT, "guide rationale is too long: " .. key)
    assert(#mob.response <= RESPONSE_TEXT_LIMIT, "guide response is too long: " .. key)
    assert(#mob.cc <= CC_TEXT_LIMIT, "guide CC guidance is too long: " .. key)
    validateStringList(mob.abilities or {}, "guide abilities: " .. key, false,
        ABILITY_TEXT_LIMIT)
    validateStringList(mob.exceptions or {}, "guide exceptions: " .. key, false,
        EXCEPTION_TEXT_LIMIT)
    validateDenseList(mob.npcIds, "guide NPC IDs: " .. key, true)
    for _, npcId in ipairs(mob.npcIds) do
        assert(type(npcId) == "number" and npcId > 0 and npcId == math.floor(npcId),
            "invalid guide NPC ID: " .. key)
        assert(not ids[npcId], "duplicate guide NPC ID: " .. npcId)
        ids[npcId] = key
    end
end

function C.ValidateGuide(guide)
    assert(type(guide) == "table" and nonblank(guide.key), "guide key is required")
    assert(nonblank(guide.name), "guide name is required")
    validateDenseList(guide.instanceIds, "guide instance IDs", true)
    assert(type(guide.clientFlavors) == "table", "guide client flavors are required")
    assert(type(guide.mobs) == "table", "guide mobs are required")
    validateDenseList(guide.sections, "guide sections", true)
    local enabledFlavorCount, instanceIds = 0, {}
    for flavor, enabled in pairs(guide.clientFlavors) do
        assert(SUPPORTED_FLAVORS[flavor], "unsupported guide client flavor: " .. tostring(flavor))
        assert(type(enabled) == "boolean", "guide client flavor flag must be boolean")
        if enabled then enabledFlavorCount = enabledFlavorCount + 1 end
    end
    assert(enabledFlavorCount > 0, "guide must enable a supported client flavor")
    for _, instanceId in ipairs(guide.instanceIds) do
        assert(type(instanceId) == "number" and instanceId > 0
                and instanceId == math.floor(instanceId),
            "invalid guide instance ID")
        assert(not instanceIds[instanceId], "duplicate guide instance ID: " .. instanceId)
        instanceIds[instanceId] = true
    end
    local ids, referenced, sectionKeys = {}, {}, {}
    for key, mob in pairs(guide.mobs) do validateMob(key, mob, ids) end
    for _, section in ipairs(guide.sections) do
        assert(nonblank(section.key) and not sectionKeys[section.key], "invalid or duplicate guide section")
        assert(nonblank(section.name), "guide section name is required")
        sectionKeys[section.key] = true
        validateDenseList(section.entries, "guide section entries: " .. section.key, true)
        local previousPriority, sectionEntries = nil, {}
        for _, key in ipairs(section.entries) do
            local mob = guide.mobs[key]
            assert(mob, "unknown guide mob reference: " .. tostring(key))
            assert(not sectionEntries[key], "duplicate guide mob in section: " .. key)
            sectionEntries[key] = true
            referenced[key] = true
            assert(not previousPriority or mob.priority >= previousPriority,
                "guide priority order is invalid in " .. section.key)
            previousPriority = mob.priority
        end
        validateDenseList(section.rules or {}, "guide section rules: " .. section.key, false)
        for _, rule in ipairs(section.rules or {}) do
            assert(nonblank(rule.title) and nonblank(rule.guidance), "invalid guide pack rule")
            assert(#rule.guidance <= RULE_TEXT_LIMIT, "guide pack rule is too long: " .. rule.title)
        end
    end
    for key in pairs(guide.mobs) do assert(referenced[key], "unreferenced guide mob: " .. key) end
    return true
end

function C.RegisterGuide(guide)
    C.ValidateGuide(guide)
    assert(not guides[guide.key], "duplicate guide key: " .. guide.key)
    for flavor, enabled in pairs(guide.clientFlavors) do
        if enabled then
            for _, instanceId in ipairs(guide.instanceIds) do
                assert(not (instanceIndex[flavor] and instanceIndex[flavor][instanceId]),
                    "duplicate guide instance registration")
            end
        end
    end
    local stored = copy(guide)
    guides[stored.key] = stored
    guideOrder[#guideOrder + 1] = stored.key
    for flavor, enabled in pairs(stored.clientFlavors) do
        if enabled then
            instanceIndex[flavor] = instanceIndex[flavor] or {}
            for _, instanceId in ipairs(stored.instanceIds) do
                instanceIndex[flavor][instanceId] = stored.key
            end
        end
    end
end

function C.ListGuides(flavor)
    local result = {}
    for _, key in ipairs(guideOrder) do
        local guide = guides[key]
        if not flavor or guide.clientFlavors[flavor] then result[#result + 1] = copy(guide) end
    end
    return result
end

function C.GetGuide(key, flavor)
    local guide = guides[key]
    if not guide or (flavor and not guide.clientFlavors[flavor]) then return nil end
    return copy(guide)
end

function C.GetGuideForInstance(flavor, instanceId)
    local key = instanceIndex[flavor] and instanceIndex[flavor][tonumber(instanceId)]
    return key and C.GetGuide(key, flavor) or nil
end

function C.FindMob(flavor, instanceId, npcId)
    local guide = C.GetGuideForInstance(flavor, instanceId)
    if not guide then return nil end
    npcId = tonumber(npcId)
    for key, mob in pairs(guide.mobs) do
        for _, id in ipairs(mob.npcIds) do
            if id == npcId then return copy(mob), key, guide end
        end
    end
    return nil
end

function C.GetMarker(key) return MARKERS[key] and copy(MARKERS[key]) or nil end
function C.GetLiveTextLimit() return LIVE_TEXT_LIMIT end
function C.GetBookTextLimits()
    return {
        rationale = RATIONALE_TEXT_LIMIT, response = RESPONSE_TEXT_LIMIT,
        cc = CC_TEXT_LIMIT, ability = ABILITY_TEXT_LIMIT,
        exception = EXCEPTION_TEXT_LIMIT, rule = RULE_TEXT_LIMIT,
    }
end
