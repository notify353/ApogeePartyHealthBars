local ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities
local State = ApogeePartyHealthBars_S

ApogeePartyHealthBars_RaidMarkers = {}
local M = ApogeePartyHealthBars_RaidMarkers

local D
local SUPPORTED_MARKERS = { [2] = true, [7] = true, [8] = true }
local STAGING_TIMEOUT_SECONDS = 15
local ownersByMarker = {}
local markersByGuid = {}
local suppressedGuids = {}
local activeGuideKey
local activeStagingContextKey
local lastStagingActivityAt

local function IsSupported()
    return (not ClientCapabilities
            or ClientCapabilities.IsFeatureAvailable("raidMarkers"))
        and type(SetRaidTarget) == "function"
        and type(GetRaidTargetIndex) == "function"
end

local function IsInCombat()
    return InCombatLockdown and InCombatLockdown() == true
end

local function Now()
    local value = D and D.Now and D.Now()
    return tonumber(value) or 0
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
    local owner = ownersByMarker[markerIndex]
    if owner and owner.guid == guid then
        ownersByMarker[markerIndex] = nil
    end
    return markerIndex
end

local function BindOwner(markerIndex, guid, source, autoMarkRank, suppressDisplaced)
    if not SUPPORTED_MARKERS[markerIndex] or not guid then return end

    local previousOwner = ownersByMarker[markerIndex]
    local previousGuid = previousOwner and previousOwner.guid
    if previousGuid and previousGuid ~= guid then
        markersByGuid[previousGuid] = nil
        if suppressDisplaced then suppressedGuids[previousGuid] = true end
    end

    local previousMarker = markersByGuid[guid]
    if previousMarker and previousMarker ~= markerIndex then
        local owner = ownersByMarker[previousMarker]
        if owner and owner.guid == guid then ownersByMarker[previousMarker] = nil end
    end

    ownersByMarker[markerIndex] = {
        guid = guid,
        source = source,
        autoMarkRank = autoMarkRank,
    }
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
        local owner = ownersByMarker[observedMarker]
        if not owner or owner.guid ~= guid then
            BindOwner(observedMarker, guid, "manual", nil, inCombat)
        end
    end
    return guid, observedMarker
end

local function ClearAllState()
    ownersByMarker = {}
    markersByGuid = {}
    suppressedGuids = {}
    activeGuideKey = nil
    activeStagingContextKey = nil
    lastStagingActivityAt = nil
end

local function ResetAutomaticStaging(preserveGuid)
    for markerIndex, owner in pairs(ownersByMarker) do
        if owner.source == "automatic" and owner.guid ~= preserveGuid then
            markersByGuid[owner.guid] = nil
            ownersByMarker[markerIndex] = nil
        end
    end
    suppressedGuids = {}
    activeStagingContextKey = nil
    lastStagingActivityAt = nil
end

function M.Initialize(deps)
    assert(type(deps) == "table"
            and type(deps.Policy) == "table"
            and type(deps.Settings) == "table",
        "RaidMarkers requires Dungeon Guide policy and settings")
    D = deps
    ClearAllState()
end

function M.EvaluateCurrentTarget()
    if not D or not State.sv or State.sv.enabled ~= true
        or not D.Settings.GetAutoMarkEnabled() or not IsSupported()
        or not IsLivingHostileTarget() or not UnitGUID then
        return nil
    end

    local targetGuid = UnitGUID("target")
    if not targetGuid then return nil end
    local recommendation = D.Policy.GetRecommendationForGuid(targetGuid)
    local markerIndex = recommendation and recommendation.markerIndex
    local autoMarkRank = recommendation and recommendation.autoMarkRank
    local eligible = SUPPORTED_MARKERS[markerIndex] and type(autoMarkRank) == "number"
    local inCombat = IsInCombat()
    local now = not inCombat and Now() or nil
    if eligible and now and lastStagingActivityAt
        and now - lastStagingActivityAt >= STAGING_TIMEOUT_SECONDS then
        ResetAutomaticStaging(targetGuid)
    end
    if recommendation and recommendation.guideKey then
        if activeGuideKey and activeGuideKey ~= recommendation.guideKey then
            ClearAllState()
        end
        activeGuideKey = recommendation.guideKey
    end
    local stagingContextKey = recommendation and recommendation.stagingContextKey
    if eligible and not inCombat and stagingContextKey then
        if activeStagingContextKey and activeStagingContextKey ~= stagingContextKey then
            ResetAutomaticStaging()
        end
        activeStagingContextKey = stagingContextKey
    end
    local guid, observedMarker = ReconcileCurrentTarget()
    if eligible and now then lastStagingActivityAt = now end
    if not guid or observedMarker or guid ~= targetGuid or not eligible then return nil end

    local owner = ownersByMarker[markerIndex]
    if inCombat then
        if suppressedGuids[guid] then return nil end
        if owner and owner.guid ~= guid then return nil end
    elseif owner and owner.guid ~= guid then
        if owner.source ~= "automatic"
            or type(owner.autoMarkRank) ~= "number"
            or autoMarkRank >= owner.autoMarkRank then
            return nil
        end
    end

    SetRaidTarget("target", markerIndex)
    if GetRaidTargetIndex("target") ~= markerIndex then return nil end

    BindOwner(markerIndex, guid, "automatic", autoMarkRank, false)
    suppressedGuids[guid] = nil
    return recommendation
end

function M.OnCombatStarted()
    ReconcileCurrentTarget()
end

function M.OnCombatEnded()
    local currentGuid = IsLivingHostileTarget() and UnitGUID and UnitGUID("target") or nil
    ResetAutomaticStaging(currentGuid)
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
