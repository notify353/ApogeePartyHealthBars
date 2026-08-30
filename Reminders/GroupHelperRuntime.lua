local Runtime = {}
ApogeePartyHealthBars.Define("Runtime", "GroupHelperRuntime", Runtime)

local D
local snapshot = { eligible = false, visible = false, manaRows = {} }
local refreshGeneration = 0
local auraRefreshGeneration = 0
local observedCapabilities = { spirit = {} }
local BUFF_UP_MESSAGE = "buff up"
local MANA_UP_MESSAGE = "mana up"
local PULLING_HERE_MESSAGE = "pulling here"

local function truthy(value)
    return value == true or value == 1
end

local function manaChannel(unitId)
    for _, channel in ipairs(D.UnitAPI.GetPowerChannels(unitId)) do
        if channel.powerType == 0 or channel.powerToken == "MANA" then
            return channel.value, channel.maximum
        end
    end
    return nil, nil
end

local function buildUnits(includeAuras)
    local units = {}
    for _, unitId in ipairs(D.UnitIds) do
        local exists = D.UnitAPI.Exists(unitId)
        local identity = exists and D.UnitAPI.GetIdentity(unitId) or {}
        local manaValue, manaMaximum = manaChannel(unitId)
        units[#units + 1] = {
            unitId = unitId,
            exists = exists,
            guid = exists and D.UnitAPI.GetGUID(unitId) or nil,
            name = identity.name or unitId,
            fullName = identity.fullName or identity.name or unitId,
            isPlayer = identity.isPlayer == true,
            classToken = identity.classToken,
            alive = exists and not D.UnitAPI.IsDead(unitId),
            connected = exists and D.UnitAPI.IsConnected(unitId),
            manaValue = manaValue,
            manaMaximum = manaMaximum,
            auras = includeAuras and exists
                and D.Auras.GetUnitAuraSnapshot(unitId).auras or {},
        }
    end
    return units
end

local function observeCapabilities(units)
    local guidByUnit = {}
    for _, unit in ipairs(units) do guidByUnit[unit.unitId] = unit.guid end
    for _, recipient in ipairs(units) do
        local aura = D.Data.FindBuffAura(recipient, "spirit")
        local providerGuid = aura and aura.sourceUnit and guidByUnit[aura.sourceUnit]
        if providerGuid then observedCapabilities.spirit[providerGuid] = true end
    end
end

local function context()
    local inInstance, instanceType = false, nil
    if IsInInstance then inInstance, instanceType = IsInInstance() end
    local playerIdentity = D.UnitAPI.GetIdentity("player") or {}
    local partyCount = 0
    for index = 1, 4 do
        if D.UnitAPI.Exists("party" .. index) then partyCount = partyCount + 1 end
    end
    local sayAvailable, sayReason = D.ChatComposer.CanSendSay()
    return {
        enabled = D.Settings.IsEnabled(),
        playerClassToken = playerIdentity.classToken,
        inInstance = truthy(inInstance),
        instanceType = instanceType,
        partyCount = partyCount,
        inCombat = InCombatLockdown and truthy(InCombatLockdown()) or false,
        auraAvailable = not D.ClientCapabilities
            or D.ClientCapabilities.IsFeatureAvailable("auraReminders"),
        auraReason = D.ClientCapabilities
            and D.ClientCapabilities.GetFeatureReason
            and D.ClientCapabilities.GetFeatureReason("auraReminders") or nil,
        sayAvailable = sayAvailable == true,
        sayReason = sayReason,
    }
end

function Runtime.Refresh()
    local currentContext = context()
    local structurallyEligible = currentContext.enabled == true
        and currentContext.inInstance == true
        and currentContext.instanceType == "party"
        and (tonumber(currentContext.partyCount) or 0) > 0
    local units = {}
    if structurallyEligible then
        units = buildUnits(currentContext.inCombat ~= true
            and currentContext.auraAvailable == true)
        if currentContext.inCombat ~= true and currentContext.auraAvailable == true then
            observeCapabilities(units)
        end
    end
    snapshot = D.Policy.BuildSnapshot(currentContext, units, observedCapabilities, D.Data)
    D.OnSnapshot(snapshot)
    return snapshot
end

local function beginFreshAuraGeneration()
    if D.Auras.BeginAuraCacheGeneration then D.Auras.BeginAuraCacheGeneration() end
end

local function scheduleRefresh(delay, freshAuras)
    refreshGeneration = refreshGeneration + 1
    local generation = refreshGeneration
    local function refreshCurrentGeneration()
        if generation ~= refreshGeneration then return end
        if freshAuras then beginFreshAuraGeneration() end
        Runtime.Refresh()
    end
    if delay and delay > 0 and D.After then
        D.After(delay, refreshCurrentGeneration)
    else
        refreshCurrentGeneration()
    end
end

function Runtime.ScheduleRefresh(delay)
    scheduleRefresh(delay, false)
end

function Runtime.OnRosterChanged()
    auraRefreshGeneration = auraRefreshGeneration + 1
    scheduleRefresh(0.20, true)
end

function Runtime.ScheduleAuraRefresh(delay)
    auraRefreshGeneration = auraRefreshGeneration + 1
    local generation = auraRefreshGeneration
    if delay and delay > 0 and D.After then
        D.After(delay, function()
            if generation == auraRefreshGeneration then Runtime.Refresh() end
        end)
    else
        Runtime.Refresh()
    end
end

local function copySnapshot(source)
    local result = {}
    for key, value in pairs(source or {}) do
        if key ~= "manaRows" and key ~= "buffIssues" then result[key] = value end
    end
    result.manaRows = {}
    for _, row in ipairs(source and source.manaRows or {}) do
        local copy = {}
        for key, value in pairs(row) do copy[key] = value end
        result.manaRows[#result.manaRows + 1] = copy
    end
    result.buffIssues = {}
    for _, issue in ipairs(source and source.buffIssues or {}) do
        local issueCopy = {}
        for key, value in pairs(issue) do
            if type(value) == "table" then
                issueCopy[key] = {}
                for childKey, child in pairs(value) do issueCopy[key][childKey] = child end
            else
                issueCopy[key] = value
            end
        end
        result.buffIssues[#result.buffIssues + 1] = issueCopy
    end
    return result
end

function Runtime.GetSnapshot()
    return copySnapshot(snapshot)
end

function Runtime.ResetSession()
    auraRefreshGeneration = auraRefreshGeneration + 1
    observedCapabilities = { spirit = {} }
    beginFreshAuraGeneration()
    Runtime.ScheduleRefresh(0)
end

function Runtime.OnCombatStarted()
    if D.OnCombatStarted then D.OnCombatStarted() end
    Runtime.ScheduleRefresh(0)
end

function Runtime.OnCombatEnded()
    if D.OnCombatEnded then D.OnCombatEnded() end
    Runtime.ScheduleRefresh(0.35)
end

local function send(message)
    local ok, reason = D.ChatComposer.SendSay(message)
    if not ok and D.Print then D.Print(reason or "Could not send say message.") end
    return ok, reason
end

function Runtime.SendBuffUp()
    return send(BUFF_UP_MESSAGE)
end

function Runtime.SendManaUp()
    return send(MANA_UP_MESSAGE)
end

function Runtime.SendPullingHere()
    return send(PULLING_HERE_MESSAGE)
end

function Runtime.CanSendSay()
    return D.ChatComposer.CanSendSay()
end

function Runtime.CanPlayerPull()
    local identity = D.UnitAPI.GetIdentity("player") or {}
    return D.Policy.IsTankClass(identity.classToken)
end

function Runtime.Initialize(deps)
    for _, key in ipairs({
        "Data", "Policy", "Auras", "UnitAPI", "Settings", "ChatComposer",
        "ClientCapabilities", "UnitIds", "OnSnapshot",
    }) do
        assert(deps and deps[key] ~= nil, "GroupHelperRuntime missing dependency: " .. key)
    end
    D = deps
end

function Runtime.GetMessages()
    return {
        buffUp = BUFF_UP_MESSAGE,
        manaUp = MANA_UP_MESSAGE,
        pullingHere = PULLING_HERE_MESSAGE,
    }
end
