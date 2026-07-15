ApogeePartyHealthBars_S = {
    sv = { enabled = true },
    charSv = { wheelMacros = { enabled = true } },
}

local inCombat = false
function InCombatLockdown() return inCombat end

local reloads, disableCalls = 0, 0
function ReloadUI() reloads = reloads + 1 end

local messages = {}
local wheelCanDisable = true
local wheel = {
    Disable = function()
        disableCalls = disableCalls + 1
        return wheelCanDisable, wheelCanDisable and nil or "wheel restore failed"
    end,
}

dofile("ApogeePartyHealthBars_ConfigController.lua")
local controller = ApogeePartyHealthBars_ConfigController
controller.Initialize({
    WheelMacros = wheel,
    Print = function(message) messages[#messages + 1] = message end,
})

ApogeePartyHealthSV = ApogeePartyHealthBars_S.sv
ApogeePartyHealthCharSV = ApogeePartyHealthBars_S.charSv

inCombat = true
assert(not controller.FactoryReset(), "factory reset ran during combat")
assert(ApogeePartyHealthSV and ApogeePartyHealthCharSV and reloads == 0 and disableCalls == 0,
    "combat-blocked factory reset changed saved state")

inCombat = false
wheelCanDisable = false
assert(not controller.FactoryReset(), "factory reset continued after wheel restoration failed")
assert(ApogeePartyHealthSV and ApogeePartyHealthCharSV and reloads == 0,
    "failed wheel restoration erased saved state")

wheelCanDisable = true
assert(controller.FactoryReset(), "factory reset failed")
assert(disableCalls == 2, "factory reset did not restore wheel bindings first")
assert(ApogeePartyHealthSV == nil and ApogeePartyHealthCharSV == nil,
    "factory reset did not clear both saved-variable roots")
assert(ApogeePartyHealthBars_S.sv == nil and ApogeePartyHealthBars_S.charSv == nil,
    "factory reset retained live saved-variable references")
assert(reloads == 1, "factory reset did not reload the UI")

print("PASS factory reset")
