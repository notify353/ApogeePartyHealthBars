local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_RowGeometry = {}
local G = ApogeePartyHealthBars_RowGeometry
local D

local function ResolveUnitId(rowOrUnit)
    if type(rowOrUnit) == "table" then return rowOrUnit.unitId end
    return rowOrUnit
end

function G.Initialize(deps)
    for _, key in ipairs({
        "GetHotStripHeight", "ShortcutBar", "WheelMacros", "KeyActions",
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

local function PlayerHasSeparateActivePower()
    local powerType, _, manaMax, activeMax = G.GetPlayerPowerInfo()
    return powerType ~= C.MANA_POWER and manaMax > 0 and activeMax > 0
end

function G.GetRowPowerChromeHeight(rowOrUnit)
    local unitId = ResolveUnitId(rowOrUnit)
    local stripCount = unitId == "player" and PlayerHasSeparateActivePower() and 2 or 1
    return stripCount * C.MANA_H + stripCount * C.MANA_GAP
end

function G.GetActionAreaHeight(rowOrUnit)
    local unitId = ResolveUnitId(rowOrUnit)
    return D.ShortcutBar.GetHeight(unitId)
        + math.max(D.WheelMacros.GetHeight(unitId), D.KeyActions.GetHeight(unitId))
end

function G.GetRowTotalHeight(rowOrUnit)
    return C.ROW_H + D.GetHotStripHeight()
        + G.GetRowPowerChromeHeight(rowOrUnit)
        + G.GetActionAreaHeight(rowOrUnit)
end
