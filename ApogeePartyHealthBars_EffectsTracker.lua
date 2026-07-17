local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local A = ApogeePartyHealthBars_Auras
local E = ApogeePartyHealthBars_Effects

ApogeePartyHealthBars_EffectsTracker = {}
local X = ApogeePartyHealthBars_EffectsTracker
local D

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

local function InitHotSpells()
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
        "rows", "SyncVisualTicker", "IsSavedFeatureEnabled",
    }) do
        assert(deps[key] ~= nil, "EffectsTracker missing dependency: " .. key)
    end
    D = deps
end
X.IsHotEnabled = IsHotEnabled
X.GetHotStripHeight = GetHotStripHeight
X.InitHotSpells = InitHotSpells
X.HasActiveHotVisuals = HasActiveHotVisuals
X.TickHotVisuals = TickHotVisuals
X.UpdateRowHotVisuals = UpdateRowHotVisuals
