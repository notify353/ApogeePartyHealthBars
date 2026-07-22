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
        emptyState = { enabled = true },
        compositeState = { enabled = true },
    },
}
ApogeePartyHealthBars_Sounds = { Play = function() return true end }
ApogeePartyHealthBars_UIHelpers = {}
ApogeePartyHealthBars_ActionMacros = {
    MAX_BODY_BYTES = 255,
    GetName = function(entry) return entry and entry.name end,
}
ApogeePartyHealthBars_ShortcutItems = {}
local boundActionsSupported = true
ApogeePartyHealthBars_ClientCapabilities = {
    IsFeatureAvailable = function(featureKey)
        return featureKey ~= "boundActions" or boundActionsSupported
    end,
}

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
    local entry = actionName and { name = actionName, macroText = "/cast " .. actionName } or nil
    return {
        Initialize = function() end,
        GetLayouts = function() return { { key = "base", runtimeState = 0 } } end,
        HasStates = function() return true end,
        GetActiveKey = function() return "base" end,
        GetActiveSpecKey = function() return "1" end,
        GetSlots = function() return { [slotId] = entry } end,
        GetSlot = function(_, requested) return requested == slotId and entry or nil end,
        SetSlot = function() return true end,
        IsKnownLayout = function(key) return key == "base" end,
        GetActiveStateValue = function() return 0 end,
        GetMaxStateValue = function() return 0 end,
        GetStateDriver = function() return "0" end,
        RefreshActiveContext = function() return false end,
        GetOptions = function() return { { key = "base", label = "Base" } } end,
    }
end

local function makeCompositeLayouts(slotId)
    local entries = {
        base = { name = "Base Action", macroText = "/cast Base Action" },
        cat = { name = "Cat Action", macroText = "/cast Cat Action" },
        prowl = { name = "Prowl Action", macroText = "/cast Prowl Action" },
    }
    return {
        Initialize = function() end,
        GetLayouts = function()
            return {
                { key = "base", runtimeState = 0 },
                { key = "cat", runtimeState = 1 },
                { key = "prowl", runtimeState = 2 },
            }
        end,
        HasStates = function() return true end,
        GetActiveKey = function() return "prowl" end,
        GetActiveSpecKey = function() return "1" end,
        GetSlots = function(key) return { [slotId] = entries[key] } end,
        GetSlot = function(key, requested) return requested == slotId and entries[key] or nil end,
        SetSlot = function() return true end,
        IsKnownLayout = function(key) return entries[key] ~= nil end,
        GetActiveStateValue = function() return 2 end,
        GetMaxStateValue = function() return 2 end,
        GetStateDriver = function()
            return "[form:1,stealth] 2; [form:1] 1; 0"
        end,
        RefreshActiveContext = function() return false end,
        GetOptions = function() return {} end,
    }
end

dofile("ApogeePartyHealthBars_ActionCooldowns.lua")
dofile("ApogeePartyHealthBars_BoundActionRuntime.lua")
local Factory = ApogeePartyHealthBars_BoundActionRuntime

local valid, validationError = pcall(Factory.Create, {})
assert(not valid and tostring(validationError):find("requires data", 1, true),
    "factory accepted an incomplete descriptor")

local function createRuntime(featureId, stateKey, slotId, actionName, prefix, feedbackGlobal, layouts)
    return Factory.Create({
        data = makeData(slotId, "Apogee" .. featureId .. "Button"),
        layouts = layouts or makeLayouts(slotId, actionName),
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
local empty = createRuntime("Empty", "emptyState", "emptySlot", nil,
    "empty-macro-", "ApogeeEmptyFeedback")
local composite = createRuntime("Composite", "compositeState", "compositeSlot", nil,
    "composite-macro-", "ApogeeCompositeFeedback", makeCompositeLayouts("compositeSlot"))
first.Configure({})
second.Configure({})
empty.Configure({})
composite.Configure({})

assert(bindingOptions[1].marker == "First" and bindingOptions[2].marker == "Second"
    and bindingOptions[4].marker == "Composite",
    "feature-specific binding options were not forwarded")
assert(first.GetBindingManager() ~= second.GetBindingManager(),
    "factory instances shared binding-manager state")

first.RefreshSecureActions()
second.RefreshSecureActions()
empty.RefreshSecureActions()
composite.RefreshSecureActions()
local firstButton = first.GetSecureButton("firstSlot")
local secondButton = second.GetSecureButton("secondSlot")
local emptyButton = empty.GetSecureButton("emptySlot")
local compositeButton = composite.GetSecureButton("compositeSlot")
assert(firstButton ~= secondButton, "factory instances shared secure buttons")
assert(firstButton:GetAttribute("first-macro-0")
        == "/run ApogeeFirstFeedback(1)\n/cast First Action",
    "assigned runtime changed or lost its feedback-prefixed action macro")
assert(secondButton:GetAttribute("second-macro-0"):find("/run ApogeeSecondFeedback(1)", 1, true),
    "second runtime lost its feedback prefix")
assert(emptyButton:GetAttribute("empty-macro-0") == "/run ApogeeEmptyFeedback(1)",
    "empty runtime did not receive a feedback-only secure macro")
assert(emptyButton:GetAttribute("type") == "macro"
    and emptyButton:GetAttribute("macrotext") == "/run ApogeeEmptyFeedback(1)",
    "empty runtime did not activate its feedback-only macro")
assert(compositeButton:GetAttribute("composite-macro-0"):find("Base Action", 1, true)
    and compositeButton:GetAttribute("composite-macro-1"):find("Cat Action", 1, true)
    and compositeButton:GetAttribute("composite-macro-2"):find("Prowl Action", 1, true)
    and compositeButton:GetAttribute("macrotext"):find("Prowl Action", 1, true),
    "composite runtime did not preload and activate every secure state macro")
assert(firstButton:GetAttribute("second-macro-0") == nil
    and secondButton:GetAttribute("first-macro-0") == nil,
    "secure macro prefixes leaked between factory instances")
assert(firstButton:GetAttribute("_onstate-Firststate"):find("first%-macro%-"),
    "first secure-state snippet used the wrong macro prefix")
assert(secondButton:GetAttribute("_onstate-Secondstate"):find("second%-macro%-"),
    "second secure-state snippet used the wrong macro prefix")
assert(emptyButton:GetAttribute("_onstate-Emptystate"):find("empty%-macro%-"),
    "empty secure-state snippet did not retain feedback across layouts")
assert(stateDrivers[1][1] == "Firststate" and stateDrivers[2][1] == "Secondstate"
    and stateDrivers[3][1] == "Emptystate" and stateDrivers[4][1] == "Compositestate"
    and stateDrivers[4][2] == "[form:1,stealth] 2; [form:1] 1; 0",
    "secure state-driver names were not isolated")

ApogeeFirstFeedback(1)
ApogeeSecondFeedback(1)
ApogeeEmptyFeedback(1)
assert(feedback[1][1] == "First" and feedback[1][2] == "firstSlot label"
    and feedback[1][3] == "First Action",
    "first feedback bridge used another runtime's descriptor")
assert(feedback[2][1] == "Second" and feedback[2][2] == "secondSlot label"
    and feedback[2][3] == "Second Action",
    "second feedback bridge used another runtime's descriptor")
assert(feedback[3][1] == "Empty" and feedback[3][2] == "emptySlot label"
    and feedback[3][3] == "Empty",
    "empty feedback bridge did not identify the unassigned slot")

boundActionsSupported = false
local unsupported = createRuntime("Unsupported", "unsupportedState", "unsupportedSlot",
    "Unsupported Action", "unsupported-macro-", "ApogeeUnsupportedFeedback")
unsupported.Configure({})
unsupported.Attach({ btn = CreateFrame("Frame") })
unsupported.InitializeSaved()
assert(unsupported.GetBindingManager() == nil and unsupported.GetHudContainer() == nil
        and unsupported.GetHeight("player") == 0 and unsupported.GetWidth("player") == 0,
    "unsupported bound actions still claimed bindings or occupied HUD geometry")

print("PASS shared bound-action runtime")
