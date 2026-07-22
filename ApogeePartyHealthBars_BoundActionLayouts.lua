local S = ApogeePartyHealthBars_S
local Actions = ApogeePartyHealthBars_ActionMacros
local ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities
local PlayerContext = ApogeePartyHealthBars_PlayerContext or {
    GetActiveTalentGroup = function()
        local value = C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup
            and C_SpecializationInfo.GetActiveSpecGroup(false, false)
            or (GetActiveTalentGroup and GetActiveTalentGroup())
        return tonumber(value) or 1
    end,
    GetClassToken = function()
        if not UnitClass then return nil end
        local _, token = UnitClass("player")
        return token
    end,
    GetForm = function() return tonumber(GetShapeshiftForm and GetShapeshiftForm()) or 0 end,
    IsStealthed = function() return IsStealthed and IsStealthed() == true or false end,
}

ApogeePartyHealthBars_BoundActionLayouts = {}
local Factory = ApogeePartyHealthBars_BoundActionLayouts

local CLASS_WITH_NATIVE_STATES = {
    DRUID = true,
    PRIEST = true,
    ROGUE = true,
    SHAMAN = true,
    WARRIOR = true,
}
local DRUID_CAT_FORM_SPELL_ID = 768
local DRUID_PROWL_SPELL_ID = 5215
local PRIEST_SHADOWFORM_SPELL_ID = 15473
local ROGUE_STEALTH_SPELL_ID = 1784
local DRUID_PROWL_LAYOUT_KEY = "state:768:5215"

local function acceptedVersion(accepted, version)
    if type(accepted) ~= "table" then return false end
    return accepted[version] == true
end

local function isFeatureAvailable(featureKey)
    return not ClientCapabilities
        or ClientCapabilities.IsFeatureAvailable(featureKey)
end

function Factory.Create(options)
    assert(type(options) == "table", "bound action layouts require options")
    assert(type(options.stateKey) == "string", "bound action layouts require a state key")
    assert(type(options.slots) == "table", "bound action layouts require slots")
    assert(type(options.schemaVersion) == "number", "bound action layouts require a schema version")
    assert(acceptedVersion(options.acceptedSchemaVersions, options.schemaVersion),
        "bound action layouts must accept their current schema version")

    local L = {
        SCHEMA_VERSION = options.schemaVersion,
        BASE_KEY = "base",
    }
    local layouts, layoutByKey, layoutKeyByState = {}, {}, {}
    local defaultStateValue, maxStateValue = 0, 0
    local activeSpecKey, activeProfile = "1", nil

    local function state()
        return S.charSv and S.charSv[options.stateKey]
    end

    local function resolveActiveSpecKey()
        local groupIndex = isFeatureAvailable("multiSpecLayouts")
            and PlayerContext.GetActiveTalentGroup() or 1
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

    local function layoutHasAssignments(layout)
        layout = normalizeLayout(layout)
        for _, slot in ipairs(options.slots) do
            if layout.slots[slot.id] then return true end
        end
        return false
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

    local function spellName(spellId, fallback)
        if spellId and C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(spellId)
            if info and info.name then return info.name end
        end
        if spellId and GetSpellInfo then
            local name = GetSpellInfo(spellId)
            if name then return name end
        end
        return fallback
    end

    local function formKey(spellId, index)
        if spellId then return "spell:" .. tostring(spellId) end
        return "form:" .. tostring(index)
    end

    local function sameRegistry(nextLayouts)
        if #layouts ~= #nextLayouts then return false end
        for index, layout in ipairs(nextLayouts) do
            local current = layouts[index]
            if not current or current.key ~= layout.key
                or current.runtimeState ~= layout.runtimeState
                or current.label ~= layout.label
                or current.condition ~= layout.condition
                or current.parentKey ~= layout.parentKey then
                return false
            end
        end
        return true
    end

    local function playerClass()
        return PlayerContext.GetClassToken()
    end

    local function shouldExposeBase(class, formCount)
        return not (class == "WARRIOR" and formCount > 0)
    end

    local function isSpellKnown(spellId)
        if C_SpellBook and C_SpellBook.IsSpellKnown then
            return C_SpellBook.IsSpellKnown(spellId)
        end
        if IsPlayerSpell then return IsPlayerSpell(spellId) end
        if IsSpellKnown then return IsSpellKnown(spellId) end
        return false
    end

    local function isStealthed()
        return PlayerContext.IsStealthed()
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
        local class = playerClass()
        local supportsForms = isFeatureAvailable("formLayouts")
        local count = supportsForms and CLASS_WITH_NATIVE_STATES[class]
            and tonumber(GetNumShapeshiftForms and GetNumShapeshiftForms()) or 0
        count = math.max(0, math.floor(count))
        local exposeBase = shouldExposeBase(class, count)
        local nextLayouts, nextByKey, nextKeyByState = {}, {}, {}
        local nextMaxState = count

        local function addDefinition(definition)
            nextLayouts[#nextLayouts + 1] = definition
            nextByKey[definition.key] = definition
            nextKeyByState[definition.runtimeState] = definition.key
            if definition.runtimeState > nextMaxState then
                nextMaxState = definition.runtimeState
            end
            if type(profile.layouts[definition.key]) ~= "table" then
                local migrationSource = definition.migrateFrom
                    and profile.layouts[definition.migrateFrom]
                profile.layouts[definition.key] = migrationSource
                    and layoutHasAssignments(migrationSource)
                    and cloneLayout(migrationSource) or normalizeLayout({})
            else
                profile.layouts[definition.key] = normalizeLayout(profile.layouts[definition.key])
            end
        end

        if exposeBase then
            addDefinition({
                key = L.BASE_KEY,
                label = "Base",
                runtimeState = 0,
                matches = function(activeForm) return activeForm == 0 end,
            })
        end

        local formKeyBySpellId = {}
        local formIndexBySpellId = {}
        for index = 1, count do
            local formIndex = index
            local texture, _, _, spellId = GetShapeshiftFormInfo(index)
            local key = formKey(spellId, index)
            if spellId then
                formKeyBySpellId[spellId] = key
                formIndexBySpellId[spellId] = formIndex
            end
            addDefinition({
                key = key,
                label = spellName(spellId, "Form " .. tostring(index)),
                runtimeState = formIndex,
                condition = "[form:" .. formIndex .. "]",
                matches = function(activeForm) return activeForm == formIndex end,
                spellId = spellId,
                texture = texture,
                migrateFrom = not exposeBase and formIndex == 1 and L.BASE_KEY or nil,
            })
        end

        if supportsForms and count == 0 and class == "PRIEST"
            and isSpellKnown(PRIEST_SHADOWFORM_SPELL_ID) then
            nextMaxState = 1
            addDefinition({
                key = formKey(PRIEST_SHADOWFORM_SPELL_ID, 1),
                label = spellName(PRIEST_SHADOWFORM_SPELL_ID, "Shadowform"),
                runtimeState = 1,
                condition = "[form:1]",
                matches = function(activeForm) return activeForm == 1 end,
                spellId = PRIEST_SHADOWFORM_SPELL_ID,
            })
        elseif supportsForms and count == 0 and class == "ROGUE"
            and isSpellKnown(ROGUE_STEALTH_SPELL_ID) then
            nextMaxState = 1
            addDefinition({
                key = formKey(ROGUE_STEALTH_SPELL_ID, 1),
                label = spellName(ROGUE_STEALTH_SPELL_ID, "Stealth"),
                runtimeState = 1,
                condition = "[stealth]",
                matches = function() return isStealthed() end,
                composite = true,
                spellId = ROGUE_STEALTH_SPELL_ID,
            })
        end

        local catFormKey = formKeyBySpellId[DRUID_CAT_FORM_SPELL_ID]
        local catFormIndex = formIndexBySpellId[DRUID_CAT_FORM_SPELL_ID]
        if supportsForms and class == "DRUID" and catFormKey
            and isSpellKnown(DRUID_PROWL_SPELL_ID) then
            local prowlState = nextMaxState + 1
            addDefinition({
                key = DRUID_PROWL_LAYOUT_KEY,
                label = spellName(DRUID_CAT_FORM_SPELL_ID, "Cat Form")
                    .. " — " .. spellName(DRUID_PROWL_SPELL_ID, "Prowl"),
                runtimeState = prowlState,
                condition = "[form:" .. catFormIndex .. ",stealth]",
                parentKey = catFormKey,
                composite = true,
                matches = function(activeForm)
                    return activeForm == catFormIndex and isStealthed()
                end,
                spellId = DRUID_PROWL_SPELL_ID,
            })
        end

        local changed = nextSpecKey ~= activeSpecKey or profile ~= activeProfile
            or not sameRegistry(nextLayouts)
        activeSpecKey, activeProfile = nextSpecKey, profile
        layouts, layoutByKey, layoutKeyByState = nextLayouts, nextByKey, nextKeyByState
        defaultStateValue = exposeBase and 0 or 1
        maxStateValue = nextMaxState
        return changed
    end

    L.RefreshStates = L.RefreshActiveContext

    function L.GetActiveSpecKey() return activeSpecKey end
    function L.GetLayouts() return layouts end
    function L.GetOptions()
        local result = {}
        for _, layout in ipairs(layouts) do
            result[#result + 1] = { key = layout.key, label = layout.label }
        end
        return result
    end
    function L.HasStates() return maxStateValue > 0 end
    function L.HasBaseLayout() return layoutByKey[L.BASE_KEY] ~= nil end
    function L.IsKnownLayout(layoutKey) return layoutByKey[layoutKey] ~= nil end
    function L.GetLayoutKeyForState(stateValue)
        return layoutKeyByState[tonumber(stateValue) or defaultStateValue]
            or layoutKeyByState[defaultStateValue] or L.BASE_KEY
    end
    function L.GetActiveStateValue()
        local activeForm = PlayerContext.GetForm()
        for _, definition in ipairs(layouts) do
            if definition.composite and definition.matches(activeForm) then
                return definition.runtimeState
            end
        end
        for _, definition in ipairs(layouts) do
            if not definition.composite and definition.matches(activeForm) then
                return definition.runtimeState
            end
        end
        return defaultStateValue
    end
    function L.GetActiveKey() return L.GetLayoutKeyForState(L.GetActiveStateValue()) end
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
        for _, definition in ipairs(layouts) do
            if definition.composite and definition.condition then
                clauses[#clauses + 1] = definition.condition .. " " .. definition.runtimeState
            end
        end
        for _, definition in ipairs(layouts) do
            if not definition.composite and definition.condition then
                clauses[#clauses + 1] = definition.condition .. " " .. definition.runtimeState
            end
        end
        clauses[#clauses + 1] = tostring(defaultStateValue)
        return table.concat(clauses, "; ")
    end
    function L.GetMaxStateValue() return maxStateValue end

    return L
end
