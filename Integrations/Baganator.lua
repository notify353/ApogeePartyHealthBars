-- Optional Baganator view-lifecycle adapter. This module uses only Baganator's
-- public callback registry and never inspects or hooks item buttons.
local I = {}
ApogeePartyHealthBars.Define("Integrations", "Baganator", I)

local callback
local registeredRegistry
local callbackOwner = {}

local function GetRegistry()
    local registry = _G.Baganator and _G.Baganator.CallbackRegistry
    if not registry or type(registry.RegisterCallback) ~= "function" then
        return nil
    end
    return registry
end

function I.EnsureRegistered(force)
    local registry = GetRegistry()
    if not registry then
        registeredRegistry = nil
        return false
    end
    if not force and registeredRegistry == registry then return true end

    -- A stable owner makes retries idempotent: CallbackRegistryMixin replaces
    -- this owner's prior callback for each event instead of accumulating
    -- handlers. Do not record success until both public callbacks attach.
    local ok = pcall(function()
        registry:RegisterCallback("BagShow", function()
            if callback then callback(true) end
        end, callbackOwner)
        registry:RegisterCallback("BagHide", function()
            if callback then callback(false) end
        end, callbackOwner)
    end)
    if not ok then
        registeredRegistry = nil
        return false
    end
    registeredRegistry = registry
    return true
end

function I.Register(onVisibilityChanged)
    assert(type(onVisibilityChanged) == "function",
        "Baganator integration requires a visibility callback")
    callback = onVisibilityChanged
    return I.EnsureRegistered()
end

function I.OnAddonLoaded(addonName)
    if addonName ~= "Baganator" then return false end
    return I.EnsureRegistered(true)
end

function I.OnLifecycleEvent()
    return I.EnsureRegistered(true)
end

function I.IsRegistered()
    return registeredRegistry ~= nil and registeredRegistry == GetRegistry()
end
