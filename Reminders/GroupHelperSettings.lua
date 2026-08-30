local Settings = {}
ApogeePartyHealthBars.Define("Runtime", "GroupHelperSettings", Settings)

local D
function Settings.Initialize(deps)
    assert(deps and type(deps.GetSavedVariables) == "function",
        "GroupHelperSettings requires saved variables")
    D = deps
end

local function values()
    return D and D.GetSavedVariables() or nil
end

function Settings.IsEnabled()
    local saved = values()
    return saved and saved.enabled ~= false and saved.groupHelperEnabled ~= false or false
end

function Settings.SetEnabled(enabled)
    local saved = values()
    if not saved then return false end
    enabled = enabled == true
    if saved.groupHelperEnabled == enabled then return false end
    saved.groupHelperEnabled = enabled
    if D.OnChanged then D.OnChanged("enabled") end
    return true
end
