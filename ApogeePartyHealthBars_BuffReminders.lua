local C = ApogeePartyHealthBars_C
local API = ApogeePartyHealthBars_UnitAPI

ApogeePartyHealthBars_BuffReminders = {}
local B = ApogeePartyHealthBars_BuffReminders
local D

local partyBuffSpellKnown = false
local partyBuffCastSpellName
local partyBuffIconTexture
local partyBuffAuraIds
local partyBuffAuraNames

local selfBuffSpellKnown = false
local selfBuffCastSpellName
local selfBuffIconTexture
local selfBuffAuraIds
local selfBuffAuraNames
local selfBuffFamilyKey
local selfBuffPreferenceKey
local selfBuffPreferenceOptions = {}

function B.Initialize(deps)
    for _, key in ipairs({
        "Auras", "Effects", "IsSavedFeatureEnabled", "IsConfigMode",
        "GetCharacterSavedVariables", "ApplyAllSelfBuffBindings", "RequestLayoutUpdate",
        "GetSurfaces", "SetSelfBuffIconTexture",
    }) do
        assert(deps[key] ~= nil, "BuffReminders missing dependency: " .. key)
    end
    D = deps
end

local function ApplyPartyBuffIconTexture(texture)
    if not texture then return end
    for _, surface in ipairs(D.GetSurfaces()) do
        if surface.partyBuffIcon then surface.partyBuffIcon:SetTexture(texture) end
    end
end

local function InitPartyBuffSpell()
    partyBuffSpellKnown = false
    partyBuffCastSpellName = nil
    partyBuffIconTexture = C.PARTY_BUFF_ICON_TEXTURE
    partyBuffAuraIds = nil
    partyBuffAuraNames = nil

    local selection = D.Effects.ResolveFirstKnown(
        C.PARTY_BUFF_DEFINITIONS,
        C.PARTY_BUFF_ICON_TEXTURE
    )
    partyBuffSpellKnown = selection.known
    partyBuffCastSpellName = selection.spellName
    partyBuffIconTexture = selection.icon
    partyBuffAuraIds = selection.auraIds
    partyBuffAuraNames = selection.auraNames
    ApplyPartyBuffIconTexture(partyBuffIconTexture)
end

local function InitSelfBuffSpell()
    selfBuffSpellKnown = false
    selfBuffCastSpellName = nil
    selfBuffIconTexture = C.SELF_BUFF_ICON_TEXTURE
    selfBuffAuraIds = nil
    selfBuffAuraNames = nil
    selfBuffFamilyKey = nil
    selfBuffPreferenceKey = nil
    selfBuffPreferenceOptions = {}

    local _, classToken = UnitClass("player")
    local activeFamily
    for _, family in ipairs(C.SELF_BUFF_FAMILIES or {}) do
        if family.classToken == classToken then
            activeFamily = family
            break
        end
    end

    if activeFamily then
        local knownOptions = {}
        D.Effects.ForEachDefinition(activeFamily.spells, function(def, known, spellName)
            if known then
                knownOptions[#knownOptions + 1] = {
                    key = def.canonical,
                    label = def.canonical,
                    spellName = spellName,
                    definition = def,
                }
            end
        end)

        if #knownOptions > 0 then
            local charSv = D.GetCharacterSavedVariables()
            local savedSelections = charSv and charSv.selfBuffSelections or {}
            local preferenceKey = savedSelections[activeFamily.key] or "any"
            local selected
            for _, option in ipairs(knownOptions) do
                if option.key == preferenceKey then selected = option; break end
            end
            if not selected then preferenceKey = "any" end

            local castOption = selected or knownOptions[1]
            local auraIds, auraNames = {}, {}
            if selected then
                for spellId in pairs(selected.definition.auraIds or {}) do auraIds[spellId] = true end
                for name in pairs(selected.definition.auraNames or {}) do auraNames[name] = true end
            else
                for _, def in ipairs(activeFamily.spells) do
                    for spellId in pairs(def.auraIds or {}) do auraIds[spellId] = true end
                    for name in pairs(def.auraNames or {}) do auraNames[name] = true end
                end
            end

            selfBuffSpellKnown = true
            selfBuffCastSpellName = castOption.spellName
            selfBuffIconTexture = castOption.definition.icon or C.SELF_BUFF_ICON_TEXTURE
            selfBuffAuraIds = auraIds
            selfBuffAuraNames = auraNames
            selfBuffFamilyKey = activeFamily.key
            selfBuffPreferenceKey = preferenceKey
            selfBuffPreferenceOptions[1] = { key = "any", label = activeFamily.anyLabel }
            for _, option in ipairs(knownOptions) do
                selfBuffPreferenceOptions[#selfBuffPreferenceOptions + 1] = {
                    key = option.key,
                    label = option.label,
                }
            end
        end
    end

    if not selfBuffSpellKnown then
        D.Effects.ForEachDefinition(C.SELF_BUFF_SPELL_DEFINITIONS, function(def, known, spellName)
            if selfBuffSpellKnown then return end
            if known then
                selfBuffSpellKnown = true
                selfBuffCastSpellName = spellName
                selfBuffIconTexture = def.icon or C.SELF_BUFF_ICON_TEXTURE
                selfBuffAuraIds = def.auraIds
                selfBuffAuraNames = def.auraNames
            end
        end)
    end

    D.SetSelfBuffIconTexture(selfBuffIconTexture)
end

local function ConfigureAuraMatchers()
    D.Auras.ConfigureBuffMatchers(
        partyBuffAuraIds,
        partyBuffAuraNames,
        selfBuffAuraIds,
        selfBuffAuraNames
    )
end

function B.RefreshKnownSpells()
    InitPartyBuffSpell()
    InitSelfBuffSpell()
    ConfigureAuraMatchers()
end

function B.GetSelfPreferenceOptions()
    return selfBuffPreferenceOptions
end

function B.GetSelfPreferenceKey()
    return selfBuffPreferenceKey
end

function B.SetSelfPreference(preferenceKey)
    local charSv = D.GetCharacterSavedVariables()
    if not selfBuffFamilyKey or not charSv then return false end
    local valid = false
    for _, option in ipairs(selfBuffPreferenceOptions) do
        if option.key == preferenceKey then valid = true; break end
    end
    if not valid then return false end

    charSv.selfBuffSelections = charSv.selfBuffSelections or {}
    charSv.selfBuffSelections[selfBuffFamilyKey] = preferenceKey
    InitSelfBuffSpell()
    ConfigureAuraMatchers()
    D.ApplyAllSelfBuffBindings()
    D.RequestLayoutUpdate()
    return true
end

function B.IsPartyKnown() return partyBuffSpellKnown end
function B.IsSelfKnown() return selfBuffSpellKnown end
function B.HasKnownReminder() return partyBuffSpellKnown or selfBuffSpellKnown end
function B.GetPartyCastSpellName() return partyBuffCastSpellName end
function B.GetSelfCastSpellName() return selfBuffCastSpellName end

local function IsPartyEnabled()
    return partyBuffSpellKnown and D.IsSavedFeatureEnabled("partyBuffEnabled")
end

local function HasPartyBuff(unitId)
    if not partyBuffAuraIds or not partyBuffAuraNames then return true end
    if not UnitExists(unitId) then return true end
    return D.Auras.SnapshotHasAura(
        D.Auras.GetUnitAuraSnapshot(unitId),
        partyBuffAuraIds,
        partyBuffAuraNames
    )
end

function B.CanHealUnit(unitId)
    return API.CanHeal(unitId)
end

function B.IsOppositeFactionPlayer(unitId)
    return API.IsOppositeFactionPlayer(unitId)
end

local function CanPartyBuffUnit(unitId)
    if not API.Exists(unitId) or API.IsDead(unitId) then return false end
    if not UnitIsPlayer or not UnitIsPlayer(unitId) then return false end
    return B.CanHealUnit(unitId)
end

local function ShouldShowIcons()
    if InCombatLockdown() then return nil end
    return true
end

function B.ShouldShowPartyIcon(unitId)
    if ShouldShowIcons() == nil then return nil end
    if not IsPartyEnabled() or D.IsConfigMode() then return false end
    if not CanPartyBuffUnit(unitId) then return false end
    return not HasPartyBuff(unitId)
end

local function IsSelfEnabled()
    return selfBuffSpellKnown and D.IsSavedFeatureEnabled("selfBuffEnabled")
end

local function HasSelfBuff(unitId)
    if not UnitExists(unitId) then return true end
    return D.Auras.SnapshotHasAura(
        D.Auras.GetUnitAuraSnapshot(unitId),
        selfBuffAuraIds,
        selfBuffAuraNames
    )
end

function B.ShouldShowSelfIcon(unitId)
    if ShouldShowIcons() == nil then return nil end
    if unitId ~= "player" then return false end
    if not IsSelfEnabled() or D.IsConfigMode() then return false end
    if not UnitExists(unitId) or UnitIsDeadOrGhost(unitId) then return false end
    return not HasSelfBuff(unitId)
end
