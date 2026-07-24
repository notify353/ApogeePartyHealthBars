ApogeePartyHealthBars_DungeonBoardRuntime = {}
local Runtime = ApogeePartyHealthBars_DungeonBoardRuntime
local Classifier = ApogeePartyHealthBars_DungeonBoardClassifier
local ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities

local DEFAULT_TIMEOUT_SECONDS = 150
local requestsBySender = {}
local nowFn
local clientFlavor
local timeoutSeconds
local initialized = false
local changedCallback

local function notifyChanged()
    if changedCallback then changedCallback() end
end

local function defaultNow()
    return GetTime and GetTime() or 0
end

local function cloneArray(values)
    local result = {}
    for index, value in ipairs(values or {}) do result[index] = value end
    return result
end

local function cloneRequest(request)
    return {
        id = request.id,
        sender = request.sender,
        guid = request.guid,
        message = request.message,
        dungeonKeys = cloneArray(request.dungeonKeys),
        status = request.status,
        heroic = request.heroic,
        channelName = request.channelName,
        channelBaseName = request.channelBaseName,
        channelIndex = request.channelIndex,
        zoneChannelID = request.zoneChannelID,
        lineID = request.lineID,
        firstSeen = request.firstSeen,
        lastSeen = request.lastSeen,
    }
end

local function arraysEqual(left, right)
    if #left ~= #right then return false end
    for index = 1, #left do
        if left[index] ~= right[index] then return false end
    end
    return true
end

local function sameRequest(existing, message, classification)
    return existing.message == message
        and existing.status == classification.status
        and existing.heroic == classification.heroic
        and arraysEqual(existing.dungeonKeys, classification.dungeonKeys)
end

local function resolveClientFlavor(options)
    if options and options.clientFlavor then return options.clientFlavor end
    if ClientCapabilities and ClientCapabilities.GetClientInfo then
        local info = ClientCapabilities.GetClientInfo()
        return info and info.flavor or "unsupported"
    end
    return "unsupported"
end

local function ensureInitialized()
    if not initialized then Runtime.Initialize() end
end

function Runtime.Initialize(options)
    options = options or {}
    requestsBySender = {}
    nowFn = options.Now or defaultNow
    clientFlavor = resolveClientFlavor(options)
    timeoutSeconds = options.timeoutSeconds or DEFAULT_TIMEOUT_SECONDS
    assert(type(nowFn) == "function", "DungeonBoardRuntime requires a time function")
    assert(type(timeoutSeconds) == "number" and timeoutSeconds > 0,
        "DungeonBoardRuntime requires a positive timeout")
    initialized = true
end

function Runtime.Prune(atTime)
    ensureInitialized()
    local currentTime = atTime or nowFn()
    local removed = 0
    for senderKey, request in pairs(requestsBySender) do
        if currentTime - request.lastSeen >= timeoutSeconds then
            requestsBySender[senderKey] = nil
            removed = removed + 1
        end
    end
    return removed
end

function Runtime.Ingest(data)
    ensureInitialized()
    if type(data) ~= "table"
        or type(data.message) ~= "string" or data.message == ""
        or type(data.sender) ~= "string" or data.sender == ""
    then
        return { kind = "none" }
    end

    local currentTime = data.atTime or nowFn()
    Runtime.Prune(currentTime)
    local classification = Classifier.Classify(data.message, {
        clientFlavor = clientFlavor,
        senderLevel = data.senderLevel,
    })
    if classification.kind ~= "request" then return classification end

    local senderKey = type(data.guid) == "string" and data.guid ~= "" and data.guid or data.sender
    local existing = requestsBySender[senderKey]
    if existing and data.lineID ~= nil and existing.lineID == data.lineID then
        return classification
    end

    local firstSeen = currentTime
    if existing and sameRequest(existing, data.message, classification) then
        firstSeen = existing.firstSeen
    end

    requestsBySender[senderKey] = {
        id = senderKey,
        sender = data.sender,
        guid = data.guid,
        message = data.message,
        dungeonKeys = cloneArray(classification.dungeonKeys),
        status = classification.status,
        heroic = classification.heroic,
        channelName = data.channelName,
        channelBaseName = data.channelBaseName,
        channelIndex = data.channelIndex,
        zoneChannelID = data.zoneChannelID,
        lineID = data.lineID,
        firstSeen = firstSeen,
        lastSeen = currentTime,
    }
    notifyChanged()
    return classification
end

function Runtime.GetSnapshot(atTime)
    ensureInitialized()
    Runtime.Prune(atTime)
    local result = {}
    for _, request in pairs(requestsBySender) do
        result[#result + 1] = cloneRequest(request)
    end
    table.sort(result, function(left, right)
        if left.lastSeen ~= right.lastSeen then return left.lastSeen > right.lastSeen end
        if left.firstSeen ~= right.firstSeen then return left.firstSeen > right.firstSeen end
        return left.id < right.id
    end)
    return result
end

function Runtime.GetTimeoutSeconds()
    ensureInitialized()
    return timeoutSeconds
end

function Runtime.SetChangedCallback(callback)
    assert(callback == nil or type(callback) == "function",
        "DungeonBoardRuntime changed callback must be a function or nil")
    changedCallback = callback
end
