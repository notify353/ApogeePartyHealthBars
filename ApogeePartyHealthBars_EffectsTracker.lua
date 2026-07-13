local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local A = ApogeePartyHealthBars_Auras
local E = ApogeePartyHealthBars_Effects
local T = ApogeePartyHealthBars_SpellTracker
local H = ApogeePartyHealthBars_Threat
local F = ApogeePartyHealthBars_SecureFrames

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

local function GetPlayerPowerInfo()
    local powerType, powerToken = UnitPowerType("player")
    if powerType == nil then powerType = C.MANA_POWER end
    local manaMax = UnitPowerMax("player", C.MANA_POWER) or 0
    local activeMax = UnitPowerMax("player", powerType) or 0
    return powerType, powerToken, manaMax, activeMax
end

local function PlayerHasSeparateActivePower()
    local powerType, _, manaMax, activeMax = GetPlayerPowerInfo()
    return powerType ~= C.MANA_POWER and manaMax > 0 and activeMax > 0
end

local function GetRowPowerChromeHeight(unitId)
    local stripCount = unitId == "player" and PlayerHasSeparateActivePower() and 2 or 1
    return stripCount * C.MANA_H + stripCount * C.MANA_GAP
end

local function GetRowTotalHeight(rowOrUnit)
    local unitId = type(rowOrUnit) == "table" and rowOrUnit.unitId or rowOrUnit
    local targetOfTargetHeight = unitId == "player"
        and D.IsSavedFeatureEnabled("showUnitTargets") and C.TARGET_OF_TARGET_STEP or 0
    return C.ROW_H + GetHotStripHeight() + GetRowPowerChromeHeight(unitId)
        + T.GetHeight(unitId) + targetOfTargetHeight
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
    D.visualTickerFrame:Hide()
end

local function WipeRowHotMeta(row)
    if row.hotMeta then wipe(row.hotMeta) end
end

local function HasActiveHotMeta()
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

local function SyncVisualTicker()
    local rangeActive = D.IsSavedFeatureEnabled("enabled")
        and D.IsSavedFeatureEnabled("rangeCheckEnabled")
        and not S.configMode
    if HasActiveHotMeta() or rangeActive or H.IsActive() or T.IsActive() then
        D.visualTickerFrame:Show()
    else
        D.visualTickerFrame:Hide()
    end
end

local function RefreshVisualTicker()
    if not D.IsSavedFeatureEnabled("enabled") then
        D.visualTickerFrame:Hide()
        return
    end
    if IsHotEnabled() then
        for i = 1, C.MAX_ROWS do
            local row = D.rows[i]
            if row and row.btn:IsShown() then
                TickRowHotVisuals(row)
            end
        end
    end
    T.Tick()
    SyncVisualTicker()
end

local function HideRowHotVisuals(row)
    if not row.hotBg then return end
    WipeRowHotMeta(row)
    for i = 1, C.MAX_HOT_SLOTS do
        if row.hotBg[i] then row.hotBg[i]:Hide() end
        if row.hotBars[i] then row.hotBars[i]:Hide() end
    end
    SyncVisualTicker()
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

    SyncVisualTicker()
end


-- =============================================================================
-- Shield absorb (PW:S remaining on player / party / friendly target)
-- =============================================================================
--
-- INVARIANTS — breaking these caused the stale shield-number bugs:
-- 1. S.shieldRemaining is written ONLY from combat-log apply/remove/absorb,
--    SeedShieldTrackerFromAuras, and ShieldTrackerSyncUnit (clear). NEVER from
--    UI refresh / GetUnitShieldRemaining / PopulateHealthRow.
-- 2. GetUnitShieldRemaining is read-only: tracker first, then seed fallbacks.
-- 3. Shield depletion uses SPELL_ABSORBED combat-log events. Do NOT use the
--    informational absorbed field on SPELL_DAMAGE (stale / wrong on Classic).
-- 4. UnitGetTotalAbsorbs and aura APIs may return initial shield size; they
--    must NOT overwrite an existing tracker entry during display reads.

local function IsShieldEnabled()
    return D.IsSavedFeatureEnabled("shieldEnabled")
end

local function ShouldTrackShieldUnit(unitId)
    if not unitId or not UnitExists(unitId) or UnitIsDeadOrGhost(unitId) then
        return false
    end
    if unitId == "player" then return true end
    if unitId:match("^party%d$") then return UnitExists(unitId) end
    return false
end

local function UnitHasPWShield(unitId)
    if not UnitExists(unitId) then return false end
    return A.UnitHasPWShieldFromSnapshot(A.GetUnitAuraSnapshot(unitId))
end

-- ---- Tracker writes (combat log + seed only) --------------------------------

local function ShieldTrackerClear(guid)
    if guid then S.shieldRemaining[guid] = nil end
end

local function ShieldTrackerSet(guid, amount)
    if guid and amount and amount > 0 then
        S.shieldRemaining[guid] = math.floor(amount + 0.5)
    end
end

local function ShieldTrackerReduce(guid, absorbed)
    if not guid or not S.shieldRemaining[guid] then return end
    if not absorbed or absorbed <= 0 then return end
    S.shieldRemaining[guid] = S.shieldRemaining[guid] - absorbed
    if S.shieldRemaining[guid] <= 0 then
        ShieldTrackerClear(guid)
    end
end

local function ShieldTrackerSyncUnit(unitId)
    if not unitId or not UnitExists(unitId) then return end
    local guid = UnitGUID(unitId)
    if guid and not UnitHasPWShield(unitId) then
        ShieldTrackerClear(guid)
    end
end

local function EstimatePWShieldAmount(spellId, sourceGUID)
    local rank = C.PW_SHIELD_RANKS[spellId] or C.PW_SHIELD_RANKS[25218]
    local base, coeff = rank[1], rank[2]
    local sp = 0
    if sourceGUID and sourceGUID == UnitGUID("player") then
        sp = GetSpellBonusHealing() or 0
    end
    return math.floor(base + sp * coeff + 0.5)
end

local function ParseAuraAmountFromCLEU(info)
    for i = 16, 20 do
        local v = info[i]
        if type(v) == "number" and v > 0 then return v end
    end
    return nil
end

-- SPELL_ABSORBED layout differs for swing vs spell hits; see warcraft.wiki.gg
local function ParseSpellAbsorbedEvent(info)
    local destGUID = info[8]
    if not destGUID then return nil, nil, nil end
    if type(info[12]) == "number" and type(info[13]) == "string" then
        return destGUID, info[19], info[22]
    end
    return destGUID, info[16], info[19]
end

local function OnShieldCombatLog()
    local subevent = select(2, CombatLogGetCurrentEventInfo())
    if subevent ~= "SPELL_AURA_APPLIED" and subevent ~= "SPELL_AURA_REFRESH"
        and subevent ~= "SPELL_AURA_REMOVED" and subevent ~= "SPELL_ABSORBED" then
        return
    end

    local info = { CombatLogGetCurrentEventInfo() }
    subevent = info[2]
    local destGUID = info[8]
    if not subevent or not destGUID then return end

    if subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_REFRESH" then
        local spellId, spellName = info[12], info[13]
        if not A.IsPowerWordShieldAura(spellId, spellName) then return end
        local amount = ParseAuraAmountFromCLEU(info)
        if not amount or amount <= 0 then
            amount = EstimatePWShieldAmount(spellId, info[4])
        end
        ShieldTrackerSet(destGUID, amount)
        S.RequestUpdate()

    elseif subevent == "SPELL_AURA_REMOVED" then
        local spellId, spellName = info[12], info[13]
        if not A.IsPowerWordShieldAura(spellId, spellName) then return end
        ShieldTrackerClear(destGUID)
        S.RequestUpdate()

    elseif subevent == "SPELL_ABSORBED" then
        local defGUID, absorbSpellId, amount = ParseSpellAbsorbedEvent(info)
        if not defGUID or not amount or amount <= 0 then return end
        if not A.IsPowerWordShieldAura(absorbSpellId, nil) and not S.shieldRemaining[defGUID] then
            return
        end
        ShieldTrackerReduce(defGUID, amount)
        S.RequestUpdate()
    end
end

local function SeedShieldTrackerFromAuras()
    for _, unitId in ipairs(C.SLOT_UNITS) do
        ShieldTrackerSyncUnit(unitId)
        if ShouldTrackShieldUnit(unitId) and UnitHasPWShield(unitId) then
            local guid = UnitGUID(unitId)
            if guid and not S.shieldRemaining[guid] then
                ShieldTrackerSet(guid, EstimatePWShieldAmount(25218, UnitGUID("player")))
            end
        end
    end
end

-- ---- Tracker reads (UI only — never write S.shieldRemaining) ------------------

local function GetUnitShieldRemaining(unitId)
    local snapshot = A.GetUnitAuraSnapshot(unitId)
    if not UnitExists(unitId) or not A.UnitHasPWShieldFromSnapshot(snapshot) then
        ShieldTrackerSyncUnit(unitId)
        return 0
    end

    local guid = UnitGUID(unitId)
    local tracked = guid and S.shieldRemaining[guid]
    if tracked and tracked > 0 then
        return tracked
    end

    local auraAmount = A.GetShieldPointsFromSnapshot(snapshot)
    if auraAmount and auraAmount > 0 then
        return auraAmount
    end

    return EstimatePWShieldAmount(25218, UnitGUID("player"))
end

local function UpdateRowShieldVisual(row, unitId, shield)
    if not row.shieldBar then return end

    if S.configMode or not IsShieldEnabled() or not unitId or not ShouldTrackShieldUnit(unitId) then
        row.shieldBar:Hide()
        return
    end

    shield = shield or GetUnitShieldRemaining(unitId)
    if shield <= 0 then
        row.shieldBar:Hide()
        return
    end

    local hp    = UnitHealth(unitId) or 0
    local hpMax = UnitHealthMax(unitId) or 1
    if hpMax <= 0 then hpMax = 1 end

    -- Draw the shield as a full-height segment immediately after current
    -- health: green = health, cyan = absorb, dark = genuinely missing health.
    local barMax = hpMax + shield
    local barWidth = math.max(row.bar:GetWidth() or 0, 1)
    local healthWidth = barWidth * hp / barMax
    local shieldWidth = math.max(barWidth * shield / barMax, 1)

    row.shieldBar:ClearAllPoints()
    row.shieldBar:SetPoint("TOPLEFT", row.bar, "TOPLEFT", healthWidth, 0)
    row.shieldBar:SetPoint("BOTTOMLEFT", row.bar, "BOTTOMLEFT", healthWidth, 0)
    row.shieldBar:SetWidth(shieldWidth)
    row.shieldBar:SetMinMaxValues(0, 1)
    row.shieldBar:SetValue(1)
    row.shieldBar:Show()
end

-- =============================================================================
-- Incoming heal overlay (Blizzard UnitGetIncomingHeals — direct casts only)
-- =============================================================================

local function IsIncomingHealEnabled()
    return D.IsSavedFeatureEnabled("incomingHealEnabled")
end

local function ShouldTrackIncomingHealUnit(unitId)
    if not unitId or not UnitExists(unitId) or UnitIsDeadOrGhost(unitId) then
        return false
    end
    if unitId == "player" or unitId == "target" then return true end
    if unitId:match("^party%d$") or unitId:match("^party%dtarget$") then return true end
    return false
end

local function GetUnitIncomingHealAmount(unitId)
    if not UnitGetIncomingHeals then return 0 end

    local incoming = UnitGetIncomingHeals(unitId) or 0
    if incoming > 0 then return incoming end

    -- Some Classic clients report predictions only for canonical group tokens,
    -- even when the same unit is displayed through a target alias.
    for _, groupUnit in ipairs(C.SLOT_UNITS) do
        if groupUnit ~= unitId and UnitExists(groupUnit)
            and UnitIsUnit(unitId, groupUnit) then
            return UnitGetIncomingHeals(groupUnit) or 0
        end
    end
    return 0
end

local function UpdateIncomingHealBarVisual(healPredBar, unitId, visualMax)
    if not healPredBar then return end

    if S.configMode or not IsIncomingHealEnabled() or not unitId
        or not ShouldTrackIncomingHealUnit(unitId) then
        healPredBar:Hide()
        return
    end

    local incoming = GetUnitIncomingHealAmount(unitId)
    if incoming <= 0 then
        healPredBar:Hide()
        return
    end

    local hp    = UnitHealth(unitId) or 0
    local hpMax = UnitHealthMax(unitId) or 1
    if hpMax <= 0 then hpMax = 1 end
    visualMax = math.max(visualMax or hpMax, 1)

    -- Keep prediction geometry on the same scale as the bar it overlays.
    -- Party rows may extend that scale to make room for an absorb segment.
    healPredBar:SetMinMaxValues(0, visualMax)
    healPredBar:SetValue(math.min(hp + incoming, visualMax))
    healPredBar:Show()
end

local function UpdateRowIncomingHealVisual(row, unitId, visualMax)
    UpdateIncomingHealBarVisual(row.healPredBar, unitId, visualMax)
end


-- =============================================================================
-- Utilities

function X.Initialize(deps)
    for _, key in ipairs({
        "rows", "visualTickerFrame", "IsSavedFeatureEnabled", "GetUnitTargetToken",
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
X.GetPlayerPowerInfo = GetPlayerPowerInfo
X.GetRowPowerChromeHeight = GetRowPowerChromeHeight
X.GetRowTotalHeight = GetRowTotalHeight
X.InitHotSpells = InitHotSpells
X.SyncVisualTicker = SyncVisualTicker
X.RefreshVisualTicker = RefreshVisualTicker
X.UpdateRowHotVisuals = UpdateRowHotVisuals
X.IsShieldEnabled = IsShieldEnabled
X.ShouldTrackShieldUnit = ShouldTrackShieldUnit
X.ShieldTrackerSyncUnit = ShieldTrackerSyncUnit
X.OnShieldCombatLog = OnShieldCombatLog
X.SeedShieldTrackerFromAuras = SeedShieldTrackerFromAuras
X.GetUnitShieldRemaining = GetUnitShieldRemaining
X.UpdateRowShieldVisual = UpdateRowShieldVisual
X.UpdateIncomingHealBarVisual = UpdateIncomingHealBarVisual
X.UpdateRowIncomingHealVisual = UpdateRowIncomingHealVisual
