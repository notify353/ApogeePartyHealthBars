local C = ApogeePartyHealthBars_C
local API = ApogeePartyHealthBars_UnitAPI

ApogeePartyHealthBars_RowGeometry = {}
local G = ApogeePartyHealthBars_RowGeometry
local D

local ACTION_FEATURES = {
    { key = "wheel", dependency = "WheelMacros" },
    { key = "keys", dependency = "KeyActions" },
    { key = "buttons", dependency = "MouseButtonActions" },
    { key = "consumables", dependency = "ConsumableBar" },
}

local function ResolveUnitId(rowOrUnit)
    if type(rowOrUnit) == "table" then return rowOrUnit.unitId end
    return rowOrUnit
end

function G.Initialize(deps)
    assert(type(deps) == "table", "RowGeometry dependencies must be a table")
    assert(type(deps.GetHotStripHeight) == "function",
        "RowGeometry missing dependency method: GetHotStripHeight")

    for dependency, method in pairs({
        PlayerUtility = "GetHeight",
        ShortcutBar = "GetLaneHeight",
        RaidMarkers = "GetHeight",
    }) do
        assert(type(deps[dependency]) == "table"
                and type(deps[dependency][method]) == "function",
            "RowGeometry missing dependency method: " .. dependency .. "." .. method)
    end

    for _, definition in ipairs(ACTION_FEATURES) do
        local feature = deps[definition.dependency]
        assert(type(feature) == "table",
            "RowGeometry missing dependency: " .. definition.dependency)
        for _, method in ipairs({ "GetHeight", "GetIconHeight" }) do
            assert(type(feature[method]) == "function",
                "RowGeometry missing dependency method: "
                    .. definition.dependency .. "." .. method)
        end
    end
    D = deps
end

function G.GetRowPowerChromeHeight(rowOrUnit)
    local unitId = ResolveUnitId(rowOrUnit)
    local stripCount = #API.GetPowerChannels(unitId)
    return stripCount * C.MANA_H + stripCount * C.MANA_GAP
end

function G.GetActionHudGeometry(rowOrUnit)
    local unitId = ResolveUnitId(rowOrUnit)
    local geometry = { height = 0, offsets = {} }
    local measurements = {}
    local tallestIcons = 0

    for _, definition in ipairs(ACTION_FEATURES) do
        local feature = D[definition.dependency]
        local featureHeight = feature.GetHeight(unitId)
        local iconHeight = featureHeight > 0 and feature.GetIconHeight(unitId) or 0
        measurements[definition.key] = {
            height = featureHeight,
            iconHeight = iconHeight,
        }
        tallestIcons = math.max(tallestIcons, iconHeight)
    end

    for _, definition in ipairs(ACTION_FEATURES) do
        local measurement = measurements[definition.key]
        local offset = 0
        if measurement.height > 0 then
            offset = math.max(0, tallestIcons - measurement.iconHeight)
            geometry.height = math.max(geometry.height, offset + measurement.height)
        end
        geometry.offsets[definition.key] = offset
    end

    return geometry
end

function G.GetActionHudHeight(rowOrUnit)
    return G.GetActionHudGeometry(rowOrUnit).height
end

function G.GetActionAreaHeight(rowOrUnit, actionGeometry)
    local unitId = ResolveUnitId(rowOrUnit)
    actionGeometry = actionGeometry or G.GetActionHudGeometry(unitId)
    local actionHudHeight = actionGeometry.height
    if unitId ~= "player" then return actionHudHeight end

    local playerStack = actionHudHeight
        + D.PlayerUtility.GetHeight(unitId)
    local targetStack = math.max(
        D.ShortcutBar.GetLaneHeight("target"),
        D.RaidMarkers.GetHeight(unitId))
    return math.max(playerStack, targetStack)
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
