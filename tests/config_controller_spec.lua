ApogeePartyHealthBars_S = {
    sv = { enabled = true },
    charSv = { wheelMacros = {} },
}

local inCombat = false
function InCombatLockdown() return inCombat end

local reloads, transactionCalls, claimCalls = 0, 0, 0
function ReloadUI() reloads = reloads + 1 end

local messages = {}
local transactionCanRelease = true
local function releaseBindings()
    transactionCalls = transactionCalls + 1
    return transactionCanRelease,
        transactionCanRelease and "released" or "binding_restore_failed",
        transactionCanRelease and "released" or "Keys restore failed"
end

dofile("ApogeePartyHealthBars_ConfigController.lua")
local controller = ApogeePartyHealthBars_ConfigController
controller.Initialize({
    ClaimBoundActionBindings = function() claimCalls = claimCalls + 1; return true, "claimed" end,
    ReleaseBoundActionBindings = releaseBindings,
    ForceRefresh = function() end,
    StopUpdateFrames = function() end,
    ClearDirtyFlags = function() end,
    panel = { Hide = function() end },
    HideAllSecureOverlays = function() end,
    UpdateMinimapButtonStyle = function() end,
    Print = function(message) messages[#messages + 1] = message end,
})

ApogeePartyHealthSV = ApogeePartyHealthBars_S.sv
ApogeePartyHealthCharSV = ApogeePartyHealthBars_S.charSv

assert(controller.SetAddonEnabled(false) and not ApogeePartyHealthBars_S.sv.enabled
        and transactionCalls == 1,
    "global add-on disable did not release permanent Keys and Wheel bindings")
assert(controller.SetAddonEnabled(true) and ApogeePartyHealthBars_S.sv.enabled
        and claimCalls == 1,
    "global add-on enable did not reclaim permanent Keys and Wheel bindings")

inCombat = true
assert(not controller.FactoryReset(), "factory reset ran during combat")
assert(ApogeePartyHealthSV and ApogeePartyHealthCharSV and reloads == 0 and transactionCalls == 1,
    "combat-blocked factory reset changed saved state")

inCombat = false
transactionCanRelease = false
assert(not controller.FactoryReset(), "factory reset continued after a binding restoration failed")
assert(ApogeePartyHealthSV and ApogeePartyHealthCharSV and reloads == 0,
    "failed atomic binding restoration erased saved state")
assert(messages[#messages] == "Keys restore failed",
    "factory reset reported an internal failure code instead of the actionable detail")

transactionCanRelease = true
assert(controller.FactoryReset(), "factory reset failed")
assert(transactionCalls == 3, "factory reset did not use one shared binding transaction")
assert(ApogeePartyHealthSV == nil and ApogeePartyHealthCharSV == nil,
    "factory reset did not clear both saved-variable roots")
assert(ApogeePartyHealthBars_S.sv == nil and ApogeePartyHealthBars_S.charSv == nil,
    "factory reset retained live saved-variable references")
assert(reloads == 1, "factory reset did not reload the UI")

print("PASS factory reset")
