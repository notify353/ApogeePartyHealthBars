ApogeePartyHealthBars_DungeonBoardRuntime = {}
local Runtime = ApogeePartyHealthBars_DungeonBoardRuntime
local Classifier = ApogeePartyHealthBars_DungeonBoardClassifier
local Catalog = ApogeePartyHealthBars_DungeonBoardCatalog
local ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities

local DEFAULT_TIMEOUT_SECONDS = 150
local requestsBySender = {}
local officialByID = {}
local nowFn
local clientFlavor
local timeoutSeconds
local initialized = false
local changedCallback
local opportunityCallback

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

local function cloneTable(values)
    local result = {}
    for key, value in pairs(values or {}) do
        if type(value) == "table" then
            result[key] = cloneTable(value)
        else
            result[key] = value
        end
    end
    return result
end

local function cloneRequest(request)
    return {
        id = request.id,
        source = request.source,
        sender = request.sender,
        guid = request.guid,
        message = request.message,
        dungeonKeys = cloneArray(request.dungeonKeys),
        status = request.status,
        heroic = request.heroic,
        neededRoles = cloneArray(request.neededRoles),
        difficulty = request.difficulty,
        maxPlayers = request.maxPlayers,
        numMembers = request.numMembers,
        memberCounts = cloneTable(request.memberCounts),
        activityIDs = cloneArray(request.activityIDs),
        activityRanges = cloneTable(request.activityRanges),
        resultID = request.resultID,
        partyGUID = request.partyGUID,
        leaderName = request.leaderName,
        name = request.name,
        comment = request.comment,
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
    left = left or {}
    right = right or {}
    if #left ~= #right then return false end
    for index = 1, #left do
        if left[index] ~= right[index] then return false end
    end
    return true
end

local function sameRequest(existing, classification)
    return existing.status == classification.status
        and existing.heroic == classification.heroic
        and arraysEqual(existing.dungeonKeys, classification.dungeonKeys)
        and arraysEqual(existing.neededRoles, classification.neededRoles)
end

local function getSharedMaxPlayers(dungeonKeys)
    local maxPlayers
    for _, key in ipairs(dungeonKeys or {}) do
        local dungeon = Catalog.GetDungeon(key)
        if not dungeon then return nil end
        if maxPlayers and maxPlayers ~= dungeon.maxPlayers then return nil end
        maxPlayers = dungeon.maxPlayers
    end
    return maxPlayers
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
    officialByID = {}
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

    local source = data.source == "guild" and "guild" or "channel"
    local firstSeen = currentTime
    if existing and existing.source == source
        and sameRequest(existing, classification)
    then
        firstSeen = existing.firstSeen
    end

    requestsBySender[senderKey] = {
        id = senderKey,
        source = source,
        sender = data.sender,
        guid = data.guid,
        message = data.message,
        dungeonKeys = cloneArray(classification.dungeonKeys),
        status = classification.status,
        heroic = classification.heroic,
        neededRoles = cloneArray(classification.neededRoles),
        difficulty = classification.heroic and "heroic" or "normal",
        maxPlayers = getSharedMaxPlayers(classification.dungeonKeys),
        channelName = data.channelName,
        channelBaseName = data.channelBaseName,
        channelIndex = data.channelIndex,
        zoneChannelID = data.zoneChannelID,
        lineID = data.lineID,
        firstSeen = firstSeen,
        lastSeen = currentTime,
    }
    notifyChanged()
    -- Forward each accepted, non-duplicate chat line. LFG Alerts owns alert
    -- deduplication so a repost first seen under the other watched role can
    -- still be considered after the player changes roles.
    if opportunityCallback then
        opportunityCallback(cloneRequest(requestsBySender[senderKey]))
    end
    return classification
end

function Runtime.ReplaceOfficialRequests(entries, atTime)
    ensureInitialized()
    local currentTime = atTime or nowFn()
    local replacement = {}
    for _, entry in ipairs(entries or {}) do
        if type(entry) == "table" and entry.resultID ~= nil then
            local id = "blizzard:" .. tostring(entry.resultID)
            replacement[id] = {
                id = id,
                source = "blizzard",
                sender = entry.leaderName or entry.name or "Group",
                message = type(entry.comment) == "string" and entry.comment ~= ""
                    and entry.comment or entry.name or "",
                dungeonKeys = cloneArray(entry.dungeonKeys),
                -- Official activity IDs are authoritative. Never allow an
                -- adapter or stale snapshot to turn them into chat ambiguity.
                status = "matched",
                heroic = entry.heroic == true,
                neededRoles = cloneArray(entry.neededRoles),
                difficulty = entry.difficulty or (entry.heroic and "heroic" or "normal"),
                maxPlayers = entry.maxPlayers or 5,
                numMembers = entry.numMembers,
                memberCounts = cloneTable(entry.memberCounts),
                activityIDs = cloneArray(entry.activityIDs),
                activityRanges = cloneTable(entry.activityRanges),
                resultID = entry.resultID,
                partyGUID = entry.partyGUID,
                leaderName = entry.leaderName,
                name = entry.name,
                comment = entry.comment,
                firstSeen = currentTime,
                lastSeen = currentTime,
            }
        end
    end
    officialByID = replacement
    notifyChanged()
end

function Runtime.RemoveOfficialRequest(resultID)
    ensureInitialized()
    local id = "blizzard:" .. tostring(resultID)
    if not officialByID[id] then return false end
    officialByID[id] = nil
    notifyChanged()
    return true
end

function Runtime.GetSnapshot(atTime)
    ensureInitialized()
    Runtime.Prune(atTime)
    local result = {}
    for _, request in pairs(requestsBySender) do
        result[#result + 1] = cloneRequest(request)
    end
    for _, request in pairs(officialByID) do
        result[#result + 1] = cloneRequest(request)
    end
    table.sort(result, function(left, right)
        if left.lastSeen ~= right.lastSeen then return left.lastSeen > right.lastSeen end
        if left.firstSeen ~= right.firstSeen then return left.firstSeen > right.firstSeen end
        return left.id < right.id
    end)
    return result
end

function Runtime.GetChatSnapshot(atTime)
    ensureInitialized()
    Runtime.Prune(atTime)
    local result = {}
    for _, request in pairs(requestsBySender) do
        result[#result + 1] = cloneRequest(request)
    end
    table.sort(result, function(left, right)
        if left.lastSeen ~= right.lastSeen then return left.lastSeen > right.lastSeen end
        return left.id < right.id
    end)
    return result
end

function Runtime.GetOfficialSnapshot()
    ensureInitialized()
    local result = {}
    for _, request in pairs(officialByID) do
        result[#result + 1] = cloneRequest(request)
    end
    table.sort(result, function(left, right)
        if left.lastSeen ~= right.lastSeen then return left.lastSeen > right.lastSeen end
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

function Runtime.SetChatOpportunityCallback(callback)
    assert(callback == nil or type(callback) == "function",
        "DungeonBoardRuntime opportunity callback must be a function or nil")
    opportunityCallback = callback
end
