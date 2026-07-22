ApogeePartyHealthBars_C = {
    ROW_H = 40,
    MANA_H = 5,
    MANA_GAP = 2,
    MANA_POWER = 0,
}

local powerType, powerToken = 0, "MANA"
local manaMax, activeMax = 100, 100
function UnitPowerType()
    return powerType, powerToken
end
function UnitPowerMax(_, requestedType)
    if requestedType == 0 then return manaMax end
    if requestedType == powerType then return activeMax end
    return 0
end
function UnitPower() return 0 end
function UnitExists() return true end

local hotHeight = 0
local playerUtilityHeight, playerShortcutHeight, targetShortcutHeight = 0, 0, 0
local raidMarkerHeight, wheelHeight, keyHeight, mouseHeight = 0, 0, 0, 0
local consumableHeight = 0
local wheelIconHeight, keyIconHeight, mouseIconHeight
local function PlayerOnlyHeight(value)
    return function(unitId)
        return unitId == "player" and value() or 0
    end
end

local wheelFeature = {
    GetHeight = PlayerOnlyHeight(function() return wheelHeight end),
    GetIconHeight = PlayerOnlyHeight(function() return wheelIconHeight or wheelHeight end),
}
local keyFeature = {
    GetHeight = PlayerOnlyHeight(function() return keyHeight end),
    GetIconHeight = PlayerOnlyHeight(function() return keyIconHeight or keyHeight end),
}
local mouseFeature = {
    GetHeight = PlayerOnlyHeight(function() return mouseHeight end),
    GetIconHeight = PlayerOnlyHeight(function() return mouseIconHeight or mouseHeight end),
}
local consumableFeature = {
    GetHeight = PlayerOnlyHeight(function() return consumableHeight end),
    GetIconHeight = PlayerOnlyHeight(function() return consumableHeight end),
}

dofile("ApogeePartyHealthBars_UnitAPI.lua")
dofile("ApogeePartyHealthBars_RowGeometry.lua")
local geometry = ApogeePartyHealthBars_RowGeometry

local valid, validationError = pcall(geometry.Initialize, {})
assert(not valid and tostring(validationError):find("GetHotStripHeight", 1, true),
    "RowGeometry accepted incomplete dependencies")

local invalidAction, invalidActionError = pcall(geometry.Initialize, {
    GetHotStripHeight = function() return 0 end,
    PlayerUtility = { GetHeight = function() return 0 end },
    ShortcutBar = { GetLaneHeight = function() return 0 end },
    RaidMarkers = { GetHeight = function() return 0 end },
    WheelMacros = { GetHeight = function() return 0 end },
    KeyActions = keyFeature,
    MouseButtonActions = mouseFeature,
    ConsumableBar = consumableFeature,
})
assert(not invalidAction and tostring(invalidActionError):find("WheelMacros.GetIconHeight", 1, true),
    "RowGeometry accepted an action dependency without its geometry contract")

geometry.Initialize({
    GetHotStripHeight = function() return hotHeight end,
    PlayerUtility = { GetHeight = PlayerOnlyHeight(function() return playerUtilityHeight end) },
    ShortcutBar = {
        GetLaneHeight = function(lane)
            if lane == "player" then return playerShortcutHeight end
            if lane == "target" then return targetShortcutHeight end
            return 0
        end,
    },
    RaidMarkers = { GetHeight = PlayerOnlyHeight(function() return raidMarkerHeight end) },
    WheelMacros = wheelFeature,
    KeyActions = keyFeature,
    MouseButtonActions = mouseFeature,
    ConsumableBar = consumableFeature,
})

assert(geometry.GetActionAreaHeight("player") == 0, "empty actions reserved height")
assert(geometry.GetRowTotalHeight("player") == 47,
    "base player row did not include exactly one power strip")

raidMarkerHeight = 18
assert(geometry.GetActionAreaHeight("player") == 18
        and geometry.GetRowTotalHeight("player") == 65,
    "hidden target accessories did not keep their stable compact tier")
raidMarkerHeight = 0

playerUtilityHeight = 18
assert(geometry.GetActionAreaHeight("player") == 18
        and geometry.GetRowTotalHeight("player") == 65,
    "player utility lane height was not reserved outside the health bar")
playerUtilityHeight = 0

playerShortcutHeight = 28
assert(geometry.GetActionAreaHeight("player") == 0
        and geometry.GetRowTotalHeight("player") == 47,
    "panel-footer Shortcuts still changed player-row geometry")

playerShortcutHeight, keyHeight = 0, 136
assert(geometry.GetActionAreaHeight("player") == 136, "Keys-only height was omitted")
assert(geometry.GetRowTotalHeight("player") == 183, "Keys-only row height was wrong")

keyHeight, wheelHeight = 0, 169
assert(geometry.GetActionAreaHeight("player") == 169, "Wheel-only height was wrong")
assert(geometry.GetRowTotalHeight("player") == 216, "Wheel-only row height changed")

wheelHeight, wheelIconHeight = 169, 159
keyHeight, keyIconHeight = 136, 105
mouseHeight, mouseIconHeight = 78, 78
consumableHeight = 51
local actionGeometry = geometry.GetActionHudGeometry("player")
assert(actionGeometry.offsets.wheel == 0
        and actionGeometry.offsets.keys == 54
        and actionGeometry.offsets.buttons == 81
        and actionGeometry.offsets.consumables == 108
        and actionGeometry.iconHeight == 159
        and actionGeometry.height == 190
        and geometry.GetActionAreaHeight("player", actionGeometry) == 190,
    "Keys and Buttons icon grids were not bottom-aligned with Wheel")
wheelIconHeight, keyIconHeight, mouseIconHeight = nil, nil, nil
consumableHeight = 0

playerShortcutHeight, keyHeight, wheelHeight = 28, 136, 169
assert(geometry.GetActionAreaHeight("player") == 169,
    "panel-footer Shortcuts changed the taller bound-action feature height")
assert(geometry.GetActionAreaHeight("player") ~= playerShortcutHeight + keyHeight + wheelHeight,
    "footer Shortcuts and player action HUDs were summed into one row")

wheelHeight, mouseHeight = 0, 81
assert(geometry.GetActionAreaHeight("player") == 136,
    "Buttons HUD height was not included in the bound-action maximum")
mouseHeight, wheelHeight = 0, 169

playerShortcutHeight, keyHeight, wheelHeight = 0, 0, 0
playerUtilityHeight, targetShortcutHeight = 18, 36
assert(geometry.GetActionAreaHeight("player") == 36,
    "parallel self-buff and target-CC lanes were summed instead of sharing a tier")
playerShortcutHeight = 28
assert(geometry.GetActionAreaHeight("player") == 36,
    "panel-footer Shortcuts changed the parallel player and target utility tier")
playerUtilityHeight, targetShortcutHeight = 0, 0
playerShortcutHeight, keyHeight, wheelHeight = 28, 136, 169

powerType, powerToken, manaMax, activeMax = 1, "RAGE", 100, 50
assert(geometry.GetRowPowerChromeHeight("player") == 14,
    "separate active player power did not reserve two strips")

hotHeight = 13
assert(geometry.GetRowTotalHeight({ unitId = "player" }) == 236,
    "HoT strip or table-based player unit was omitted")
assert(geometry.GetRowPowerChromeHeight("party1") == 14,
    "non-player row did not use the shared adaptive resource rule")
assert(geometry.GetActionAreaHeight("party1") == 0,
    "non-player row reserved player-only action height")
assert(geometry.GetRowTotalHeight("party1") == 67,
    "non-player row height did not include adaptive power chrome")

powerType, powerToken, activeMax = 0, "MANA", 100
assert(geometry.GetRowPowerChromeHeight("player") == 7,
    "mana-only player did not return to one power strip")

print("PASS row geometry")
