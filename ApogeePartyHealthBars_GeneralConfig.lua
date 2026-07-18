local C = ApogeePartyHealthBars_C
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_GeneralConfig = {}
local G = ApogeePartyHealthBars_GeneralConfig
local D

local tab
local form
local generalRows = {}
local generalRowsByKey = {}
local hotRows = {}
local hotRowsByKey = {}
local resetBarBtn, resetSettingsBtn, resetMinimapBtn, prepareDisableBtn, factoryResetBtn
local behaviorSection, alertsSection, displaySection, hotSection, positionsSection, dangerSection
local resetRow, prepareDisableRow, factoryRow
local prepareDisableArmed, prepareDisableToken = false, 0
local factoryResetArmed, factoryResetToken = false, 0
local refreshing = false

local function SetCheckboxChecked(check, checked)
    local onClick = check:GetScript("OnClick")
    check:SetScript("OnClick", nil)
    check:SetChecked(checked)
    check:SetScript("OnClick", onClick)
end

local function CreateCheckboxRow(parent, labelText, indent)
    local row = UIH.CreateFormRow(parent, form.rowWidth, 32)

    local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    check:SetSize(22, 22)
    check:SetPoint("RIGHT", row, "RIGHT", -5, 0)

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", row, "LEFT", 8 + (indent or 0), 0)
    label:SetPoint("RIGHT", check, "LEFT", -5, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetText(labelText)

    row.check = check
    row.label = label
    return row
end

local function IsRowVisible(svKey)
    if svKey == "partyBuffEnabled" then return D.IsPartyBuffKnown() end
    if svKey == "selfBuffEnabled" then return D.IsSelfBuffKnown() end
    if svKey == "clickableBuffIcons" then return D.HasKnownBuffReminder() end
    if svKey == "selfBuffPreference" then
        return #(D.GetSelfBuffPreferenceOptions() or {}) > 2
    end
    return true
end

local function DisarmFactoryReset()
    factoryResetArmed = false
    factoryResetToken = factoryResetToken + 1
    if factoryResetBtn then factoryResetBtn.label:SetText("Factory Reset") end
end

local function DisarmPrepareDisable()
    prepareDisableArmed = false
    prepareDisableToken = prepareDisableToken + 1
    if prepareDisableBtn then prepareDisableBtn.label:SetText("Prepare to Disable") end
end

local function Layout()
    local saved = D.GetSavedVariables() or {}
    local hotGlobal = D.IsHotEnabled()
    local disabled = saved.hotDisabled or {}
    local entries = {
        { frame = behaviorSection, height = 16, gap = 9 },
    }

    local function addSetting(svKey)
        local row = generalRowsByKey[svKey]
        local visible = row and IsRowVisible(svKey)
        entries[#entries + 1] = { frame = row.frame, height = 32, visible = visible }
        if visible then
            if row.svKey == "selfBuffPreference" then
                local currentKey = D.GetSelfBuffPreferenceKey()
                local currentLabel = "Any self buff"
                for _, option in ipairs(D.GetSelfBuffPreferenceOptions() or {}) do
                    if option.key == currentKey then currentLabel = option.label; break end
                end
                row.frame.value.label:SetText(currentLabel .. "  |cff777777(click to change)|r")
            elseif row.svKey == "lowHealthSoundKey" then
                row.frame.value:SetSelectedKey(D.HealthAlerts.GetSoundKey())
            elseif row.svKey == "lowHealthThreshold" then
                local threshold = D.HealthAlerts.GetThreshold()
                row.frame.value:SetText(threshold .. "%")

                local canDecrease = threshold > C.LOW_HEALTH_MIN_THRESHOLD
                if canDecrease then row.frame.decrease:Enable() else row.frame.decrease:Disable() end
                row.frame.decrease.label:SetTextColor(
                    canDecrease and 1 or 0.45,
                    canDecrease and 0.82 or 0.45,
                    canDecrease and 0 or 0.45)

                local canIncrease = threshold < C.LOW_HEALTH_MAX_THRESHOLD
                if canIncrease then row.frame.increase:Enable() else row.frame.increase:Disable() end
                row.frame.increase.label:SetTextColor(
                    canIncrease and 1 or 0.45,
                    canIncrease and 0.82 or 0.45,
                    canIncrease and 0 or 0.45)
            else
                SetCheckboxChecked(row.frame.check, D.IsSavedFeatureEnabled(row.svKey))
            end
        end
    end

    addSetting("showAllSlots")
    addSetting("combatUIAutoHide")

    entries[#entries + 1] = { frame = alertsSection, height = 16, gap = 10 }
    addSetting("lowHealthThreshold")
    addSetting("lowHealthSoundKey")
    addSetting("partyBuffEnabled")
    addSetting("selfBuffEnabled")
    addSetting("selfBuffPreference")
    addSetting("clickableBuffIcons")

    entries[#entries + 1] = { frame = displaySection, height = 16, gap = 10 }
    addSetting("shieldEnabled")
    addSetting("incomingHealEnabled")
    addSetting("rangeCheckEnabled")
    addSetting("threatEnabled")
    addSetting("threatPercentEnabled")
    addSetting("showUnitTargets")
    addSetting("hotEnabled")

    local knownHotCount = 0
    for _, entry in ipairs(hotRows) do
        if D.IsHotTrackKnown(entry.def.key) then knownHotCount = knownHotCount + 1 end
    end
    entries[#entries + 1] = {
        frame = hotSection, height = 16, gap = 10, visible = knownHotCount > 0,
    }
    for _, entry in ipairs(hotRows) do
        local visible = D.IsHotTrackKnown(entry.def.key)
        entries[#entries + 1] = {
            frame = entry.row, height = 32, indent = 12, visible = visible,
        }
        if visible then
            SetCheckboxChecked(entry.row.check, not disabled[entry.def.key])
            if hotGlobal then
                entry.row.check:Enable()
                entry.row.label:SetTextColor(0.9, 0.9, 0.9)
            else
                entry.row.check:Disable()
                entry.row.label:SetTextColor(0.45, 0.45, 0.45)
            end
        end
    end

    entries[#entries + 1] = { frame = positionsSection, height = 16, gap = 10 }
    entries[#entries + 1] = { frame = resetRow, height = 32 }
    entries[#entries + 1] = { frame = dangerSection, height = 16, gap = 10 }
    entries[#entries + 1] = { frame = prepareDisableRow, height = 32 }
    entries[#entries + 1] = { frame = factoryRow, height = 32 }
    UIH.LayoutForm(form, entries)
end

local function AddGeneralRow(frame, svKey)
    local entry = { frame = frame, svKey = svKey }
    generalRows[#generalRows + 1] = entry
    generalRowsByKey[svKey] = entry
end

local function AddCheckbox(label, svKey, onChange)
    local frame = CreateCheckboxRow(form.content, label, 0)
    AddGeneralRow(frame, svKey)
    frame.check:SetScript("OnClick", function(self)
        if refreshing then return end
        local checked = self:GetChecked()
        D.SetSavedFeature(svKey, checked, onChange)
        D.RequestConfigRefresh()
    end)
end

local function AddSelfBuffPreference()
    local frame = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", frame, "LEFT", 8, 0)
    label:SetWidth(155)
    label:SetJustifyH("LEFT")
    label:SetText("Preferred self buff")
    local value = UIH.CreateButton(frame, "Any self buff", 240, 22)
    value:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    value:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    value:SetScript("OnClick", function(_, mouseButton)
        if refreshing then return end
        local options = D.GetSelfBuffPreferenceOptions() or {}
        if #options == 0 then return end
        local currentKey = D.GetSelfBuffPreferenceKey()
        local currentIndex = 1
        for i, option in ipairs(options) do
            if option.key == currentKey then currentIndex = i; break end
        end
        local direction = mouseButton == "RightButton" and -1 or 1
        local nextIndex = ((currentIndex - 1 + direction) % #options) + 1
        D.SetSelfBuffPreference(options[nextIndex].key)
        D.RequestConfigRefresh()
    end)
    frame.value = value
    AddGeneralRow(frame, "selfBuffPreference")
end

local function AddLowHealthSoundPreference()
    local frame = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", frame, "LEFT", 8, 0)
    label:SetWidth(155)
    label:SetJustifyH("LEFT")
    label:SetText("Low-health sound")

    local value = UIH.CreateDropdown(frame, 220, 22)
    value:SetOptions(D.Sounds.GetOptions(true))
    value:SetArrowShown(false)
    value:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    value:SetSelectionCallback(function(soundKey)
        if refreshing then return end
        D.HealthAlerts.SetSoundKey(soundKey)
        D.HealthAlerts.PreviewSound()
        D.RequestConfigRefresh()
    end)

    frame.value = value
    AddGeneralRow(frame, "lowHealthSoundKey")
end

local function AddLowHealthThresholdPreference()
    local frame = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", frame, "LEFT", 8, 0)
    label:SetWidth(155)
    label:SetJustifyH("LEFT")
    label:SetText("Alert below")

    local increase = UIH.CreateButton(frame, "+5%", 52, 22)
    increase:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    increase:SetScript("OnClick", function()
        if refreshing then return end
        D.HealthAlerts.AdjustThreshold(1)
        D.RequestConfigRefresh()
    end)

    local value = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    value:SetPoint("RIGHT", increase, "LEFT", -4, 0)
    value:SetWidth(58)
    value:SetJustifyH("CENTER")

    local decrease = UIH.CreateButton(frame, "-5%", 52, 22)
    decrease:SetPoint("RIGHT", value, "LEFT", -4, 0)
    decrease:SetScript("OnClick", function()
        if refreshing then return end
        D.HealthAlerts.AdjustThreshold(-1)
        D.RequestConfigRefresh()
    end)

    frame.decrease = decrease
    frame.value = value
    frame.increase = increase
    AddGeneralRow(frame, "lowHealthThreshold")
end

function G.Build(parent, deps)
    if tab then return tab end
    assert(type(deps) == "table", "GeneralConfig requires dependencies")
    for _, key in ipairs({
        "ApplyAllSecureBindings", "ApplyDefaultConfigPosition",
        "ApplyDefaultMinimapPosition", "ApplyDefaultPosition", "CombatUIFader",
        "FactoryReset", "ForceRefresh", "GetSavedVariables",
        "GetSelfBuffPreferenceKey", "GetSelfBuffPreferenceOptions",
        "HasKnownBuffReminder", "HealthAlerts", "InitHotSpells", "IsHotEnabled",
        "IsHotTrackKnown", "IsPartyBuffKnown", "IsSavedFeatureEnabled",
        "IsSelfBuffKnown", "Print", "RequestConfigRefresh", "SetAddonEnabled",
        "SetHotTrackEnabled", "SetSavedFeature", "SetSelfBuffPreference", "Sounds",
        "SyncVisualTicker", "Threat",
    }) do
        assert(deps[key] ~= nil, "GeneralConfig missing dependency: " .. key)
    end
    D = deps

    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)

    form = UIH.CreateFormScaffold(tab, "ApogeePartyHealthBarsGeneralConfigScroll",
        "Choose what the party bars show and how they behave.", false)

    behaviorSection = UIH.CreateFormSection(form.content, form.rowWidth, "Behavior")
    alertsSection = UIH.CreateFormSection(form.content, form.rowWidth, "Alerts and reminders")
    displaySection = UIH.CreateFormSection(form.content, form.rowWidth, "Bar display")
    hotSection = UIH.CreateFormSection(form.content, form.rowWidth, "Tracked HoTs")
    positionsSection = UIH.CreateFormSection(form.content, form.rowWidth, "Positions")
    dangerSection = UIH.CreateFormSection(form.content, form.rowWidth, "Danger")

    AddCheckbox("Show all 5 slots when solo", "showAllSlots")
    AddCheckbox("Auto-hide Blizzard UI in combat", "combatUIAutoHide", function()
        local saved = D.GetSavedVariables()
        D.CombatUIFader.ApplyEnabledState(saved and saved.combatUIAutoHide)
    end)
    AddLowHealthThresholdPreference()
    AddLowHealthSoundPreference()
    AddCheckbox("Missing party buff icons", "partyBuffEnabled")
    AddCheckbox("Missing self-buff or aura icon", "selfBuffEnabled")
    AddSelfBuffPreference()
    AddCheckbox("Clickable buff reminder icons", "clickableBuffIcons", function()
        D.ApplyAllSecureBindings()
    end)
    AddCheckbox("Shield overlay", "shieldEnabled")
    AddCheckbox("Incoming heal overlay", "incomingHealEnabled")
    AddCheckbox("Fade out-of-range party members", "rangeCheckEnabled")
    local function refreshThreatSetting()
        D.Threat.Refresh()
        D.SyncVisualTicker()
    end
    AddCheckbox("Threat indicators", "threatEnabled", refreshThreatSetting)
    AddCheckbox("Threat margin (current target)", "threatPercentEnabled", refreshThreatSetting)
    AddCheckbox("Unit target bars", "showUnitTargets")
    AddCheckbox("HoT duration bars", "hotEnabled", D.InitHotSpells)

    for _, def in ipairs(C.HOT_SPELL_DEFINITIONS) do
        local frame = CreateCheckboxRow(form.content, def.canonical, 4)
        local entry = { row = frame, def = def }
        hotRows[#hotRows + 1] = entry
        hotRowsByKey[def.key] = entry
        frame.check:SetScript("OnClick", function(self)
            if refreshing or not D.IsHotEnabled() then return end
            D.SetHotTrackEnabled(def.key, self:GetChecked())
            D.RequestConfigRefresh()
        end)
    end

    resetRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local resetWidth = (form.rowWidth - 22) / 3
    resetBarBtn = UIH.CreateButton(resetRow, "Reset Bars", resetWidth, 22)
    resetBarBtn:SetPoint("LEFT", resetRow, "LEFT", 5, 0)
    resetBarBtn:SetScript("OnClick", function()
        D.ApplyDefaultPosition()
        D.ForceRefresh()
    end)

    resetSettingsBtn = UIH.CreateButton(resetRow, "Reset Settings", resetWidth, 22)
    resetSettingsBtn:SetPoint("LEFT", resetBarBtn, "RIGHT", 6, 0)
    resetSettingsBtn:SetScript("OnClick", D.ApplyDefaultConfigPosition)

    resetMinimapBtn = UIH.CreateButton(resetRow, "Reset Minimap", resetWidth, 22)
    resetMinimapBtn:SetPoint("LEFT", resetSettingsBtn, "RIGHT", 6, 0)
    resetMinimapBtn:SetScript("OnClick", D.ApplyDefaultMinimapPosition)

    prepareDisableRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local prepareDisableLabel = prepareDisableRow:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    prepareDisableLabel:SetPoint("LEFT", prepareDisableRow, "LEFT", 8, 0)
    prepareDisableLabel:SetText("Restore Keys & Wheel bindings first")
    prepareDisableBtn = UIH.CreateButton(prepareDisableRow, "Prepare to Disable", 142, 22)
    prepareDisableBtn:SetPoint("RIGHT", prepareDisableRow, "RIGHT", -5, 0)
    prepareDisableLabel:SetPoint("RIGHT", prepareDisableBtn, "LEFT", -8, 0)
    prepareDisableLabel:SetJustifyH("LEFT")
    prepareDisableLabel:SetWordWrap(false)
    prepareDisableBtn:SetScript("OnClick", function()
        if not prepareDisableArmed then
            prepareDisableArmed = true
            prepareDisableToken = prepareDisableToken + 1
            local token = prepareDisableToken
            prepareDisableBtn.label:SetText("Confirm Release")
            if C_Timer and C_Timer.After then
                C_Timer.After(5, function()
                    if prepareDisableToken == token then DisarmPrepareDisable() end
                end)
            end
            return
        end

        DisarmPrepareDisable()
        if D.SetAddonEnabled(false) then
            D.Print("Keys and Wheel bindings restored. You can now disable the addon in WoW's AddOns manager.")
        end
    end)

    factoryRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local factoryLabel = factoryRow:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    factoryLabel:SetPoint("LEFT", factoryRow, "LEFT", 8, 0)
    factoryLabel:SetText("Erase all profiles and settings")
    factoryResetBtn = UIH.CreateButton(factoryRow, "Factory Reset", 126, 22)
    factoryResetBtn:SetPoint("RIGHT", factoryRow, "RIGHT", -5, 0)
    factoryResetBtn:SetScript("OnClick", function()
        if not factoryResetArmed then
            factoryResetArmed = true
            factoryResetToken = factoryResetToken + 1
            local token = factoryResetToken
            factoryResetBtn.label:SetText("Confirm Erase")
            if C_Timer and C_Timer.After then
                C_Timer.After(5, function()
                    if factoryResetToken == token then DisarmFactoryReset() end
                end)
            end
            return
        end

        DisarmFactoryReset()
        D.FactoryReset()
    end)

    return tab
end

function G.Refresh()
    if not tab then return end
    refreshing = true
    Layout()
    refreshing = false
end

function G.GetRow(svKey)
    local entry = generalRowsByKey[svKey]
    return entry and entry.frame or nil
end

function G.GetHotRow(key)
    local entry = hotRowsByKey[key]
    return entry and entry.row or nil
end

function G.GetResetButtons()
    return {
        bar = resetBarBtn,
        settings = resetSettingsBtn,
        minimap = resetMinimapBtn,
        prepareDisable = prepareDisableBtn,
        factory = factoryResetBtn,
    }
end

G.GetTab = function() return tab end
G.GetPrepareDisableButton = function() return prepareDisableBtn end
G.GetFactoryResetButton = function() return factoryResetBtn end
G.GetForm = function() return form end
