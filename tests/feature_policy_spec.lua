dofile("Core/Namespace.lua")
dofile("Core/FeaturePolicy.lua")

local available = { auraReminders = true, shieldOverlay = false }
local state = { sv = {} }
local policy = ApogeePartyHealthBars.Require("Core", "FeaturePolicy").Create(state, {
    IsFeatureAvailable = function(key) return available[key] == true end,
})

assert(policy.IsSavedFeatureEnabled("enabled") == true,
    "unset saved intent should remain enabled")
state.sv.enabled = false
assert(policy.IsSavedFeatureEnabled("enabled") == false,
    "explicitly disabled saved intent was ignored")
assert(policy.IsEffectiveFeatureEnabled("partyBuffEnabled") == true,
    "available optional feature was rejected")
assert(policy.IsEffectiveFeatureEnabled("shieldEnabled") == false,
    "unavailable optional feature was accepted")
state.sv.shieldEnabled = false
available.shieldOverlay = true
assert(policy.IsEffectiveFeatureEnabled("shieldEnabled") == false,
    "client support overrode disabled saved intent")
assert(policy.IsEffectiveFeatureEnabled("showUnitTargets") == true,
    "ordinary saved feature was incorrectly capability-gated")

print("PASS feature support policy")

