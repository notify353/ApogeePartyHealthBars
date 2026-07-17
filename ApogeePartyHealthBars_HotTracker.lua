local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_HotTracker = {}
local H = ApogeePartyHealthBars_HotTracker
local D

local activeTracks = {}
local knownByKey = {}

local function IsEnabled()
    return D.IsSavedFeatureEnabled("hotEnabled")
end

local function GetActiveTrackCount()
    return #activeTracks
end

local function GetStripHeight()
    if not IsEnabled() then return 0 end
    local count = GetActiveTrackCount()
    if count <= 0 then return 0 end
    return C.HOT_AREA_GAP + count * C.HOT_H + (count - 1) * C.HOT_GAP
end

local function IsTrackKnown(key)
    return knownByKey[key] == true
end

local function ScanUnitPlayerHots(unitId)
    return D.Auras.GetUnitAuraSnapshot(unitId).playerHots
end

local function RefreshKnownSpells()
    wipe(activeTracks)
    wipe(knownByKey)

    local saved = D.GetSavedVariables()
    local disabled = saved and saved.hotDisabled
    D.Effects.ForEachDefinition(C.HOT_SPELL_DEFINITIONS, function(def, known)
        knownByKey[def.key] = known
        if not IsEnabled() then return end
        if known and not (disabled and disabled[def.key]) then
            activeTracks[#activeTracks + 1] = {
                key       = def.key,
                canonical = def.canonical,
                auraNames = def.auraNames,
                auraIds   = def.auraIds,
                barColor  = def.barColor,
            }
        end
    end)

    D.Auras.ConfigureHotMatchers(activeTracks)
    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if row and row.hotMeta then wipe(row.hotMeta) end
    end
    D.SyncVisualTicker()
end

local function WipeRowMeta(row)
    if row.hotMeta then wipe(row.hotMeta) end
end

local function HasActiveVisuals()
    if not IsEnabled() or not D.IsSavedFeatureEnabled("enabled") then return false end
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

local function TickRowVisuals(row)
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

local function TickVisuals()
    if not D.IsSavedFeatureEnabled("enabled") then return end
    if IsEnabled() then
        for i = 1, C.MAX_ROWS do
            local row = D.rows[i]
            if row and row.btn:IsShown() then
                TickRowVisuals(row)
            end
        end
    end
end

local function HideRowVisuals(row)
    if not row.hotBg then return end
    WipeRowMeta(row)
    for i = 1, C.MAX_HOT_SLOTS do
        if row.hotBg[i] then row.hotBg[i]:Hide() end
        if row.hotBars[i] then row.hotBars[i]:Hide() end
    end
    D.SyncVisualTicker()
end

local function UpdateRowVisuals(row, unitId)
    if not row.hotBg then return end

    if not IsEnabled() or not unitId or not UnitExists(unitId) then
        HideRowVisuals(row)
        return
    end

    if #activeTracks == 0 then
        HideRowVisuals(row)
        return
    end

    row.hotMeta = row.hotMeta or {}

    local hots = ScanUnitPlayerHots(unitId)
    for i = 1, #activeTracks do
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
                hotBar:SetStatusBarColor(unpack(activeTracks[i].barColor))
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

    for i = #activeTracks + 1, C.MAX_HOT_SLOTS do
        row.hotMeta[i] = nil
        if row.hotBg[i] then row.hotBg[i]:Hide() end
        if row.hotBars[i] then row.hotBars[i]:Hide() end
    end

    D.SyncVisualTicker()
end

function H.Initialize(deps)
    for _, key in ipairs({
        "Auras", "Effects", "rows", "SyncVisualTicker",
        "IsSavedFeatureEnabled", "GetSavedVariables",
    }) do
        assert(deps[key] ~= nil, "HotTracker missing dependency: " .. key)
    end
    D = deps
end

H.IsEnabled = IsEnabled
H.GetStripHeight = GetStripHeight
H.GetActiveTrackCount = GetActiveTrackCount
H.IsTrackKnown = IsTrackKnown
H.RefreshKnownSpells = RefreshKnownSpells
H.HasActiveVisuals = HasActiveVisuals
H.TickVisuals = TickVisuals
H.UpdateRowVisuals = UpdateRowVisuals
