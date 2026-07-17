local C = ApogeePartyHealthBars_C
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_GeneralConfig = {}
local G = ApogeePartyHealthBars_GeneralConfig
local D

local tab
local scrollChild
local generalRows = {}
local generalRowsByKey = {}
local hotRows = {}
local hotRowsByKey = {}
local resetBarBtn, resetSettingsBtn, resetMinimapBtn, factoryResetBtn, hintFS
local factoryResetArmed, factoryResetToken = false, 0
local refreshing = false

local function SetCheckboxChecked(check, checked)
    local onClick = check:GetScript("OnClick")
    check:SetScript("OnClick", nil)
    check:SetChecked(checked)
    check:SetScript("OnClick", onClick)
end

local function CreateCheckboxRow(parent, labelText, indent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(C.CONFIG_CONTENT_W, C.CONFIG_CHECK_ROW_H)

    local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    check:SetSize(20, 20)
    check:SetPoint("LEFT", row, "LEFT", 0, 0)

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", check, "RIGHT", 2, 0)
    label:SetJustifyH("LEFT")
    label:SetWidth(C.CONFIG_CONTENT_W - 40 - (indent or 0))
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
    if factoryResetBtn then factoryResetBtn.label:SetText("Factory reset addon") end
end

local function Layout()
    local saved = D.GetSavedVariables() or {}
    local hotGlobal = D.IsHotEnabled()
    local disabled = saved.hotDisabled or {}
    local y = 0

    for _, row in ipairs(generalRows) do
        if IsRowVisible(row.svKey) then
            row.frame:Show()
            row.frame:ClearAllPoints()
            row.frame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
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
            y = y + C.CONFIG_CHECK_ROW_H
        else
            row.frame:Hide()
        end
    end

    y = y + C.CONFIG_SECTION_GAP

    for _, entry in ipairs(hotRows) do
        if D.IsHotTrackKnown(entry.def.key) then
            entry.row:Show()
            entry.row:ClearAllPoints()
            entry.row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 12, -y)
            SetCheckboxChecked(entry.row.check, not disabled[entry.def.key])
            if hotGlobal then
                entry.row.check:Enable()
                entry.row.label:SetTextColor(0.9, 0.9, 0.9)
            else
                entry.row.check:Disable()
                entry.row.label:SetTextColor(0.45, 0.45, 0.45)
            end
            y = y + C.CONFIG_CHECK_ROW_H
        else
            entry.row:Hide()
        end
    end

    y = y + C.CONFIG_SECTION_GAP

    for _, button in ipairs({ resetBarBtn, resetSettingsBtn, resetMinimapBtn, factoryResetBtn }) do
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
        y = y + C.CONFIG_BTN_H + 4
    end

    hintFS:ClearAllPoints()
    hintFS:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
    y = y + 28

    scrollChild:SetHeight(y)
end

local function AddGeneralRow(frame, svKey)
    local entry = { frame = frame, svKey = svKey }
    generalRows[#generalRows + 1] = entry
    generalRowsByKey[svKey] = entry
end

local function AddCheckbox(label, svKey, onChange)
    local frame = CreateCheckboxRow(scrollChild, label, 0)
    AddGeneralRow(frame, svKey)
    frame.check:SetScript("OnClick", function(self)
        if refreshing then return end
        local checked = self:GetChecked()
        if svKey == "enabled" then
            D.SetAddonEnabled(checked)
        else
            D.SetSavedFeature(svKey, checked, onChange)
        end
        D.RequestConfigRefresh()
    end)
end

local function AddSelfBuffPreference()
    local frame = CreateFrame("Frame", nil, scrollChild)
    frame:SetSize(C.CONFIG_CONTENT_W, C.CONFIG_CHECK_ROW_H)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", frame, "LEFT", 2, 0)
    label:SetWidth(125)
    label:SetJustifyH("LEFT")
    label:SetText("Preferred self buff")
    local value = UIH.CreateButton(frame, "Any self buff", C.CONFIG_CONTENT_W - 132, C.CONFIG_CHECK_ROW_H)
    value:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
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
    local frame = CreateFrame("Frame", nil, scrollChild)
    frame:SetSize(C.CONFIG_CONTENT_W, C.CONFIG_CHECK_ROW_H)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", frame, "LEFT", 2, 0)
    label:SetWidth(125)
    label:SetJustifyH("LEFT")
    label:SetText("Low-health sound")

    local value = UIH.CreateDropdown(frame, 265, C.CONFIG_CHECK_ROW_H)
    value:SetOptions(D.Sounds.GetOptions(true))
    value:SetArrowShown(false)
    value:SetPoint("LEFT", label, "RIGHT", 4, 0)
    value:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
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
    local frame = CreateFrame("Frame", nil, scrollChild)
    frame:SetSize(C.CONFIG_CONTENT_W, C.CONFIG_CHECK_ROW_H)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", frame, "LEFT", 2, 0)
    label:SetWidth(125)
    label:SetJustifyH("LEFT")
    label:SetText("Alert below")

    local decrease = UIH.CreateButton(frame, "-5%", 52, C.CONFIG_CHECK_ROW_H)
    decrease:SetPoint("LEFT", label, "RIGHT", 4, 0)
    decrease:SetScript("OnClick", function()
        if refreshing then return end
        D.HealthAlerts.AdjustThreshold(-1)
        D.RequestConfigRefresh()
    end)

    local value = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    value:SetPoint("LEFT", decrease, "RIGHT", 4, 0)
    value:SetWidth(58)
    value:SetJustifyH("CENTER")

    local increase = UIH.CreateButton(frame, "+5%", 52, C.CONFIG_CHECK_ROW_H)
    increase:SetPoint("LEFT", value, "RIGHT", 4, 0)
    increase:SetScript("OnClick", function()
        if refreshing then return end
        D.HealthAlerts.AdjustThreshold(1)
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
        "IsSelfBuffKnown", "RequestConfigRefresh", "SetAddonEnabled",
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

    local scroll
    scroll, scrollChild = UIH.CreateScrollFrame(tab)
    UIH.AttachScrollWheel(scroll, C.CONFIG_CHECK_ROW_H * 2)

    AddCheckbox("Enable addon", "enabled")
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
        local frame = CreateCheckboxRow(scrollChild, def.canonical, 12)
        local entry = { row = frame, def = def }
        hotRows[#hotRows + 1] = entry
        hotRowsByKey[def.key] = entry
        frame.check:SetScript("OnClick", function(self)
            if refreshing or not D.IsHotEnabled() then return end
            D.SetHotTrackEnabled(def.key, self:GetChecked())
            D.RequestConfigRefresh()
        end)
    end

    resetBarBtn = UIH.CreateButton(scrollChild, "Reset bar position")
    resetBarBtn:SetScript("OnClick", function()
        D.ApplyDefaultPosition()
        D.ForceRefresh()
    end)

    resetSettingsBtn = UIH.CreateButton(scrollChild, "Reset settings position")
    resetSettingsBtn:SetScript("OnClick", D.ApplyDefaultConfigPosition)

    resetMinimapBtn = UIH.CreateButton(scrollChild, "Reset minimap button")
    resetMinimapBtn:SetScript("OnClick", D.ApplyDefaultMinimapPosition)

    factoryResetBtn = UIH.CreateButton(scrollChild, "Factory reset addon")
    factoryResetBtn:SetScript("OnClick", function()
        if not factoryResetArmed then
            factoryResetArmed = true
            factoryResetToken = factoryResetToken + 1
            local token = factoryResetToken
            factoryResetBtn.label:SetText("Click again to erase all settings")
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

    hintFS = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hintFS:SetWidth(C.CONFIG_CONTENT_W)
    hintFS:SetJustifyH("LEFT")
    hintFS:SetText("Drag the bars or the settings tabs to move them independently. Right-drag the minimap icon to reposition it.")

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
        factory = factoryResetBtn,
    }
end

G.GetTab = function() return tab end
G.GetFactoryResetButton = function() return factoryResetBtn end
