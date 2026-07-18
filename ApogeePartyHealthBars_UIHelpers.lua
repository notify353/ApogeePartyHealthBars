local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_UIHelpers = {}
local H = ApogeePartyHealthBars_UIHelpers
local activeDropdown

local FORM_SCROLLBAR_W = 24
local FORM_HINT_H = 18
local FORM_SECTION_H = 16
local FORM_ROW_H = 32
local FORM_STATUS_H = 30

function H.EscapeText(value)
    return tostring(value or ""):gsub("|", "||")
end

function H.CloseActiveDropdown()
    if activeDropdown then activeDropdown:Close() end
end

function H.StyleTabButton(button, active)
    button.bg:SetColorTexture(active and 0.22 or 0.10, active and 0.22 or 0.10, active and 0.26 or 0.12, 1)
    if active then button.label:SetTextColor(1, 0.82, 0) else button.label:SetTextColor(0.75, 0.75, 0.75) end
    button.accent:SetShown(active)
end

function H.CreateButton(parent, labelText, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or C.CONFIG_CONTENT_W, height or C.CONFIG_BTN_H)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(0.12, 0.12, 0.14, 1)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(); highlight:SetColorTexture(1, 1, 1, 0.08)
    local border = button:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT"); border:SetPoint("TOPRIGHT"); border:SetHeight(1)
    border:SetColorTexture(0.36, 0.36, 0.40, 0.75)
    local label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("CENTER"); label:SetText(labelText)
    button.bg, button.label, button.border = bg, label, border
    return button
end

function H.SetButtonEnabled(button, enabled)
    if enabled then button:Enable() else button:Disable() end
    if button.label then
        local color = enabled and 0.85 or 0.45
        button.label:SetTextColor(color, color, color)
    end
end

-- Keep spell-icon tooltips compact and consistent without modifying Blizzard's
-- shared tooltip frame styling or protected UI state.
function H.ShowSpellTooltip(anchor, spellId, title, stateLabel, reason, contextLines)
    if not GameTooltip then return end
    if GameTooltip.ClearLines then GameTooltip:ClearLines() end
    GameTooltip:SetOwner(anchor, "ANCHOR_TOP")
    if spellId and GameTooltip.SetSpellByID then
        GameTooltip:SetSpellByID(spellId)
    else
        GameTooltip:SetText(title or "Spell", 1, 0.82, 0.15)
    end
    GameTooltip:AddLine(" ")
    if stateLabel and stateLabel ~= "" then GameTooltip:AddLine(stateLabel, 0.72, 0.72, 0.76) end
    if reason and reason ~= "" then GameTooltip:AddLine(reason, 1, 0.45, 0.35, true) end
    for _, line in ipairs(contextLines or {}) do
        GameTooltip:AddLine(line.text or line, line.r or 0.72, line.g or 0.72, line.b or 0.76, line.wrap)
    end
    GameTooltip:Show()
end

function H.ShowItemTooltip(anchor, itemId, title, stateLabel, reason, contextLines)
    if not GameTooltip then return end
    if GameTooltip.ClearLines then GameTooltip:ClearLines() end
    GameTooltip:SetOwner(anchor, "ANCHOR_TOP")
    if itemId and GameTooltip.SetItemByID then
        GameTooltip:SetItemByID(itemId)
    else
        GameTooltip:SetText(title or "Item", 1, 0.82, 0.15)
    end
    GameTooltip:AddLine(" ")
    if stateLabel and stateLabel ~= "" then GameTooltip:AddLine(stateLabel, 0.72, 0.72, 0.76) end
    if reason and reason ~= "" then GameTooltip:AddLine(reason, 1, 0.45, 0.35, true) end
    for _, line in ipairs(contextLines or {}) do
        GameTooltip:AddLine(line.text or line, line.r or 0.72, line.g or 0.72, line.b or 0.76, line.wrap)
    end
    GameTooltip:Show()
end

function H.CreateDropdown(parent, width, height, popupWidth)
    width = width or C.CONFIG_CONTENT_W
    height = height or C.CONFIG_BTN_H
    popupWidth = popupWidth or width

    local dropdown = H.CreateButton(parent, "Select...", width, height)
    dropdown.label:ClearAllPoints()
    dropdown.label:SetPoint("LEFT", dropdown, "LEFT", 6, 0)
    dropdown.label:SetPoint("RIGHT", dropdown, "RIGHT", -18, 0)
    dropdown.label:SetJustifyH("LEFT")
    dropdown.label:SetWordWrap(false)

    local arrow = dropdown:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    arrow:SetPoint("RIGHT", dropdown, "RIGHT", -6, 0)
    arrow:SetText("v")

    local dismiss = CreateFrame("Button", nil, UIParent)
    dismiss:SetAllPoints(UIParent)
    dismiss:SetFrameStrata("DIALOG")
    dismiss:SetFrameLevel(100)
    dismiss:EnableMouse(true)
    dismiss:Hide()

    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetWidth(popupWidth)
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(101)
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:Hide()

    local supportsKeyboardPropagation = dismiss.SetPropagateKeyboardInput ~= nil
    if supportsKeyboardPropagation then
        dismiss:SetPropagateKeyboardInput(true)
    end

    local popupBg = popup:CreateTexture(nil, "BACKGROUND")
    popupBg:SetAllPoints()
    popupBg:SetColorTexture(0.06, 0.06, 0.08, 0.98)
    for _, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local border = popup:CreateTexture(nil, "BORDER")
        if edge == "TOP" or edge == "BOTTOM" then
            border:SetPoint(edge .. "LEFT", popup, edge .. "LEFT")
            border:SetPoint(edge .. "RIGHT", popup, edge .. "RIGHT")
            border:SetHeight(1)
        else
            border:SetPoint("TOP" .. edge, popup, "TOP" .. edge)
            border:SetPoint("BOTTOM" .. edge, popup, "BOTTOM" .. edge)
            border:SetWidth(1)
        end
        border:SetColorTexture(0.36, 0.36, 0.40, 0.9)
    end

    dropdown.arrow = arrow
    dropdown.dismiss = dismiss
    dropdown.popup = popup
    dropdown.options = {}
    dropdown.optionButtons = {}

    local function styleEnabled(enabled)
        dropdown.label:SetTextColor(enabled and 0.85 or 0.42,
            enabled and 0.85 or 0.42, enabled and 0.85 or 0.44)
        arrow:SetTextColor(enabled and 0.85 or 0.38,
            enabled and 0.85 or 0.38, enabled and 0.85 or 0.40)
        dropdown.bg:SetColorTexture(enabled and 0.12 or 0.055,
            enabled and 0.12 or 0.055, enabled and 0.14 or 0.065, 1)
        dropdown.border:SetColorTexture(enabled and 0.36 or 0.20,
            enabled and 0.36 or 0.20, enabled and 0.40 or 0.23, enabled and 0.75 or 0.55)
    end

    function dropdown:SetArrowShown(shown)
        self.arrowShown = shown ~= false
        if self.arrowShown then arrow:Show() else arrow:Hide() end
        self.label:ClearAllPoints()
        self.label:SetPoint("LEFT", self, "LEFT", 6, 0)
        self.label:SetPoint("RIGHT", self, "RIGHT", self.arrowShown and -18 or -6, 0)
    end

    function dropdown:Close()
        popup:Hide()
        if supportsKeyboardPropagation then dismiss:EnableKeyboard(false) end
        dismiss:Hide()
        arrow:SetText("v")
        if activeDropdown == self then activeDropdown = nil end
    end

    function dropdown:SetSelectionCallback(callback)
        assert(callback == nil or type(callback) == "function", "dropdown callback must be a function")
        self.onSelect = callback
    end

    function dropdown:SetSelectedKey(key)
        local selectedLabel
        for index, option in ipairs(self.options) do
            local selected = option.key == key
            local optionButton = self.optionButtons[index]
            optionButton.bg:SetColorTexture(
                selected and 0.22 or 0.10,
                selected and 0.22 or 0.10,
                selected and 0.26 or 0.12,
                1)
            optionButton.label:SetTextColor(
                selected and 1 or 0.85,
                selected and 0.82 or 0.85,
                selected and 0 or 0.85)
            if selected then selectedLabel = option.label end
        end
        self.selectedKey = selectedLabel and key or nil
        self.label:SetText(selectedLabel or "Select...")
        return self.selectedKey
    end

    function dropdown:SetOptions(options)
        assert(type(options) == "table", "dropdown options must be a table")
        local seen = {}
        self.options = {}

        for index, option in ipairs(options) do
            assert(type(option) == "table" and type(option.key) == "string"
                and type(option.label) == "string", "invalid dropdown option")
            assert(not seen[option.key], "duplicate dropdown option: " .. option.key)
            seen[option.key] = true
            self.options[index] = { key = option.key, label = option.label }

            local optionButton = self.optionButtons[index]
            if not optionButton then
                optionButton = H.CreateButton(popup, "", popupWidth - 4, height)
                optionButton:SetPoint("TOPLEFT", popup, "TOPLEFT", 2, -(2 + (index - 1) * height))
                optionButton.label:ClearAllPoints()
                optionButton.label:SetPoint("LEFT", optionButton, "LEFT", 6, 0)
                optionButton.label:SetPoint("RIGHT", optionButton, "RIGHT", -6, 0)
                optionButton.label:SetJustifyH("LEFT")
                optionButton.label:SetWordWrap(false)
                optionButton:SetScript("OnClick", function(self)
                    local selectedKey = self.optionKey
                    dropdown:SetSelectedKey(selectedKey)
                    dropdown:Close()
                    if dropdown.onSelect then dropdown.onSelect(selectedKey) end
                end)
                self.optionButtons[index] = optionButton
            end
            optionButton.optionKey = option.key
            optionButton.label:SetText(option.label)
            optionButton:Show()
        end

        for index = #options + 1, #self.optionButtons do
            self.optionButtons[index]:Hide()
        end
        popup:SetHeight(#options * height + 4)
        self:SetSelectedKey(self.selectedKey)
    end

    function dropdown:Open()
        if not self:IsEnabled() or #self.options == 0 then return end
        if activeDropdown and activeDropdown ~= self then H.CloseActiveDropdown() end
        activeDropdown = self
        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        self:SetSelectedKey(self.selectedKey)
        if supportsKeyboardPropagation then
            dismiss:SetPropagateKeyboardInput(true)
            dismiss:EnableKeyboard(true)
        end
        dismiss:Show()
        popup:Show()
        arrow:SetText("^")
    end

    dropdown:SetScript("OnClick", function(self)
        if popup:IsShown() then self:Close() else self:Open() end
    end)
    dropdown:SetScript("OnHide", function(self) self:Close() end)
    dropdown:SetScript("OnEnable", function() styleEnabled(true) end)
    dropdown:SetScript("OnDisable", function(self) self:Close(); styleEnabled(false) end)
    dismiss:SetScript("OnClick", function() dropdown:Close() end)
    if supportsKeyboardPropagation then
        dismiss:SetScript("OnKeyDown", function(self, key)
            local isEscape = key == "ESCAPE"
            self:SetPropagateKeyboardInput(not isEscape)
            if isEscape then dropdown:Close() end
        end)
    end
    popup:SetScript("OnHide", function()
        if supportsKeyboardPropagation then dismiss:EnableKeyboard(false) end
        dismiss:Hide()
        arrow:SetText("v")
        if activeDropdown == dropdown then activeDropdown = nil end
    end)

    dropdown:SetArrowShown(true)
    styleEnabled(true)
    return dropdown
end

function H.CreateTabButton(parent, text, xOffset, width)
    local button = H.CreateButton(parent, text, width, C.CONFIG_TAB_H)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -(C.CONFIG_HEADER_H + C.BIND_PAD))
    local accent = button:CreateTexture(nil, "OVERLAY")
    accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT")
    accent:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT")
    accent:SetHeight(2)
    accent:SetColorTexture(1, 0.82, 0, 1)
    accent:Hide()
    button.accent = accent
    return button
end

function H.AttachScrollWheel(scroll, step)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maximum = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(maximum, current - delta * step)))
    end)
end

function H.CreateScrollFrame(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(C.CONFIG_CONTENT_W)
    scroll:SetScrollChild(child)
    return scroll, child
end

function H.CreateFormScaffold(parent, frameName, hintText, showStatus)
    local scroll = CreateFrame("ScrollFrame", frameName, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -FORM_SCROLLBAR_W, 0)

    local content = CreateFrame("Frame", nil, scroll)
    local rowWidth = C.CONFIG_CONTENT_W - FORM_SCROLLBAR_W
    content:SetWidth(rowWidth)
    scroll:SetScrollChild(content)

    local hint = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    hint:SetSize(rowWidth, FORM_HINT_H)
    hint:SetJustifyH("LEFT"); hint:SetJustifyV("TOP"); hint:SetWordWrap(false)
    hint:SetText(hintText or "")

    local status = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    status:SetWidth(rowWidth); status:SetHeight(FORM_STATUS_H)
    status:SetJustifyH("LEFT"); status:SetJustifyV("TOP"); status:SetWordWrap(true)
    showStatus = showStatus ~= false
    status:SetShown(showStatus)

    local form = {
        scroll = scroll,
        content = content,
        hint = hint,
        status = status,
        showStatus = showStatus,
        rowWidth = rowWidth,
    }

    local scrollBar = scroll.ScrollBar
    if scrollBar then
        scrollBar:Hide()
        scroll:HookScript("OnScrollRangeChanged", function(_, _, verticalRange)
            scrollBar:SetShown((verticalRange or 0) > 0)
        end)
    end
    H.AttachScrollWheel(scroll, FORM_ROW_H * 2)
    return form
end

function H.CreateFormSection(parent, width, labelText)
    local section = CreateFrame("Frame", nil, parent)
    section:SetSize(width, FORM_SECTION_H)
    local label = section:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    label:SetPoint("LEFT", section, "LEFT", 1, 0)
    label:SetPoint("RIGHT", section, "RIGHT", -1, 0)
    label:SetJustifyH("LEFT"); label:SetWordWrap(false)
    label:SetText(labelText or "")
    label:SetTextColor(0.58, 0.58, 0.61)
    section.label = label
    return section
end

function H.CreateFormRow(parent, width, height)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(width, height or FORM_ROW_H)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(0.075, 0.075, 0.09, 1)
    row.bg = bg
    return row
end

function H.SetFormStatus(form, message, good)
    if not form or not form.status then return end
    if not message or message == "" then
        form.status:SetText("")
        return
    end
    form.status:SetText((good and "|cff00ff00" or "|cffffaa00")
        .. tostring(message) .. "|r")
end

function H.LayoutForm(form, entries)
    if not form then return end
    local y = FORM_HINT_H
    for _, entry in ipairs(entries or {}) do
        local frame = entry.frame
        local visible = entry.visible ~= false
        frame:SetShown(visible)
        if visible then
            y = y + (entry.gap or 3)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", form.content, "TOPLEFT", entry.indent or 0, -y)
            frame:SetWidth(form.rowWidth - (entry.indent or 0))
            if entry.height then frame:SetHeight(entry.height) end
            y = y + (entry.height or FORM_ROW_H)
        end
    end

    if form.showStatus then
        form.status:Show()
        form.status:ClearAllPoints()
        form.status:SetPoint("TOPLEFT", form.content, "TOPLEFT", 0, -(y + 7))
        form.content:SetHeight(y + 7 + FORM_STATUS_H)
    else
        form.status:Hide()
        form.content:SetHeight(y)
    end

    local scrollBar = form.scroll.ScrollBar
    if scrollBar and form.scroll.GetVerticalScrollRange then
        scrollBar:SetShown((form.scroll:GetVerticalScrollRange() or 0) > 0)
    end
end
