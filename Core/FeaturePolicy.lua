-- Saved intent and client-capability policy for optional runtime features.
local FeaturePolicy = {}
ApogeePartyHealthBars.Define("Core", "FeaturePolicy", FeaturePolicy)

local SUPPORT_FEATURE_BY_SETTING = {
    partyBuffEnabled = "auraReminders",
    selfBuffEnabled = "auraReminders",
    clickableBuffIcons = "auraReminders",
    shieldEnabled = "shieldOverlay",
    incomingHealEnabled = "incomingHeals",
    rangeCheckEnabled = "rangeFade",
    threatEnabled = "threat",
    threatPercentEnabled = "threat",
    threatAwarenessEnabled = "threat",
    hotEnabled = "hotTracking",
}

function FeaturePolicy.Create(state, capabilities)
    assert(type(state) == "table", "FeaturePolicy requires state")
    assert(type(capabilities) == "table"
        and type(capabilities.IsFeatureAvailable) == "function",
        "FeaturePolicy requires client capabilities")

    local Policy = {}

    function Policy.IsSavedFeatureEnabled(settingKey)
        return state.sv and state.sv[settingKey] ~= false
    end

    function Policy.IsEffectiveFeatureEnabled(settingKey)
        if not Policy.IsSavedFeatureEnabled(settingKey) then return false end
        local capabilityKey = SUPPORT_FEATURE_BY_SETTING[settingKey]
        return not capabilityKey or capabilities.IsFeatureAvailable(capabilityKey)
    end

    return Policy
end

