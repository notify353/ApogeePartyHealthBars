dofile("ApogeePartyHealthBars_Data.lua")

local units = {
    player = { exists = true, connected = true, guid = "Player-1", health = 80, healthMax = 100,
        powerType = 3, powerToken = "ENERGY", mana = 75, manaMax = 100,
        power = 60, powerMax = 100 },
    target = { exists = true, connected = false, health = 0, healthMax = 0,
        powerType = 0, powerToken = "MANA", mana = 0, manaMax = 0 },
}
function UnitExists(unit) return units[unit] and units[unit].exists or false end
function UnitGUID(unit) return units[unit] and units[unit].guid end
function UnitIsConnected(unit) return units[unit].connected end
function UnitIsDeadOrGhost() return false end
function UnitHealth(unit) return units[unit].health end
function UnitHealthMax(unit) return units[unit].healthMax end
function UnitPowerType(unit) return units[unit].powerType, units[unit].powerToken end
function UnitPowerMax(unit, powerType)
    if powerType == 0 then return units[unit].manaMax end
    return units[unit].powerMax or 0
end
function UnitPower(unit, powerType)
    if powerType == 0 then return units[unit].mana end
    return units[unit].power or 0
end
function UnitInRange() return false, true end
function UnitCanAssist() return true end
function UnitIsEnemy() return false end

dofile("ApogeePartyHealthBars_UnitAPI.lua")
local api = ApogeePartyHealthBars_UnitAPI

local channels = api.GetPowerChannels("player")
assert(#channels == 2 and channels[1].powerType == 0 and channels[2].powerType == 3,
    "dual-resource unit did not receive mana then active power")
assert(channels[1].value == 75 and channels[2].value == 60)
local health, maximum = api.GetHealth("target")
assert(health == 0 and maximum == 1, "invalid maximum health did not fail closed")
local _, _, validMaximum = api.GetHealth("target")
assert(not validMaximum, "invalid maximum health was not reported to strict consumers")
assert(not api.IsConnected("target") and not api.GetDefaultRange("player"))
assert(api.GetGUID("player") == "Player-1" and api.GetGUID("focus") == nil)
assert(not api.Exists("focus") and #api.GetPowerChannels("focus") == 0)

local deadAPI, assistAPI, enemyAPI = UnitIsDeadOrGhost, UnitCanAssist, UnitIsEnemy
UnitIsDeadOrGhost, UnitCanAssist, UnitIsEnemy = nil, nil, nil
assert(api.CanHeal("player"), "missing optional healability APIs did not fail open")
UnitIsDeadOrGhost, UnitCanAssist, UnitIsEnemy = deadAPI, assistAPI, enemyAPI

print("PASS unit API adapter")
