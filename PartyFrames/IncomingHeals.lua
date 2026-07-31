local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_IncomingHeals = {}
local X = ApogeePartyHealthBars_IncomingHeals
local UnitAPI = ApogeePartyHealthBars_UnitAPI
local D

function X.Initialize(deps)
    for _, key in ipairs({ "IsSavedFeatureEnabled", "IsConfigMode", "IsTrackedUnit" }) do
        assert(deps[key] ~= nil, "IncomingHeals missing dependency: " .. key)
    end
    D = deps
end

function X.IsEnabled()
    return D.IsSavedFeatureEnabled("incomingHealEnabled")
end

function X.ShouldTrackUnit(unitId)
    if not unitId or not UnitExists(unitId) or UnitIsDeadOrGhost(unitId) then
        return false
    end
    return D.IsTrackedUnit(unitId)
end

function X.GetAmount(unitId)
    if not UnitGetIncomingHeals then return 0 end

    local incoming = UnitGetIncomingHeals(unitId) or 0
    if incoming > 0 then return incoming end

    -- Some Classic clients report predictions only for canonical group tokens,
    -- even when the same unit is displayed through a target alias.
    for _, groupUnit in ipairs(C.SLOT_UNITS) do
        if groupUnit ~= unitId and UnitExists(groupUnit)
            and UnitIsUnit(unitId, groupUnit) then
            return UnitGetIncomingHeals(groupUnit) or 0
        end
    end
    return 0
end

function X.UpdateBarVisual(healPredBar, unitId, visualMax)
    if not healPredBar then return end

    if D.IsConfigMode() or not X.IsEnabled() or not unitId
        or not X.ShouldTrackUnit(unitId) then
        healPredBar:Hide()
        return
    end

    local incoming = X.GetAmount(unitId)
    if incoming <= 0 then
        healPredBar:Hide()
        return
    end

    local hp, hpMax = UnitAPI.GetHealth(unitId)
    if hpMax <= 0 then hpMax = 1 end
    visualMax = math.max(visualMax or hpMax, 1)

    healPredBar:SetMinMaxValues(0, visualMax)
    healPredBar:SetValue(math.min(hp + incoming, visualMax))
    healPredBar:Show()
end

function X.UpdateRowVisual(row, unitId, visualMax)
    X.UpdateBarVisual(row.healPredBar, unitId, visualMax)
end
