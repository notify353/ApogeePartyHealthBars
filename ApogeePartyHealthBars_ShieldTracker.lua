local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_ShieldTracker = {}
local X = ApogeePartyHealthBars_ShieldTracker
local D
local remainingByGuid = {}

-- Ledger invariants:
-- 1. remainingByGuid is written only from combat-log apply/remove/absorb,
--    SeedFromAuras, and SyncUnit clearing.
-- 2. GetRemaining is read-only apart from clearing a unit whose aura vanished.
-- 3. Shield depletion uses SPELL_ABSORBED, not SPELL_DAMAGE absorbed fields.
-- 4. Aura values never overwrite an existing ledger entry during display reads.

function X.Initialize(deps)
    for _, key in ipairs({
        "Auras", "IsSavedFeatureEnabled", "IsConfigMode", "RequestUpdate",
    }) do
        assert(deps[key] ~= nil, "ShieldTracker missing dependency: " .. key)
    end
    D = deps
    remainingByGuid = {}
end

function X.IsEnabled()
    return D.IsSavedFeatureEnabled("shieldEnabled")
end

function X.ShouldTrackUnit(unitId)
    if not unitId or not UnitExists(unitId) or UnitIsDeadOrGhost(unitId) then
        return false
    end
    if unitId == "player" then return true end
    if unitId:match("^party%d$") then return UnitExists(unitId) end
    return false
end

local function UnitHasPWShield(unitId)
    if not UnitExists(unitId) then return false end
    return D.Auras.UnitHasPWShieldFromSnapshot(D.Auras.GetUnitAuraSnapshot(unitId))
end

local function Clear(guid)
    if guid then remainingByGuid[guid] = nil end
end

local function Set(guid, amount)
    if guid and amount and amount > 0 then
        remainingByGuid[guid] = math.floor(amount + 0.5)
    end
end

local function Reduce(guid, absorbed)
    if not guid or not remainingByGuid[guid] then return end
    if not absorbed or absorbed <= 0 then return end
    remainingByGuid[guid] = remainingByGuid[guid] - absorbed
    if remainingByGuid[guid] <= 0 then Clear(guid) end
end

function X.SyncUnit(unitId)
    if not unitId or not UnitExists(unitId) then return end
    local guid = UnitGUID(unitId)
    if guid and not UnitHasPWShield(unitId) then Clear(guid) end
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
        local value = info[i]
        if type(value) == "number" and value > 0 then return value end
    end
    return nil
end

-- SPELL_ABSORBED uses different offsets for swing and spell damage payloads.
local function ParseSpellAbsorbedEvent(info)
    local destGUID = info[8]
    if not destGUID then return nil, nil, nil end
    if type(info[12]) == "number" and type(info[13]) == "string" then
        return destGUID, info[19], info[22]
    end
    return destGUID, info[16], info[19]
end

function X.OnCombatLog()
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
        if not D.Auras.IsPowerWordShieldAura(spellId, spellName) then return end
        local amount = ParseAuraAmountFromCLEU(info)
        if not amount or amount <= 0 then
            amount = EstimatePWShieldAmount(spellId, info[4])
        end
        Set(destGUID, amount)
        D.RequestUpdate()

    elseif subevent == "SPELL_AURA_REMOVED" then
        local spellId, spellName = info[12], info[13]
        if not D.Auras.IsPowerWordShieldAura(spellId, spellName) then return end
        Clear(destGUID)
        D.RequestUpdate()

    elseif subevent == "SPELL_ABSORBED" then
        local defGUID, absorbSpellId, amount = ParseSpellAbsorbedEvent(info)
        if not defGUID or not amount or amount <= 0 then return end
        if not D.Auras.IsPowerWordShieldAura(absorbSpellId, nil)
            and not remainingByGuid[defGUID] then
            return
        end
        Reduce(defGUID, amount)
        D.RequestUpdate()
    end
end

function X.SeedFromAuras()
    for _, unitId in ipairs(C.SLOT_UNITS) do
        X.SyncUnit(unitId)
        if X.ShouldTrackUnit(unitId) and UnitHasPWShield(unitId) then
            local guid = UnitGUID(unitId)
            if guid and not remainingByGuid[guid] then
                Set(guid, EstimatePWShieldAmount(25218, UnitGUID("player")))
            end
        end
    end
end

function X.GetRemaining(unitId)
    local snapshot = D.Auras.GetUnitAuraSnapshot(unitId)
    if not UnitExists(unitId) or not D.Auras.UnitHasPWShieldFromSnapshot(snapshot) then
        X.SyncUnit(unitId)
        return 0
    end

    local guid = UnitGUID(unitId)
    local tracked = guid and remainingByGuid[guid]
    if tracked and tracked > 0 then return tracked end

    local auraAmount = D.Auras.GetShieldPointsFromSnapshot(snapshot)
    if auraAmount and auraAmount > 0 then return auraAmount end

    return EstimatePWShieldAmount(25218, UnitGUID("player"))
end

function X.UpdateRowVisual(row, unitId, shield)
    if not row.shieldBar then return end

    if D.IsConfigMode() or not X.IsEnabled() or not unitId
        or not X.ShouldTrackUnit(unitId) then
        row.shieldBar:Hide()
        return
    end

    shield = shield or X.GetRemaining(unitId)
    if shield <= 0 then
        row.shieldBar:Hide()
        return
    end

    local hp = UnitHealth(unitId) or 0
    local hpMax = UnitHealthMax(unitId) or 1
    if hpMax <= 0 then hpMax = 1 end

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
