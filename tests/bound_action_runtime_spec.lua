ApogeePartyHealthBars_C = {
    ROW_CONTENT_W = 188,
    SHORTCUT_ICON_SIZE = 26,
    SHORTCUT_ICON_GAP = 2,
    SHORTCUT_READY_PULSE = 0.35,
    SHORTCUT_SOUND_DEBOUNCE = 0.2,
    OUT_OF_RANGE_ALPHA = 0.45,
}
ApogeePartyHealthBars_S = {
    charSv = {
        firstState = { enabled = true },
        secondState = { enabled = true },
    },
}
ApogeePartyHealthBars_Sounds = { Play = function() return true end }
ApogeePartyHealthBars_UIHelpers = {}
ApogeePartyHealthBars_ActionMacros = {
    MAX_BODY_BYTES = 255,
    GetName = function(entry) return entry and entry.name end,
}
ApogeePartyHealthBars_ShortcutItems = {}

local feedback = {}
ApogeePartyHealthBars_ActionHud = {
    Show = function(source, trigger, action, duration)
        feedback[#feedback + 1] = { source, trigger, action, duration }
    end,
    Clear = function() return true end,
}

local bindingOptions = {}
ApogeePartyHealthBars_BoundActionBindings = {
    Create = function(options)
        bindingOptions[#bindingOptions + 1] = options
        return {
            Reconcile = function() return true end,
            GetConflicts = function() return {} end,
            Enable = function() return true end,
            Disable = function() return true end,
        }
    end,
}

UIParent = {}
local stateDrivers = {}
function RegisterStateDriver(_, state, condition)
    stateDrivers[#stateDrivers + 1] = { state, condition }
end
function InCombatLockdown() return false end
function GetTime() return 10 end
function CreateFrame(_, name)
    local frame = { attributes = {}, shown = false, name = name }
    function frame:SetSize() end
    function frame:SetPoint() end
    function frame:RegisterForClicks() end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    function frame:SetAttribute(key, value) self.attributes[key] = value end
    function frame:GetAttribute(key) return self.attributes[key] end
    return frame
end

local function makeData(id, buttonName)
    return {
        SLOTS = { { id = id, key = id, label = id .. " label", buttonName = buttonName } },
        DISPLAY_ORDER = { id },
        ValidateAll = function() return true, {} end,
    }
end

local function makeLayouts(slotId, actionName)
    local entry = { name = actionName, macroText = "/cast " .. actionName }
    return {
        Initialize = function() end,
        GetLayouts = function() return { { key = "base", index = 0 } } end,
        HasStances = function() return true end,
        GetActiveKey = function() return "base" end,
        GetActiveSpecKey = function() return "1" end,
        GetSlots = function() return { [slotId] = entry } end,
        GetSlot = function(_, requested) return requested == slotId and entry or nil end,
        SetSlot = function() return true end,
        IsKnownLayout = function(key) return key == "base" end,
        GetActiveIndex = function() return 0 end,
        GetMaxStateIndex = function() return 0 end,
        GetStateDriver = function() return "0" end,
        RefreshActiveContext = function() return false end,
        GetOptions = function() return { { key = "base", label = "Base" } } end,
    }
end

dofile("ApogeePartyHealthBars_BoundActionRuntime.lua")
local Factory = ApogeePartyHealthBars_BoundActionRuntime

local valid, validationError = pcall(Factory.Create, {})
assert(not valid and tostring(validationError):find("requires data", 1, true),
    "factory accepted an incomplete descriptor")

local function createRuntime(featureId, stateKey, slotId, actionName, prefix, feedbackGlobal)
    return Factory.Create({
        data = makeData(slotId, "Apogee" .. featureId .. "Button"),
        layouts = makeLayouts(slotId, actionName),
        stateKey = stateKey,
        featureId = featureId,
        featureLabel = featureId,
        slotNoun = featureId .. " slot",
        feedbackGlobal = feedbackGlobal,
        feedbackLabel = function(slot) return slot.label end,
        secureState = featureId .. "state",
        secureMacroPrefix = prefix,
        hud = {
            panelHeight = 100,
            totalHeight = 110,
            positionIcon = function() end,
        },
        bindings = { marker = featureId },
        allSlotsMessage = featureId .. " is full.",
    })
end

local first = createRuntime("First", "firstState", "firstSlot", "First Action",
    "first-macro-", "ApogeeFirstFeedback")
local second = createRuntime("Second", "secondState", "secondSlot", "Second Action",
    "second-macro-", "ApogeeSecondFeedback")
first.Configure({})
second.Configure({})

assert(bindingOptions[1].marker == "First" and bindingOptions[2].marker == "Second",
    "feature-specific binding options were not forwarded")
assert(first.GetBindingManager() ~= second.GetBindingManager(),
    "factory instances shared binding-manager state")

first.RefreshSecureActions()
second.RefreshSecureActions()
local firstButton = first.GetSecureButton("firstSlot")
local secondButton = second.GetSecureButton("secondSlot")
assert(firstButton ~= secondButton, "factory instances shared secure buttons")
assert(firstButton:GetAttribute("first-macro-0"):find("/run ApogeeFirstFeedback(1)", 1, true),
    "first runtime lost its feedback prefix")
assert(secondButton:GetAttribute("second-macro-0"):find("/run ApogeeSecondFeedback(1)", 1, true),
    "second runtime lost its feedback prefix")
assert(firstButton:GetAttribute("second-macro-0") == nil
    and secondButton:GetAttribute("first-macro-0") == nil,
    "secure macro prefixes leaked between factory instances")
assert(firstButton:GetAttribute("_onstate-Firststate"):find("first%-macro%-"),
    "first secure-state snippet used the wrong macro prefix")
assert(secondButton:GetAttribute("_onstate-Secondstate"):find("second%-macro%-"),
    "second secure-state snippet used the wrong macro prefix")
assert(stateDrivers[1][1] == "Firststate" and stateDrivers[2][1] == "Secondstate",
    "secure state-driver names were not isolated")

ApogeeFirstFeedback(1)
ApogeeSecondFeedback(1)
assert(feedback[1][1] == "First" and feedback[1][2] == "firstSlot label"
    and feedback[1][3] == "First Action",
    "first feedback bridge used another runtime's descriptor")
assert(feedback[2][1] == "Second" and feedback[2][2] == "secondSlot label"
    and feedback[2][3] == "Second Action",
    "second feedback bridge used another runtime's descriptor")

print("PASS shared bound-action runtime")
