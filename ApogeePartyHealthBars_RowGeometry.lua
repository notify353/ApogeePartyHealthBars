local C = ApogeePartyHealthBars_C
local API = ApogeePartyHealthBars_UnitAPI

ApogeePartyHealthBars_RowGeometry = {}
local G = ApogeePartyHealthBars_RowGeometry
local D

local function ResolveUnitId(rowOrUnit)
    if type(rowOrUnit) == "table" then return rowOrUnit.unitId end
    return rowOrUnit
end

function G.Initialize(deps)
    for _, key in ipairs({
        "GetHotStripHeight", "ShortcutBar", "WheelMacros", "KeyActions", "MouseButtonActions",
    }) do
        assert(deps[key] ~= nil, "RowGeometry missing dependency: " .. key)
    end
    D = deps
end

function G.GetPlayerPowerInfo()
    local powerType, powerToken = UnitPowerType("player")
    if powerType == nil then powerType = C.MANA_POWER end
    local manaMax = UnitPowerMax("player", C.MANA_POWER) or 0
    local activeMax = UnitPowerMax("player", powerType) or 0
    return powerType, powerToken, manaMax, activeMax
end

function G.GetRowPowerChromeHeight(rowOrUnit)
    local unitId = ResolveUnitId(rowOrUnit)
    local stripCount = #API.GetPowerChannels(unitId)
    return stripCount * C.MANA_H + stripCount * C.MANA_GAP
end

function G.GetActionAreaHeight(rowOrUnit)
    local unitId = ResolveUnitId(rowOrUnit)
    return D.ShortcutBar.GetHeight(unitId)
        + math.max(D.WheelMacros.GetHeight(unitId), D.KeyActions.GetHeight(unitId),
            D.MouseButtonActions.GetHeight(unitId))
end

function G.GetRowTotalHeight(rowOrUnit)
    if type(rowOrUnit) == "table" and rowOrUnit.surfaces then
        local surfaceHeight = C.ROW_H
        for _, surface in ipairs(rowOrUnit.surfaces) do
            if surface.visible or surface == rowOrUnit.primary then
                surfaceHeight = math.max(surfaceHeight, surface:GetHeight())
            end
        end
        return surfaceHeight + G.GetActionAreaHeight(rowOrUnit)
    end
    return C.ROW_H + D.GetHotStripHeight() + G.GetRowPowerChromeHeight(rowOrUnit)
        + G.GetActionAreaHeight(rowOrUnit)
end
