ApogeePartyHealthBars_C = {
    PROFILE_STORE_VERSION = 1,
    PROFILE_PAYLOAD_VERSION = 2,
    SAVED_VARIABLES_VERSION = 5,
}
ApogeePartyHealthBars_S = {}
ApogeePartyHealthBars_Effects = {
    InitializeSavedVariables = function(settings, actions)
        local version = tonumber(settings.schemaVersion) or 0
        if version < 1 then
            if settings.partyBuffEnabled == nil then settings.partyBuffEnabled = settings.fortEnabled end
            if settings.selfBuffEnabled == nil then settings.selfBuffEnabled = settings.innerFireEnabled end
            actions.bindings = type(actions.bindings) == "table" and actions.bindings or {}
            if next(actions.bindings) == nil and type(settings.bindings) == "table" then
                for key, value in pairs(settings.bindings) do actions.bindings[key] = value end
            end
        end
        if version < 3 and settings.lowHealthSoundEnabled == false then
            settings.lowHealthSoundKey = "none"
        end
        if settings.enabled == nil then settings.enabled = true end
        if settings.showAllSlots == nil then settings.showAllSlots = true end
        if settings.combatUIAutoHide == nil then settings.combatUIAutoHide = true end
        settings.schemaVersion = 5
        actions.bindings = type(actions.bindings) == "table" and actions.bindings or {}
        actions.shortcuts = type(actions.shortcuts) == "table" and actions.shortcuts or {}
        actions.selfBuffSelections = type(actions.selfBuffSelections) == "table" and actions.selfBuffSelections or {}
        actions.wheelMacros = type(actions.wheelMacros) == "table" and actions.wheelMacros or {}
        actions.keyActions = type(actions.keyActions) == "table" and actions.keyActions or {}
    end,
}
local clock = 100
function time() clock = clock + 1; return clock end

dofile("ApogeePartyHealthBars_ProfileStore.lua")
local store = ApogeePartyHealthBars_ProfileStore

local account = { schemaVersion = 5, enabled = false, x = 42, minimapAngle = 133 }
local character = {
    bindings = { ["1"] = { kind = "spell", spellName = "Flash Heal" } },
    shortcuts = { { kind = "spell", spellName = "Renew" } },
    keyActions = {
        enabled = true,
        ownership = { ["2"] = { keyQ = { previousAction = "MOVEFORWARD" } } },
        bindingVersion = 1,
        profiles = { ["1"] = { layouts = { base = { slots = {} } } } },
    },
    wheelMacros = { enabled = false, ownership = {} },
}
local active = store.Initialize(account, character, "PRIEST", "Healer - Realm")
assert(active.name == "Healer - Realm" and active.classToken == "PRIEST",
    "legacy character did not receive a class profile")
assert(active.payload.settings.enabled == false and active.payload.settings.x == 42
    and active.payload.settings.minimapAngle == 133,
    "legacy account settings were not migrated into the profile")
assert(active.payload.actions.bindings["1"].spellName == "Flash Heal"
    and active.payload.actions.shortcuts[1].spellName == "Renew",
    "legacy character actions were not migrated")
assert(active.payload.actions.keyActions.enabled == nil
    and active.payload.actions.keyActions.ownership == nil
    and active.payload.actions.keyActions.bindingVersion == nil,
    "obsolete binding intent or runtime ownership leaked into the profile")
local migratedRuntime = store.GetBindingRuntime("keyActions")
assert(migratedRuntime.bindingVersion == 1
    and migratedRuntime.ownership["2"].keyQ.previousAction == "MOVEFORWARD",
    "legacy binding recovery state was not moved to character-local storage")
assert(account.enabled == nil and character.bindings == nil
    and account.profileStore and character.activeProfileId == active.id,
    "legacy roots were not converted to profile storage")

local created = assert(store.Create("Clean"))
assert(created.payload.settings.enabled and #created.payload.actions.shortcuts == 0,
    "new profile did not start from defaults")
local duplicate = assert(store.Duplicate(active.id, "Copy"))
duplicate.payload.settings.x = 999
assert(active.payload.settings.x == 42, "duplicated profile retained aliased settings")
assert(not store.Create(" copy "), "profile names were not unique case-insensitively")
assert(not store.Create(string.rep("x", 41)), "oversized profile name was accepted")
assert(store.Rename(duplicate.id, "Raid"), "profile rename failed")
assert(not store.Rename(created.id, "raid"), "rename allowed a duplicate name")
assert(not store.Delete(active.id), "active profile deletion was allowed")
assert(store.Delete(created.id), "inactive profile deletion failed")

local imported = {
    profileName = "Shared",
    classToken = "PRIEST",
    author = "Author - Realm",
    payload = { settings = { showAllSlots = true }, actions = { shortcuts = {
        { kind = "spell", spellName = "Prayer of Healing" },
    } } },
}
local shared = assert(store.AddImported(imported))
assert(shared.author == "Author - Realm" and shared.payload.settings.showAllSlots,
    "imported metadata or payload was not preserved")
assert(not store.AddImported({ profileName = "Wrong", classToken = "MAGE", payload = {} }),
    "wrong-class profile was imported")
assert(store.MergeImported(active.id, imported), "profile merge failed")
assert(active.payload.settings.x == 42 and active.payload.settings.showAllSlots
    and active.payload.actions.shortcuts[1].spellName == "Prayer of Healing",
    "profile merge did not preserve absent values or replace ordered actions")
assert(store.ReplaceImported(active.id, imported), "profile replace failed")
assert(active.author == "Author - Realm" and active.payload.settings.x == nil,
    "profile replace retained old portable values or lost imported author")

active.payload.actions.keyActions.ownership = { bad = true }
active.payload.actions.keyActions.enabled = true
local exported = store.Exportable(active.id)
assert(exported.payload.actions.keyActions.ownership == nil
    and exported.payload.actions.keyActions.enabled == nil,
    "exportable profile leaked binding ownership or activation intent")

local secondCharacter = { shortcuts = { { kind = "spell", spellName = "Smite" } } }
local second = store.Initialize(account, secondCharacter, "PRIEST", "Alt - Realm")
assert(second.name == "Alt - Realm" and second.payload.settings.x == 42
    and second.payload.actions.shortcuts[1].spellName == "Smite",
    "later legacy character did not migrate from the retained account template")
assert(#store.List() >= 2, "same-class account profile library was not shared")

local oldAccount = {
    schemaVersion = 0,
    fortEnabled = false,
    innerFireEnabled = false,
    lowHealthSoundEnabled = false,
    bindings = { ["1"] = { kind = "spell", spellName = "Legacy Heal" } },
}
local oldProfile = store.Initialize(oldAccount, { bindings = {} }, "PRIEST", "Legacy - Realm")
assert(oldProfile.payload.settings.partyBuffEnabled == false
    and oldProfile.payload.settings.selfBuffEnabled == false
    and oldProfile.payload.settings.lowHealthSoundKey == "none"
    and oldProfile.payload.actions.bindings["1"].spellName == "Legacy Heal",
    "pre-profile saved-variable migrations were bypassed or lost")

oldAccount.profileStore.nextId = 1
local collisionSafe = assert(store.Create("Collision Safe"))
assert(collisionSafe.id ~= "p1" and oldAccount.profileStore.profiles[oldProfile.id] == oldProfile,
    "corrupt next-profile ID overwrote an existing profile")

oldAccount.profileStore.nextId = 0 / 0
local nonFiniteId = assert(store.Create("Finite ID"))
assert(nonFiniteId.id:match("^p%d+$"), "non-finite next-profile ID was not repaired")

local sanitized = store.NormalizePayload({ settings = {
    minimapAngle = 0 / 0,
    x = math.huge,
    y = 24,
}, actions = {} })
assert(sanitized.settings.minimapAngle == nil,
    "non-finite minimap position survived profile normalization")
assert(sanitized.settings.x == nil and sanitized.settings.y == 24,
    "profile numeric normalization did not reject only non-finite values")

local futureAccount = { profileStore = { schemaVersion = 2, profiles = {}, order = {}, nextId = 1 } }
local ok = pcall(store.Initialize, futureAccount, {}, "PRIEST", "Future - Realm")
assert(not ok and futureAccount.profileStore.schemaVersion == 2,
    "future profile-store schema was silently downgraded")

local futurePayload = { schemaVersion = 3, settings = {}, actions = {} }
assert(not pcall(store.NormalizePayload, futurePayload),
    "future profile payload schema was silently downgraded")

local futureCharacter = { profileStateVersion = 2, activeProfileId = "p1" }
local untouchedAccount = { enabled = false }
ok = pcall(store.Initialize, untouchedAccount, futureCharacter, "PRIEST", "Future - Realm")
assert(not ok and futureCharacter.profileStateVersion == 2 and untouchedAccount.profileStore == nil
        and untouchedAccount.enabled == false,
    "future character profile state mutated saved data before it was rejected")

print("PASS named profile store and legacy migration")
