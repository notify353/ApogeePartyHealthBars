local C = ApogeePartyHealthBars_C
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_ThreatControlSettingsPage = {}
local Page = ApogeePartyHealthBars_ThreatControlSettingsPage

local D, page, form
local rows = {}
local cooldownRows = {}
local enabledRow, remindersRow, defaultRow, spellSection, cooldownsRow, cooldownSection
local refreshing = false

local function setChecked(check, value)
    local script = check:GetScript("OnClick")
    check:SetScript("OnClick", nil); check:SetChecked(value); check:SetScript("OnClick", script)
end

local function checkboxRow(parent, labelText)
    local row = UIH.CreateFormRow(parent, form.rowWidth, 32)
    local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    check:SetSize(22, 22); check:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", row, "LEFT", 8, 0); label:SetPoint("RIGHT", check, "LEFT", -5, 0)
    label:SetJustifyH("LEFT"); label:SetText(labelText)
    row.check, row.label = check, label
    if UIH.PrepareAvailabilityRow then UIH.PrepareAvailabilityRow(row, label, check, 8) end
    return row
end

local function stepperRow(parent, labelText)
    local row = UIH.CreateFormRow(parent, form.rowWidth, 32)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", row, "LEFT", 8, 0); label:SetText(labelText)
    local down = UIH.CreateButton(row, "-", 28, 22)
    local value = UIH.CreateButton(row, "3s", 54, 22)
    local up = UIH.CreateButton(row, "+", 28, 22)
    up:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    value:SetPoint("RIGHT", up, "LEFT", -4, 0)
    down:SetPoint("RIGHT", value, "LEFT", -4, 0)
    row.label, row.decrease, row.value, row.increase = label, down, value, up
    return row
end

local function createSpellRow(parent, index)
    local row = UIH.CreateFormRow(parent, form.rowWidth, 42)
    local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    check:SetSize(22, 22); check:SetPoint("LEFT", row, "LEFT", 4, 0)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", check, "RIGHT", 2, 0); label:SetJustifyH("LEFT")
    local upPriority = UIH.CreateArrowButton(row, "up", 34, 22)
    local downPriority = UIH.CreateArrowButton(row, "down", 34, 22)
    downPriority:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    upPriority:SetPoint("RIGHT", downPriority, "LEFT", -3, 0)
    label:SetPoint("RIGHT", upPriority, "LEFT", -5, 0)
    UIH.SetTooltip(upPriority, "Move earlier",
        "Give this reminder higher priority in the on-screen order.")
    UIH.SetTooltip(downPriority, "Move later",
        "Give this reminder lower priority in the on-screen order.")
    row.check, row.label, row.up, row.down = check, label, upPriority, downPriority
    check:SetScript("OnClick", function(self)
        if refreshing or not row.key then return end
        D.TargetEffectTracker.SetEnabled(row.key, self:GetChecked())
        Page.Refresh()
    end)
    upPriority:SetScript("OnClick", function() if row.key then D.TargetEffectTracker.Move(row.key, -1); Page.Refresh() end end)
    downPriority:SetScript("OnClick", function() if row.key then D.TargetEffectTracker.Move(row.key, 1); Page.Refresh() end end)
    rows[index] = row
    return row
end

local function createCooldownRow(parent, index)
    local row = UIH.CreateFormRow(parent, form.rowWidth, 42)
    local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    check:SetSize(22, 22); check:SetPoint("LEFT", row, "LEFT", 4, 0)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", check, "RIGHT", 2, 0); label:SetJustifyH("LEFT")
    local upPriority = UIH.CreateArrowButton(row, "up", 34, 22)
    local downPriority = UIH.CreateArrowButton(row, "down", 34, 22)
    downPriority:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    upPriority:SetPoint("RIGHT", downPriority, "LEFT", -3, 0)
    label:SetPoint("RIGHT", upPriority, "LEFT", -5, 0)
    UIH.SetTooltip(upPriority, "Move earlier",
        "Place this cooldown closer to the player bars.")
    UIH.SetTooltip(downPriority, "Move later",
        "Place this cooldown farther from the player bars.")
    row.check, row.label, row.up, row.down = check, label, upPriority, downPriority
    check:SetScript("OnClick", function(self)
        if refreshing or not row.key then return end
        local changed, reason = D.CooldownTracker.SetEnabled(row.key, self:GetChecked())
        if not changed and reason and UIErrorsFrame and UIErrorsFrame.AddMessage then
            UIErrorsFrame:AddMessage(reason, 1, 0.35, 0.2)
        end
        Page.Refresh()
    end)
    upPriority:SetScript("OnClick", function()
        if row.key then D.CooldownTracker.Move(row.key, -1); Page.Refresh() end
    end)
    downPriority:SetScript("OnClick", function()
        if row.key then D.CooldownTracker.Move(row.key, 1); Page.Refresh() end
    end)
    cooldownRows[index] = row
    return row
end

function Page.Refresh()
    if not page then return end
    refreshing = true
    local saved = D.GetSavedVariables() or {
        targetEffectRemindersEnabled = true,
        targetEffectRefreshThreshold = 3,
    }
    local hudSupported = D.ClientCapabilities.IsFeatureAvailable("threat")
    local effectsSupported = D.ClientCapabilities.IsFeatureAvailable("targetEffectReminders")
    local cooldownsSupported = D.ClientCapabilities.IsFeatureAvailable("abilityCooldowns")
    local hudUnavailableReason = not hudSupported
        and D.ClientCapabilities.GetFeatureReason("threat") or nil
    local effectsUnavailableReason = not effectsSupported
        and D.ClientCapabilities.GetFeatureReason("targetEffectReminders") or nil
    local cooldownsUnavailableReason = not cooldownsSupported
        and D.ClientCapabilities.GetFeatureReason("abilityCooldowns") or nil
    if UIH.SetControlAvailability then
        UIH.SetControlAvailability(enabledRow, enabledRow.check, hudSupported, hudUnavailableReason)
    else
        if hudSupported then enabledRow.check:Enable() else enabledRow.check:Disable() end
        UIH.SetUnavailableTooltip(enabledRow, hudUnavailableReason)
    end
    defaultRow.value.label:SetText(tostring(saved.targetEffectRefreshThreshold) .. "s")
    if effectsSupported then
        defaultRow.decrease:Enable()
        defaultRow.increase:Enable()
    else
        defaultRow.decrease:Disable()
        defaultRow.increase:Disable()
    end
    local timerColor = effectsSupported and 0.90 or 0.55
    defaultRow.label:SetTextColor(timerColor, timerColor, timerColor)
    UIH.SetUnavailableTooltip(defaultRow, effectsUnavailableReason)

    setChecked(enabledRow.check, saved.threatAwarenessEnabled == true)
    setChecked(remindersRow.check, saved.targetEffectRemindersEnabled == true)
    setChecked(cooldownsRow.check, saved.abilityCooldownsEnabled ~= false)
    if UIH.SetControlAvailability then
        UIH.SetControlAvailability(remindersRow, remindersRow.check,
            effectsSupported, effectsUnavailableReason)
    elseif effectsSupported then
        remindersRow.check:Enable()
    else
        remindersRow.check:Disable()
    end
    if UIH.SetControlAvailability then
        UIH.SetControlAvailability(cooldownsRow, cooldownsRow.check,
            cooldownsSupported, cooldownsUnavailableReason)
    elseif cooldownsSupported then cooldownsRow.check:Enable() else cooldownsRow.check:Disable() end
    local known = D.TargetEffectTracker.GetKnownFamilies()
    local entries = {
        { frame = enabledRow, height = hudSupported and 32 or 40 },
        { frame = remindersRow, height = effectsSupported and 32 or 40 },
        { frame = defaultRow, height = 32 },
        { frame = spellSection, height = 16, gap = 10 },
    }
    for index, entry in ipairs(known) do
        local row = rows[index] or createSpellRow(form.content, index)
        row.key = entry.definition.key
        row.label:SetText(entry.label)
        setChecked(row.check, D.TargetEffectTracker.IsEnabled(row.key))
        if effectsSupported and index > 1 then row.up:Enable() else row.up:Disable() end
        if effectsSupported and index < #known then row.down:Enable() else row.down:Disable() end
        if effectsSupported and saved.targetEffectRemindersEnabled then row.check:Enable() else row.check:Disable() end
        local rowColor = effectsSupported and 0.90 or 0.55
        row.label:SetTextColor(rowColor, rowColor, rowColor)
        UIH.SetUnavailableTooltip(row, effectsUnavailableReason)
        entries[#entries + 1] = { frame = row, height = 42 }
    end
    for index = #known + 1, #rows do rows[index]:Hide() end
    entries[#entries + 1] = { frame = cooldownSection, height = 16, gap = 10 }
    entries[#entries + 1] = {
        frame = cooldownsRow, height = cooldownsSupported and 32 or 40,
    }
    local cooldownKnown = D.CooldownTracker.GetKnownFamilies()
    local selectedCount = D.CooldownTracker.GetSelectedCount()
    local selectedPosition = 0
    for index, entry in ipairs(cooldownKnown) do
        local row = cooldownRows[index] or createCooldownRow(form.content, index)
        local selected = D.CooldownTracker.IsEnabled(entry.definition.key)
        if selected then selectedPosition = selectedPosition + 1 end
        row.key = entry.definition.key
        row.label:SetText(entry.label)
        setChecked(row.check, selected)
        local canToggle = cooldownsSupported and saved.abilityCooldownsEnabled ~= false
            and (selected or selectedCount < 6)
        if canToggle then row.check:Enable() else row.check:Disable() end
        local canReorder = cooldownsSupported and saved.abilityCooldownsEnabled ~= false
        if canReorder and selected and selectedPosition > 1 then row.up:Enable()
        else row.up:Disable() end
        if canReorder and selected and selectedPosition < selectedCount then row.down:Enable()
        else row.down:Disable() end
        local reason = cooldownsUnavailableReason
        if not reason and not selected and selectedCount >= 6 then
            reason = "Up to six cooldowns can be selected. Disable one before adding another."
        end
        UIH.SetUnavailableTooltip(row, reason)
        entries[#entries + 1] = { frame = row, height = 42 }
    end
    for index = #cooldownKnown + 1, #cooldownRows do cooldownRows[index]:Hide() end
    UIH.LayoutForm(form, entries)
    refreshing = false
end

function Page.Create(parent, deps)
    D = deps
    page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_PAGE_SELECTOR_H + 4))
    page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    page:Hide()
    form = UIH.CreateFormScaffold(page, "ApogeePartyHealthBarsThreatControlSettingsPageScroll",
        "Show maintained effects, player status, ability cooldowns, and multi-enemy threat in one fixed HUD.", false)
    enabledRow = checkboxRow(form.content, "Show Tank Threat Control HUD")
    remindersRow = checkboxRow(form.content, "Show maintained-effect reminders")
    defaultRow = stepperRow(form.content, "Remind when this much time remains")
    defaultRow.decrease:SetScript("OnClick", function() D.TargetEffectTracker.AdjustThreshold(-1); Page.Refresh() end)
    defaultRow.increase:SetScript("OnClick", function() D.TargetEffectTracker.AdjustThreshold(1); Page.Refresh() end)
    enabledRow.check:SetScript("OnClick", function(self)
        if refreshing then return end
        local saved = D.GetSavedVariables()
        saved.threatAwarenessEnabled = self:GetChecked() == true
        D.ThreatAwareness.Refresh()
        Page.Refresh()
    end)
    remindersRow.check:SetScript("OnClick", function(self)
        if refreshing then return end
        D.TargetEffectTracker.SetFeatureEnabled(self:GetChecked())
        Page.Refresh()
    end)
    spellSection = UIH.CreateFormSection(form.content, form.rowWidth,
        "Learned target effects — enablement and priority")
    cooldownSection = UIH.CreateFormSection(form.content, form.rowWidth,
        "Ability Cooldowns — up to 6 learned class or pet spells")
    cooldownsRow = checkboxRow(form.content, "Show Ability Cooldowns")
    cooldownsRow.check:SetScript("OnClick", function(self)
        if refreshing then return end
        D.CooldownTracker.SetFeatureEnabled(self:GetChecked())
        Page.Refresh()
    end)
    Page.Refresh()
    return page
end

function Page.GetRows() return rows end
function Page.GetForm() return form end
function Page.GetEnabledRow() return enabledRow end
function Page.GetRemindersRow() return remindersRow end
function Page.GetDefaultRow() return defaultRow end
function Page.GetCooldownRows() return cooldownRows end
function Page.GetCooldownsRow() return cooldownsRow end
