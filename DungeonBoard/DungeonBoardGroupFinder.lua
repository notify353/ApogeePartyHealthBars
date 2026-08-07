ApogeePartyHealthBars_DungeonBoardGroupFinder = {}
local GroupFinder = ApogeePartyHealthBars_DungeonBoardGroupFinder

local D
local state = {
    status = "idle",
    lastRefreshAt = nil,
    failureReason = nil,
}
local changedCallback
local searchHookInstalled = false

local function notifyChanged()
    if changedCallback then changedCallback() end
end

local function setState(status, failureReason, refreshed)
    state.status = status
    state.failureReason = failureReason
    if refreshed then state.lastRefreshAt = D.Now() end
    notifyChanged()
end

local function cloneState()
    return {
        status = state.status,
        lastRefreshAt = state.lastRefreshAt,
        failureReason = state.failureReason,
        available = GroupFinder.IsAvailable(),
    }
end

local function isLevelAppropriate(mapped, playerLevel)
    if type(mapped) ~= "table" or type(playerLevel) ~= "number" then return false end
    local levelWindow = D.Settings.GetLevelWindow(playerLevel)
    return D.Catalog.IsLevelAppropriate(
        mapped.key, playerLevel, mapped.heroic, levelWindow)
end

local function getMappedActivity(activityID, playerLevel)
    local mapped = D.ActivityData.GetActivity(activityID, D.GetClientFlavor())
    if not mapped or not D.Catalog.IsFivePlayer(mapped.key) then return nil end
    local info = D.API.GetActivityInfoTable(activityID)
    if type(info) ~= "table"
        or info.maxNumPlayers ~= 5
        or not isLevelAppropriate(mapped, playerLevel)
    then
        return nil
    end
    if mapped.heroic and info.isHeroicActivity ~= true then return nil end
    if not mapped.heroic and info.isNormalActivity == false then return nil end
    return mapped, info
end

local function buildSearchActivities()
    local result = {}
    local categoryID
    local playerLevel = D.GetPlayerLevel()
    for _, mapped in ipairs(D.ActivityData.GetActivities(D.GetClientFlavor())) do
        local accepted, info = getMappedActivity(mapped.id, playerLevel)
        if accepted and (categoryID == nil or info.categoryID == categoryID) then
            categoryID = categoryID or info.categoryID
            result[#result + 1] = mapped.id
        end
    end
    return categoryID, result
end

local function sortDungeonKeys(keys)
    local order = {}
    for index, dungeon in ipairs(D.Catalog.GetDungeons(D.GetClientFlavor())) do
        order[dungeon.key] = index
    end
    table.sort(keys, function(left, right)
        return (order[left] or math.huge) < (order[right] or math.huge)
    end)
end

local function parseResult(resultID)
    local info = D.API.GetSearchResultInfo(resultID)
    if type(info) ~= "table"
        or info.isDelisted
        or info.hasSelf
        or type(info.numMembers) ~= "number"
        or info.numMembers < 1
        or info.numMembers > 4
    then
        return nil
    end

    local dungeonKeys = {}
    local seenKeys = {}
    local activityIDs = {}
    local anyHeroic = false
    local anyNormal = false
    local playerLevel = D.GetPlayerLevel()
    for _, activityID in ipairs(info.activityIDs or {}) do
        local mapped = getMappedActivity(activityID, playerLevel)
        if mapped then
            activityIDs[#activityIDs + 1] = activityID
            if not seenKeys[mapped.key] then
                seenKeys[mapped.key] = true
                dungeonKeys[#dungeonKeys + 1] = mapped.key
            end
            if mapped.heroic then anyHeroic = true else anyNormal = true end
        end
    end
    if #dungeonKeys == 0 then return nil end
    sortDungeonKeys(dungeonKeys)

    local counts = D.API.GetSearchResultMemberCounts(resultID)
    if type(counts) ~= "table" then counts = {} end
    local neededRoles = {}
    if (tonumber(counts.TANK_REMAINING) or 0) > 0 then
        neededRoles[#neededRoles + 1] = "tank"
    end
    if (tonumber(counts.HEALER_REMAINING) or 0) > 0 then
        neededRoles[#neededRoles + 1] = "healer"
    end
    if #neededRoles ~= 1 then return nil end

    local difficulty = "normal"
    if anyHeroic and anyNormal then
        difficulty = "mixed"
    elseif anyHeroic then
        difficulty = "heroic"
    end

    return {
        resultID = resultID,
        partyGUID = info.partyGUID,
        leaderName = info.leaderName,
        name = info.name,
        comment = info.comment,
        dungeonKeys = dungeonKeys,
        activityIDs = activityIDs,
        -- Blizzard activity IDs are structured selections, not ambiguous chat text.
        -- A leader can select more than one dungeon, so preserve every mapped
        -- option while keeping the result definitively matched.
        status = "matched",
        heroic = anyHeroic and not anyNormal,
        difficulty = difficulty,
        maxPlayers = 5,
        numMembers = info.numMembers,
        memberCounts = counts,
        neededRoles = neededRoles,
    }
end

local function readCurrentResults()
    local _, resultIDs = D.API.GetSearchResults()
    local entries = {}
    for _, resultID in ipairs(resultIDs or {}) do
        local entry = parseResult(resultID)
        if entry then entries[#entries + 1] = entry end
    end
    return entries
end

local function replaceCurrentResults()
    local ok, entries = pcall(readCurrentResults)
    if not ok then
        setState("failed", tostring(entries), false)
        return false
    end
    D.Runtime.ReplaceOfficialRequests(entries, D.Now())
    return true
end

function GroupFinder.Initialize(deps)
    assert(type(deps) == "table", "DungeonBoardGroupFinder requires dependencies")
    for _, key in ipairs({
        "Runtime", "ActivityData", "Catalog", "ClientCapabilities", "API",
        "Settings", "GetClientFlavor", "GetPlayerLevel", "Now",
    }) do
        assert(deps[key] ~= nil, "DungeonBoardGroupFinder missing dependency: " .. key)
    end
    D = deps
    state.status = "idle"
    state.lastRefreshAt = nil
    state.failureReason = nil

    if not searchHookInstalled and GroupFinder.IsAvailable()
        and type(deps.HookSearch) == "function"
    then
        deps.HookSearch(function()
            setState("searching", nil, false)
        end)
        searchHookInstalled = true
    end
end

function GroupFinder.IsAvailable()
    return D ~= nil
        and D.ClientCapabilities.IsFeatureAvailable("dungeonBoardOfficialListings")
end

function GroupFinder.RequestRefresh()
    if not GroupFinder.IsAvailable() then
        setState("failed",
            D.ClientCapabilities.GetFeatureReason("dungeonBoardOfficialListings"), false)
        return false
    end

    local canCall, canUse, reason = pcall(D.API.CanPlayerUsePremadeGroup)
    if not canCall then
        setState("failed", tostring(canUse), false)
        return false
    end
    if canUse ~= true then
        setState("failed", tostring(reason or "Group Finder is unavailable."), false)
        return false
    end

    local built, categoryID, activityIDs = pcall(buildSearchActivities)
    if not built then
        setState("failed", tostring(categoryID), false)
        return false
    end
    if not categoryID or #activityIDs == 0 then
        D.Runtime.ReplaceOfficialRequests({}, D.Now())
        setState("ready", nil, true)
        return true
    end

    setState("searching", nil, false)
    local ok, failure = pcall(D.API.Search,
        categoryID, 0, 0, { enUS = true }, false, nil, activityIDs)
    if not ok then
        setState("failed", tostring(failure), false)
        return false
    end
    return true
end

function GroupFinder.HandleSearchResultsReceived()
    if not GroupFinder.IsAvailable() then return end
    if not replaceCurrentResults() then return end
    setState("ready", nil, true)
end

function GroupFinder.HandleSearchResultsUpdated()
    if not GroupFinder.IsAvailable() then return end
    -- Blizzard fires this when the contents of an existing search change. It
    -- is not a completed search, so preserve the last-refresh time and status.
    replaceCurrentResults()
end

function GroupFinder.HandleSearchFailed(reason)
    if not GroupFinder.IsAvailable() then return end
    setState("failed", tostring(reason or "The Group Finder search failed."), false)
end

function GroupFinder.HandleSearchResultUpdated(resultID)
    if not GroupFinder.IsAvailable() then return end
    local okInfo, info = pcall(D.API.GetSearchResultInfo, resultID)
    if not okInfo then
        setState("failed", tostring(info), false)
        return
    end
    if not info or info.isDelisted then
        D.Runtime.RemoveOfficialRequest(resultID)
        return
    end
    local ok, entries = pcall(readCurrentResults)
    if ok then
        D.Runtime.ReplaceOfficialRequests(entries, D.Now())
    else
        setState("failed", tostring(entries), false)
    end
end

function GroupFinder.GetStatus()
    return cloneState()
end

function GroupFinder.GetSnapshot()
    if not D or type(D.Runtime.GetOfficialSnapshot) ~= "function" then return {} end
    return D.Runtime.GetOfficialSnapshot()
end

function GroupFinder.SetChangedCallback(callback)
    assert(callback == nil or type(callback) == "function",
        "DungeonBoardGroupFinder changed callback must be a function or nil")
    changedCallback = callback
end
