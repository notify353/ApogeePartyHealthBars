local ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities
local State = ApogeePartyHealthBars_S

ApogeePartyHealthBars_RaidMarkers = {}
local M = ApogeePartyHealthBars_RaidMarkers

local D
local SUPPORTED_MARKERS = { [2] = true, [7] = true, [8] = true }
local ownersByMarker = {}
local markersByGuid = {}
local suppressedGuids = {}

local function IsSupported()
    return (not ClientCapabilities
            or ClientCapabilities.IsFeatureAvailable("raidMarkers"))
        and type(SetRaidTarget) == "function"
        and type(GetRaidTargetIndex) == "function"
end

local function IsInCombat()
    return InCombatLockdown and InCombatLockdown() == true
end

local function IsLivingHostileTarget()
    return UnitExists and UnitExists("target")
        and UnitCanAttack and UnitCanAttack("player", "target")
        and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("target"))
end

local function ReleaseGuid(guid)
    local markerIndex = guid and markersByGuid[guid]
    if not markerIndex then return nil end
    markersByGuid[guid] = nil
    if ownersByMarker[markerIndex] == guid then
        ownersByMarker[markerIndex] = nil
    end
    return markerIndex
end

local function BindOwner(markerIndex, guid, suppressDisplaced)
    if not SUPPORTED_MARKERS[markerIndex] or not guid then return end

    local previousGuid = ownersByMarker[markerIndex]
    if previousGuid and previousGuid ~= guid then
        markersByGuid[previousGuid] = nil
        if suppressDisplaced then suppressedGuids[previousGuid] = true end
    end

    local previousMarker = markersByGuid[guid]
    if previousMarker and previousMarker ~= markerIndex
        and ownersByMarker[previousMarker] == guid then
        ownersByMarker[previousMarker] = nil
    end

    ownersByMarker[markerIndex] = guid
    markersByGuid[guid] = markerIndex
end

local function ReconcileCurrentTarget()
    if not UnitExists or not UnitExists("target") or not UnitGUID
        or type(GetRaidTargetIndex) ~= "function" then
        return nil, nil
    end

    local guid = UnitGUID("target")
    if not guid then return nil, nil end
    local observedMarker = GetRaidTargetIndex("target")
    local trackedMarker = markersByGuid[guid]
    local inCombat = IsInCombat()
    local livingHostile = IsLivingHostileTarget()

    if trackedMarker and (not livingHostile or trackedMarker ~= observedMarker) then
        ReleaseGuid(guid)
        if inCombat and livingHostile then suppressedGuids[guid] = true end
    end

    if livingHostile and SUPPORTED_MARKERS[observedMarker] then
        BindOwner(observedMarker, guid, inCombat)
    end
    return guid, observedMarker
end

local function ClearCombatState()
    ownersByMarker = {}
    markersByGuid = {}
    suppressedGuids = {}
end

function M.Initialize(deps)
    assert(type(deps) == "table"
            and type(deps.Policy) == "table"
            and type(deps.Settings) == "table",
        "RaidMarkers requires Dungeon Guide policy and settings")
    D = deps
    ClearCombatState()
end

function M.EvaluateCurrentTarget()
    if not D or not State.sv or State.sv.enabled ~= true
        or not D.Settings.GetAutoMarkEnabled() or not IsSupported()
        or not IsLivingHostileTarget() or not UnitGUID then
        return nil
    end

    local guid, observedMarker = ReconcileCurrentTarget()
    if not guid or observedMarker then return nil end

    local recommendation = D.Policy.GetRecommendationForGuid(guid)
    local markerIndex = recommendation and recommendation.markerIndex
    if not SUPPORTED_MARKERS[markerIndex] then return nil end

    local inCombat = IsInCombat()
    if inCombat then
        if suppressedGuids[guid] then return nil end
        local ownerGuid = ownersByMarker[markerIndex]
        if ownerGuid and ownerGuid ~= guid then return nil end
    end

    SetRaidTarget("target", markerIndex)
    if GetRaidTargetIndex("target") ~= markerIndex then return nil end

    BindOwner(markerIndex, guid, false)
    suppressedGuids[guid] = nil
    return recommendation
end

function M.OnCombatStarted()
    ReconcileCurrentTarget()
end

function M.OnCombatEnded()
    ClearCombatState()
    return M.EvaluateCurrentTarget()
end

function M.OnRaidTargetUpdate()
    ReconcileCurrentTarget()
end

function M.OnUnitDied(guid)
    if type(guid) ~= "string" or guid == "" then return false end
    local released = ReleaseGuid(guid) ~= nil
    suppressedGuids[guid] = nil
    local currentGuid = UnitGUID and UnitGUID("target") or nil
    if released and currentGuid ~= guid then M.EvaluateCurrentTarget() end
    return released
end

M.IsSupported = IsSupported
