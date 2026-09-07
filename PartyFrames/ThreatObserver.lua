-- Dynamic hostile-unit observation and normalized group threat snapshots.
local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_ThreatObserver = {}
local O = ApogeePartyHealthBars_ThreatObserver

local STALE_SECONDS = 2
local TOTEM_CREATURE_TYPE_ID = 11
local nameplateUnits = {}
local history = {}
local nowFn = function() return GetTime and GetTime() or 0 end
local auraAdapter, debuffData, getClassToken, unitAPI
local DEBUFF_LIMIT = 6
local debuffDisplayByGuid = {}

local CHALLENGER_UNITS = {
    "player", "party1", "party2", "party3", "party4",
    "pet", "partypet1", "partypet2", "partypet3", "partypet4",
}

local SEVERITY_ORDER = { lost = 1, critical = 2, slipping = 3, safe = 4 }

local function NewSnapshot(limitedCoverage, refreshedAt)
    return {
        enemies = {},
        counts = { safe = 0, slipping = 0, critical = 0, lost = 0 },
        total = 0,
        limitedCoverage = limitedCoverage == true,
        refreshedAt = refreshedAt,
    }
end

local snapshot = NewSnapshot(true)

local function DeepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do result[DeepCopy(key, seen)] = DeepCopy(child, seen) end
    return result
end

local function IsTotem(unit)
    if not UnitCreatureType then return false end
    local _, creatureTypeID = UnitCreatureType(unit)
    return creatureTypeID == TOTEM_CREATURE_TYPE_ID
end

local function IsHostileLiving(unit)
    return UnitExists and UnitExists(unit)
        and UnitCanAttack and UnitCanAttack("player", unit)
        and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit))
        and not IsTotem(unit)
end

function O.GetThreatDetails(mobUnit, activeChallengers, assumeValidMob)
    local details = {}
    if not UnitDetailedThreatSituation
        or (not assumeValidMob and not IsHostileLiving(mobUnit)) then
        return details
    end
    for _, unit in ipairs(activeChallengers or CHALLENGER_UNITS) do
        if activeChallengers or UnitExists(unit) then
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

local function ResolveVictim(unit, activeChallengers)
    local victim = unit .. "target"
    if not UnitExists or not UnitExists(victim) then return nil end
    for _, groupUnit in ipairs(activeChallengers or CHALLENGER_UNITS) do
        if (activeChallengers or UnitExists(groupUnit))
            and UnitIsUnit and UnitIsUnit(victim, groupUnit) then
            return UnitName and UnitName(groupUnit) or groupUnit
        end
    end
    return nil
end

local function EmptyDebuffSlots()
    local slots = {}
    for slot = 1, DEBUFF_LIMIT do slots[slot] = false end
    return slots
end

local function NormalizeDebuff(aura)
    return {
        name = aura.name,
        icon = aura.icon,
        spellId = aura.spellId,
        applications = aura.applications,
        duration = aura.duration,
        expirationTime = aura.expirationTime,
    }
end

local function CacheDebuffDisplay(guid, slots, overflow)
    if guid then debuffDisplayByGuid[guid] = { slots = slots, overflow = overflow } end
    return slots, overflow
end

local function GetPlayerDebuffDisplay(unit, guid)
    local cached = guid and debuffDisplayByGuid[guid] or nil
    if cached then return cached.slots, cached.overflow end
    local slots = EmptyDebuffSlots()
    if not auraAdapter or type(auraAdapter.GetUnitHarmfulAuraSnapshot) ~= "function" then
        return CacheDebuffDisplay(guid, slots, 0)
    end
    local harmful = auraAdapter.GetUnitHarmfulAuraSnapshot(unit)
    local classToken = getClassToken and getClassToken() or nil
    local reservedCount = debuffData and debuffData.GetThreatDebuffSlotCount
        and debuffData.GetThreatDebuffSlotCount(classToken) or 0
    reservedCount = math.max(0, math.min(DEBUFF_LIMIT, tonumber(reservedCount) or 0))
    local fallback = {}
    for scanIndex, aura in ipairs(harmful and harmful.playerAuras or {}) do
        local normalized = NormalizeDebuff(aura)
        local reservedSlot = debuffData and debuffData.GetThreatDebuffSlot
            and debuffData.GetThreatDebuffSlot(classToken, aura.spellId) or nil
        if type(reservedSlot) == "number" and reservedSlot >= 1
            and reservedSlot <= reservedCount and not slots[reservedSlot] then
            slots[reservedSlot] = normalized
        else
            fallback[#fallback + 1] = { aura = normalized, scanIndex = scanIndex }
        end
    end
    table.sort(fallback, function(left, right)
        local leftId = tonumber(left.aura.spellId) or math.huge
        local rightId = tonumber(right.aura.spellId) or math.huge
        if leftId ~= rightId then return leftId < rightId end
        local leftName, rightName = tostring(left.aura.name or ""), tostring(right.aura.name or "")
        if leftName ~= rightName then return leftName < rightName end
        return left.scanIndex < right.scanIndex
    end)
    local nextSlot = reservedCount + 1
    local overflow = 0
    for _, entry in ipairs(fallback) do
        if nextSlot <= DEBUFF_LIMIT then
            slots[nextSlot] = entry.aura
            nextSlot = nextSlot + 1
        else
            overflow = overflow + 1
        end
    end
    return CacheDebuffDisplay(guid, slots, overflow)
end

local function BuildEnemy(unit, guid, now, activeChallengers)
    local details = O.GetThreatDetails(unit, activeChallengers, true)
    if next(details) == nil then return nil end
    local player = details.player
    local isTanking = player and player.isTanking == true or false
    local control
    if isTanking then
        control = math.max(0, math.min(100, 100 - GetClosestChallenger(details)))
    else
        local recoveryProgress = player and math.max(0, math.min(100,
            player.scaledPercent or 0)) or 0
        control = -(100 - recoveryProgress)
    end
    local severity
    if not isTanking then
        severity = "lost"
    elseif control <= 10 then
        severity = "critical"
    elseif control <= 30 then
        severity = "slipping"
    else
        severity = "safe"
    end

    local previous = history[guid]
    local changedAt = previous and previous.severity == severity and previous.changedAt or now
    local playerDebuffSlots, playerDebuffOverflow = GetPlayerDebuffDisplay(unit, guid)
    local health, healthMaximum, healthValid = 0, 1, false
    local cast
    if unitAPI and type(unitAPI.GetHealth) == "function" then
        health, healthMaximum, healthValid = unitAPI.GetHealth(unit)
    end
    if unitAPI and type(unitAPI.GetCast) == "function" then
        cast = unitAPI.GetCast(unit)
    end
    return {
        guid = guid,
        unit = unit,
        name = UnitName and UnitName(unit) or "Enemy",
        raidMarker = GetRaidTargetIndex and GetRaidTargetIndex(unit) or nil,
        victim = ResolveVictim(unit, activeChallengers),
        isTanking = isTanking,
        control = control,
        severity = severity,
        changedAt = changedAt,
        lastSeen = now,
        live = true,
        stale = false,
        health = health,
        healthMaximum = healthMaximum,
        healthValid = healthValid == true,
        cast = cast,
        playerDebuffSlots = playerDebuffSlots,
        playerDebuffOverflow = playerDebuffOverflow,
    }
end

local function BuildHistoryEntry(enemy)
    return {
        guid = enemy.guid,
        name = enemy.name,
        severity = enemy.severity,
        changedAt = enemy.changedAt,
        lastSeen = enemy.lastSeen,
    }
end

local function AddStaticSources(result)
    result.target, result.focus, result.mouseover = true, true, true
    for _, owner in ipairs(C.SLOT_UNITS or {}) do result[owner .. "target"] = true end
    result.pettarget = true
    for index = 1, 4 do result["partypet" .. index .. "target"] = true end
end

local STATIC_SOURCES = {}
AddStaticSources(STATIC_SOURCES)

function O.IsObservedUnit(unit)
    if type(unit) ~= "string" then return false end
    if nameplateUnits[unit] then return true end
    return STATIC_SOURCES[unit] == true
end

function O.InvalidateAuras(unit)
    if type(unit) ~= "string" then return end
    local guid = unitAPI and type(unitAPI.GetGUID) == "function" and unitAPI.GetGUID(unit)
        or (UnitGUID and UnitGUID(unit))
    if guid then debuffDisplayByGuid[guid] = nil end
end

local function SortEnemies(left, right)
    local leftOrder = SEVERITY_ORDER[left.severity] or 99
    local rightOrder = SEVERITY_ORDER[right.severity] or 99
    if leftOrder ~= rightOrder then return leftOrder < rightOrder end
    local leftControl = type(left.control) == "number" and left.control or math.huge
    local rightControl = type(right.control) == "number" and right.control or math.huge
    if leftControl ~= rightControl then return leftControl < rightControl end
    if left.changedAt ~= right.changedAt then return left.changedAt > right.changedAt end
    return tostring(left.guid) < tostring(right.guid)
end

function O.Refresh()
    local now = nowFn()
    local activeChallengers = {}
    for _, unit in ipairs(CHALLENGER_UNITS) do
        if UnitExists and UnitExists(unit) then
            activeChallengers[#activeChallengers + 1] = unit
        end
    end
    local sources = {}
    for unit in pairs(STATIC_SOURCES) do sources[unit] = true end
    for unit in pairs(nameplateUnits) do sources[unit] = true end

    local byGuid = {}
    local selectedSources = {}
    local resolvedGuids = {}
    local visibleNameplates = 0
    for unit in pairs(sources) do
        if UnitExists and UnitExists(unit) then
            local guid = UnitGUID and UnitGUID(unit)
            local isDead = UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)
            local isHostile = UnitCanAttack and UnitCanAttack("player", unit)
            local isTotem = guid and isHostile and not isDead and IsTotem(unit)
            if guid and (isDead or not isHostile or isTotem) then
                resolvedGuids[guid] = true
            elseif guid and isHostile and not isDead then
                if nameplateUnits[unit] then visibleNameplates = visibleNameplates + 1 end
                local priority = unit == "target" and 3 or (nameplateUnits[unit] and 2 or 1)
                local current = selectedSources[guid]
                if not current or priority > current.priority then
                    selectedSources[guid] = { unit = unit, priority = priority }
                end
            end
        end
    end
    for guid, source in pairs(selectedSources) do
        local enemy = BuildEnemy(source.unit, guid, now, activeChallengers)
        if enemy then byGuid[guid] = enemy end
    end

    local nextSnapshot = NewSnapshot(visibleNameplates == 0, now)

    for guid, enemy in pairs(byGuid) do
        history[guid] = BuildHistoryEntry(enemy)
        nextSnapshot.enemies[#nextSnapshot.enemies + 1] = enemy
    end

    for guid, previous in pairs(history) do
        if not byGuid[guid] then
            if resolvedGuids[guid] then
                history[guid] = nil
                debuffDisplayByGuid[guid] = nil
            end
            if not resolvedGuids[guid] and previous.severity == "lost"
                and now - previous.lastSeen <= STALE_SECONDS then
                local stale = DeepCopy(previous)
                stale.live, stale.stale = false, true
                nextSnapshot.enemies[#nextSnapshot.enemies + 1] = stale
            elseif not resolvedGuids[guid] and now - previous.lastSeen > STALE_SECONDS then
                history[guid] = nil
                debuffDisplayByGuid[guid] = nil
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
    auraAdapter = deps and deps.Auras or nil
    debuffData = deps and deps.DebuffData or nil
    getClassToken = deps and deps.GetClassToken or nil
    unitAPI = deps and deps.UnitAPI or nil
end

function O.ResetHistory()
    history = {}
    debuffDisplayByGuid = {}
    snapshot = NewSnapshot(next(nameplateUnits) == nil)
end

function O.Reset()
    nameplateUnits = {}
    O.ResetHistory()
end
