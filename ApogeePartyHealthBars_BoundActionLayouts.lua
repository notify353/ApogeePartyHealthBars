local S = ApogeePartyHealthBars_S
local Actions = ApogeePartyHealthBars_ActionMacros

ApogeePartyHealthBars_BoundActionLayouts = {}
local Factory = ApogeePartyHealthBars_BoundActionLayouts

local function acceptedVersion(accepted, version)
    if type(accepted) ~= "table" then return false end
    return accepted[version] == true
end

function Factory.Create(options)
    assert(type(options) == "table", "bound action layouts require options")
    assert(type(options.stateKey) == "string", "bound action layouts require a state key")
    assert(type(options.slots) == "table", "bound action layouts require slots")
    assert(type(options.schemaVersion) == "number", "bound action layouts require a schema version")

    local L = {
        SCHEMA_VERSION = options.schemaVersion,
        BASE_KEY = "base",
    }
    local layouts, layoutByKey, layoutKeyByIndex = {}, {}, {}
    local defaultStateIndex, maxStateIndex = 0, 0
    local activeSpecKey, activeProfile = "1", nil

    local function state()
        return S.charSv and S.charSv[options.stateKey]
    end

    local function resolveActiveSpecKey()
        local groupIndex = 1
        if C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup then
            local current = C_SpecializationInfo.GetActiveSpecGroup(false, false)
            if type(current) == "number" and current >= 1 then groupIndex = math.floor(current) end
        end
        return tostring(groupIndex)
    end

    local function normalizeLayout(layout)
        if type(layout) ~= "table" then layout = {} end
        if type(layout.slots) ~= "table" then layout.slots = {} end
        for _, slot in ipairs(options.slots) do
            layout.slots[slot.id] = Actions.Normalize(layout.slots[slot.id])
        end
        return layout
    end

    local function cloneLayout(source)
        local result = { slots = {} }
        source = normalizeLayout(source)
        for _, slot in ipairs(options.slots) do
            local entry = Actions.Clone(source.slots[slot.id])
            if entry then result.slots[slot.id] = entry end
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
        local saved = S.charSv[options.stateKey]
        local schemaVersion = type(saved) == "table" and tonumber(saved.schemaVersion) or nil
        if type(saved) ~= "table"
            or not acceptedVersion(options.acceptedSchemaVersions, schemaVersion) then
            saved = {
                schemaVersion = L.SCHEMA_VERSION,
                profiles = {},
            }
            S.charSv[options.stateKey] = saved
        else
            saved.schemaVersion = L.SCHEMA_VERSION
        end
        if type(saved.profiles) ~= "table" then saved.profiles = {} end
        saved.enabled = nil
        for _, profile in pairs(saved.profiles) do
            if type(profile) == "table" and type(profile.layouts) == "table" then
                for layoutKey, layout in pairs(profile.layouts) do
                    profile.layouts[layoutKey] = normalizeLayout(layout)
                end
            end
        end
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
                profile.layouts[key] = options.newLayoutsStartEmpty
                    and normalizeLayout({}) or cloneLayout(seedLayout)
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

    L.RefreshForms = L.RefreshActiveContext

    function L.GetActiveSpecKey() return activeSpecKey end
    function L.GetLayouts() return layouts end
    function L.GetOptions()
        local result = {}
        for _, layout in ipairs(layouts) do
            result[#result + 1] = { key = layout.key, label = layout.label }
        end
        return result
    end
    function L.HasStances() return maxStateIndex > 0 end
    function L.HasBaseLayout() return layoutByKey[L.BASE_KEY] ~= nil end
    function L.IsKnownLayout(layoutKey) return layoutByKey[layoutKey] ~= nil end
    function L.GetLayoutKeyForIndex(index)
        return layoutKeyByIndex[tonumber(index) or defaultStateIndex]
            or layoutKeyByIndex[defaultStateIndex] or L.BASE_KEY
    end
    function L.GetActiveIndex()
        local index = GetShapeshiftForm and GetShapeshiftForm() or 0
        return layoutKeyByIndex[index] and index or defaultStateIndex
    end
    function L.GetActiveKey() return L.GetLayoutKeyForIndex(L.GetActiveIndex()) end
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
        slots[slotId] = Actions.Normalize(entry)
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
    function L.GetMaxStateIndex() return maxStateIndex end

    return L
end
