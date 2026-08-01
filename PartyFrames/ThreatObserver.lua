-- Dynamic hostile-unit observation and normalized group threat snapshots.
local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_ThreatObserver = {}
local O = ApogeePartyHealthBars_ThreatObserver

local STALE_SECONDS = 2
local nameplateUnits = {}
local history = {}
local snapshot = {
    enemies = {}, counts = { safe = 0, slipping = 0, critical = 0, lost = 0 },
    total = 0, limitedCoverage = true, lostTransitions = {},
}
local nowFn = function() return GetTime and GetTime() or 0 end

local CHALLENGER_UNITS = {
    "player", "party1", "party2", "party3", "party4",
    "pet", "partypet1", "partypet2", "partypet3", "partypet4",
}

local SEVERITY_ORDER = { lost = 1, critical = 2, slipping = 3, safe = 4 }

local function DeepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do result[DeepCopy(key, seen)] = DeepCopy(child, seen) end
    return result
end

local function IsHostileLiving(unit)
    return UnitExists and UnitExists(unit)
        and UnitCanAttack and UnitCanAttack("player", unit)
        and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit))
end

function O.GetThreatDetails(mobUnit)
    local details = {}
    if not UnitDetailedThreatSituation or not IsHostileLiving(mobUnit) then return details end
    for _, unit in ipairs(CHALLENGER_UNITS) do
        if UnitExists(unit) then
            local isTanking, status, scaledPercent, rawPercent, rawThreat =
                UnitDetailedThreatSituation(unit, mobUnit)
            if type(scaledPercent) == "number" then
                details[unit] = {
                    isTanking = isTanking == true,
                    status = status,
                    scaledPercent = scaledPercent,
                    rawPercent = rawPercent,
                    rawThreat = rawThreat,
                }
            end
        end
    end
    return details
end

local function GetClosestChallenger(details)
    local closest = 0
    for unit, detail in pairs(details) do
        if unit ~= "player" then closest = math.max(closest, detail.scaledPercent or 0) end
    end
    return closest
end

local function ResolveVictim(unit)
    local victim = unit .. "target"
    if not UnitExists or not UnitExists(victim) then return nil end
    for _, groupUnit in ipairs(CHALLENGER_UNITS) do
        if UnitExists(groupUnit) and UnitIsUnit and UnitIsUnit(victim, groupUnit) then
            return UnitName and UnitName(groupUnit) or groupUnit
        end
    end
    return nil
end

local function BuildEnemy(unit, guid, now, sourcePriority)
    local details = O.GetThreatDetails(unit)
    if next(details) == nil then return nil end
    local player = details.player
    local isTanking = player and player.isTanking == true or false
    local margin = isTanking and math.max(0, 100 - GetClosestChallenger(details))
        or (player and math.max(0, player.scaledPercent or 0) or 0)
    local severity
    if not isTanking then
        severity = "lost"
    elseif margin <= 10 then
        severity = "critical"
    elseif margin <= 30 then
        severity = "slipping"
    else
        severity = "safe"
    end

    local previous = history[guid]
    local changedAt = previous and previous.severity == severity and previous.changedAt or now
    return {
        guid = guid,
        unit = unit,
        name = UnitName and UnitName(unit) or "Enemy",
        raidMarker = GetRaidTargetIndex and GetRaidTargetIndex(unit) or nil,
        victim = ResolveVictim(unit),
        isTanking = isTanking,
        margin = margin,
        severity = severity,
        changedAt = changedAt,
        lastSeen = now,
        live = true,
        stale = false,
        observed = true,
        details = details,
        sourcePriority = sourcePriority or 1,
    }
end

local function AddStaticSources(result)
    result.target, result.focus, result.mouseover = true, true, true
    for _, owner in ipairs(C.SLOT_UNITS or {}) do result[owner .. "target"] = true end
    result.pettarget = true
    for index = 1, 4 do result["partypet" .. index .. "target"] = true end
end

local function SortEnemies(left, right)
    local leftOrder = SEVERITY_ORDER[left.severity] or 99
    local rightOrder = SEVERITY_ORDER[right.severity] or 99
    if leftOrder ~= rightOrder then return leftOrder < rightOrder end
    local leftMargin = type(left.margin) == "number" and left.margin or math.huge
    local rightMargin = type(right.margin) == "number" and right.margin or math.huge
    if leftMargin ~= rightMargin then return leftMargin < rightMargin end
    if left.changedAt ~= right.changedAt then return left.changedAt > right.changedAt end
    return tostring(left.guid) < tostring(right.guid)
end

function O.Refresh()
    local now = nowFn()
    local sources = {}
    AddStaticSources(sources)
    for unit in pairs(nameplateUnits) do sources[unit] = true end

    local byGuid = {}
    local resolvedGuids = {}
    local visibleNameplates = 0
    for unit in pairs(sources) do
        if UnitExists and UnitExists(unit) then
            local guid = UnitGUID and UnitGUID(unit)
            local isDead = UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)
            local isHostile = UnitCanAttack and UnitCanAttack("player", unit)
            if guid and (isDead or not isHostile) then
                resolvedGuids[guid] = true
            elseif guid and IsHostileLiving(unit) then
                if nameplateUnits[unit] then visibleNameplates = visibleNameplates + 1 end
                local priority = unit == "target" and 3 or (nameplateUnits[unit] and 2 or 1)
                local enemy = BuildEnemy(unit, guid, now, priority)
                local current = byGuid[guid]
                if enemy and (not current or enemy.sourcePriority > current.sourcePriority) then
                    byGuid[guid] = enemy
                end
            end
        end
    end

    local nextSnapshot = {
        enemies = {},
        counts = { safe = 0, slipping = 0, critical = 0, lost = 0 },
        total = 0,
        limitedCoverage = visibleNameplates == 0,
        lostTransitions = {},
        refreshedAt = now,
    }

    for guid, enemy in pairs(byGuid) do
        local previous = history[guid]
        if previous and previous.observed ~= false and previous.isTanking and not enemy.isTanking then
            nextSnapshot.lostTransitions[#nextSnapshot.lostTransitions + 1] = guid
        end
        history[guid] = DeepCopy(enemy)
        nextSnapshot.enemies[#nextSnapshot.enemies + 1] = enemy
    end

    for guid, previous in pairs(history) do
        if not byGuid[guid] then
            if resolvedGuids[guid] then
                history[guid] = nil
            else
                previous.observed = false
            end
            if not resolvedGuids[guid] and previous.severity == "lost"
                and now - previous.lastSeen <= STALE_SECONDS then
                local stale = DeepCopy(previous)
                stale.unit, stale.margin, stale.details = nil, nil, nil
                stale.live, stale.stale = false, true
                stale.observed = false
                nextSnapshot.enemies[#nextSnapshot.enemies + 1] = stale
            elseif not resolvedGuids[guid] and now - previous.lastSeen > STALE_SECONDS then
                history[guid] = nil
            end
        end
    end

    table.sort(nextSnapshot.enemies, SortEnemies)
    for _, enemy in ipairs(nextSnapshot.enemies) do
        nextSnapshot.counts[enemy.severity] = nextSnapshot.counts[enemy.severity] + 1
    end
    nextSnapshot.total = #nextSnapshot.enemies
    nextSnapshot.worst = nextSnapshot.enemies[1]
    snapshot = nextSnapshot
    return O.GetSnapshot()
end

function O.GetSnapshot() return DeepCopy(snapshot) end

function O.OnNamePlateAdded(unit)
    if type(unit) == "string" then nameplateUnits[unit] = true end
end

function O.OnNamePlateRemoved(unit)
    if type(unit) == "string" then nameplateUnits[unit] = nil end
end

function O.Initialize(deps)
    if deps and type(deps.Now) == "function" then nowFn = deps.Now end
end

function O.ResetHistory()
    history = {}
    snapshot = {
        enemies = {}, counts = { safe = 0, slipping = 0, critical = 0, lost = 0 },
        total = 0, limitedCoverage = next(nameplateUnits) == nil, lostTransitions = {},
    }
end

function O.Reset()
    nameplateUnits = {}
    O.ResetHistory()
end
