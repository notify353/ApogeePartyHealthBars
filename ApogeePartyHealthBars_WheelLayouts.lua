local S = ApogeePartyHealthBars_S
local WD = ApogeePartyHealthBars_WheelData
local Sounds = ApogeePartyHealthBars_Sounds

ApogeePartyHealthBars_WheelLayouts = {}
local L = ApogeePartyHealthBars_WheelLayouts

L.SCHEMA_VERSION = 3
L.BASE_KEY = "base"

local layouts = {}
local layoutByKey = {}
local layoutKeyByIndex = {}
local defaultStateIndex = 0
local maxStateIndex = 0
local activeSpecKey = "1"
local activeProfile

local function state()
    return S.charSv and S.charSv.wheelMacros
end

local function resolveActiveSpecKey()
    local groupIndex = 1
    if C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup then
        local current = C_SpecializationInfo.GetActiveSpecGroup(false, false)
        if type(current) == "number" and current >= 1 then groupIndex = math.floor(current) end
    end
    return tostring(groupIndex)
end

local function newSlot()
    return { macroText = "", soundKey = "none" }
end

local function cloneSlot(entry)
    if type(entry) ~= "table" then return newSlot() end
    local copy = {}
    for key, value in pairs(entry) do copy[key] = value end
    copy.soundKey = Sounds.NormalizeKey(copy.soundKey, "none", true)
    return copy
end

local function normalizeLayout(layout)
    if type(layout) ~= "table" then layout = {} end
    if type(layout.slots) ~= "table" then layout.slots = {} end
    for _, slot in ipairs(WD.SLOTS) do
        layout.slots[slot.id] = cloneSlot(layout.slots[slot.id])
    end
    return layout
end

local function cloneLayout(source)
    local result = { slots = {} }
    source = normalizeLayout(source)
    for _, slot in ipairs(WD.SLOTS) do
        result.slots[slot.id] = cloneSlot(source.slots[slot.id])
    end
    return result
end

local function spellName(spellId, index)
    if spellId and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellId)
        if info and info.name then return info.name end
    end
    if spellId and GetSpellInfo then
        local name = GetSpellInfo(spellId)
        if name then return name end
    end
    return "Stance " .. tostring(index)
end

local function formKey(spellId, index)
    if spellId then return "spell:" .. tostring(spellId) end
    -- The verified 2.5.6 API supplies a spell ID. Keep an index fallback so
    -- an unexpected incomplete client result never prevents configuration.
    return "form:" .. tostring(index)
end

local function sameRegistry(nextLayouts)
    if #layouts ~= #nextLayouts then return false end
    for index, layout in ipairs(nextLayouts) do
        local current = layouts[index]
        if not current or current.key ~= layout.key or current.index ~= layout.index
            or current.label ~= layout.label then
            return false
        end
    end
    return true
end

local function shouldExposeBase(formCount)
    local class
    if UnitClass then _, class = UnitClass("player") end
    return not (class == "WARRIOR" and formCount > 0)
end

local function ensureProfile(saved, specKey)
    if type(saved.profiles[specKey]) ~= "table" then
        saved.profiles[specKey] = { layouts = {} }
    end
    local profile = saved.profiles[specKey]
    if type(profile.layouts) ~= "table" then profile.layouts = {} end
    profile.layouts[L.BASE_KEY] = normalizeLayout(profile.layouts[L.BASE_KEY])
    return profile
end

function L.Initialize()
    if not S.charSv then return false end
    local saved = S.charSv.wheelMacros
    if type(saved) ~= "table" or saved.schemaVersion ~= L.SCHEMA_VERSION then
        saved = {
            schemaVersion = L.SCHEMA_VERSION,
            enabled = false,
            bindingVersion = 1,
            ownership = {},
            profiles = {},
        }
        S.charSv.wheelMacros = saved
    end
    if type(saved.ownership) ~= "table" then saved.ownership = {} end
    if type(saved.profiles) ~= "table" then saved.profiles = {} end
    if saved.enabled == nil then saved.enabled = false end
    return L.RefreshActiveContext()
end

function L.RefreshActiveContext()
    local saved = state()
    if not saved then return false end
    local nextSpecKey = resolveActiveSpecKey()
    local profile = ensureProfile(saved, nextSpecKey)
    local count = tonumber(GetNumShapeshiftForms and GetNumShapeshiftForms()) or 0
    count = math.max(0, math.floor(count))
    local exposeBase = shouldExposeBase(count)
    local nextLayouts, nextByKey, nextKeyByIndex = {}, {}, {}
    if exposeBase then
        local base = { key = L.BASE_KEY, label = "Base", index = 0 }
        nextLayouts[1], nextByKey[L.BASE_KEY], nextKeyByIndex[0] = base, base, L.BASE_KEY
    end
    local seedLayout = profile.layouts[L.BASE_KEY]
    for index = 1, count do
        local texture, _, _, spellId = GetShapeshiftFormInfo(index)
        local key = formKey(spellId, index)
        local definition = {
            key = key,
            label = spellName(spellId, index),
            index = index,
            spellId = spellId,
            texture = texture,
        }
        nextLayouts[#nextLayouts + 1] = definition
        nextByKey[key] = definition
        nextKeyByIndex[index] = key
        if type(profile.layouts[key]) ~= "table" then
            profile.layouts[key] = cloneLayout(seedLayout)
        else
            profile.layouts[key] = normalizeLayout(profile.layouts[key])
        end
        if not exposeBase and index == 1 then seedLayout = profile.layouts[key] end
    end
    local changed = nextSpecKey ~= activeSpecKey or profile ~= activeProfile
        or not sameRegistry(nextLayouts)
    activeSpecKey, activeProfile = nextSpecKey, profile
    layouts, layoutByKey, layoutKeyByIndex = nextLayouts, nextByKey, nextKeyByIndex
    defaultStateIndex = exposeBase and 0 or 1
    maxStateIndex = count
    return changed
end

-- Retain the old entry point for callers that only need to reconcile forms.
L.RefreshForms = L.RefreshActiveContext

function L.GetActiveSpecKey()
    return activeSpecKey
end

function L.GetLayouts()
    return layouts
end

function L.GetOptions()
    local options = {}
    for _, layout in ipairs(layouts) do
        options[#options + 1] = { key = layout.key, label = layout.label }
    end
    return options
end

function L.HasStances()
    return maxStateIndex > 0
end

function L.HasBaseLayout()
    return layoutByKey[L.BASE_KEY] ~= nil
end

function L.IsKnownLayout(layoutKey)
    return layoutByKey[layoutKey] ~= nil
end

function L.GetLayoutKeyForIndex(index)
    return layoutKeyByIndex[tonumber(index) or defaultStateIndex]
        or layoutKeyByIndex[defaultStateIndex] or L.BASE_KEY
end

function L.GetActiveIndex()
    local index = GetShapeshiftForm and GetShapeshiftForm() or 0
    return layoutKeyByIndex[index] and index or defaultStateIndex
end

function L.GetActiveKey()
    return L.GetLayoutKeyForIndex(L.GetActiveIndex())
end

function L.GetLayout(layoutKey)
    return activeProfile and activeProfile.layouts and activeProfile.layouts[layoutKey]
end

function L.GetSlots(layoutKey)
    local layout = L.GetLayout(layoutKey)
    return layout and layout.slots or nil
end

function L.GetSlot(layoutKey, slotId)
    local slots = L.GetSlots(layoutKey)
    return slots and slots[slotId] or nil
end

function L.SetSlot(layoutKey, slotId, entry)
    local slots = L.GetSlots(layoutKey)
    if not slots then return false end
    slots[slotId] = entry
    return true
end

function L.GetStateDriver()
    local clauses = {}
    for index = 1, maxStateIndex do
        clauses[#clauses + 1] = "[stance:" .. index .. "] " .. index
    end
    clauses[#clauses + 1] = tostring(defaultStateIndex)
    return table.concat(clauses, "; ")
end

function L.GetMaxStateIndex()
    return maxStateIndex
end
