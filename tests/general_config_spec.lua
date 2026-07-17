ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396,
    CONFIG_CHECK_ROW_H = 24,
    CONFIG_SECTION_GAP = 8,
    CONFIG_BTN_H = 22,
    BIND_PAD = 8,
    CONFIG_HEADER_H = 40,
    CONFIG_TAB_H = 24,
    LOW_HEALTH_MIN_THRESHOLD = 35,
    LOW_HEALTH_MAX_THRESHOLD = 80,
    HOT_SPELL_DEFINITIONS = {
        { key = "renew", canonical = "Renew" },
        { key = "rejuv", canonical = "Rejuvenation" },
    },
}

local function Widget()
    local widget = {
        scripts = {}, shown = true, enabled = true, checked = false, text = "",
    }
    local noops = { "RegisterForClicks", "SetJustifyH" }
    for _, name in ipairs(noops) do widget[name] = function() end end
    function widget:SetScript(name, callback) self.scripts[name] = callback end
    function widget:GetScript(name) return self.scripts[name] end
    function widget:SetSize(width, height) self.width, self.height = width, height end
    function widget:SetWidth(width) self.width = width end
    function widget:SetHeight(height) self.height = height end
    function widget:SetPoint(...) self.point = { ... } end
    function widget:ClearAllPoints() self.point = nil end
    function widget:CreateFontString() return Widget() end
    function widget:CreateTexture() return Widget() end
    function widget:Show() self.shown = true end
    function widget:Hide() self.shown = false end
    function widget:IsShown() return self.shown end
    function widget:Enable() self.enabled = true end
    function widget:Disable() self.enabled = false end
    function widget:IsEnabled() return self.enabled end
    function widget:SetChecked(checked) self.checked = checked == true end
    function widget:GetChecked() return self.checked end
    function widget:SetText(text) self.text = text or "" end
    function widget:GetText() return self.text end
    function widget:SetTextColor(...) self.textColor = { ... } end
    function widget:SetScrollChild(child) self.scrollChild = child end
    return widget
end

function CreateFrame() return Widget() end

ApogeePartyHealthBars_UIHelpers = {}
local UIH = ApogeePartyHealthBars_UIHelpers
function UIH.CreateButton(_, label)
    local button = Widget()
    button.label = Widget()
    button.label:SetText(label)
    return button
end
function UIH.CreateDropdown(parent)
    local dropdown = UIH.CreateButton(parent, "Select...")
    function dropdown:SetOptions(options) self.options = options end
    function dropdown:SetArrowShown(shown) self.arrowShown = shown end
    function dropdown:SetSelectionCallback(callback) self.onSelect = callback end
    function dropdown:SetSelectedKey(key) self.selectedKey = key; return key end
    return dropdown
end
function UIH.CreateScrollFrame()
    local scroll, child = Widget(), Widget()
    scroll:SetScrollChild(child)
    return scroll, child
end
function UIH.AttachScrollWheel(scroll, step) scroll.wheelStep = step end

local saved = {
    enabled = true,
    showAllSlots = false,
    combatUIAutoHide = true,
    hotEnabled = true,
    hotDisabled = { renew = true },
}
local known = { party = true, self = false, reminder = true, renew = true, rejuv = false }
local selfOptions = {
    { key = "any", label = "Any self buff" },
    { key = "inner", label = "Inner Fire" },
    { key = "shadow", label = "Shadowform" },
}
local selfPreference = "inner"
local threshold = 50
local calls = {
    refresh = 0, secure = 0, threat = 0, ticker = 0, hotInit = 0,
    hotTrack = 0, barReset = 0, force = 0, settingsReset = 0,
    minimapReset = 0, factoryReset = 0, soundPreview = 0,
}
local timerCallback
C_Timer = { After = function(_, callback) timerCallback = callback end }

local deps = {
    ApplyAllSecureBindings = function() calls.secure = calls.secure + 1 end,
    ApplyDefaultConfigPosition = function() calls.settingsReset = calls.settingsReset + 1 end,
    ApplyDefaultMinimapPosition = function() calls.minimapReset = calls.minimapReset + 1 end,
    ApplyDefaultPosition = function() calls.barReset = calls.barReset + 1 end,
    CombatUIFader = {
        ApplyEnabledState = function(enabled) calls.fadeState = enabled end,
    },
    FactoryReset = function() calls.factoryReset = calls.factoryReset + 1 end,
    ForceRefresh = function() calls.force = calls.force + 1 end,
    GetSavedVariables = function() return saved end,
    GetSelfBuffPreferenceKey = function() return selfPreference end,
    GetSelfBuffPreferenceOptions = function() return selfOptions end,
    HasKnownBuffReminder = function() return known.reminder end,
    HealthAlerts = {
        GetSoundKey = function() return "alarm_soft" end,
        SetSoundKey = function(key) calls.soundKey = key end,
        PreviewSound = function() calls.soundPreview = calls.soundPreview + 1 end,
        GetThreshold = function() return threshold end,
        AdjustThreshold = function(direction) calls.thresholdDirection = direction end,
    },
    InitHotSpells = function() calls.hotInit = calls.hotInit + 1 end,
    IsHotEnabled = function() return saved.hotEnabled ~= false end,
    IsHotTrackKnown = function(key) return known[key] == true end,
    IsPartyBuffKnown = function() return known.party end,
    IsSavedFeatureEnabled = function(key) return saved[key] ~= false end,
    IsSelfBuffKnown = function() return known.self end,
    RequestConfigRefresh = function() calls.refresh = calls.refresh + 1 end,
    SetAddonEnabled = function(enabled) saved.enabled = enabled; calls.addonEnabled = enabled end,
    SetHotTrackEnabled = function(key, enabled)
        calls.hotTrack = calls.hotTrack + 1
        calls.hotTrackKey, calls.hotTrackEnabled = key, enabled
    end,
    SetSavedFeature = function(key, enabled, onChange)
        saved[key] = enabled
        calls.savedKey, calls.savedEnabled = key, enabled
        if onChange then onChange() end
    end,
    SetSelfBuffPreference = function(key) selfPreference = key; calls.selfPreference = key end,
    Sounds = {
        GetOptions = function() return { { key = "none", label = "None" } } end,
    },
    SyncVisualTicker = function() calls.ticker = calls.ticker + 1 end,
    Threat = { Refresh = function() calls.threat = calls.threat + 1 end },
}

dofile("ApogeePartyHealthBars_GeneralConfig.lua")
local config = ApogeePartyHealthBars_GeneralConfig

local valid, validationError = pcall(config.Build, Widget(), {})
assert(not valid and tostring(validationError):find("ApplyAllSecureBindings", 1, true),
    "GeneralConfig accepted incomplete dependencies")

config.Build(Widget(), deps)
config.Refresh()

assert(config.GetRow("showAllSlots").check:GetChecked() == false
        and config.GetRow("combatUIAutoHide").check:GetChecked() == true,
    "saved General checkboxes did not refresh")
assert(config.GetRow("partyBuffEnabled"):IsShown()
        and not config.GetRow("selfBuffEnabled"):IsShown()
        and config.GetRow("clickableBuffIcons"):IsShown(),
    "known-spell visibility policy changed")
assert(config.GetRow("selfBuffPreference"):IsShown()
        and config.GetRow("selfBuffPreference").value.label:GetText():find("Inner Fire", 1, true),
    "self-buff preference did not display the active family")
assert(config.GetRow("lowHealthSoundKey").value.selectedKey == "alarm_soft"
        and config.GetRow("lowHealthThreshold").value:GetText() == "50%",
    "health-alert preferences did not refresh")
assert(config.GetHotRow("renew"):IsShown()
        and not config.GetHotRow("renew").check:GetChecked()
        and not config.GetHotRow("rejuv"):IsShown(),
    "known and disabled HoT rows changed")

local function Click(control, mouseButton)
    assert(control.scripts.OnClick, "missing click handler")
    control.scripts.OnClick(control, mouseButton or "LeftButton")
end

local showAll = config.GetRow("showAllSlots").check
showAll:SetChecked(true)
Click(showAll)
assert(saved.showAllSlots and calls.savedKey == "showAllSlots" and calls.refresh == 1,
    "General checkbox did not persist and request refresh")

local enable = config.GetRow("enabled").check
enable:SetChecked(false)
Click(enable)
assert(calls.addonEnabled == false and calls.refresh == 2,
    "add-on enable checkbox did not use the controller")

local combatFade = config.GetRow("combatUIAutoHide").check
combatFade:SetChecked(false)
Click(combatFade)
assert(calls.fadeState == false,
    "combat UI setting did not apply its immediate side effect")

local clickable = config.GetRow("clickableBuffIcons").check
clickable:SetChecked(false)
Click(clickable)
assert(calls.secure == 1, "clickable reminder setting did not refresh secure bindings")

local threat = config.GetRow("threatEnabled").check
threat:SetChecked(true)
Click(threat)
assert(calls.threat == 1 and calls.ticker == 1,
    "threat setting did not refresh threat and ticker state")

local hotGlobal = config.GetRow("hotEnabled").check
hotGlobal:SetChecked(false)
Click(hotGlobal)
assert(calls.hotInit == 1, "global HoT setting did not rebuild known tracks")

saved.hotEnabled = false
config.Refresh()
assert(not config.GetHotRow("renew").check:IsEnabled()
        and config.GetHotRow("renew").label.textColor[1] == 0.45,
    "disabled global HoT setting did not mute per-spell controls")
local renew = config.GetHotRow("renew").check
renew:SetChecked(true)
Click(renew)
assert(calls.hotTrack == 0, "disabled HoT row accepted a click")
saved.hotEnabled = true
config.Refresh()
renew:SetChecked(true)
Click(renew)
assert(calls.hotTrack == 1 and calls.hotTrackKey == "renew" and calls.hotTrackEnabled,
    "enabled HoT row did not persist its per-spell setting")

config.GetRow("lowHealthSoundKey").value.onSelect("alarm_high")
assert(calls.soundKey == "alarm_high" and calls.soundPreview == 1,
    "low-health sound selection did not persist and preview")
Click(config.GetRow("lowHealthThreshold").decrease)
assert(calls.thresholdDirection == -1, "threshold decrease control changed direction")
Click(config.GetRow("selfBuffPreference").value, "RightButton")
assert(calls.selfPreference == "any", "right-click self-buff cycling changed order")

local resets = config.GetResetButtons()
Click(resets.bar); Click(resets.settings); Click(resets.minimap)
assert(calls.barReset == 1 and calls.force == 1 and calls.settingsReset == 1
        and calls.minimapReset == 1,
    "General reset controls changed their callbacks")
Click(resets.factory)
assert(calls.factoryReset == 0
        and resets.factory.label:GetText() == "Click again to erase all settings",
    "factory reset lost its confirmation arm")
timerCallback()
assert(resets.factory.label:GetText() == "Factory reset addon",
    "factory reset timeout did not disarm")
Click(resets.factory); Click(resets.factory)
assert(calls.factoryReset == 1 and resets.factory.label:GetText() == "Factory reset addon",
    "confirmed factory reset did not execute and disarm")

known.party, known.self, known.reminder = false, true, false
selfOptions = { selfOptions[1], selfOptions[2] }
config.Refresh()
assert(not config.GetRow("partyBuffEnabled"):IsShown()
        and config.GetRow("selfBuffEnabled"):IsShown()
        and not config.GetRow("clickableBuffIcons"):IsShown()
        and not config.GetRow("selfBuffPreference"):IsShown(),
    "General visibility did not respond to refreshed spell capabilities")

assert(ApogeePartyHealthBars_S == nil,
    "GeneralConfig unexpectedly depended on shared session state")

print("PASS General configuration")
