-- Unified helpful-aura scan and per-refresh cache.
local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S

ApogeePartyHealthBars_Auras = {}

local A = ApogeePartyHealthBars_Auras
local partyBuffAuraIds
local partyBuffAuraNames
local selfBuffAuraIds
local selfBuffAuraNames
local hotMatchers = {}
local harmfulCache = {}

function A.ConfigureBuffMatchers(partyIds, partyNames, selfIds, selfNames)
    partyBuffAuraIds = partyIds
    partyBuffAuraNames = partyNames
    selfBuffAuraIds = selfIds
    selfBuffAuraNames = selfNames
end

function A.ConfigureHotMatchers(tracks)
    hotMatchers = {}
    for index, track in ipairs(tracks or {}) do
        hotMatchers[index] = {
            auraIds = track.auraIds,
            auraNames = track.auraNames,
        }
    end
end

local function AuraFromIndex(unitId, index)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        return C_UnitAuras.GetAuraDataByIndex(unitId, index, "HELPFUL")
    end
    if not UnitBuff then return nil end
    local name, _, _, _, duration, expirationTime, unitCaster, _, _, spellId =
        UnitBuff(unitId, index)
    if not name then return nil end
    return {
        name = name,
        spellId = spellId,
        duration = duration,
        expirationTime = expirationTime,
        sourceUnit = unitCaster,
    }
end

local function HarmfulAuraFromIndex(unitId, index)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        return C_UnitAuras.GetAuraDataByIndex(unitId, index, "HARMFUL")
    end
    if not UnitDebuff then return nil end
    local name, icon, applications, dispelName, duration, expirationTime, sourceUnit,
        _, _, spellId = UnitDebuff(unitId, index)
    if not name then return nil end
    return {
        name = name, icon = icon, applications = applications, dispelName = dispelName,
        duration = duration, expirationTime = expirationTime, sourceUnit = sourceUnit,
        spellId = spellId, isHarmful = true,
    }
end

function A.IsPowerWordShieldAura(spellId, name)
    if spellId and C.PW_SHIELD_SPELL_IDS[spellId] then return true end
    if name and C.PW_SHIELD_AURA_NAMES[name] then return true end
    if name and name:find("^Power Word: Shield") then return true end
    return false
end

local function AuraMatchesTables(aura, idTable, nameTable, preferNameFirst)
    if not aura then return false end
    if preferNameFirst then
        if aura.name and nameTable and nameTable[aura.name] then return true end
        if aura.spellId and idTable and idTable[aura.spellId] then return true end
    else
        if aura.spellId and idTable and idTable[aura.spellId] then return true end
        if aura.name and nameTable and nameTable[aura.name] then return true end
    end
    return false
end

function A.SnapshotHasAura(snapshot, idTable, nameTable)
    if not snapshot or not snapshot.auras then return false end
    for _, aura in ipairs(snapshot.auras) do
        if AuraMatchesTables(aura, idTable, nameTable, false) then
            return true
        end
    end
    return false
end

local function MatchesHotTrack(aura, track)
    return AuraMatchesTables(aura, track.auraIds, track.auraNames, true)
end

local function MatchesAnyPartyBuff(aura)
    if partyBuffAuraIds or partyBuffAuraNames then
        return AuraMatchesTables(aura, partyBuffAuraIds, partyBuffAuraNames, false)
    end
    for _, def in ipairs(C.PARTY_BUFF_DEFINITIONS) do
        if def.auraIds and def.auraNames
            and AuraMatchesTables(aura, def.auraIds, def.auraNames, false) then
            return true
        end
    end
    return false
end

local function ExtractShieldPoints(aura)
    if not aura or not aura.points then return nil end
    for _, point in ipairs(aura.points) do
        if type(point) == "number" and point > 0 then
            return math.floor(point + 0.5)
        end
    end
    return nil
end

local function BuildEmptySnapshot()
    return {
        auras = {},
        partyBuff = false,
        selfBuff = false,
        pwShield = nil,
        playerHots = {},
    }
end

function A.ScanUnitHelpfulAuras(unitId)
    if not unitId or not UnitExists or not UnitExists(unitId) then
        return BuildEmptySnapshot()
    end

    local snapshot = BuildEmptySnapshot()
    local trackCount = #hotMatchers
    local hotMatched = 0

    for i = 1, 40 do
        local aura = AuraFromIndex(unitId, i)
        if not aura then break end

        snapshot.auras[#snapshot.auras + 1] = aura

        if not snapshot.partyBuff and MatchesAnyPartyBuff(aura) then
            snapshot.partyBuff = true
        end

        if not snapshot.selfBuff
            and AuraMatchesTables(
                aura,
                selfBuffAuraIds,
                selfBuffAuraNames,
                false
            ) then
            snapshot.selfBuff = true
        end

        if not snapshot.pwShield and A.IsPowerWordShieldAura(aura.spellId, aura.name) then
            snapshot.pwShield = aura
        end

        if trackCount > 0 then
            local src = aura.sourceUnit
            if src and UnitIsUnit(src, "player") then
                for ti, track in ipairs(hotMatchers) do
                    if not snapshot.playerHots[ti] and MatchesHotTrack(aura, track) then
                        snapshot.playerHots[ti] = aura
                        hotMatched = hotMatched + 1
                        break
                    end
                end
            end
        end

        if snapshot.partyBuff and snapshot.selfBuff and snapshot.pwShield
            and hotMatched >= trackCount then
            break
        end
    end

    return snapshot
end

function A.BeginAuraCacheGeneration()
    S.auraCacheGen = (S.auraCacheGen or 0) + 1
end

function A.InvalidateUnitAuraCache(unitId)
    if unitId and S.auraCache then
        S.auraCache[unitId] = nil
    end
    if unitId then harmfulCache[unitId] = nil end
end

function A.ScanUnitHarmfulAuras(unitId)
    local snapshot = { auras = {}, playerBySpellId = {} }
    if not unitId or not UnitExists or not UnitExists(unitId) then return snapshot end
    for index = 1, 40 do
        local aura = HarmfulAuraFromIndex(unitId, index)
        if not aura then break end
        snapshot.auras[#snapshot.auras + 1] = aura
        local sourceUnit = aura.sourceUnit
        if aura.spellId and sourceUnit and UnitIsUnit and UnitIsUnit(sourceUnit, "player") then
            snapshot.playerBySpellId[aura.spellId] = aura
        end
    end
    return snapshot
end

function A.GetUnitHarmfulAuraSnapshot(unitId)
    if not unitId then return { auras = {}, playerBySpellId = {} } end
    local cached = harmfulCache[unitId]
    if cached then return cached end
    cached = A.ScanUnitHarmfulAuras(unitId)
    harmfulCache[unitId] = cached
    return cached
end

function A.GetUnitAuraSnapshot(unitId)
    if not unitId then return BuildEmptySnapshot() end
    S.auraCache = S.auraCache or {}
    local gen = S.auraCacheGen or 0
    local entry = S.auraCache[unitId]
    if entry and entry.gen == gen then
        return entry.snapshot
    end
    local snapshot = A.ScanUnitHelpfulAuras(unitId)
    S.auraCache[unitId] = { gen = gen, snapshot = snapshot }
    return snapshot
end

function A.GetShieldPointsFromSnapshot(snapshot)
    if not snapshot or not snapshot.pwShield then return nil end
    return ExtractShieldPoints(snapshot.pwShield)
end

function A.GetShieldSpellIdFromSnapshot(snapshot)
    if not snapshot or not snapshot.pwShield then return nil end
    return snapshot.pwShield.spellId
end

function A.UnitHasPWShieldFromSnapshot(snapshot)
    return snapshot and snapshot.pwShield ~= nil
end
