ApogeePartyHealthBars_C = {
    PROFILE_STORE_VERSION = 2,
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
        local legacyShortcuts = type(actions.trackedSpells) == "table" and actions.trackedSpells or nil
        if type(actions.shortcuts) ~= "table"
            or (next(actions.shortcuts) == nil and legacyShortcuts and next(legacyShortcuts) ~= nil) then
            actions.shortcuts = legacyShortcuts or {}
        end
        if actions.shortcutDefaultsVersion == nil then
            actions.shortcutDefaultsVersion = actions.trackerDefaultsVersion
        end
        actions.trackedSpells = nil
        actions.trackedSpellsSchemaVersion = nil
        actions.trackerDefaultsVersion = nil
        actions.selfBuffSelections = type(actions.selfBuffSelections) == "table" and actions.selfBuffSelections or {}
        actions.wheelMacros = type(actions.wheelMacros) == "table" and actions.wheelMacros or {}
        actions.keyActions = type(actions.keyActions) == "table" and actions.keyActions or {}
        actions.mouseActions = type(actions.mouseActions) == "table" and actions.mouseActions or {}
    end,
}
local clock = 100
function time() clock = clock + 1; return clock end

dofile("ApogeePartyHealthBars_ProfileStore.lua")
local store = ApogeePartyHealthBars_ProfileStore

local account = { schemaVersion = 5, enabled = false, x = 42, minimapAngle = 133 }
local character = {
    bindings = { ["1"] = { kind = "spell", spellName = "Flash Heal" } },
    shortcuts = { {
        kind = "spell", spellName = "Renew",
        macroText = "/cast [@mouseover,help,nodead] Renew",
    } },
    keyActions = {
        enabled = true,
        ownership = { ["2"] = { keyQ = { previousAction = "MOVEFORWARD" } } },
        bindingVersion = 1,
        profiles = { ["1"] = { layouts = { base = { slots = {} } } } },
    },
    wheelMacros = { enabled = false, ownership = {} },
    mouseActions = {
        ownership = { ["2"] = { normal3 = { previousAction = "TOGGLEAUTORUN" } } },
        bindingVersion = 1,
        profiles = { ["1"] = { layouts = { base = { slots = {
            normal3 = { kind = "spell", spellName = "Smite" },
        } } } } },
    },
}
local active = store.Initialize(account, character, "PRIEST", "Healer - Realm")
assert(active.name == "Healer - Realm" and active.classToken == "PRIEST",
    "legacy character did not receive a class profile")
assert(active.payload.settings.enabled == false and active.payload.settings.x == 42
    and active.payload.settings.minimapAngle == 133,
    "legacy account settings were not migrated into the profile")
assert(active.payload.actions.bindings["1"].spellName == "Flash Heal"
    and active.payload.actions.shortcuts[1].spellName == "Renew"
    and active.payload.actions.shortcuts[1].macroText
        == "/cast [@mouseover,help,nodead] Renew",
    "legacy character actions were not migrated")
assert(active.payload.actions.keyActions.enabled == nil
    and active.payload.actions.keyActions.ownership == nil
    and active.payload.actions.keyActions.bindingVersion == nil,
    "obsolete binding intent or runtime ownership leaked into the profile")
local migratedRuntime = store.GetBindingRuntime("keyActions")
assert(migratedRuntime.bindingVersion == 1
    and migratedRuntime.ownership["2"].keyQ.previousAction == "MOVEFORWARD",
    "legacy binding recovery state was not moved to character-local storage")
local migratedMouseRuntime = store.GetBindingRuntime("mouseActions")
assert(active.payload.actions.mouseActions.profiles["1"].layouts.base.slots.normal3.spellName == "Smite"
        and migratedMouseRuntime.ownership["2"].normal3.previousAction == "TOGGLEAUTORUN",
    "Buttons profile actions or binding recovery state were not migrated correctly")
assert(account.enabled == false and account.profileStore == nil and character.bindings == nil
    and character.profileStore and character.profileStore.activeProfileId == active.id,
    "legacy roots were not converted to character-owned profile storage")

local created = assert(store.Create("Clean"))
assert(created.payload.settings.enabled and #created.payload.actions.shortcuts == 0,
    "new profile did not start from defaults")
local duplicate = assert(store.Duplicate(active.id, "Copy"))
duplicate.payload.settings.x = 999
assert(duplicate.payload.actions.shortcuts[1].macroText
        == "/cast [@mouseover,help,nodead] Renew",
    "profile duplication changed custom macro text")
duplicate.payload.actions.shortcuts[1].macroText = "/cast Duplicate Renew"
assert(active.payload.settings.x == 42
        and active.payload.actions.shortcuts[1].macroText
            == "/cast [@mouseover,help,nodead] Renew",
    "duplicated profile retained aliased settings or macro data")
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
        {
            kind = "spell", spellName = "Prayer of Healing",
            macroText = "/cast [mod:shift] Prayer of Healing",
        },
    } } },
}
local shared = assert(store.AddImported(imported))
assert(shared.author == "Author - Realm" and shared.payload.settings.showAllSlots
        and shared.payload.actions.shortcuts[1].macroText
            == "/cast [mod:shift] Prayer of Healing",
    "imported metadata or payload was not preserved")
assert(not store.AddImported({ profileName = "Wrong", classToken = "MAGE", payload = {} }),
    "wrong-class profile was imported")
assert(store.MergeImported(active.id, imported), "profile merge failed")
assert(active.payload.settings.x == 42 and active.payload.settings.showAllSlots
    and active.payload.actions.shortcuts[1].spellName == "Prayer of Healing"
    and active.payload.actions.shortcuts[1].macroText
        == "/cast [mod:shift] Prayer of Healing",
    "profile merge did not preserve absent values or replace ordered actions")
assert(store.ReplaceImported(active.id, imported), "profile replace failed")
assert(active.author == "Author - Realm" and active.payload.settings.x == nil
        and active.payload.actions.shortcuts[1].macroText
            == "/cast [mod:shift] Prayer of Healing",
    "profile replace retained old portable values or lost imported author")

active.payload.actions.keyActions.ownership = { bad = true }
active.payload.actions.keyActions.enabled = true
active.payload.actions.mouseActions.ownership = { bad = true }
active.payload.actions.mouseActions.bindingVersion = 1
local exported = store.Exportable(active.id)
assert(exported.payload.actions.keyActions.ownership == nil
    and exported.payload.actions.keyActions.enabled == nil,
    "exportable profile leaked binding ownership or activation intent")
assert(exported.payload.actions.mouseActions.ownership == nil
        and exported.payload.actions.mouseActions.bindingVersion == nil,
    "exportable profile leaked Buttons binding ownership")
assert(exported.payload.actions.shortcuts[1].macroText
        == "/cast [mod:shift] Prayer of Healing",
    "profile export changed custom macro text")

local secondCharacter = { shortcuts = { { kind = "spell", spellName = "Smite" } } }
local second = store.Initialize(account, secondCharacter, "PRIEST", "Alt - Realm")
assert(second.name == "Alt - Realm" and second.payload.settings.x == 42
    and second.payload.actions.shortcuts[1].spellName == "Smite",
    "later legacy character did not migrate its private data")
assert(#store.List() == 1 and secondCharacter.profileStore.profiles[second.id] == second,
    "later character did not receive an isolated profile library")
second.payload.settings.x = 777
assert(active.payload.settings.x ~= 777,
    "separate characters retained aliased profile payloads")

local cleanCharacter = {}
local cleanProfile = store.Initialize(nil, cleanCharacter, "WARRIOR", "Fresh - Realm")
assert(cleanProfile.name == "Default" and cleanCharacter.profileStore.activeProfileId == cleanProfile.id,
    "fresh character did not receive a clean Default profile")

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
    and oldProfile.payload.actions.bindings["1"] == nil,
    "pre-profile migration copied unsafe account-wide actions")
assert(oldAccount.bindings["1"].spellName == "Legacy Heal" and oldAccount.profileStore == nil,
    "pre-profile account data was mutated during migration")

local oldCharacter = ApogeePartyHealthBars_S.characterRoot
oldCharacter.profileStore.nextId = 1
local collisionSafe = assert(store.Create("Collision Safe"))
assert(collisionSafe.id ~= "p1" and oldCharacter.profileStore.profiles[oldProfile.id] == oldProfile,
    "corrupt next-profile ID overwrote an existing profile")

oldCharacter.profileStore.nextId = 0 / 0
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

local legacyAccount = { schemaVersion = 1, profileStore = {
    schemaVersion = 1,
    nextId = 4,
    legacySettingsTemplate = { x = 55, showAllSlots = false, hotDisabled = { [139] = true } },
    order = { "p1", "p2", "p3" },
    profiles = {
        p1 = {
            id = "p1", name = "Default", classToken = "UNKNOWN",
            author = "Meds - Dreamscythe", createdAt = 10, modifiedAt = 11,
            payload = {
                settings = { x = 88, showAllSlots = false, hotDisabled = { [139] = true } },
                actions = { bindings = {
                    ["1"] = { kind = "spell", spellName = "Flash Heal" },
                } },
            },
        },
        p2 = {
            id = "p2", name = "Arms", classToken = "WARRIOR",
            author = "Bold - Dreamscythe",
            payload = { settings = { x = 22 }, actions = { shortcuts = {
                { kind = "spell", spellName = "Charge" },
            } } },
        },
        p3 = {
            id = "p3", name = "Tank", classToken = "WARRIOR",
            author = "Bold - Dreamscythe",
            payload = { settings = { x = 33 }, actions = {} },
        },
    },
} }

local priestCharacter = { profileStateVersion = 1, activeProfileId = "p1" }
local priestProfile = store.Initialize(
    legacyAccount, priestCharacter, "PRIEST", "Meds - Dreamscythe")
assert(priestProfile.id == "p1" and priestProfile.classToken == "PRIEST"
        and priestProfile.payload.actions.bindings["1"].spellName == "Flash Heal",
    "owner did not retain and reclassify the complete UNKNOWN profile")
assert(#store.List() == 1 and priestCharacter.profileStateVersion == nil
        and priestCharacter.activeProfileId == nil,
    "owner migration retained obsolete state or foreign profiles")

local warriorCharacter = { profileStateVersion = 1, activeProfileId = "p1" }
local warriorProfile = store.Initialize(
    legacyAccount, warriorCharacter, "WARRIOR", "Bold - Dreamscythe")
assert(warriorProfile.id == "p1" and warriorProfile.classToken == "WARRIOR"
        and warriorProfile.payload.settings.x == 88
        and (warriorProfile.payload.settings.hotDisabled == nil
            or next(warriorProfile.payload.settings.hotDisabled) == nil)
        and next(warriorProfile.payload.actions.bindings) == nil,
    "non-owner UNKNOWN migration retained leaked actions or lost settings")
assert(#store.List() == 3 and store.Get("p2").payload.actions.shortcuts[1].spellName == "Charge"
        and store.Get("p3").name == "Tank",
    "matching-class profile library was not copied in full")
assert(legacyAccount.profileStore.profiles.p1.classToken == "UNKNOWN"
        and legacyAccount.profileStore.profiles.p1.payload.actions.bindings["1"].spellName == "Flash Heal",
    "legacy account profile library was mutated")

local secondWarriorCharacter = { profileStateVersion = 1, activeProfileId = "p2" }
local secondWarriorProfile = store.Initialize(
    legacyAccount, secondWarriorCharacter, "WARRIOR", "Bolderbear - Dreamscythe")
assert(secondWarriorProfile.id == "p2" and #store.List() == 2,
    "matching active profile or same-class library was not preserved")
secondWarriorProfile.payload.settings.x = 999
assert(warriorCharacter.profileStore.profiles.p2.payload.settings.x == 22,
    "same-class characters shared a migrated profile table")
local profileCountBeforeReload = #store.List()
store.Initialize(legacyAccount, secondWarriorCharacter, "WARRIOR", "Bolderbear - Dreamscythe")
assert(#store.List() == profileCountBeforeReload and store.GetActiveId() == "p2",
    "character migration was not idempotent")

local missingLegacyCharacter = { profileStateVersion = 1, activeProfileId = "p9" }
local missingLegacyProfile = store.Initialize(
    legacyAccount, missingLegacyCharacter, "DRUID", "Crazyelfer - Dreamscythe")
assert(missingLegacyProfile.name == "Default" and missingLegacyProfile.payload.settings.x == 55
        and (missingLegacyProfile.payload.settings.hotDisabled == nil
            or next(missingLegacyProfile.payload.settings.hotDisabled) == nil)
        and next(missingLegacyProfile.payload.actions.bindings) == nil,
    "missing legacy active profile did not recover safe settings into a clean Default")

local metadataOnlyLegacyCharacter = {
    profileStateVersion = 1,
    activeProfileId = "p9",
    trackedSpells = {},
    trackedSpellsSchemaVersion = 1,
    trackerDefaultsVersion = 1,
    keyActions = { schemaVersion = 2, profiles = {
        [2] = { layouts = { base = { slots = {} } } },
    } },
}
local metadataOnlyLegacyProfile = store.Initialize(
    legacyAccount, metadataOnlyLegacyCharacter, "PALADIN", "Muteness - Dreamscythe")
assert(metadataOnlyLegacyProfile.name == "Default"
        and next(metadataOnlyLegacyProfile.payload.actions.shortcuts) == nil
        and metadataOnlyLegacyCharacter.trackedSpells == nil
        and metadataOnlyLegacyCharacter.keyActions == nil,
    "empty legacy action metadata was mistaken for private character actions")

local lateLegacyCharacter = {
    trackedSpells = { { kind = "spell", spellName = "Moonfire" } },
    trackedSpellsSchemaVersion = 1,
    trackerDefaultsVersion = 1,
}
local lateLegacyProfile = store.Initialize(
    legacyAccount, lateLegacyCharacter, "DRUID", "Crazyelfer - Dreamscythe")
assert(lateLegacyProfile.name == "Crazyelfer - Dreamscythe"
        and lateLegacyProfile.payload.settings.x == 55
        and (lateLegacyProfile.payload.settings.hotDisabled == nil
            or next(lateLegacyProfile.payload.settings.hotDisabled) == nil)
        and lateLegacyProfile.payload.actions.shortcuts[1].spellName == "Moonfire"
        and lateLegacyProfile.payload.actions.shortcutDefaultsVersion == 1
        and lateLegacyCharacter.trackedSpells == nil
        and lateLegacyCharacter.trackerDefaultsVersion == nil,
    "late pre-profile character did not recover private actions and safe account settings")

local foreignCharacter = { profileStore = {
    schemaVersion = 2, nextId = 2, activeProfileId = "p1", order = { "p1" }, profiles = {
        p1 = { id = "p1", name = "Wrong", classToken = "MAGE", author = "Mage - Realm", payload = {} },
    },
} }
assert(not pcall(store.Initialize, {}, foreignCharacter, "WARRIOR", "Warrior - Realm"),
    "character store accepted a profile for another class")

local resetRoot = assert(store.ResetCharacter())
assert(resetRoot.profileStore.schemaVersion == 2 and #store.List() == 1
        and store.GetActiveProfile().name == "Default" and next(resetRoot.bindingRuntime) == nil,
    "character reset did not create a clean authoritative store")
local resetAgain = store.Initialize(legacyAccount, resetRoot, "WARRIOR", "Bolderbear - Dreamscythe")
assert(resetAgain.name == "Default" and #store.List() == 1,
    "character reset allowed legacy profiles to be reimported")

local futureAccount = { profileStore = { schemaVersion = 2, profiles = {}, order = {}, nextId = 1 } }
local ok = pcall(store.Initialize, futureAccount, {}, "PRIEST", "Future - Realm")
assert(not ok and futureAccount.profileStore.schemaVersion == 2,
    "future legacy account profile-store schema was silently accepted or mutated")

local futurePayload = { schemaVersion = 3, settings = {}, actions = {} }
assert(not pcall(store.NormalizePayload, futurePayload),
    "future profile payload schema was silently downgraded")

local futureCharacter = { profileStore = {
    schemaVersion = 3, activeProfileId = "p1", profiles = {}, order = {}, nextId = 1,
} }
local untouchedAccount = { enabled = false }
ok = pcall(store.Initialize, untouchedAccount, futureCharacter, "PRIEST", "Future - Realm")
assert(not ok and futureCharacter.profileStore.schemaVersion == 3 and untouchedAccount.profileStore == nil
        and untouchedAccount.enabled == false,
    "future character profile state mutated saved data before it was rejected")

print("PASS named profile store and legacy migration")
