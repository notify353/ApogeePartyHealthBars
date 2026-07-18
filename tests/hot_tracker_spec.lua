unpack = unpack or table.unpack
function wipe(value) for key in pairs(value or {}) do value[key] = nil end return value end

ApogeePartyHealthBars_C = {
    MAX_ROWS = 2,
    MAX_HOT_SLOTS = 2,
    HOT_H = 4,
    HOT_GAP = 1,
    HOT_AREA_GAP = 1,
    HOT_SPELL_DEFINITIONS = {
        {
            key = "renew", canonical = "Renew",
            auraIds = { [139] = true }, auraNames = { Renew = true },
            barColor = { 0.35, 0.82, 0.48, 1 },
        },
        {
            key = "rejuv", canonical = "Rejuvenation",
            auraIds = { [774] = true }, auraNames = { Rejuvenation = true },
            barColor = { 0.22, 0.72, 0.38, 1 },
        },
    },
}

local known = { renew = true, rejuv = false }
local Effects = {}
function Effects.ForEachDefinition(definitions, callback)
    for _, definition in ipairs(definitions) do
        callback(definition, known[definition.key] == true, definition.canonical)
    end
end

local snapshots = {}
local configuredMatchers
local Auras = {}
function Auras.ConfigureHotMatchers(tracks)
    configuredMatchers = {}
    for index, track in ipairs(tracks or {}) do
        configuredMatchers[index] = track
    end
end
function Auras.GetUnitAuraSnapshot(unitId)
    return snapshots[unitId] or { playerHots = {} }
end

local now = 3
function GetTime() return now end
function UnitExists(unitId) return unitId == "player" or unitId == "party1" end

local function Widget(shown)
    local widget = { shown = shown == true }
    function widget:IsShown() return self.shown end
    function widget:Show() self.shown = true end
    function widget:Hide() self.shown = false end
    function widget:SetMinMaxValues(minimum, maximum)
        self.minimum, self.maximum = minimum, maximum
    end
    function widget:SetValue(value) self.value = value end
    function widget:SetStatusBarColor(...) self.color = { ... } end
    return widget
end

local function Row()
    return {
        btn = Widget(true),
        hotBg = { Widget(false), Widget(false) },
        hotBars = { Widget(false), Widget(false) },
        hotMeta = { [1] = { expirationTime = 99, duration = 99 } },
    }
end

local rows = { Row(), Row() }
local featureEnabled = { enabled = true, hotEnabled = true }
local saved = { hotDisabled = {} }
local syncCount = 0

dofile("ApogeePartyHealthBars_HotTracker.lua")
local tracker = ApogeePartyHealthBars_HotTracker

local valid, validationError = pcall(tracker.Initialize, {})
assert(not valid and tostring(validationError):find("Auras", 1, true),
    "HotTracker accepted incomplete dependencies")

tracker.Initialize({
    Auras = Auras,
    Effects = Effects,
    GetSurfaces = function() return rows end,
    SyncVisualTicker = function() syncCount = syncCount + 1 end,
    IsSavedFeatureEnabled = function(key) return featureEnabled[key] ~= false end,
    GetSavedVariables = function() return saved end,
})

tracker.RefreshKnownSpells()
assert(tracker.IsEnabled() and tracker.IsTrackKnown("renew")
        and not tracker.IsTrackKnown("rejuv"),
    "known HoT spell state was not private and queryable")
assert(tracker.GetActiveTrackCount() == 1 and tracker.GetStripHeight() == 5,
    "single-track geometry changed")
assert(#configuredMatchers == 1 and configuredMatchers[1].key == "renew",
    "active HoT matchers were not forwarded to Auras")
assert(next(rows[1].hotMeta) == nil and syncCount == 1,
    "known-spell refresh did not clear row metadata and sync the ticker")

saved.hotDisabled.renew = true
tracker.RefreshKnownSpells()
assert(tracker.IsTrackKnown("renew") and tracker.GetActiveTrackCount() == 0
        and tracker.GetStripHeight() == 0 and #configuredMatchers == 0,
    "per-track disablement changed known state or retained an active matcher")

saved.hotDisabled.renew = nil
known.rejuv = true
tracker.RefreshKnownSpells()
assert(tracker.GetActiveTrackCount() == 2 and tracker.GetStripHeight() == 10,
    "multi-track geometry or discovery changed")

featureEnabled.hotEnabled = false
tracker.RefreshKnownSpells()
assert(not tracker.IsEnabled() and tracker.IsTrackKnown("renew")
        and tracker.IsTrackKnown("rejuv") and tracker.GetActiveTrackCount() == 0,
    "global disablement lost known state or retained active tracks")

featureEnabled.hotEnabled = true
tracker.RefreshKnownSpells()
snapshots.party1 = {
    playerHots = {
        [1] = { duration = 10, expirationTime = 8 },
    },
}
local row = rows[1]
tracker.UpdateRowVisuals(row, "party1")
assert(row.hotBg[1]:IsShown() and row.hotBars[1]:IsShown()
        and row.hotBars[1].minimum == 0 and row.hotBars[1].maximum == 10
        and row.hotBars[1].value == 5,
    "active HoT duration bar changed")
assert(row.hotBars[1].color[1] == 0.35 and row.hotBars[1].color[4] == 1
        and row.hotMeta[1].expirationTime == 8,
    "active HoT color or metadata changed")
assert(row.hotBg[2]:IsShown() and not row.hotBars[2]:IsShown()
        and row.hotMeta[2] == nil,
    "missing known HoT did not retain its empty track")
assert(tracker.HasActiveVisuals(),
    "active visible HoT did not activate the visual ticker")

now = 6
tracker.TickVisuals()
assert(row.hotBars[1].value == 2 and row.hotBars[1]:IsShown(),
    "HoT countdown cadence changed")
now = 8
tracker.TickVisuals()
assert(row.hotMeta[1] == nil and not row.hotBars[1]:IsShown(),
    "expired HoT bar remained active")

row.hotMeta[1] = { duration = 10, expirationTime = 20 }
row.hotBars[1]:Show()
featureEnabled.enabled = false
assert(not tracker.HasActiveVisuals(),
    "disabled add-on retained active HoT visuals")
local disabledValue = row.hotBars[1].value
tracker.TickVisuals()
assert(row.hotBars[1].value == disabledValue,
    "disabled add-on continued ticking HoT visuals")

featureEnabled.enabled = true
tracker.UpdateRowVisuals(row, nil)
assert(next(row.hotMeta) == nil and not row.hotBg[1]:IsShown()
        and not row.hotBg[2]:IsShown(),
    "invalid unit did not clear every HoT visual")

assert(ApogeePartyHealthBars_S == nil,
    "HotTracker unexpectedly required shared session state")

print("PASS hot tracker")
