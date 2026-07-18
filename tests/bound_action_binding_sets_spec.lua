local currentSet = 2
local saved = { ownership = {} }
local bindingSets = {
    [1] = { Q = "ACCOUNT_Q", E = "ACCOUNT_E" },
    [2] = { Q = "CHARACTER_Q", E = "CHARACTER_E" },
}
local rejected

function GetCurrentBindingSet() return currentSet end
function GetBindingAction(key) return bindingSets[currentSet][key] or "" end
function GetBindingName(action) return action end
function SetBinding(key, action)
    if rejected and rejected.set == currentSet and rejected.key == key
        and rejected.action == (action or "") then
        return false
    end
    bindingSets[currentSet][key] = action or ""
    return true
end
function SaveBindings(set) assert(set == currentSet, "saved the wrong binding set") end
function LoadBindings(set)
    assert(bindingSets[set], "loaded an unknown binding set")
    currentSet = set
end
function InCombatLockdown() return false end

dofile("ApogeePartyHealthBars_BoundActionBindings.lua")
local factory = ApogeePartyHealthBars_BoundActionBindings
local slots = {
    { id = "keyQ", key = "Q", label = "Key Q" },
    { id = "keyE", key = "E", label = "Key E" },
}
local function owned(slot) return "CLICK Test" .. slot.id .. ":LeftButton" end
local manager = factory.Create({
    slots = slots,
    state = function() return saved end,
    ownedAction = owned,
    label = "test bindings",
})

assert(manager.ClaimCurrentSet(), "character binding set was not claimed")
assert(bindingSets[2].Q == owned(slots[1]) and bindingSets[2].E == owned(slots[2]),
    "character binding set was not claimed")

LoadBindings(1)
local reconciled, conflicts = manager.Reconcile()
assert(reconciled and #conflicts == 0,
    "permanent feature did not claim a newly active binding set")
assert(bindingSets[1].Q == owned(slots[1]) and bindingSets[1].E == owned(slots[2])
    and saved.ownership["1"].keyQ.previousAction == "ACCOUNT_Q"
    and saved.ownership["2"].keyQ.previousAction == "CHARACTER_Q",
    "binding-set ownership was not isolated")

bindingSets[1].Q = ""
local currentConflicts = manager.GetConflicts()
assert(#currentConflicts == 1 and currentConflicts[1].slot.id == "keyQ",
    "external unbind was hidden after a binding-set switch")
bindingSets[1].Q = owned(slots[1])

assert(factory.ReleaseAll({ manager }), "multi-set release failed")
assert(currentSet == 1, "multi-set release did not restore the originally active set")
assert(bindingSets[1].Q == "ACCOUNT_Q" and bindingSets[1].E == "ACCOUNT_E"
    and bindingSets[2].Q == "CHARACTER_Q" and bindingSets[2].E == "CHARACTER_E",
    "multi-set release did not restore both binding sets")
assert(saved.ownership["1"] == nil and saved.ownership["2"] == nil,
    "multi-set release retained ownership")

assert(manager.ClaimCurrentSet(), "account binding set could not be claimed for copied-set coverage")
bindingSets[2].Q, bindingSets[2].E = owned(slots[1]), owned(slots[2])
LoadBindings(2)
assert(manager.Reconcile(), "copied character binding set could not reconcile")
assert(saved.ownership["2"].keyQ.previousAction == "ACCOUNT_Q"
    and saved.ownership["2"].keyE.previousAction == "ACCOUNT_E",
    "copied binding set forgot the prior actions captured in the source set")
assert(factory.ReleaseAll({ manager }), "copied binding sets could not be released")
assert(bindingSets[1].Q == "ACCOUNT_Q" and bindingSets[1].E == "ACCOUNT_E"
    and bindingSets[2].Q == "ACCOUNT_Q" and bindingSets[2].E == "ACCOUNT_E",
    "copied binding set did not restore inherited prior actions")

bindingSets[2].Q, bindingSets[2].E = "CHARACTER_Q", "CHARACTER_E"
LoadBindings(1)
assert(manager.ClaimCurrentSet(), "account binding set could not be reclaimed")
LoadBindings(2)
assert(manager.Reconcile(), "character binding set could not be re-enabled")
LoadBindings(1)
rejected = { set = 2, key = "E", action = "CHARACTER_E" }
local released, code = factory.ReleaseAll({ manager })
assert(not released and code == "binding_restore_failed",
    "multi-set restoration failure was reported as successful")
assert(currentSet == 1,
    "multi-set restoration failure did not restore the active binding set")
for set = 1, 2 do
    assert(bindingSets[set].Q == owned(slots[1]) and bindingSets[set].E == owned(slots[2]),
        "multi-set restoration failure did not roll back set " .. set)
    assert(saved.ownership[tostring(set)].keyQ and saved.ownership[tostring(set)].keyE,
        "multi-set restoration failure lost ownership for set " .. set)
end

print("PASS cross-binding-set transactions")
