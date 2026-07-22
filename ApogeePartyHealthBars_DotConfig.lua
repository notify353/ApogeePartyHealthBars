local C = ApogeePartyHealthBars_C
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_DotConfig = {}
local DC = ApogeePartyHealthBars_DotConfig

local D, tab, form
local rows = {}
local enabledRow, defaultRow, resetRow, spellSection
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
    label:SetPoint("LEFT", check, "RIGHT", 2, 0); label:SetWidth(126); label:SetJustifyH("LEFT")
    local upPriority = UIH.CreateButton(row, "Up", 34, 22)
    upPriority:SetPoint("LEFT", label, "RIGHT", 3, 0)
    local downPriority = UIH.CreateButton(row, "Dn", 34, 22)
    downPriority:SetPoint("LEFT", upPriority, "RIGHT", 3, 0)
    local threshold = UIH.CreateButton(row, "3s", 43, 22)
    threshold:SetPoint("RIGHT", row, "RIGHT", -65, 0)
    local minus = UIH.CreateButton(row, "-", 25, 22)
    minus:SetPoint("RIGHT", threshold, "LEFT", -3, 0)
    local plus = UIH.CreateButton(row, "+", 25, 22)
    plus:SetPoint("LEFT", threshold, "RIGHT", 3, 0)
    local reset = UIH.CreateButton(row, "D", 24, 22)
    reset:SetPoint("LEFT", plus, "RIGHT", 3, 0)
    row.check, row.label, row.up, row.down = check, label, upPriority, downPriority
    row.threshold, row.minus, row.plus, row.reset = threshold, minus, plus, reset
    check:SetScript("OnClick", function(self)
        if refreshing or not row.key then return end
        D.DotTracker.SetEnabled(row.key, self:GetChecked())
        DC.Refresh()
    end)
    upPriority:SetScript("OnClick", function() if row.key then D.DotTracker.Move(row.key, -1); DC.Refresh() end end)
    downPriority:SetScript("OnClick", function() if row.key then D.DotTracker.Move(row.key, 1); DC.Refresh() end end)
    minus:SetScript("OnClick", function() if row.key then D.DotTracker.AdjustThreshold(row.key, -1); DC.Refresh() end end)
    plus:SetScript("OnClick", function() if row.key then D.DotTracker.AdjustThreshold(row.key, 1); DC.Refresh() end end)
    reset:SetScript("OnClick", function() if row.key then D.DotTracker.ResetThreshold(row.key); DC.Refresh() end end)
    rows[index] = row
    return row
end

function DC.Refresh()
    if not tab then return end
    refreshing = true
    local saved = D.GetSavedVariables() or {
        dotRemindersEnabled = true,
        dotRefreshThreshold = 3,
    }
    local supported = D.ClientCapabilities.IsFeatureAvailable("dotReminders")
    setChecked(enabledRow.check, saved.dotRemindersEnabled == true)
    if supported then enabledRow.check:Enable() else enabledRow.check:Disable() end
    UIH.SetUnavailableTooltip(enabledRow, supported and nil
        or D.ClientCapabilities.GetFeatureReason("dotReminders"))
    defaultRow.value.label:SetText(tostring(saved.dotRefreshThreshold) .. "s")

    local known = D.DotTracker.GetKnownFamilies()
    local entries = {
        { frame = enabledRow, height = 32 },
        { frame = defaultRow, height = 32 },
        { frame = resetRow, height = 32 },
        { frame = spellSection, height = 16, gap = 10 },
    }
    for index, entry in ipairs(known) do
        local row = rows[index] or createSpellRow(form.content, index)
        row.key = entry.definition.key
        row.label:SetText(entry.label)
        setChecked(row.check, D.DotTracker.IsEnabled(row.key))
        row.threshold.label:SetText(tostring(D.DotTracker.GetThreshold(row.key)) .. "s")
        row.reset.label:SetText(D.DotTracker.HasThresholdOverride(row.key) and "D*" or "D")
        if index > 1 then row.up:Enable() else row.up:Disable() end
        if index < #known then row.down:Enable() else row.down:Disable() end
        if supported and saved.dotRemindersEnabled then row.check:Enable() else row.check:Disable() end
        entries[#entries + 1] = { frame = row, height = 42 }
    end
    for index = #known + 1, #rows do rows[index]:Hide() end
    UIH.LayoutForm(form, entries)
    refreshing = false
end

function DC.Build(parent, deps)
    D = deps
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()
    form = UIH.CreateFormScaffold(tab, "ApogeePartyHealthBarsDotConfigScroll",
        "Show passive reminders for usable DoTs missing from your hostile target.", false)
    enabledRow = checkboxRow(form.content, "Enable DoT reminders")
    defaultRow = stepperRow(form.content, "Default refresh threshold")
    defaultRow.decrease:SetScript("OnClick", function() D.DotTracker.AdjustDefaultThreshold(-1); DC.Refresh() end)
    defaultRow.increase:SetScript("OnClick", function() D.DotTracker.AdjustDefaultThreshold(1); DC.Refresh() end)
    enabledRow.check:SetScript("OnClick", function(self)
        if refreshing then return end
        D.DotTracker.SetFeatureEnabled(self:GetChecked()); DC.Refresh()
    end)
    resetRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local reset = UIH.CreateButton(resetRow, "Reset HUD Position", 150, 22)
    reset:SetPoint("LEFT", resetRow, "LEFT", 8, 0)
    reset:SetScript("OnClick", function() D.DotHud.ResetPosition() end)
    local hint = resetRow:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("LEFT", reset, "RIGHT", 8, 0); hint:SetText("Drag while settings are open")
    spellSection = UIH.CreateFormSection(form.content, form.rowWidth, "Known DoTs — priority and threshold")
    DC.Refresh()
    return tab
end

function DC.GetRows() return rows end
function DC.GetForm() return form end
