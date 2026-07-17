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

local hotHeight = 0
local shortcutHeight, wheelHeight, keyHeight = 0, 0, 0
local function PlayerOnlyHeight(value)
    return function(unitId)
        return unitId == "player" and value() or 0
    end
end

dofile("ApogeePartyHealthBars_RowGeometry.lua")
local geometry = ApogeePartyHealthBars_RowGeometry

local valid, validationError = pcall(geometry.Initialize, {})
assert(not valid and tostring(validationError):find("GetHotStripHeight", 1, true),
    "RowGeometry accepted incomplete dependencies")

geometry.Initialize({
    GetHotStripHeight = function() return hotHeight end,
    ShortcutBar = { GetHeight = PlayerOnlyHeight(function() return shortcutHeight end) },
    WheelMacros = { GetHeight = PlayerOnlyHeight(function() return wheelHeight end) },
    KeyActions = { GetHeight = PlayerOnlyHeight(function() return keyHeight end) },
})

assert(geometry.GetActionAreaHeight("player") == 0, "empty actions reserved height")
assert(geometry.GetRowTotalHeight("player") == 47,
    "base player row did not include exactly one power strip")

shortcutHeight = 28
assert(geometry.GetActionAreaHeight("player") == 28, "Shortcut-only height was wrong")
assert(geometry.GetRowTotalHeight("player") == 75, "Shortcut-only row height was wrong")

shortcutHeight, keyHeight = 0, 136
assert(geometry.GetActionAreaHeight("player") == 136, "Keys-only height was omitted")
assert(geometry.GetRowTotalHeight("player") == 183, "Keys-only row height was wrong")

keyHeight, wheelHeight = 0, 169
assert(geometry.GetActionAreaHeight("player") == 169, "Wheel-only height was wrong")
assert(geometry.GetRowTotalHeight("player") == 216, "Wheel-only row height changed")

shortcutHeight, keyHeight, wheelHeight = 28, 136, 169
assert(geometry.GetActionAreaHeight("player") == 197,
    "action area did not combine Shortcuts with the taller bound-action feature")
assert(geometry.GetActionAreaHeight("player") ~= shortcutHeight + keyHeight + wheelHeight,
    "Keys and Wheel heights were summed instead of taking the maximum")

powerType, powerToken, manaMax, activeMax = 1, "RAGE", 100, 50
assert(geometry.GetRowPowerChromeHeight("player") == 14,
    "separate active player power did not reserve two strips")
local returnedType, returnedToken, returnedManaMax, returnedActiveMax =
    geometry.GetPlayerPowerInfo()
assert(returnedType == 1 and returnedToken == "RAGE"
        and returnedManaMax == 100 and returnedActiveMax == 50,
    "player power information changed shape")

hotHeight = 13
assert(geometry.GetRowTotalHeight({ unitId = "player" }) == 264,
    "HoT strip or table-based player unit was omitted")
assert(geometry.GetRowPowerChromeHeight("party1") == 7,
    "non-player row inherited the player's extra power strip")
assert(geometry.GetActionAreaHeight("party1") == 0,
    "non-player row reserved player-only action height")
assert(geometry.GetRowTotalHeight("party1") == 60,
    "non-player row height did not include base, HoT, and one power strip")

powerType, powerToken, activeMax = 0, "MANA", 100
assert(geometry.GetRowPowerChromeHeight("player") == 7,
    "mana-only player did not return to one power strip")

print("PASS row geometry")
