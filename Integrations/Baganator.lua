-- Optional Baganator view-lifecycle adapter. This module uses only Baganator's
-- public callback registry and never inspects or hooks item buttons.
local I = {}
ApogeePartyHealthBars.Define("Integrations", "Baganator", I)

local callback
local registered = false

local function TryRegister()
    if registered then return true end
    local registry = _G.Baganator and _G.Baganator.CallbackRegistry
    if not registry or type(registry.RegisterCallback) ~= "function" then
        return false
    end
    registry:RegisterCallback("BagShow", function()
        if callback then callback(true) end
    end)
    registry:RegisterCallback("BagHide", function()
        if callback then callback(false) end
    end)
    registered = true
    return true
end

function I.Register(onVisibilityChanged)
    assert(type(onVisibilityChanged) == "function",
        "Baganator integration requires a visibility callback")
    callback = onVisibilityChanged
    return TryRegister()
end

function I.OnAddonLoaded(addonName)
    if addonName ~= "Baganator" then return false end
    return TryRegister()
end

function I.IsRegistered()
    return registered
end

