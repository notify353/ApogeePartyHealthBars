-- Current-target threat details for party-frame threat indicators.
ApogeePartyHealthBars_ThreatObserver = {}
local O = ApogeePartyHealthBars_ThreatObserver
local TOTEM_CREATURE_TYPE_ID = 11
local CHALLENGER_UNITS = {
    "player", "party1", "party2", "party3", "party4",
    "pet", "partypet1", "partypet2", "partypet3", "partypet4",
}

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
