-- Startup-only protocol. No saved preferences are changed, and no APHB effect
-- starts until both addons have loaded and Essentials has completed its attempt.
local B = { version = 1 }
ApogeePartyHealthBars_EssentialsOwnership = B
local settled, managed = false, false
local callbacks = {}
function B.IsSuspended() return not settled or managed end
function B.WhenLocal(callback)
    if not settled then callbacks[#callbacks + 1] = callback
    elseif not managed then callback() end
end
local function deferToggle(module)
    local apply = module.ApplyEnabledState
    local requested = false
    module.ApplyEnabledState = function(value)
        requested = value == true
        if settled and not managed then apply(requested) end
    end
    -- Initialize may resolve frame references, but cannot touch their alpha or
    -- registrations until ApplyEnabledState is released by the decision.
    B.WhenLocal(function() apply(requested) end)
end
deferToggle(ApogeePartyHealthBars_CombatUIFader)
deferToggle(ApogeePartyHealthBars_UIErrorSuppressor)
local mentions = ApogeePartyHealthBars_MentionAlerts
local register = mentions.Register
mentions.Register = function(router) B.WhenLocal(function() register(router) end) end
local isEnabled = mentions.IsEnabled
mentions.IsEnabled = function() return not B.IsSuspended() and isEnabled() end
function B.Resolve()
    if settled then return managed end
    local peer = ApogeeEssentialsOwnership
    if peer and peer.version == 1 and type(peer.Resolve) == "function" then
        local ok, owns = pcall(peer.Resolve)
        managed = ok and owns == true
    end
    settled = true
    local pending = callbacks
    callbacks = {}
    if not managed then for _, callback in ipairs(pending) do callback() end end
    return managed
end
local startup = CreateFrame("Frame")
startup:RegisterEvent("PLAYER_LOGIN")
startup:SetScript("OnEvent", function() B.Resolve(); startup:UnregisterAllEvents() end)
