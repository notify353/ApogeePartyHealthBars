local ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities
local State = ApogeePartyHealthBars_S

ApogeePartyHealthBars_RaidMarkers = {}
local M = ApogeePartyHealthBars_RaidMarkers

local D
local SUPPORTED_MARKERS = { [2] = true, [5] = true, [7] = true, [8] = true }
local COMBAT_MARKERS = { [2] = true, [8] = true }

local function IsSupported()
    return (not ClientCapabilities
            or ClientCapabilities.IsFeatureAvailable("raidMarkers"))
        and type(SetRaidTarget) == "function"
        and type(GetRaidTargetIndex) == "function"
end

local function IsLivingHostileTarget()
    return UnitExists and UnitExists("target")
        and UnitCanAttack and UnitCanAttack("player", "target")
        and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("target"))
end

function M.Initialize(deps)
    assert(type(deps) == "table"
            and type(deps.Policy) == "table"
            and type(deps.Settings) == "table",
        "RaidMarkers requires Dungeon Guide policy and settings")
    D = deps
end

function M.EvaluateCurrentTarget()
    if not D or not State.sv or State.sv.enabled ~= true
        or not D.Settings.GetAutoMarkEnabled() or not IsSupported()
        or not IsLivingHostileTarget() or not UnitGUID then
        return nil
    end

    local guid = UnitGUID("target")
    local recommendation = guid and D.Policy.GetRecommendationForGuid(guid) or nil
    local markerIndex = recommendation and recommendation.markerIndex
    if not SUPPORTED_MARKERS[markerIndex] then return nil end
    if InCombatLockdown and InCombatLockdown() and not COMBAT_MARKERS[markerIndex] then return nil end
    if GetRaidTargetIndex("target") then return nil end

    SetRaidTarget("target", markerIndex)
    return recommendation
end

M.IsSupported = IsSupported
