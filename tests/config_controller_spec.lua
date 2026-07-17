ApogeePartyHealthBars_S = {
    sv = { enabled = true },
    charSv = { wheelMacros = { enabled = true } },
}

local inCombat = false
function InCombatLockdown() return inCombat end

local reloads, transactionCalls = 0, 0
function ReloadUI() reloads = reloads + 1 end

local messages = {}
local wheelManager, keyManager = { name = "wheel" }, { name = "keys" }
local wheel = { GetBindingManager = function() return wheelManager end }
local keys = { GetBindingManager = function() return keyManager end }
local transactionCanDisable = true
local transactions = {
    DisableAll = function(managers)
        transactionCalls = transactionCalls + 1
        assert(#managers == 2 and managers[1] == wheelManager and managers[2] == keyManager,
            "factory reset did not include both binding managers in canonical order")
        return transactionCanDisable,
            transactionCanDisable and "disabled" or "binding_restore_failed",
            transactionCanDisable and "disabled" or "Keys restore failed"
    end,
}

dofile("ApogeePartyHealthBars_ConfigController.lua")
local controller = ApogeePartyHealthBars_ConfigController
controller.Initialize({
    WheelMacros = wheel,
    KeyActions = keys,
    BoundActionBindings = transactions,
    Print = function(message) messages[#messages + 1] = message end,
})

ApogeePartyHealthSV = ApogeePartyHealthBars_S.sv
ApogeePartyHealthCharSV = ApogeePartyHealthBars_S.charSv

inCombat = true
assert(not controller.FactoryReset(), "factory reset ran during combat")
assert(ApogeePartyHealthSV and ApogeePartyHealthCharSV and reloads == 0 and transactionCalls == 0,
    "combat-blocked factory reset changed saved state")

inCombat = false
transactionCanDisable = false
assert(not controller.FactoryReset(), "factory reset continued after a binding restoration failed")
assert(ApogeePartyHealthSV and ApogeePartyHealthCharSV and reloads == 0,
    "failed atomic binding restoration erased saved state")
assert(messages[#messages] == "Keys restore failed",
    "factory reset reported an internal failure code instead of the actionable detail")

transactionCanDisable = true
assert(controller.FactoryReset(), "factory reset failed")
assert(transactionCalls == 2, "factory reset did not use one shared binding transaction")
assert(ApogeePartyHealthSV == nil and ApogeePartyHealthCharSV == nil,
    "factory reset did not clear both saved-variable roots")
assert(ApogeePartyHealthBars_S.sv == nil and ApogeePartyHealthBars_S.charSv == nil,
    "factory reset retained live saved-variable references")
assert(reloads == 1, "factory reset did not reload the UI")

print("PASS factory reset")
