ApogeePartyHealthBars_S = { sv = {
    enabled = true, abilityCooldownsEnabled = true,
    abilityCooldownOverrides = {}, abilityCooldownPriority = {},
} }
BOOKTYPE_SPELL, BOOKTYPE_PET = "spell", "pet"
dofile("Reminders/AbilityCooldowns/CooldownData.lua")
ApogeePartyHealthBars_PlayerContext = { GetClassToken = function() return "WARRIOR" end }

local spellList = {
    { id = 6552, baseName = "Pummel", sourceBook = "spell" },
    { id = 72, baseName = "Shield Bash", sourceBook = "spell" },
    { id = 871, baseName = "Shield Wall", sourceBook = "spell" },
    { id = 355, baseName = "Taunt", sourceBook = "spell" },
    { id = 1161, baseName = "Challenging Shout", sourceBook = "spell" },
    { id = 2687, baseName = "Bloodrage", sourceBook = "spell" },
    { id = 694, baseName = "Mocking Blow", sourceBook = "spell" },
    { id = 5246, baseName = "Intimidating Shout", sourceBook = "spell" },
}
ApogeePartyHealthBars_PlayerSpells = {
    BuildKnownSpellMap = function() return {}, {}, spellList end,
    GetSpellTexture = function(identifier) return "icon-" .. tostring(identifier) end,
}
local cooldownState = {}
ApogeePartyHealthBars_ActionCooldowns = {
    GetSpellCooldown = function(identifier)
        local state = cooldownState[identifier] or {}
        return state.start or 0, state.duration or 0, state.enabled ~= false, state.gcd
    end,
    IsGlobalCooldown = function(_, _, reported) return reported == true end,
    GetSpellUsability = function(identifier)
        local state = cooldownState[identifier] or {}
        return state.usable ~= false, state.lacksResource == true
    end,
    GetSpellCharges = function(identifier)
        local info = C_Spell and C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(identifier)
        if not info then return nil end
        return info.currentCharges, info.maxCharges,
            info.cooldownStartTime, info.cooldownDuration
    end,
}
local displayed, preview
ApogeePartyHealthBars_CooldownHud = {
    Initialize = function() end,
    SetEntries = function(entries) displayed = entries end,
    SetPreviewEntries = function(entries) preview = entries end,
    Tick = function() return false end,
}
C_Spell = { GetSpellCharges = function() return nil end }
function GetTime() return 100 end

dofile("Reminders/AbilityCooldowns/CooldownTracker.lua")
local tracker = ApogeePartyHealthBars_CooldownTracker
tracker.Initialize()
assert(tracker.GetSelectedCount() == 5 and #displayed == 5
        and displayed[1].definition.key == "pummel"
        and displayed[2].definition.key == "shieldBash"
        and displayed[5].definition.key == "bloodrage"
        and #preview == 5,
    "reviewed learned Warrior defaults did not include Bloodrage in priority order")

spellList[#spellList + 1] = { id = 12975, baseName = "Last Stand", sourceBook = "spell" }
tracker.ResolveKnown()
assert(tracker.GetSelectedCount() == 6 and #displayed == 6,
    "newly learned default cooldown did not inherit catalog intent")
local changed, reason = tracker.SetEnabled("mockingBlow", true)
assert(not changed and reason:find("six", 1, true),
    "six-slot selection limit accepted a seventh cooldown")
local disabled = tracker.SetEnabled("bloodrage", false)
local optedIn = tracker.SetEnabled("mockingBlow", true)
assert(disabled and optedIn and tracker.GetSelectedCount() == 6,
    "explicit opt-out did not free a cooldown slot for an opt-in: "
        .. tostring(disabled) .. "," .. tostring(optedIn) .. ","
        .. tostring(tracker.GetSelectedCount()))
local orderedFamilies = tracker.GetKnownFamilies()
assert(orderedFamilies[6].definition.key == "mockingBlow",
    "newly enabled cooldown did not append at the lowest selected priority")
assert(tracker.Move("mockingBlow", -1)
        and #ApogeePartyHealthBars_S.sv.abilityCooldownPriority == 6,
    "selected cooldown priority did not persist")

cooldownState[6552] = { start = 95, duration = 10 }
local state = tracker.GetCooldownState({ spellId = 6552, available = true }, 100)
assert(state.cooling and not state.ready and state.start == 95 and state.duration == 10,
    "ordinary spell cooldown state changed")
cooldownState[6552] = { start = 99, duration = 1.5, gcd = true }
state = tracker.GetCooldownState({ spellId = 6552, available = true }, 100)
assert(state.ready and not state.cooling, "global cooldown entered Ability Cooldowns")
cooldownState[6552] = { usable = false }
state = tracker.GetCooldownState({ spellId = 6552, available = true }, 100)
assert(state.unavailable and not state.ready,
    "form- or pet-unavailable cooldown rendered ready")
cooldownState[6552] = { usable = false, lacksResource = true }
state = tracker.GetCooldownState({ spellId = 6552, available = true }, 100)
assert(state.ready and not state.usable and state.lacksResource and not state.unavailable,
    "resource shortage did not preserve cooldown readiness while marking the spell unusable")
cooldownState[6552] = {}

C_Spell.GetSpellCharges = function()
    return { currentCharges = 0, maxCharges = 2, cooldownStartTime = 96, cooldownDuration = 8 }
end
state = tracker.GetCooldownState({ spellId = 6552, available = true }, 100)
assert(not state.ready and state.cooling and state.charges == 0 and state.maximumCharges == 2,
    "zero-charge cooldown state changed")
C_Spell.GetSpellCharges = function()
    return { currentCharges = 1, maxCharges = 2, cooldownStartTime = 96, cooldownDuration = 8 }
end
state = tracker.GetCooldownState({ spellId = 6552, available = true }, 100)
assert(state.ready and state.cooling and state.charges == 1,
    "partial charges did not remain ready while recharging")
C_Spell.GetSpellCharges = function()
    return { currentCharges = 2, maxCharges = 2, cooldownStartTime = 0, cooldownDuration = 0 }
end
state = tracker.GetCooldownState({ spellId = 6552, available = true }, 100)
assert(state.ready and not state.cooling and state.charges == 2,
    "full charges did not render ready")
C_Spell.GetSpellCharges = function()
    return { currentCharges = nil, maxCharges = 2, cooldownStartTime = 96, cooldownDuration = 8 }
end
state = tracker.GetCooldownState({ spellId = 6552, available = true }, 100)
assert(not state.ready and state.charges == 0,
    "partial charge data caused an invalid ready state")
assert(tracker.GetCooldownState({ spellId = 19244, available = false }, 100).unavailable,
    "temporarily missing pet spell did not retain an unavailable state")

print("PASS reviewed Ability Cooldowns policy and state")
