local C = ApogeePartyHealthBars_C
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_TargetEffectsSettingsPage = {}
local DC = ApogeePartyHealthBars_TargetEffectsSettingsPage

local D, page, form
local rows = {}
local enabledRow, defaultRow, previewRow, spellSection
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
        DC.Refresh()
    end)
    upPriority:SetScript("OnClick", function() if row.key then D.TargetEffectTracker.Move(row.key, -1); DC.Refresh() end end)
    downPriority:SetScript("OnClick", function() if row.key then D.TargetEffectTracker.Move(row.key, 1); DC.Refresh() end end)
    rows[index] = row
    return row
end

function DC.Refresh()
    if not page then return end
    refreshing = true
    local saved = D.GetSavedVariables() or {
        targetEffectRemindersEnabled = true,
        targetEffectRefreshThreshold = 3,
    }
    local supported = D.ClientCapabilities.IsFeatureAvailable("targetEffectReminders")
    setChecked(enabledRow.check, saved.targetEffectRemindersEnabled == true)
    local unavailableReason = not supported
        and D.ClientCapabilities.GetFeatureReason("targetEffectReminders") or nil
    if UIH.SetControlAvailability then
        UIH.SetControlAvailability(enabledRow, enabledRow.check, supported, unavailableReason)
    else
        if supported then enabledRow.check:Enable() else enabledRow.check:Disable() end
        UIH.SetUnavailableTooltip(enabledRow, unavailableReason)
    end
    defaultRow.value.label:SetText(tostring(saved.targetEffectRefreshThreshold) .. "s")

    local known = D.TargetEffectTracker.GetKnownFamilies()
    local entries = {
        { frame = enabledRow, height = supported and 32 or 40 },
        { frame = defaultRow, height = 32 },
        { frame = previewRow, height = 50 },
        { frame = spellSection, height = 16, gap = 10 },
    }
    for index, entry in ipairs(known) do
        local row = rows[index] or createSpellRow(form.content, index)
        row.key = entry.definition.key
        row.label:SetText(entry.label)
        setChecked(row.check, D.TargetEffectTracker.IsEnabled(row.key))
        if index > 1 then row.up:Enable() else row.up:Disable() end
        if index < #known then row.down:Enable() else row.down:Disable() end
        if supported and saved.targetEffectRemindersEnabled then row.check:Enable() else row.check:Disable() end
        entries[#entries + 1] = { frame = row, height = 42 }
    end
    for index = #known + 1, #rows do rows[index]:Hide() end
    UIH.LayoutForm(form, entries)
    refreshing = false
end

function DC.Create(parent, deps)
    D = deps
    page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_PAGE_SELECTOR_H + 4))
    page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    page:Hide()
    form = UIH.CreateFormScaffold(page, "ApogeePartyHealthBarsTargetEffectsSettingsPageScroll",
        "Show missing or expiring maintained effects above the visible target nameplate.", false)
    enabledRow = checkboxRow(form.content, "Enable target-effect reminders")
    defaultRow = stepperRow(form.content, "Remind when this much time remains")
    defaultRow.decrease:SetScript("OnClick", function() D.TargetEffectTracker.AdjustThreshold(-1); DC.Refresh() end)
    defaultRow.increase:SetScript("OnClick", function() D.TargetEffectTracker.AdjustThreshold(1); DC.Refresh() end)
    enabledRow.check:SetScript("OnClick", function(self)
        if refreshing then return end
        D.TargetEffectTracker.SetFeatureEnabled(self:GetChecked()); DC.Refresh()
    end)
    previewRow = UIH.CreateFormRow(form.content, form.rowWidth, 50)
    local previewLabel = previewRow:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    previewLabel:SetPoint("TOP", previewRow, "TOP", 0, -4)
    previewLabel:SetText("Nameplate reminder preview")
    local preview = D.TargetEffectHud.CreateConfigurationPreview(previewRow)
    preview:SetPoint("BOTTOM", previewRow, "BOTTOM", 0, 4)
    previewRow.preview = preview
    spellSection = UIH.CreateFormSection(form.content, form.rowWidth,
        "Learned target effects — enablement and priority")
    DC.Refresh()
    return page
end

function DC.GetRows() return rows end
function DC.GetForm() return form end
function DC.GetPreviewRow() return previewRow end
