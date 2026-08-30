local C = ApogeePartyHealthBars_C
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_CoreSettingsPages = {}
local G = ApogeePartyHealthBars_CoreSettingsPages
local D

local page
local form
local generalRows = {}
local generalRowsByKey = {}
local hotRows = {}
local hotRowsByKey = {}
local resetButtons = {}
local behaviorSection, alertsSection, lowHealthSection, nameMentionsSection
local dungeonBoardSection, displaySection, threatAwarenessSection, hudDisplaysSection
local hotSection, compatibilitySection
local positionsSection, recoverySection, dangerSection
local resetPartyFramesRow, resetSettingsRow, resetMinimapRow
local cleanseResetRow, buffThanksResetRow, lfgAlertsResetRow, dungeonBoardResetRow
local compatibilityRow, compatibilityLabel, prepareDisableRow, factoryRow
local previewControls = { buttons = {} }
local prepareDisableArmed, prepareDisableToken = false, 0
local factoryResetArmed, factoryResetToken = false, 0
local refreshing = false
local activePage = "frames"

local PAGE_HINTS = {
    frames = "Choose party-frame behavior, details, and nearby HUD displays.",
    healthChat = "Configure low-health and name-mention alerts.",
    buffsCleanse = "Configure buff and cleansing reminders; samples remain visible and draggable while this page is open.",
    threatControl = "Configure tank threat lead and recovery; the sample remains visible at its fixed gameplay position while this page is open.",
    dungeon = "Configure LFG results and alerts.",
    maintenance = "Restore bindings or reset this character.",
}

local SUPPORT_FEATURE_BY_SETTING = {
    partyBuffEnabled = "auraReminders",
    selfBuffEnabled = "auraReminders",
    selfBuffPreference = "auraReminders",
    clickableBuffIcons = "auraReminders",
    shieldEnabled = "shieldOverlay",
    incomingHealEnabled = "incomingHeals",
    rangeCheckEnabled = "rangeFade",
    threatEnabled = "threat",
    threatPercentEnabled = "threat",
    threatAwarenessEnabled = "threat",
    hotEnabled = "hotTracking",
    buffThanksEnabled = "buffThanks",
}

local function GetSettingSupport(svKey)
    if svKey == "cleanseWatchEnabled" and D and D.CleanseWatch then
        return D.CleanseWatch.HasCapability(), D.CleanseWatch.GetUnavailableReason()
    end
    local featureKey = SUPPORT_FEATURE_BY_SETTING[svKey]
    if not featureKey or not D or not D.ClientCapabilities then return true, nil end
    return D.ClientCapabilities.IsFeatureAvailable(featureKey),
        D.ClientCapabilities.GetFeatureReason(featureKey)
end

local function ApplySettingSupport(entry)
    if not SUPPORT_FEATURE_BY_SETTING[entry.svKey]
        and entry.svKey ~= "cleanseWatchEnabled" then return true end
    local supported, reason = GetSettingSupport(entry.svKey)
    local frame = entry.frame
    local control = frame.check or frame.value
    if UIH.SetControlAvailability then
        UIH.SetControlAvailability(frame, control, supported, reason)
    else
        if control then
            if supported then control:Enable() else control:Disable() end
        end
        if frame.label then
            local color = supported and 0.9 or 0.45
            frame.label:SetTextColor(color, color, color)
        end
        if UIH.SetUnavailableTooltip then
            UIH.SetUnavailableTooltip(frame, supported and nil or reason)
        end
    end
    return supported
end

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
    if UIH.PrepareAvailabilityRow then
        UIH.PrepareAvailabilityRow(row, label, check, 8 + (indent or 0))
    end
    return row
end

local function IsRowVisible(svKey)
    local supported = GetSettingSupport(svKey)
    if supported == false then return true end
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
    if resetButtons.factory then resetButtons.factory.label:SetText("Reset Character") end
end

local function DisarmPrepareDisable()
    prepareDisableArmed = false
    prepareDisableToken = prepareDisableToken + 1
    if resetButtons.prepareDisable then resetButtons.prepareDisable.label:SetText("Restore All") end
end

local function RefreshPreviewControls()
    if not D or not D.PartyFramePreview then return end
    local selected = D.PartyFramePreview.GetScenario()
    for key, button in pairs(previewControls.buttons) do
        if button.label then
            button.label:SetTextColor(key == selected and 1 or 0.72,
                key == selected and 0.82 or 0.72,
                key == selected and 0 or 0.76)
        end
    end
    previewControls.channel:SetText("PREVIEW GUIDE")
    if selected == "combat" then
        previewControls.text:SetText(
            "COMBAT: Group Helper hides.\n"
            .. "Threat rails and target margins use the reserved companion area.")
    else
        previewControls.text:SetText(
            "OUT OF COMBAT\n"
            .. "DRINKING: active drink aura. THIRSTY: below 75% without one.\n"
            .. "Buffs: Priest Fort/Spirit · Mage Int · Druid Mark.\n"
            .. "Click mana: mana up · buff: buff up · charge: pulling here.")
    end
end

function previewControls.Create(parent, rowWidth)
    local scenarioRow = UIH.CreateFormRow(parent, rowWidth, 58)
    local scenarioLabel = scenarioRow:CreateFontString(
        nil, "ARTWORK", "GameFontHighlightSmall")
    scenarioLabel:SetPoint("TOPLEFT", scenarioRow, "TOPLEFT", 8, -6)
    scenarioLabel:SetText("Preview a five-player dungeon moment")
    local scenarios = D.PartyFramePreview.GetScenarios()
    local buttonWidth = math.floor((rowWidth - 16 - (#scenarios - 1) * 4) / #scenarios)
    for index, scenario in ipairs(scenarios) do
        local button = UIH.CreateButton(
            scenarioRow, scenario.label, buttonWidth, 22, "quiet")
        button:SetPoint("BOTTOMLEFT", scenarioRow, "BOTTOMLEFT",
            8 + (index - 1) * (buttonWidth + 4), 5)
        button:SetScript("OnClick", function()
            D.PartyFramePreview.SetScenario(scenario.key)
            RefreshPreviewControls()
        end)
        previewControls.buttons[scenario.key] = button
    end

    local actionRow = UIH.CreateFormRow(parent, rowWidth, 86)
    local channel = actionRow:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    channel:SetPoint("TOPLEFT", actionRow, "TOPLEFT", 8, -7)
    channel:SetTextColor(1, 0.78, 0.18)
    local text = actionRow:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", channel, "BOTTOMLEFT", 0, -4)
    text:SetPoint("BOTTOMRIGHT", actionRow, "BOTTOMRIGHT", -8, 7)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetWordWrap(true)
    previewControls.scenarioRow = scenarioRow
    previewControls.actionRow = actionRow
    previewControls.channel = channel
    previewControls.text = text
    D.PartyFramePreview.SetChangedCallback(RefreshPreviewControls)
end

local function Layout()
    local saved = D.GetSavedVariables() or {}
    local hotGlobal = D.IsHotEnabled()
    local disabled = saved.hotDisabled or {}
    local entries = {}

    for _, entry in ipairs(generalRows) do entry.frame:Hide() end
    for _, entry in ipairs(hotRows) do entry.row:Hide() end
    for _, frame in ipairs({
        behaviorSection, alertsSection, lowHealthSection, nameMentionsSection,
        dungeonBoardSection, displaySection, previewControls.section,
        threatAwarenessSection, hudDisplaysSection, hotSection, compatibilitySection, positionsSection, dangerSection,
        recoverySection, resetPartyFramesRow, resetSettingsRow, resetMinimapRow,
        cleanseResetRow, buffThanksResetRow,
        lfgAlertsResetRow, dungeonBoardResetRow,
        compatibilityRow, prepareDisableRow, factoryRow,
        previewControls.scenarioRow, previewControls.actionRow,
    }) do
        if frame then frame:Hide() end
    end

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
            elseif row.svKey == "mentionSoundKey" then
                row.frame.value:SetSelectedKey(D.MentionAlerts.GetSoundKey())
            elseif row.svKey == "dungeonBoardFeedEnabled" then
                SetCheckboxChecked(
                    row.frame.check, D.DungeonBoardSettings.GetFeedEnabled())
            elseif row.svKey == "dungeonBoardRole" then
                row.frame.value:SetSelectedKey(D.DungeonBoardSettings.GetRole())
            elseif row.svKey == "dungeonBoardSoundKey" then
                row.frame.value:SetSelectedKey(D.DungeonBoardSettings.GetSoundKey())
            elseif row.svKey == "threatAwarenessExplanation" then
                -- Static guidance for the signed tank-control meter.
            elseif row.svKey == "dungeonBoardLevelsBelow"
                or row.svKey == "dungeonBoardLevelsAbove"
            then
                local levelsBelow, levelsAbove = D.DungeonBoardSettings.GetLevelOffsets()
                local value = row.svKey == "dungeonBoardLevelsBelow"
                    and levelsBelow or levelsAbove
                local minOffset, maxOffset =
                    D.DungeonBoardSettings.GetLevelOffsetLimits()
                row.frame.value:SetText(tostring(value))
                if value > minOffset then
                    row.frame.decrease:Enable()
                else
                    row.frame.decrease:Disable()
                end
                if value < maxOffset then
                    row.frame.increase:Enable()
                else
                    row.frame.increase:Disable()
                end
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
            local supported = ApplySettingSupport(row)
            entries[#entries].height = supported and 32 or 40
        end
    end

    local unavailable = D.ClientCapabilities and D.ClientCapabilities.ListUnavailableFeatures() or {}
    local failures = D.ClientCapabilities and D.ClientCapabilities.ListRuntimeFailures() or {}
    local compatibilityVisible = #unavailable > 0 or #failures > 0
    if compatibilityVisible then
        local summary = {}
        if #unavailable > 0 then
            summary[#summary + 1] = tostring(#unavailable) .. " optional feature"
                .. (#unavailable == 1 and " is" or "s are") .. " unavailable on this client."
        end
        if #failures > 0 then
            summary[#summary + 1] = tostring(#failures) .. " feature initialization failure"
                .. (#failures == 1 and " was" or "s were") .. " isolated."
        end
        compatibilityLabel:SetText(table.concat(summary, " "))
        local details = {}
        for _, entry in ipairs(unavailable) do
            details[#details + 1] = entry.label .. ": " .. entry.reason
        end
        for _, failure in ipairs(failures) do
            details[#details + 1] = failure.owner .. ": " .. failure.reason
        end
        if UIH.SetUnavailableTooltip then
            UIH.SetUnavailableTooltip(compatibilityRow, table.concat(details, "\n"))
        end
    end

    if activePage == "frames" then
        entries[#entries + 1] = { frame = behaviorSection, height = 16, gap = 9 }
        addSetting("showAllSlots")
        addSetting("combatUIAutoHide")
        addSetting("hideUIErrors")
        entries[#entries + 1] = { frame = previewControls.section, height = 16, gap = 10 }
        addSetting("groupHelperEnabled")
        entries[#entries + 1] = { frame = previewControls.scenarioRow, height = 58 }
        entries[#entries + 1] = { frame = previewControls.actionRow, height = 86, gap = 3 }
        RefreshPreviewControls()
        entries[#entries + 1] = { frame = displaySection, height = 16, gap = 10 }
        addSetting("shieldEnabled")
        addSetting("incomingHealEnabled")
        addSetting("rangeCheckEnabled")
        addSetting("threatEnabled")
        addSetting("threatPercentEnabled")
        local threatMargin = generalRowsByKey.threatPercentEnabled
        local threatEnabled = D.IsSavedFeatureEnabled("threatEnabled")
        if threatMargin and GetSettingSupport("threatPercentEnabled") then
            if threatEnabled then
                threatMargin.frame.check:Enable()
                threatMargin.frame.label:SetTextColor(0.9, 0.9, 0.9)
            else
                threatMargin.frame.check:Disable()
                threatMargin.frame.label:SetTextColor(0.45, 0.45, 0.45)
            end
        end
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
                local supported, reason = GetSettingSupport("hotEnabled")
                if hotGlobal and supported then
                    entry.row.check:Enable()
                    entry.row.label:SetTextColor(0.9, 0.9, 0.9)
                else
                    entry.row.check:Disable()
                    entry.row.label:SetTextColor(0.45, 0.45, 0.45)
                end
                if UIH.SetControlAvailability then
                    UIH.SetControlAvailability(entry.row, entry.row.check, supported, reason)
                elseif UIH.SetUnavailableTooltip then
                    UIH.SetUnavailableTooltip(entry.row, supported and nil or reason)
                end
                entries[#entries].height = supported and 32 or 40
            end
        end
        entries[#entries + 1] = { frame = hudDisplaysSection, height = 16, gap = 10 }
        addSetting("actionFeedbackEnabled")
        addSetting("automaticConsumablesEnabled")
        entries[#entries + 1] = { frame = positionsSection, height = 16, gap = 10 }
        entries[#entries + 1] = { frame = resetPartyFramesRow, height = 32 }
        entries[#entries + 1] = { frame = resetSettingsRow, height = 32 }
        entries[#entries + 1] = { frame = resetMinimapRow, height = 32 }
    elseif activePage == "healthChat" then
        entries[#entries + 1] = { frame = lowHealthSection, height = 16, gap = 9 }
        addSetting("lowHealthThreshold")
        addSetting("lowHealthSoundKey")
        entries[#entries + 1] = { frame = nameMentionsSection, height = 16, gap = 10 }
        addSetting("mentionAlertsEnabled")
        addSetting("mentionSoundKey")
        addSetting("mentionHighlightEnabled")
    elseif activePage == "buffsCleanse" then
        entries[#entries + 1] = { frame = alertsSection, height = 16, gap = 9 }
        addSetting("cleanseWatchEnabled")
        addSetting("buffThanksEnabled")
        addSetting("partyBuffEnabled")
        addSetting("selfBuffEnabled")
        addSetting("selfBuffPreference")
        addSetting("clickableBuffIcons")
        entries[#entries + 1] = { frame = positionsSection, height = 16, gap = 10 }
        entries[#entries + 1] = { frame = cleanseResetRow, height = 32 }
        entries[#entries + 1] = { frame = buffThanksResetRow, height = 32 }
    elseif activePage == "threatControl" then
        entries[#entries + 1] = { frame = threatAwarenessSection, height = 16, gap = 9 }
        addSetting("threatAwarenessEnabled")
        addSetting("threatAwarenessExplanation")
    elseif activePage == "dungeon" then
        entries[#entries + 1] = { frame = dungeonBoardSection, height = 16, gap = 9 }
        addSetting("dungeonBoardRole")
        addSetting("dungeonBoardFeedEnabled")
        addSetting("dungeonBoardSoundKey")
        addSetting("dungeonBoardLevelsBelow")
        addSetting("dungeonBoardLevelsAbove")
        entries[#entries + 1] = { frame = positionsSection, height = 16, gap = 10 }
        entries[#entries + 1] = { frame = lfgAlertsResetRow, height = 32 }
        entries[#entries + 1] = { frame = dungeonBoardResetRow, height = 32 }
    else
        entries[#entries + 1] = {
            frame = compatibilitySection, height = 16, gap = 9,
            visible = compatibilityVisible,
        }
        entries[#entries + 1] = {
            frame = compatibilityRow, height = 42, visible = compatibilityVisible,
        }
        entries[#entries + 1] = { frame = recoverySection, height = 16, gap = 10 }
        entries[#entries + 1] = { frame = prepareDisableRow, height = 32 }
        entries[#entries + 1] = { frame = dangerSection, height = 16, gap = 12 }
        entries[#entries + 1] = { frame = factoryRow, height = 32 }
    end
    form.hint:SetText(PAGE_HINTS[activePage] or PAGE_HINTS.frames)
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

local function AddDungeonBoardFeedPreference()
    local frame = CreateCheckboxRow(
        form.content, "Show looking-for-group alerts", 0)
    AddGeneralRow(frame, "dungeonBoardFeedEnabled")
    frame.check:SetScript("OnClick", function(self)
        if refreshing then return end
        D.DungeonBoardSettings.SetFeedEnabled(self:GetChecked())
        D.RequestConfigRefresh()
    end)
end

local function AddDungeonBoardRolePreference()
    local frame = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", frame, "LEFT", 8, 0)
    label:SetWidth(155)
    label:SetJustifyH("LEFT")
    label:SetText("Watch for groups needing")

    local value = UIH.CreateDropdown(frame, 220, 22)
    value:SetOptions({
        { key = "healer", label = "Healer" },
        { key = "tank", label = "Tank" },
    })
    value:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    value:SetSelectionCallback(function(role)
        if refreshing then return end
        D.DungeonBoardSettings.SetRole(role)
        D.RequestConfigRefresh()
    end)

    frame.value = value
    frame.label = label
    AddGeneralRow(frame, "dungeonBoardRole")
end

local function AddThreatAwarenessExplanation()
    local frame = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", frame, "LEFT", 8, 0)
    label:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetText("Right is threat lead; left is effort to regain.")
    label:SetTextColor(0.65, 0.65, 0.68)
    frame.label = label
    AddGeneralRow(frame, "threatAwarenessExplanation")
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
    frame.label = label
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

local function AddMentionSoundPreference()
    local frame = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", frame, "LEFT", 8, 0)
    label:SetWidth(155)
    label:SetJustifyH("LEFT")
    label:SetText("Name mention sound")

    local value = UIH.CreateDropdown(frame, 220, 22)
    value:SetOptions(D.Sounds.GetOptions(true))
    value:SetArrowShown(false)
    value:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    value:SetSelectionCallback(function(soundKey)
        if refreshing then return end
        D.MentionAlerts.SetSoundKey(soundKey)
        D.MentionAlerts.PreviewSound()
        D.RequestConfigRefresh()
    end)

    frame.value = value
    AddGeneralRow(frame, "mentionSoundKey")
end

local function AddDungeonBoardSoundPreference()
    local frame = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", frame, "LEFT", 8, 0)
    label:SetWidth(155)
    label:SetJustifyH("LEFT")
    label:SetText("Dungeon Board sound")

    local value = UIH.CreateDropdown(frame, 220, 22)
    value:SetOptions(D.Sounds.GetOptions(true))
    value:SetArrowShown(false)
    value:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    value:SetSelectionCallback(function(soundKey)
        if refreshing then return end
        D.DungeonBoardSettings.SetSoundKey(soundKey)
        D.DungeonBoardSettings.PreviewSound()
        D.RequestConfigRefresh()
    end)

    frame.value = value
    AddGeneralRow(frame, "dungeonBoardSoundKey")
end

local function AddDungeonBoardLevelOffsetPreference(svKey, labelText, kind)
    local frame = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", frame, "LEFT", 8, 0)
    label:SetWidth(190)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)

    local increase = UIH.CreateButton(frame, "+1", 44, 22)
    increase:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    increase:SetScript("OnClick", function()
        if refreshing then return end
        D.DungeonBoardSettings.AdjustLevelOffset(kind, 1)
        D.RequestConfigRefresh()
    end)

    local value = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    value:SetPoint("RIGHT", increase, "LEFT", -4, 0)
    value:SetWidth(44)
    value:SetJustifyH("CENTER")

    local decrease = UIH.CreateButton(frame, "-1", 44, 22)
    decrease:SetPoint("RIGHT", value, "LEFT", -4, 0)
    decrease:SetScript("OnClick", function()
        if refreshing then return end
        D.DungeonBoardSettings.AdjustLevelOffset(kind, -1)
        D.RequestConfigRefresh()
    end)

    frame.decrease = decrease
    frame.value = value
    frame.increase = increase
    AddGeneralRow(frame, svKey)
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

function G.Create(parent, deps)
    if page then return page end
    assert(type(deps) == "table", "CoreSettingsPages requires dependencies")
    for _, key in ipairs({
        "ApplyAllSecureBindings", "ActionHud", "ApplyDefaultConfigPosition",
        "ApplyDefaultMinimapPosition", "ApplyDefaultPosition", "CombatUIFader",
        "FactoryReset", "ForceRefresh", "GetSavedVariables",
        "GetSelfBuffPreferenceKey", "GetSelfBuffPreferenceOptions",
        "HasKnownBuffReminder", "HealthAlerts", "MentionAlerts", "InitHotSpells", "IsHotEnabled",
        "IsHotTrackKnown", "IsPartyBuffKnown", "IsSavedFeatureEnabled",
        "IsSelfBuffKnown", "Print", "RequestConfigRefresh", "SetAddonEnabled",
        "SetHotTrackEnabled", "SetSavedFeature", "SetSelfBuffPreference", "Sounds",
        "SyncVisualTicker", "Threat", "ThreatAwareness", "ConsumableBar", "DungeonBoardSettings",
        "UIErrorSuppressor",
        "CleanseWatch", "BuffThanks", "GroupHelperRuntime", "PartyFramePreview",
    }) do
        assert(deps[key] ~= nil, "CoreSettingsPages missing dependency: " .. key)
    end
    D = deps

    page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_PAGE_SELECTOR_H + 4))
    page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)

    form = UIH.CreateFormScaffold(page, "ApogeePartyHealthBarsCoreSettingsPagesScroll",
        "Choose what the party bars show and how they behave.", false)

    behaviorSection = UIH.CreateFormSection(form.content, form.rowWidth, "Behavior")
    previewControls.section = UIH.CreateFormSection(
        form.content, form.rowWidth, "Dungeon leadership")
    alertsSection = UIH.CreateFormSection(form.content, form.rowWidth, "Alerts and reminders")
    lowHealthSection = UIH.CreateFormSection(form.content, form.rowWidth, "Low Health")
    nameMentionsSection = UIH.CreateFormSection(form.content, form.rowWidth, "Name Mentions")
    dungeonBoardSection = UIH.CreateFormSection(form.content, form.rowWidth, "Dungeon Board")
    displaySection = UIH.CreateFormSection(form.content, form.rowWidth, "Frame details")
    threatAwarenessSection = UIH.CreateFormSection(form.content, form.rowWidth, "Tank threat control")
    hudDisplaysSection = UIH.CreateFormSection(form.content, form.rowWidth, "HUD displays")
    hotSection = UIH.CreateFormSection(form.content, form.rowWidth, "Tracked heal-over-time effects")
    compatibilitySection = UIH.CreateFormSection(form.content, form.rowWidth,
        "Client compatibility")
    positionsSection = UIH.CreateFormSection(form.content, form.rowWidth, "Positions")
    recoverySection = UIH.CreateFormSection(form.content, form.rowWidth, "Recovery")
    dangerSection = UIH.CreateFormSection(form.content, form.rowWidth, "Danger Zone")
    dangerSection.label:SetTextColor(1, 0.45, 0.38)
    if dangerSection.rule then dangerSection.rule:SetColorTexture(0.62, 0.16, 0.14, 0.85) end

    AddCheckbox("Show all 5 party frames while solo", "showAllSlots")
    AddCheckbox("Fade selected Blizzard HUD elements in combat", "combatUIAutoHide", function()
        local saved = D.GetSavedVariables()
        D.CombatUIFader.ApplyEnabledState(saved and saved.combatUIAutoHide)
    end)
    AddCheckbox("Hide Blizzard UI error messages", "hideUIErrors", function()
        local saved = D.GetSavedVariables()
        D.UIErrorSuppressor.ApplyEnabledState(saved and saved.hideUIErrors)
    end)
    AddCheckbox("Show brief action feedback text", "actionFeedbackEnabled", function()
        D.ActionHud.Clear()
    end)
    AddCheckbox("Show Group Helper companion", "groupHelperEnabled", function()
        D.GroupHelperRuntime.Refresh()
    end)
    AddCheckbox("Show automatic consumables from carried bags", "automaticConsumablesEnabled", function()
        local saved = D.GetSavedVariables()
        D.ConsumableBar.SetEnabled(saved and saved.automaticConsumablesEnabled)
    end)
    AddLowHealthThresholdPreference()
    AddLowHealthSoundPreference()
    AddCheckbox("Alert when chat mentions my character", "mentionAlertsEnabled")
    AddMentionSoundPreference()
    AddCheckbox("Highlight my character name in chat", "mentionHighlightEnabled")
    AddCheckbox("Show Cleanse Watch for removable party debuffs", "cleanseWatchEnabled", function()
        D.CleanseWatch.RefreshCapabilities()
    end)
    AddCheckbox("Enable Thank You prompts for lasting buffs and player cleanses",
        "buffThanksEnabled", function()
            D.BuffThanks.Refresh()
        end)
    AddDungeonBoardRolePreference()
    AddDungeonBoardFeedPreference()
    AddDungeonBoardSoundPreference()
    AddDungeonBoardLevelOffsetPreference(
        "dungeonBoardLevelsBelow", "Levels below your character", "below")
    AddDungeonBoardLevelOffsetPreference(
        "dungeonBoardLevelsAbove", "Levels above your character", "above")
    AddCheckbox("Show missing party-buff reminders", "partyBuffEnabled")
    AddCheckbox("Show missing self-buff or aura reminder", "selfBuffEnabled")
    AddSelfBuffPreference()
    AddCheckbox("Click a buff reminder to cast it", "clickableBuffIcons", function()
        D.ApplyAllSecureBindings()
    end)
    AddCheckbox("Show shield amount", "shieldEnabled")
    AddCheckbox("Show incoming healing", "incomingHealEnabled")
    AddCheckbox("Fade out-of-range party members", "rangeCheckEnabled")
    local function refreshThreatSetting()
        D.Threat.Refresh()
        D.SyncVisualTicker()
    end
    AddCheckbox("Show party threat status", "threatEnabled", refreshThreatSetting)
    AddCheckbox("Show threat margin for the current target", "threatPercentEnabled", refreshThreatSetting)
    AddCheckbox("Show Tank Threat Control HUD", "threatAwarenessEnabled", function()
        D.ThreatAwareness.Refresh()
        D.SyncVisualTicker()
    end)
    AddThreatAwarenessExplanation()
    AddCheckbox("Show each party member's target", "showUnitTargets")
    AddCheckbox("Show heal-over-time duration bars", "hotEnabled", D.InitHotSpells)

    previewControls.Create(form.content, form.rowWidth)

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

    compatibilityRow = UIH.CreateFormRow(form.content, form.rowWidth, 42)
    compatibilityLabel = compatibilityRow:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    compatibilityLabel:SetPoint("TOPLEFT", compatibilityRow, "TOPLEFT", 8, -7)
    compatibilityLabel:SetPoint("BOTTOMRIGHT", compatibilityRow, "BOTTOMRIGHT", -8, 7)
    compatibilityLabel:SetJustifyH("LEFT")
    compatibilityLabel:SetJustifyV("MIDDLE")
    compatibilityLabel:SetWordWrap(true)
    compatibilityLabel:SetTextColor(1, 0.65, 0.2)

    local function CreatePositionResetRow(labelText)
        local row = UIH.CreateFormRow(form.content, form.rowWidth, 32)
        local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        label:SetPoint("LEFT", row, "LEFT", 8, 0)
        label:SetText(labelText)
        local button = UIH.CreateButton(row, "Reset", 86, 22)
        button:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        return row, button
    end

    resetPartyFramesRow, resetButtons.bar = CreatePositionResetRow("Party Frames")
    resetButtons.bar:SetScript("OnClick", function()
        D.ApplyDefaultPosition()
        D.ForceRefresh()
    end)

    resetSettingsRow, resetButtons.settings = CreatePositionResetRow("Settings Window")
    resetButtons.settings:SetScript("OnClick", D.ApplyDefaultConfigPosition)

    resetMinimapRow, resetButtons.minimap = CreatePositionResetRow("Minimap Button")
    resetButtons.minimap:SetScript("OnClick", D.ApplyDefaultMinimapPosition)

    cleanseResetRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local cleanseResetLabel = cleanseResetRow:CreateFontString(
        nil, "ARTWORK", "GameFontHighlightSmall")
    cleanseResetLabel:SetPoint("LEFT", cleanseResetRow, "LEFT", 8, 0)
    cleanseResetLabel:SetText("Cleanse Watch panel")
    local cleanseResetButton = UIH.CreateButton(
        cleanseResetRow, "Reset Position", 126, 22)
    cleanseResetButton:SetPoint("RIGHT", cleanseResetRow, "RIGHT", -5, 0)
    cleanseResetButton:SetScript("OnClick", function()
        D.CleanseWatch.ResetPosition()
        D.CleanseWatch.Refresh()
    end)

    buffThanksResetRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local buffThanksResetLabel = buffThanksResetRow:CreateFontString(
        nil, "ARTWORK", "GameFontHighlightSmall")
    buffThanksResetLabel:SetPoint("LEFT", buffThanksResetRow, "LEFT", 8, 0)
    buffThanksResetLabel:SetText("Thank You prompts")
    resetButtons.buffThanks = UIH.CreateButton(
        buffThanksResetRow, "Reset Position", 126, 22)
    resetButtons.buffThanks:SetPoint("RIGHT", buffThanksResetRow, "RIGHT", -5, 0)
    resetButtons.buffThanks:SetScript("OnClick", function()
        D.BuffThanks.ResetPosition()
        D.BuffThanks.Refresh()
    end)

    lfgAlertsResetRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local lfgAlertsResetLabel = lfgAlertsResetRow:CreateFontString(
        nil, "ARTWORK", "GameFontHighlightSmall")
    lfgAlertsResetLabel:SetPoint("LEFT", lfgAlertsResetRow, "LEFT", 8, 0)
    lfgAlertsResetLabel:SetText("LFG Alerts")
    resetButtons.lfgAlerts = UIH.CreateButton(
        lfgAlertsResetRow, "Reset Position", 126, 22)
    resetButtons.lfgAlerts:SetPoint("RIGHT", lfgAlertsResetRow, "RIGHT", -5, 0)
    resetButtons.lfgAlerts:SetScript("OnClick", D.DungeonBoardFeed.ResetPosition)

    dungeonBoardResetRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local dungeonBoardResetLabel = dungeonBoardResetRow:CreateFontString(
        nil, "ARTWORK", "GameFontHighlightSmall")
    dungeonBoardResetLabel:SetPoint("LEFT", dungeonBoardResetRow, "LEFT", 8, 0)
    dungeonBoardResetLabel:SetText("Dungeon Board")
    resetButtons.dungeonBoard = UIH.CreateButton(
        dungeonBoardResetRow, "Reset Position", 126, 22)
    resetButtons.dungeonBoard:SetPoint("RIGHT", dungeonBoardResetRow, "RIGHT", -5, 0)
    resetButtons.dungeonBoard:SetScript("OnClick", D.DungeonBoardUI.ResetPosition)

    prepareDisableRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local prepareDisableLabel = prepareDisableRow:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    prepareDisableLabel:SetPoint("LEFT", prepareDisableRow, "LEFT", 8, 0)
    prepareDisableLabel:SetText("Restore keyboard, wheel, and mouse button bindings")
    resetButtons.prepareDisable = UIH.CreateButton(prepareDisableRow, "Restore All", 118, 22)
    resetButtons.prepareDisable:SetPoint("RIGHT", prepareDisableRow, "RIGHT", -5, 0)
    prepareDisableLabel:SetPoint("RIGHT", resetButtons.prepareDisable, "LEFT", -8, 0)
    prepareDisableLabel:SetJustifyH("LEFT")
    prepareDisableLabel:SetWordWrap(false)
    resetButtons.prepareDisable:SetScript("OnClick", function()
        if not prepareDisableArmed then
            prepareDisableArmed = true
            prepareDisableToken = prepareDisableToken + 1
            local token = prepareDisableToken
            resetButtons.prepareDisable.label:SetText("Confirm Restore")
            if C_Timer and C_Timer.After then
                C_Timer.After(5, function()
                    if prepareDisableToken == token then DisarmPrepareDisable() end
                end)
            end
            return
        end

        DisarmPrepareDisable()
        if D.SetAddonEnabled(false) then
            D.Print("Keyboard, Mouse Wheel, and Mouse Buttons bindings restored. You can now disable the addon in WoW's AddOns manager.")
        end
    end)

    factoryRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local factoryLabel = factoryRow:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    factoryLabel:SetPoint("LEFT", factoryRow, "LEFT", 8, 0)
    factoryLabel:SetText("Erase this character's profiles and settings")
    resetButtons.factory = UIH.CreateButton(factoryRow, "Reset Character", 126, 22, "danger")
    resetButtons.factory:SetPoint("RIGHT", factoryRow, "RIGHT", -5, 0)
    resetButtons.factory:SetScript("OnClick", function()
        if not factoryResetArmed then
            factoryResetArmed = true
            factoryResetToken = factoryResetToken + 1
            local token = factoryResetToken
            resetButtons.factory.label:SetText("Confirm Erase")
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

    return page
end

function G.Refresh()
    if not page then return end
    refreshing = true
    Layout()
    refreshing = false
end

function G.SetPage(pageKey)
    if not PAGE_HINTS[pageKey] then pageKey = "frames" end
    activePage = pageKey
    G.Refresh()
end

function G.GetPage()
    return activePage
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
        bar = resetButtons.bar,
        settings = resetButtons.settings,
        minimap = resetButtons.minimap,
        buffThanks = resetButtons.buffThanks,
        lfgAlerts = resetButtons.lfgAlerts,
        dungeonBoard = resetButtons.dungeonBoard,
        prepareDisable = resetButtons.prepareDisable,
        factory = resetButtons.factory,
    }
end

G.GetFrame = function() return page end
G.GetPrepareDisableButton = function() return resetButtons.prepareDisable end
G.GetFactoryResetButton = function() return resetButtons.factory end
G.GetForm = function() return form end
G.GetPreviewControls = function() return previewControls end
