local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local A = ApogeePartyHealthBars_Auras
local E = ApogeePartyHealthBars_Effects

ApogeePartyHealthBars_EffectsTracker = {}
local X = ApogeePartyHealthBars_EffectsTracker
local D

local function ApplyPartyBuffIconTexture(texture)
    if not texture then return end
    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if row and row.partyBuffIcon then
            row.partyBuffIcon:SetTexture(texture)
        end
        if row and row.targetPartyBuffIcon then
            row.targetPartyBuffIcon:SetTexture(texture)
        end
    end
end

local function InitPartyBuffSpell()
    S.partyBuffSpellKnown = false
    S.partyBuffCastSpellName = nil
    S.partyBuffIconTexture = C.PARTY_BUFF_ICON_TEXTURE
    S.partyBuffAuraIds = nil
    S.partyBuffAuraNames = nil

    local selection = E.ResolveFirstKnown(
        C.PARTY_BUFF_DEFINITIONS,
        C.PARTY_BUFF_ICON_TEXTURE
    )
    S.partyBuffSpellKnown = selection.known
    S.partyBuffCastSpellName = selection.spellName
    S.partyBuffIconTexture = selection.icon
    S.partyBuffAuraIds = selection.auraIds
    S.partyBuffAuraNames = selection.auraNames
    ApplyPartyBuffIconTexture(S.partyBuffIconTexture)
end

local function InitSelfBuffSpell()
    S.selfBuffSpellKnown = false
    S.selfBuffCastSpellName = nil
    S.selfBuffIconTexture = C.SELF_BUFF_ICON_TEXTURE
    S.selfBuffAuraIds = nil
    S.selfBuffAuraNames = nil
    S.selfBuffFamilyKey = nil
    S.selfBuffFamilyLabel = nil
    S.selfBuffPreferenceKey = nil
    wipe(S.selfBuffPreferenceOptions)

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
        E.ForEachDefinition(activeFamily.spells, function(def, known, spellName)
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
            local savedSelections = S.charSv and S.charSv.selfBuffSelections or {}
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

            S.selfBuffSpellKnown = true
            S.selfBuffCastSpellName = castOption.spellName
            S.selfBuffIconTexture = castOption.definition.icon or C.SELF_BUFF_ICON_TEXTURE
            S.selfBuffAuraIds = auraIds
            S.selfBuffAuraNames = auraNames
            S.selfBuffFamilyKey = activeFamily.key
            S.selfBuffFamilyLabel = activeFamily.label
            S.selfBuffPreferenceKey = preferenceKey
            S.selfBuffPreferenceOptions[1] = { key = "any", label = activeFamily.anyLabel }
            for _, option in ipairs(knownOptions) do
                S.selfBuffPreferenceOptions[#S.selfBuffPreferenceOptions + 1] = {
                    key = option.key,
                    label = option.label,
                }
            end
        end
    end

    if not S.selfBuffSpellKnown then
        E.ForEachDefinition(C.SELF_BUFF_SPELL_DEFINITIONS, function(def, known, spellName)
            if S.selfBuffSpellKnown then return end
            if known then
                S.selfBuffSpellKnown = true
                S.selfBuffCastSpellName = spellName
                S.selfBuffIconTexture = def.icon or C.SELF_BUFF_ICON_TEXTURE
                S.selfBuffAuraIds = def.auraIds
                S.selfBuffAuraNames = def.auraNames
            end
        end)
    end

    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if row and row.selfBuffIcon then
            row.selfBuffIcon:SetTexture(S.selfBuffIconTexture)
        end
    end
end

local function GetSelfBuffPreferenceOptions()
    return S.selfBuffPreferenceOptions
end

local function GetSelfBuffPreferenceKey()
    return S.selfBuffPreferenceKey
end

local function SetSelfBuffPreference(preferenceKey)
    if not S.selfBuffFamilyKey or not S.charSv then return false end
    local valid = false
    for _, option in ipairs(S.selfBuffPreferenceOptions) do
        if option.key == preferenceKey then valid = true; break end
    end
    if not valid then return false end

    S.charSv.selfBuffSelections = S.charSv.selfBuffSelections or {}
    S.charSv.selfBuffSelections[S.selfBuffFamilyKey] = preferenceKey
    InitSelfBuffSpell()
    D.ApplyAllSelfBuffBindings()
    S.RequestLayoutUpdate()
    return true
end

local InitHotSpells

local function InitPlayerSpells()
    InitPartyBuffSpell()
    InitSelfBuffSpell()
    InitHotSpells()
    if S.configMode then
        D.RefreshConfigPanel()
    end
end

local function IsPartyBuffEnabled()
    return S.partyBuffSpellKnown and D.IsSavedFeatureEnabled("partyBuffEnabled")
end

local function HasAnyPartyBuffAura(unitId)
    if not UnitExists(unitId) then return true end
    return A.SnapshotHasAura(
        A.GetUnitAuraSnapshot(unitId),
        S.partyBuffAuraIds,
        S.partyBuffAuraNames
    )
end

local function HasPartyBuff(unitId)
    if not S.partyBuffAuraIds or not S.partyBuffAuraNames then return true end
    return HasAnyPartyBuffAura(unitId)
end

local function CanPlayerHealUnit(unitId)
    if not UnitExists(unitId) or UnitIsDeadOrGhost(unitId) then return false end
    if UnitIsConnected and not UnitIsConnected(unitId) then return false end
    if UnitCanAssist and not UnitCanAssist("player", unitId) then return false end
    if UnitIsEnemy and UnitIsEnemy("player", unitId) then return false end
    return true
end

local function IsOppositeFactionPlayer(unitId)
    if not UnitExists(unitId) or not UnitIsPlayer(unitId) then return false end
    local myFaction = UnitFactionGroup("player")
    local theirFaction = UnitFactionGroup(unitId)
    if not myFaction or not theirFaction then return false end
    return myFaction ~= theirFaction
end

local function CanPartyBuffUnit(unitId)
    if not UnitExists(unitId) or UnitIsDeadOrGhost(unitId) then return false end
    if not UnitIsPlayer(unitId) then return false end
    return CanPlayerHealUnit(unitId)
end

local function ShouldShowBuffIcons()
    return not InCombatLockdown()
end

local function ShouldShowPartyBuffIcon(unitId)
    if not ShouldShowBuffIcons() then return false end
    if not IsPartyBuffEnabled() or S.configMode then return false end
    if not CanPartyBuffUnit(unitId) then return false end
    return not HasPartyBuff(unitId)
end


-- =============================================================================
-- Self-buff reminder (player row only, enabled when known)
-- =============================================================================

local function IsSelfBuffEnabled()
    return S.selfBuffSpellKnown and D.IsSavedFeatureEnabled("selfBuffEnabled")
end

local function HasSelfBuff(unitId)
    if not UnitExists(unitId) then return true end
    return A.GetUnitAuraSnapshot(unitId).selfBuff
end

local function ShouldShowSelfBuffIcon(unitId)
    if not ShouldShowBuffIcons() then return false end
    if unitId ~= "player" then return false end
    if not IsSelfBuffEnabled() or S.configMode then return false end
    if not UnitExists(unitId) or UnitIsDeadOrGhost(unitId) then return false end
    return not HasSelfBuff(unitId)
end


-- =============================================================================
-- HoT duration bars (player-cast Renew / Rejuv / Regrowth / Lifebloom)
-- =============================================================================
--
-- HoT invariants: activeHotTracks rebuilt only in InitHotSpells; player-cast via sourceUnit.

local function IsHotEnabled()
    return D.IsSavedFeatureEnabled("hotEnabled")
end

local function GetHotStripHeight()
    if not IsHotEnabled() then return 0 end
    local n = S.activeHotTracks and #S.activeHotTracks or 0
    if n <= 0 then return 0 end
    return C.HOT_AREA_GAP + n * C.HOT_H + (n - 1) * C.HOT_GAP
end

local function ScanUnitPlayerHots(unitId)
    return A.GetUnitAuraSnapshot(unitId).playerHots
end

InitHotSpells = function()
    wipe(S.activeHotTracks)
    wipe(S.hotSpellKnown)

    local disabled = S.sv and S.sv.hotDisabled
    E.ForEachDefinition(C.HOT_SPELL_DEFINITIONS, function(def, known)
        S.hotSpellKnown[def.key] = known
        if not IsHotEnabled() then return end
        if known and not (disabled and disabled[def.key]) then
            S.activeHotTracks[#S.activeHotTracks + 1] = {
                key       = def.key,
                canonical = def.canonical,
                auraNames = def.auraNames,
                auraIds   = def.auraIds,
                barColor  = def.barColor,
            }
        end
    end)

    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if row and row.hotMeta then wipe(row.hotMeta) end
    end
    D.SyncVisualTicker()
end

local function WipeRowHotMeta(row)
    if row.hotMeta then wipe(row.hotMeta) end
end

local function HasActiveHotVisuals()
    if not IsHotEnabled() or not D.IsSavedFeatureEnabled("enabled") then return false end
    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if row and row.btn and row.btn:IsShown() and row.hotMeta then
            for j = 1, C.MAX_HOT_SLOTS do
                if row.hotMeta[j] then return true end
            end
        end
    end
    return false
end

local function TickRowHotVisuals(row)
    if not row.hotMeta then return end
    for i = 1, C.MAX_HOT_SLOTS do
        local meta = row.hotMeta[i]
        local hotBar = row.hotBars and row.hotBars[i]
        if meta and hotBar and hotBar:IsShown() then
            local remaining = math.max(0, meta.expirationTime - GetTime())
            hotBar:SetValue(remaining)
            if remaining <= 0 then
                row.hotMeta[i] = nil
                hotBar:Hide()
            end
        end
    end
end

local function TickHotVisuals()
    if not D.IsSavedFeatureEnabled("enabled") then return end
    if IsHotEnabled() then
        for i = 1, C.MAX_ROWS do
            local row = D.rows[i]
            if row and row.btn:IsShown() then
                TickRowHotVisuals(row)
            end
        end
    end
end

local function HideRowHotVisuals(row)
    if not row.hotBg then return end
    WipeRowHotMeta(row)
    for i = 1, C.MAX_HOT_SLOTS do
        if row.hotBg[i] then row.hotBg[i]:Hide() end
        if row.hotBars[i] then row.hotBars[i]:Hide() end
    end
    D.SyncVisualTicker()
end

local function UpdateRowHotVisuals(row, unitId)
    if not row.hotBg then return end

    if not IsHotEnabled() or not unitId or not UnitExists(unitId) then
        HideRowHotVisuals(row)
        return
    end

    local tracks = S.activeHotTracks
    if not tracks or #tracks == 0 then
        HideRowHotVisuals(row)
        return
    end

    row.hotMeta = row.hotMeta or {}

    local hots = ScanUnitPlayerHots(unitId)
    for i = 1, #tracks do
        local bg = row.hotBg[i]
        local hotBar = row.hotBars[i]
        if bg and hotBar then
            local aura = hots[i]
            local duration = aura and aura.duration
            local expirationTime = aura and aura.expirationTime
            if aura and duration and duration > 0
                and expirationTime and expirationTime > 0 then
                local remaining = math.max(0, expirationTime - GetTime())
                hotBar:SetMinMaxValues(0, duration)
                hotBar:SetValue(remaining)
                hotBar:SetStatusBarColor(unpack(tracks[i].barColor))
                row.hotMeta[i] = { expirationTime = expirationTime, duration = duration }
                bg:Show()
                hotBar:Show()
            else
                row.hotMeta[i] = nil
                bg:Show()
                hotBar:Hide()
            end
        end
    end

    for i = #tracks + 1, C.MAX_HOT_SLOTS do
        row.hotMeta[i] = nil
        if row.hotBg[i] then row.hotBg[i]:Hide() end
        if row.hotBars[i] then row.hotBars[i]:Hide() end
    end

    D.SyncVisualTicker()
end


-- =============================================================================
-- Utilities

function X.Initialize(deps)
    for _, key in ipairs({
        "rows", "SyncVisualTicker", "IsSavedFeatureEnabled", "GetUnitTargetToken",
        "ApplyAllPartyBuffBindings", "ApplyAllSelfBuffBindings", "RefreshConfigPanel",
        "SyncCastOverlays", "LayoutRows", "UpdateRowValues",
    }) do
        assert(deps[key] ~= nil, "EffectsTracker missing dependency: " .. key)
    end
    D = deps
end
X.InitPlayerSpells = InitPlayerSpells
X.CanPlayerHealUnit = CanPlayerHealUnit
X.IsOppositeFactionPlayer = IsOppositeFactionPlayer
X.ShouldShowPartyBuffIcon = ShouldShowPartyBuffIcon
X.ShouldShowSelfBuffIcon = ShouldShowSelfBuffIcon
X.GetSelfBuffPreferenceOptions = GetSelfBuffPreferenceOptions
X.GetSelfBuffPreferenceKey = GetSelfBuffPreferenceKey
X.SetSelfBuffPreference = SetSelfBuffPreference
X.IsHotEnabled = IsHotEnabled
X.GetHotStripHeight = GetHotStripHeight
X.InitHotSpells = InitHotSpells
X.HasActiveHotVisuals = HasActiveHotVisuals
X.TickHotVisuals = TickHotVisuals
X.UpdateRowHotVisuals = UpdateRowHotVisuals
