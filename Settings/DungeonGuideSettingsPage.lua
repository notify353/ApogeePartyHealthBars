local C = ApogeePartyHealthBars_C
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_DungeonGuideSettingsPage = {}
local P = ApogeePartyHealthBars_DungeonGuideSettingsPage
local D, page, form, enabledRow, openRow, resetRow
local refreshing

local function setChecked(check, value)
    local script = check:GetScript("OnClick")
    check:SetScript("OnClick", nil); check:SetChecked(value); check:SetScript("OnClick", script)
end

function P.Refresh()
    if not page then return end
    refreshing = true
    local enabled = D.DungeonGuideSettings.GetAutoMarkEnabled()
    setChecked(enabledRow.check, enabled)
    refreshing = false
end

function P.Create(parent, deps)
    D = deps
    page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_PAGE_SELECTOR_H + 4))
    page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    page:Hide()
    form = UIH.CreateFormScaffold(page, "ApogeePartyHealthBarsDungeonGuideSettingsPageScroll",
        "Learn the strategy in the Book, then let target changes apply its raid marks.", false)
    enabledRow = UIH.CreateFormRow(form.content, form.rowWidth, 38)
    local label = enabledRow:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", enabledRow, "LEFT", 8, 0); label:SetText("Enable automatic dungeon raid marking")
    enabledRow.check = CreateFrame("CheckButton", nil, enabledRow, "UICheckButtonTemplate")
    enabledRow.check:SetSize(22, 22); enabledRow.check:SetPoint("RIGHT", enabledRow, "RIGHT", -5, 0)
    enabledRow.check:SetScript("OnClick", function(self)
        if refreshing then return end
        local enabled = self:GetChecked() == true
        D.DungeonGuideSettings.SetAutoMarkEnabled(enabled)
        P.Refresh()
        if enabled then D.RaidMarkers.EvaluateCurrentTarget() end
    end)
    openRow = UIH.CreateFormRow(form.content, form.rowWidth, 44)
    local open = UIH.CreateButton(openRow, "Open Dungeon Book", 180, 26)
    open:SetPoint("LEFT", openRow, "LEFT", 8, 0)
    open:SetScript("OnClick", D.DungeonGuideUI.Toggle)
    resetRow = UIH.CreateFormRow(form.content, form.rowWidth, 44)
    local reset = UIH.CreateButton(resetRow, "Reset Book Position", 180, 26)
    reset:SetPoint("LEFT", resetRow, "LEFT", 8, 0)
    reset:SetScript("OnClick", D.DungeonGuideUI.ResetPosition)
    local legend = UIH.CreateFormRow(form.content, form.rowWidth, 94)
    local text = legend:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", legend, "TOPLEFT", 8, -8); text:SetPoint("RIGHT", legend, "RIGHT", -8, 0)
    text:SetJustifyH("LEFT"); text:SetJustifyV("TOP")
    text:SetText("Out of combat: SKULL, CROSS, and boss CIRCLE may move as you change targets.\nIn combat: each observed mark stays with its living target until removed.\n\nCC guidance is manual. Existing marks are preserved; the add-on never targets mobs or casts abilities.")
    form.explanation = text
    UIH.LayoutForm(form, {
        { frame = enabledRow, height = 38 },
        { frame = openRow, height = 44 },
        { frame = resetRow, height = 44 }, { frame = legend, height = 94, gap = 8 },
    })
    P.Refresh()
    return page
end
function P.GetRows()
    return { autoMark = enabledRow }
end
function P.GetForm() return form end
