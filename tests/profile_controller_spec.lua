ApogeePartyHealthBars_S = { sv = {}, charSv = {} }
local releaseOk, rollbackOk, releases, reloads, activeId = true, nil, 0, 0, "p1"
function InCombatLockdown() return false end
function ReloadUI() reloads = reloads + 1 end

dofile("ApogeePartyHealthBars_ConfigController.lua")
local controller = ApogeePartyHealthBars_ConfigController
local profiles = {
    p1 = { id = "p1", classToken = "PRIEST" },
    p2 = { id = "p2", classToken = "PRIEST" },
}
local setActiveOk = true
controller.Initialize({
    ClaimBoundActionBindings = function() return true, "claimed" end,
    ReleaseBoundActionBindings = function()
        releases = releases + 1
        return releaseOk, releaseOk and "released" or "failed", releaseOk and nil or "restore failed",
            rollbackOk
    end,
    ProfileStore = {
        GetActiveId = function() return activeId end,
        GetClassToken = function() return "PRIEST" end,
        Get = function(id) return profiles[id] end,
        ValidateProfile = function() return true end,
        SetActive = function(id)
            if not setActiveOk then return false, "commit failed" end
            activeId = id; return true
        end,
        ResetCharacter = function()
            return { profileStore = { schemaVersion = 2 }, bindingRuntime = {} }
        end,
    },
    Print = function() end,
})

assert(controller.ActivateProfile("p2") and activeId == "p2" and releases == 1 and reloads == 1,
    "profile activation did not release, commit, and reload")
assert(controller.ActivateProfile("p2") and releases == 1 and reloads == 1,
    "reselecting the active profile performed work")
releaseOk = false
assert(not controller.ActivateProfile("p1") and activeId == "p2" and reloads == 1,
    "failed binding restoration changed or reloaded the profile")
rollbackOk = false
assert(not controller.ActivateProfile("p1") and activeId == "p2" and reloads == 2,
    "failed binding rollback left partial binding state without a recovery reload")
rollbackOk = nil
releaseOk = true
setActiveOk = false
assert(not controller.ActivateProfile("p1") and activeId == "p2" and reloads == 3,
    "failed profile commit left released bindings without a recovery reload")
setActiveOk = true
local mutated = false
assert(controller.MutateActiveProfile(function() mutated = true; return true end)
    and mutated and reloads == 4,
    "active profile mutation did not use the safe reload path")
profiles.p3 = { id = "p3", classToken = "PRIEST" }
assert(controller.CreateAndActivateProfile(function() return profiles.p3 end)
    and activeId == "p3" and reloads == 5,
    "import creation was not committed after safe binding release")

local accountRoot = { legacy = true }
ApogeePartyHealthSV = accountRoot
ApogeePartyHealthCharSV = { old = true }
assert(controller.FactoryReset() and reloads == 6 and releases == 7,
    "character reset did not restore bindings and reload")
assert(ApogeePartyHealthSV == accountRoot and ApogeePartyHealthSV.legacy
        and ApogeePartyHealthCharSV.profileStore.schemaVersion == 2
        and ApogeePartyHealthCharSV.old == nil,
    "character reset changed account data or retained the old character root")

print("PASS binding-safe profile controller")
