local bindings = {
    W = "CLICK TestW:LeftButton",
    Q = "CLICK TestQ:LeftButton",
}
local rejectDirectReplacement = true
local onBindingChanged
local wheelSaved = {
    bindingVersion = 1,
    ownership = { ["1"] = { w = { previousAction = "MOVEFORWARD" } } },
}
local keySaved = {
    bindingVersion = 1,
    ownership = { ["1"] = { q = { previousAction = "MOVEFORWARD" } } },
}
function GetCurrentBindingSet() return 1 end
function GetBindingAction(key) return bindings[key] or "" end
function GetBindingName(action) return action end
function SetBinding(key, action)
    if rejectDirectReplacement and action and bindings[key] ~= "" and bindings[key] ~= action then
        return false
    end
    bindings[key] = action or ""
    if onBindingChanged then onBindingChanged() end
    return true
end
function SaveBindings() end
function InCombatLockdown() return false end

dofile("ApogeePartyHealthBars_BoundActionBindings.lua")
local factory = ApogeePartyHealthBars_BoundActionBindings
local wheelManager = factory.Create({
    slots = { { id = "w", key = "W", label = "Key W" } },
    state = function() return wheelSaved end,
    ownedAction = function() return "CLICK TestW:LeftButton" end,
})
local keyManager = factory.Create({
    slots = { { id = "q", key = "Q", label = "Key Q" } },
    state = function() return keySaved end,
    ownedAction = function() return "CLICK TestQ:LeftButton" end,
})
local bindingEvents = 0
onBindingChanged = function()
    bindingEvents = bindingEvents + 1
    local reconciled, code = factory.ReconcileAll({ wheelManager, keyManager })
    assert(reconciled and code == "transaction",
        "UPDATE_BINDINGS re-entered an active cross-feature transaction")
end
local released = factory.ReleaseAll({ wheelManager, keyManager })
onBindingChanged = nil
assert(released and bindingEvents > 0
    and wheelSaved.ownership["1"] == nil and keySaved.ownership["1"] == nil
    and bindings.W == "MOVEFORWARD" and bindings.Q == "MOVEFORWARD",
    "profile release did not clear CLICK bindings before restoring normal actions")
assert(keyManager.Reconcile() and bindings.Q == "CLICK TestQ:LeftButton"
    and keySaved.ownership["1"].q.previousAction == "MOVEFORWARD",
    "permanent destination did not reclaim released bindings")

print("PASS profile-safe binding release and reclaim")
