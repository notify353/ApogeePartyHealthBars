ApogeePartyHealthBars_C = {
    SHORTCUT_ICON_SIZE = 24, SHORTCUT_ICON_GAP = 3, SHORTCUT_READY_PULSE = 0.65,
    SHORTCUT_SOUND_DEBOUNCE = 2, OUT_OF_RANGE_ALPHA = 0.35, ROW_CONTENT_W = 184,
}
ApogeePartyHealthBars_S = { charSv = {} }
ApogeePartyHealthBars_Sounds = { NormalizeKey = function(key) return key or "none" end }
ApogeePartyHealthBars_ShortcutItems = {}
ApogeePartyHealthBars_UIHelpers = {}
ApogeePartyHealthBars_ActionHud = { Clear = function() end, Show = function() end, Attach = function() end }

function GetNumShapeshiftForms() return 0 end
function GetShapeshiftForm() return 0 end
function UnitClass() return "Mage", "MAGE" end

local function widget()
    local value = { attributes = {} }
    function value:SetSize() end
    function value:SetPoint() end
    function value:RegisterForClicks() end
    function value:Show() end
    function value:Hide() end
    function value:SetAttribute(key, entry) self.attributes[key] = entry end
    function value:GetAttribute(key) return self.attributes[key] end
    return value
end
UIParent = widget()
function CreateFrame() return widget() end

local currentSet, saveCount, rejectedKey, rejectedRestoreKey = 2, 0, nil, nil
local bindings = {}
local expectedPrevious = {}
local keys = { "1", "2", "3", "4", "5", "Q", "E", "R", "T", "F", "G", "Z", "X", "C", "V" }
for _, key in ipairs(keys) do
    bindings[key] = "PREVIOUS_" .. key
    expectedPrevious[key] = bindings[key]
end
function GetCurrentBindingSet() return currentSet end
function GetBindingAction(key) return bindings[key] or "" end
function GetBindingName(action) return action end
function SetBinding(key, action)
    if rejectedKey == key and type(action) == "string" and action:find("^CLICK ") then return false end
    if rejectedRestoreKey == key and action == "SECOND_" .. key then return false end
    bindings[key] = action or ""
    return true
end
function SaveBindings(set) assert(set == currentSet); saveCount = saveCount + 1 end
function InCombatLockdown() return false end

dofile("ApogeePartyHealthBars_KeyData.lua")
dofile("ApogeePartyHealthBars_ActionData.lua")
dofile("ApogeePartyHealthBars_ActionMacros.lua")
dofile("ApogeePartyHealthBars_BoundActionLayouts.lua")
dofile("ApogeePartyHealthBars_KeyLayouts.lua")
dofile("ApogeePartyHealthBars_BoundActionBindings.lua")
dofile("ApogeePartyHealthBars_KeyActions.lua")

local data = ApogeePartyHealthBars_KeyData
local layouts = ApogeePartyHealthBars_KeyLayouts
local keysRuntime = ApogeePartyHealthBars_KeyActions
layouts.Initialize()
keysRuntime.Configure({})
local manager = assert(keysRuntime.GetBindingManager(), "Keys binding manager was not created")

local enabled, code = manager.Enable()
assert(enabled and code == "enabled" and ApogeePartyHealthBars_S.charSv.keyActions.enabled,
    "Keys did not enable transactionally")
for _, slot in ipairs(data.SLOTS) do
    assert(bindings[slot.key] == "CLICK " .. slot.buttonName .. "Hud:LeftButton",
        "Keys did not claim " .. slot.key)
    assert(ApogeePartyHealthBars_S.charSv.keyActions.ownership["2"][slot.id].previousAction
        == expectedPrevious[slot.key], "Keys did not snapshot " .. slot.key)
end

bindings.Q = ""
local unboundReconciled, unboundConflicts = manager.Reconcile()
assert(not unboundReconciled and #unboundConflicts == 1 and unboundConflicts[1].slot.key == "Q"
    and bindings.Q == "", "Keys silently reclaimed an externally unbound key")
local visibleUnbound = manager.GetConflicts()
assert(#visibleUnbound == 1 and visibleUnbound[1].slot.key == "Q"
    and visibleUnbound[1].label == "Unbound",
    "Keys did not expose an externally unbound key as a conflict")
bindings.Q = "STRAFELEFT"
local reconciled, conflicts = manager.Reconcile()
assert(not reconciled and #conflicts == 1 and conflicts[1].slot.key == "Q"
    and bindings.Q == "STRAFELEFT", "Keys overwrote or failed to report a foreign binding")

local disabled, disableCode = manager.Disable()
assert(disabled and disableCode == "disabled" and not ApogeePartyHealthBars_S.charSv.keyActions.enabled,
    "Keys did not disable")
for _, slot in ipairs(data.SLOTS) do
    local expected = slot.key == "Q" and "STRAFELEFT" or expectedPrevious[slot.key]
    assert(bindings[slot.key] == expected, "Keys restored the wrong action for " .. slot.key)
end

currentSet = 1
for _, key in ipairs(keys) do bindings[key] = "ACCOUNT_" .. key end
assert(manager.Enable(), "Keys did not enable for the account binding set")
for _, slot in ipairs(data.SLOTS) do
    assert(ApogeePartyHealthBars_S.charSv.keyActions.ownership["1"][slot.id].previousAction
        == "ACCOUNT_" .. slot.key, "Keys did not isolate account ownership for " .. slot.key)
end
assert(manager.Disable(), "Keys did not restore the account binding set")
for _, key in ipairs(keys) do
    assert(bindings[key] == "ACCOUNT_" .. key, "Keys restored the wrong account action for " .. key)
end
currentSet = 2

for _, key in ipairs(keys) do bindings[key] = "SECOND_" .. key end
rejectedKey = "R"
local failed, failureCode = manager.Enable()
assert(not failed and failureCode == "binding_failed"
    and not ApogeePartyHealthBars_S.charSv.keyActions.enabled,
    "partial Keys takeover reported success")
for _, key in ipairs(keys) do
    assert(bindings[key] == "SECOND_" .. key, "partial Keys takeover did not roll back " .. key)
end
assert(ApogeePartyHealthBars_S.charSv.keyActions.ownership["2"] == nil,
    "partial Keys takeover did not restore the prior ownership schema exactly")

rejectedRestoreKey = "1"
local rollbackFailed, rollbackFailureCode = manager.Enable()
assert(not rollbackFailed and rollbackFailureCode == "binding_rollback_failed"
    and not ApogeePartyHealthBars_S.charSv.keyActions.enabled,
    "a rejected rollback was not reported distinctly")
local recoveryOwnership = ApogeePartyHealthBars_S.charSv.keyActions.ownership["2"]
assert(bindings["1"] == "CLICK " .. data.SLOTS[1].buttonName .. "Hud:LeftButton"
    and recoveryOwnership and recoveryOwnership.key1.previousAction == "SECOND_1",
    "a rejected rollback did not preserve its restoration record")
rejectedKey, rejectedRestoreKey = nil, nil
local recovered, recoveryFailures = manager.Reconcile()
assert(recovered and #recoveryFailures == 0 and bindings["1"] == "SECOND_1"
    and ApogeePartyHealthBars_S.charSv.keyActions.ownership["2"] == nil,
    "reconciliation did not finish a previously rejected rollback")

ApogeePartyHealthBars_S.charSv.keyActions.enabled = true
rejectedKey, rejectedRestoreKey = "R", "1"
local incompleteClaim, incompleteCode = manager.Reconcile()
local incompleteOwnership = ApogeePartyHealthBars_S.charSv.keyActions.ownership["2"]
assert(not incompleteClaim and incompleteCode == "binding_rollback_failed"
    and incompleteOwnership and incompleteOwnership.__claimPending,
    "an interrupted active-set claim was not preserved for retry")
rejectedKey, rejectedRestoreKey = nil, nil
local retriedClaim, retryConflicts = manager.Reconcile()
assert(retriedClaim and #retryConflicts == 0
    and not ApogeePartyHealthBars_S.charSv.keyActions.ownership["2"].__claimPending,
    "reconciliation did not retry an interrupted active-set claim")
for _, slot in ipairs(data.SLOTS) do
    assert(bindings[slot.key] == "CLICK " .. slot.buttonName .. "Hud:LeftButton",
        "retried active-set claim missed " .. slot.key)
end
assert(manager.Disable(), "Keys did not disable after the retried active-set claim")
for _, key in ipairs(keys) do
    assert(bindings[key] == "SECOND_" .. key,
        "retried active-set claim restored the wrong action for " .. key)
end

local inCombat = true
InCombatLockdown = function() return inCombat end
local combatEnabled, combatCode = manager.Enable()
assert(not combatEnabled and combatCode == "combat", "Keys enabled in combat")
assert(saveCount >= 3, "Keys binding mutations were not persisted")
inCombat = false

local firstState, secondState = "enabled", "enabled"
local firstRestoreCount, secondRestoreCount = 0, 0
local firstManager = {
    Snapshot = function() return { state = firstState } end,
    Disable = function() firstState = "disabled"; return true end,
    RestoreSnapshot = function(snapshot)
        firstRestoreCount = firstRestoreCount + 1
        firstState = snapshot.state
        return true
    end,
}
local secondManager = {
    Snapshot = function() return { state = secondState } end,
    Disable = function() secondState = "failed"; return false, "binding_restore_failed", "second failed" end,
    RestoreSnapshot = function(snapshot)
        secondRestoreCount = secondRestoreCount + 1
        secondState = snapshot.state
        return true
    end,
}
local atomic, atomicCode = ApogeePartyHealthBars_BoundActionBindings.DisableAll({
    firstManager, secondManager,
})
assert(not atomic and atomicCode == "binding_restore_failed",
    "cross-feature binding failure was reported as successful")
assert(firstState == "enabled" and secondState == "enabled"
    and firstRestoreCount == 1 and secondRestoreCount == 1,
    "cross-feature binding failure did not restore every feature snapshot")

print("PASS transactional 15-key bindings")
