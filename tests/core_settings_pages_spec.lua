ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396,
    CONFIG_CHECK_ROW_H = 24,
    CONFIG_SECTION_GAP = 8,
    CONFIG_BTN_H = 22,
    BIND_PAD = 8,
    CONFIG_HEADER_H = 40,
    CONFIG_PAGE_SELECTOR_H = 24,
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
    local noops = { "RegisterForClicks", "SetJustifyH", "SetJustifyV", "SetWordWrap" }
    for _, name in ipairs(noops) do widget[name] = function() end end
    function widget:SetScript(name, callback) self.scripts[name] = callback end
    function widget:GetScript(name) return self.scripts[name] end
    function widget:SetSize(width, height) self.width, self.height = width, height end
    function widget:SetWidth(width) self.width = width end
    function widget:SetHeight(height) self.height = height end
    function widget:SetPoint(...) self.point = { ... } end
    function widget:ClearAllPoints() self.point = nil end
    function widget:CreateFontString()
        local fontString = Widget()
        fontString.Enable = nil
        fontString.Disable = nil
        return fontString
    end
    function widget:CreateTexture() return Widget() end
    function widget:Show() self.shown = true end
    function widget:Hide() self.shown = false end
    function widget:SetShown(shown) self.shown = shown == true end
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
function UIH.CreateFormScaffold(_, _, hintText, showStatus)
    local form = {
        scroll = Widget(), content = Widget(), hint = Widget(), status = Widget(), rowWidth = 372,
        showStatus = showStatus ~= false,
    }
    form.hint:SetText(hintText)
    form.status:SetShown(form.showStatus)
    return form
end
function UIH.CreateFormSection(_, width, label)
    local section = Widget(); section:SetWidth(width); section.label = Widget(); section.label:SetText(label)
    return section
end
function UIH.CreateFormRow(_, width, height)
    local row = Widget(); row:SetSize(width, height); return row
end
function UIH.LayoutForm(form, entries)
    form.entries = entries
    for _, entry in ipairs(entries) do entry.frame:SetShown(entry.visible ~= false) end
end
function UIH.SetUnavailableTooltip(frame, reason) frame.unavailableReason = reason end

local saved = {
    enabled = true,
    showAllSlots = false,
    combatUIAutoHide = true,
    hideUIErrors = true,
    automaticConsumablesEnabled = false,
    mentionAlertsEnabled = true,
    mentionSoundKey = "toast",
    mentionHighlightEnabled = true,
    buffThanksEnabled = true,
    dungeonBoardFeedEnabled = true,
    dungeonBoardSoundKey = "none",
    dungeonBoardLevelsBelow = 10,
    dungeonBoardLevelsAbove = 3,
    hotEnabled = true,
    threatAwarenessEnabled = false,
    threatAwarenessMode = "radar",
    threatAwarenessSoundKey = "alarm_soft",
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
    lfgAlertsReset = 0, dungeonBoardReset = 0,
    dungeonSoundPreview = 0, mentionSoundPreview = 0,
    messages = {}, feedbackClear = 0, consumablesEnabled = nil,
}
local timerCallback
C_Timer = { After = function(_, callback) timerCallback = callback end }
local unsupportedFeatures = {}
local clientCapabilities = {
    IsFeatureAvailable = function(featureKey) return unsupportedFeatures[featureKey] ~= true end,
    GetFeatureReason = function(featureKey) return featureKey .. " unavailable" end,
    ListUnavailableFeatures = function()
        local result = {}
        for key in pairs(unsupportedFeatures) do
            result[#result + 1] = { key = key, label = key, reason = key .. " unavailable" }
        end
        return result
    end,
    ListRuntimeFailures = function() return {} end,
}

local deps = {
    ApplyAllSecureBindings = function() calls.secure = calls.secure + 1 end,
    ActionHud = { Clear = function() calls.feedbackClear = calls.feedbackClear + 1 end },
    ApplyDefaultConfigPosition = function() calls.settingsReset = calls.settingsReset + 1 end,
    ApplyDefaultMinimapPosition = function() calls.minimapReset = calls.minimapReset + 1 end,
    ApplyDefaultPosition = function() calls.barReset = calls.barReset + 1 end,
    CombatUIFader = {
        ApplyEnabledState = function(enabled) calls.fadeState = enabled end,
    },
    UIErrorSuppressor = {
        ApplyEnabledState = function(enabled) calls.uiErrorsState = enabled end,
    },
    ConsumableBar = {
        SetEnabled = function(enabled) calls.consumablesEnabled = enabled == true end,
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
    MentionAlerts = {
        GetSoundKey = function() return saved.mentionSoundKey end,
        SetSoundKey = function(key)
            saved.mentionSoundKey = key
            calls.mentionSoundKey = key
        end,
        PreviewSound = function()
            calls.mentionSoundPreview = calls.mentionSoundPreview + 1
        end,
    },
    DungeonBoardSettings = {
        GetRole = function() return saved.dungeonBoardRole or "healer" end,
        SetRole = function(role)
            saved.dungeonBoardRole = role
            calls.dungeonRole = role
            return true
        end,
        GetFeedEnabled = function() return saved.dungeonBoardFeedEnabled ~= false end,
        SetFeedEnabled = function(enabled)
            saved.dungeonBoardFeedEnabled = enabled == true
            calls.dungeonFeedEnabled = enabled == true
            return true
        end,
        GetSoundKey = function() return saved.dungeonBoardSoundKey end,
        GetLevelOffsets = function()
            return saved.dungeonBoardLevelsBelow, saved.dungeonBoardLevelsAbove
        end,
        GetLevelOffsetLimits = function() return 0, 60 end,
        AdjustLevelOffset = function(kind, direction)
            local key = kind == "below" and "dungeonBoardLevelsBelow"
                or kind == "above" and "dungeonBoardLevelsAbove" or nil
            if not key then return false end
            saved[key] = math.max(0, math.min(60, saved[key] + direction))
            return true
        end,
        SetSoundKey = function(key)
            saved.dungeonBoardSoundKey = key
            calls.dungeonSoundKey = key
        end,
        PreviewSound = function()
            calls.dungeonSoundPreview = calls.dungeonSoundPreview + 1
        end,
    },
    DungeonBoardFeed = {
        ResetPosition = function()
            calls.lfgAlertsReset = calls.lfgAlertsReset + 1
        end,
    },
    DungeonBoardUI = {
        ResetPosition = function()
            calls.dungeonBoardReset = calls.dungeonBoardReset + 1
        end,
    },
    InitHotSpells = function() calls.hotInit = calls.hotInit + 1 end,
    IsHotEnabled = function() return saved.hotEnabled ~= false end,
    IsHotTrackKnown = function(key) return known[key] == true end,
    IsPartyBuffKnown = function() return known.party end,
    IsSavedFeatureEnabled = function(key) return saved[key] ~= false end,
    IsSelfBuffKnown = function() return known.self end,
    Print = function(message) calls.messages[#calls.messages + 1] = message end,
    RequestConfigRefresh = function() calls.refresh = calls.refresh + 1 end,
    SetAddonEnabled = function(enabled)
        saved.enabled = enabled
        calls.addonEnabled = enabled
        return true
    end,
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
    ThreatAwareness = {
        Refresh = function() calls.threatAwareness = (calls.threatAwareness or 0) + 1 end,
        GetSoundKey = function() return saved.threatAwarenessSoundKey end,
        SetSoundKey = function(key) saved.threatAwarenessSoundKey = key end,
        PreviewSound = function() calls.threatAwarenessPreview = (calls.threatAwarenessPreview or 0) + 1 end,
        ResetPosition = function() calls.threatAwarenessReset = (calls.threatAwarenessReset or 0) + 1 end,
    },
    CleanseWatch = {
        HasCapability = function() return true end,
        GetUnavailableReason = function() return nil end,
        RefreshCapabilities = function() calls.cleanseRefresh = (calls.cleanseRefresh or 0) + 1 end,
        ResetPosition = function() calls.cleanseReset = (calls.cleanseReset or 0) + 1 end,
        Refresh = function() calls.cleansePanel = (calls.cleansePanel or 0) + 1 end,
    },
    BuffThanks = {
        Refresh = function() calls.buffThanksRefresh = (calls.buffThanksRefresh or 0) + 1 end,
        ResetPosition = function() calls.buffThanksReset = (calls.buffThanksReset or 0) + 1 end,
    },
    ClientCapabilities = clientCapabilities,
}

dofile("Settings/CoreSettingsPages.lua")
local config = ApogeePartyHealthBars_CoreSettingsPages

local valid, validationError = pcall(config.Create, Widget(), {})
assert(not valid and tostring(validationError):find("ApplyAllSecureBindings", 1, true),
    "CoreSettingsPages accepted incomplete dependencies")

config.Create(Widget(), deps)
config.Refresh()

assert(config.GetPage() == "frames"
        and config.GetForm().hint:GetText()
            == "Choose party-frame behavior, details, and nearby HUD displays."
        and #config.GetForm().entries > 10 and not config.GetForm().status:IsShown(),
    "Frames did not use the shared focused-page hierarchy")

assert(config.GetRow("showAllSlots").check:GetChecked() == false
        and config.GetRow("combatUIAutoHide").check:GetChecked() == true
        and config.GetRow("hideUIErrors").check:GetChecked() == true
        and config.GetRow("showAllSlots").label:GetText()
            == "Show all 5 party frames while solo",
    "saved frame checkboxes did not refresh")
assert(not config.GetRow("threatAwarenessEnabled"):IsShown()
        and not config.GetRow("threatAwarenessExplanation"):IsShown()
        and not config.GetRow("threatAwarenessSoundKey"):IsShown(),
    "Frames still exposed Tank Threat Control settings")
config.SetPage("threatControl")
assert(config.GetPage() == "threatControl"
        and config.GetForm().hint:GetText()
            == "Configure tank threat lead, recovery, and lost-threat alerts; the sample remains visible and draggable while this page is open."
        and config.GetRow("threatAwarenessMode") == nil
        and config.GetRow("threatAwarenessExplanation").label:GetText()
            == "Right is threat lead; left is effort to regain."
        and config.GetRow("threatAwarenessEnabled").label:GetText()
            == "Show Tank Threat Control HUD"
        and not config.GetRow("threatAwarenessSoundKey").value:IsEnabled(),
    "dedicated Tank Threat Control page did not expose its complete workflow")
assert(config.GetRow("enabled") == nil,
    "General still exposed the redundant add-on enable checkbox")
config.SetPage("buffsCleanse")
local buffThanksResetRow = config.GetForm().entries[#config.GetForm().entries].frame
assert(config.GetRow("partyBuffEnabled"):IsShown()
        and config.GetRow("buffThanksEnabled"):IsShown()
        and config.GetRow("buffThanksEnabled").check:GetChecked()
        and config.GetRow("buffThanksEnabled").label:GetText()
            == "Enable Thank You prompts for lasting buffs and player cleanses"
        and not config.GetRow("selfBuffEnabled"):IsShown()
        and config.GetRow("clickableBuffIcons"):IsShown(),
    "known-spell visibility policy changed")
assert(config.GetRow("selfBuffPreference"):IsShown()
        and config.GetRow("selfBuffPreference").value.label:GetText():find("Inner Fire", 1, true),
    "self-buff preference did not display the active family")
config.SetPage("healthChat")
assert(config.GetRow("lowHealthSoundKey").value.selectedKey == "alarm_soft"
        and config.GetRow("lowHealthThreshold").value:GetText() == "50%"
        and config.GetRow("mentionAlertsEnabled").check:GetChecked()
        and config.GetRow("mentionSoundKey").value.selectedKey == "toast"
        and config.GetRow("mentionHighlightEnabled").check:GetChecked(),
    "health and chat preferences did not refresh")
assert(not buffThanksResetRow:IsShown(),
    "Thank You reset row remained visible after leaving Buffs & Cleansing")
config.SetPage("dungeon")
assert(config.GetRow("dungeonBoardRole").value.selectedKey == "healer"
        and config.GetRow("dungeonBoardFeedEnabled").check:GetChecked()
        and config.GetRow("dungeonBoardSoundKey").value.selectedKey == "none"
        and config.GetRow("dungeonBoardLevelsBelow").value:GetText() == "10"
        and config.GetRow("dungeonBoardLevelsAbove").value:GetText() == "3",
    "Dungeon Board preferences did not refresh")
config.SetPage("frames")
assert(config.GetHotRow("renew"):IsShown()
        and not config.GetHotRow("renew").check:GetChecked()
        and not config.GetHotRow("rejuv"):IsShown(),
    "known and disabled HoT rows changed")

local function Click(control, mouseButton)
    assert(control.scripts.OnClick, "missing click handler")
    control.scripts.OnClick(control, mouseButton or "LeftButton")
end

local buffThanksCheck = config.GetRow("buffThanksEnabled").check
buffThanksCheck:SetChecked(false)
Click(buffThanksCheck)
assert(saved.buffThanksEnabled == false
        and calls.savedKey == "buffThanksEnabled"
        and calls.savedEnabled == false
        and calls.buffThanksRefresh == 1,
    "Buff Thanks enable checkbox did not disable and refresh the feature")

Click(config.GetResetButtons().buffThanks)
assert(calls.buffThanksReset == 1 and calls.buffThanksRefresh == 2,
    "Buff Thanks position reset did not reset and refresh the panel")

local showAll = config.GetRow("showAllSlots").check
local refreshBeforeShowAll = calls.refresh
showAll:SetChecked(true)
Click(showAll)
assert(saved.showAllSlots and calls.savedKey == "showAllSlots"
        and calls.refresh == refreshBeforeShowAll + 1,
    "General checkbox did not persist and request refresh")

local dungeonFeed = config.GetRow("dungeonBoardFeedEnabled").check
dungeonFeed:SetChecked(false)
Click(dungeonFeed)
assert(saved.dungeonBoardFeedEnabled == false
        and calls.dungeonFeedEnabled == false,
    "LFG Alerts checkbox did not persist its immediate state")

local combatFade = config.GetRow("combatUIAutoHide").check
combatFade:SetChecked(false)
Click(combatFade)
assert(calls.fadeState == false,
    "combat UI setting did not apply its immediate side effect")

local hideUIErrors = config.GetRow("hideUIErrors").check
hideUIErrors:SetChecked(false)
Click(hideUIErrors)
assert(saved.hideUIErrors == false and calls.uiErrorsState == false,
    "UI error setting did not persist and immediately restore Blizzard errors")

local actionFeedback = config.GetRow("actionFeedbackEnabled").check
assert(config.GetRow("actionFeedbackEnabled"):IsShown()
        and config.GetRow("automaticConsumablesEnabled"):IsShown(),
    "action HUD settings were not included on the Frames page")
actionFeedback:SetChecked(false)
Click(actionFeedback)
assert(saved.actionFeedbackEnabled == false and calls.feedbackClear == 1,
    "action feedback setting did not persist and clear the visible text")

local automaticConsumables = config.GetRow("automaticConsumablesEnabled").check
automaticConsumables:SetChecked(true)
Click(automaticConsumables)
assert(saved.automaticConsumablesEnabled == true and calls.consumablesEnabled == true,
    "General automatic consumables setting did not rebuild the dedicated HUD")

local clickable = config.GetRow("clickableBuffIcons").check
clickable:SetChecked(false)
Click(clickable)
assert(calls.secure == 1, "clickable reminder setting did not refresh secure bindings")

local threat = config.GetRow("threatEnabled").check
threat:SetChecked(true)
Click(threat)
assert(calls.threat == 1 and calls.ticker == 1,
    "threat setting did not refresh threat and ticker state")

config.SetPage("threatControl")
local awarenessToggle = config.GetRow("threatAwarenessEnabled").check
awarenessToggle:SetChecked(true)
Click(awarenessToggle)
assert(saved.threatAwarenessEnabled and calls.threatAwareness == 1 and calls.ticker == 2,
    "Threat Awareness enablement did not refresh the HUD and ticker")
config.GetRow("threatAwarenessSoundKey").value.onSelect("alarm_soft")
assert(saved.threatAwarenessMode == "radar"
        and saved.threatAwarenessSoundKey == "alarm_soft"
        and calls.threatAwarenessPreview == 1,
    "Tank Threat Control sound selection changed legacy mode compatibility")
Click(config.GetResetButtons().threatAwareness)
assert(calls.threatAwarenessReset == 1,
    "Threat Awareness position reset did not reach the HUD")

config.SetPage("frames")
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
config.GetRow("mentionSoundKey").value.onSelect("glass")
assert(calls.mentionSoundKey == "glass" and calls.mentionSoundPreview == 1,
    "mention sound selection did not persist and preview")
config.GetRow("dungeonBoardSoundKey").value.onSelect("alarm_soft")
assert(calls.dungeonSoundKey == "alarm_soft" and calls.dungeonSoundPreview == 1,
    "Dungeon Board sound selection did not persist and preview")
config.SetPage("dungeon")
Click(config.GetRow("dungeonBoardLevelsBelow").decrease)
Click(config.GetRow("dungeonBoardLevelsAbove").increase)
config.Refresh()
assert(saved.dungeonBoardLevelsBelow == 9
        and saved.dungeonBoardLevelsAbove == 4
        and config.GetRow("dungeonBoardLevelsBelow").value:GetText() == "9"
        and config.GetRow("dungeonBoardLevelsAbove").value:GetText() == "4",
    "Dungeon Board per-profile level controls did not persist or refresh")
Click(config.GetRow("lowHealthThreshold").decrease)
assert(calls.thresholdDirection == -1, "threshold decrease control changed direction")
Click(config.GetRow("selfBuffPreference").value, "RightButton")
assert(calls.selfPreference == "any", "right-click self-buff cycling changed order")

local resets = config.GetResetButtons()
Click(resets.bar); Click(resets.settings); Click(resets.minimap)
Click(resets.lfgAlerts); Click(resets.dungeonBoard)
assert(calls.barReset == 1 and calls.force == 1 and calls.settingsReset == 1
        and calls.minimapReset == 1 and calls.lfgAlertsReset == 1
        and calls.dungeonBoardReset == 1,
    "General reset controls changed their callbacks")
Click(resets.prepareDisable)
assert(calls.addonEnabled == nil
        and resets.prepareDisable.label:GetText() == "Confirm Restore",
    "prepare-to-disable action lost its confirmation arm")
timerCallback()
assert(resets.prepareDisable.label:GetText() == "Restore All",
    "prepare-to-disable timeout did not disarm")
Click(resets.prepareDisable); Click(resets.prepareDisable)
assert(calls.addonEnabled == false
        and calls.messages[#calls.messages]:find("AddOns manager", 1, true),
    "confirmed prepare-to-disable action did not restore bindings and guide the user")
Click(resets.factory)
assert(calls.factoryReset == 0
        and resets.factory.label:GetText() == "Confirm Erase",
    "factory reset lost its confirmation arm")
timerCallback()
assert(resets.factory.label:GetText() == "Reset Character",
    "factory reset timeout did not disarm")
Click(resets.factory); Click(resets.factory)
assert(calls.factoryReset == 1 and resets.factory.label:GetText() == "Reset Character",
    "confirmed factory reset did not execute and disarm")

saved.threatEnabled = true
unsupportedFeatures.threat = true
config.SetPage("threatControl")
config.Refresh()
assert(config.GetPage() == "threatControl"
        and config.GetRow("threatAwarenessEnabled").check:GetChecked()
        and not config.GetRow("threatAwarenessEnabled").check:IsEnabled()
        and config.GetRow("threatAwarenessEnabled").unavailableReason == "threat unavailable"
        and not config.GetRow("threatAwarenessSoundKey").value:IsEnabled()
        and saved.threatAwarenessEnabled == true,
    "unsupported Threat Control page did not preserve and disable its saved preference")
config.SetPage("frames")
config.Refresh()
assert(config.GetRow("threatEnabled").check:GetChecked()
        and not config.GetRow("threatEnabled").check:IsEnabled()
        and config.GetRow("threatEnabled").unavailableReason == "threat unavailable"
        and saved.threatEnabled == true,
    "unsupported feature did not preserve and visibly disable its saved preference")
unsupportedFeatures.threat = nil

known.party, known.self, known.reminder = false, true, false
selfOptions = { selfOptions[1], selfOptions[2] }
config.SetPage("buffsCleanse")
config.Refresh()
assert(not config.GetRow("partyBuffEnabled"):IsShown()
        and config.GetRow("selfBuffEnabled"):IsShown()
        and not config.GetRow("clickableBuffIcons"):IsShown()
        and not config.GetRow("selfBuffPreference"):IsShown(),
    "General visibility did not respond to refreshed spell capabilities")

assert(ApogeePartyHealthBars_S == nil,
    "CoreSettingsPages unexpectedly depended on shared session state")

print("PASS General configuration")
