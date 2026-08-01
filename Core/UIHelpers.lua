local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_UIHelpers = {}
local H = ApogeePartyHealthBars_UIHelpers

function H.ApplyBackdrop(frame, bgAlpha, borderColor)
    frame:SetBackdrop(C.BACKDROP)
    frame:SetBackdropColor(
        C.PANEL_BG_COLOR[1], C.PANEL_BG_COLOR[2], C.PANEL_BG_COLOR[3],
        bgAlpha or C.PANEL_BG_COLOR[4])
    if borderColor then frame:SetBackdropBorderColor(unpack(borderColor)) end
end
local activeDropdown

local FORM_SCROLLBAR_W = 24
local FORM_HINT_H = 18
local FORM_SECTION_H = 16
local FORM_ROW_H = 32
local FORM_STATUS_H = 30

local BUTTON_STYLES = {
    neutral = {
        bg = { 0.12, 0.12, 0.14, 1 },
        border = { 0.36, 0.36, 0.40, 0.75 },
        text = { 0.85, 0.85, 0.85 },
    },
    primary = {
        bg = { 0.20, 0.17, 0.07, 1 },
        border = { 0.72, 0.57, 0.10, 0.95 },
        text = { 1, 0.86, 0.32 },
    },
    danger = {
        bg = { 0.19, 0.07, 0.07, 1 },
        border = { 0.66, 0.20, 0.18, 0.95 },
        text = { 1, 0.58, 0.50 },
    },
    quiet = {
        bg = { 0.075, 0.075, 0.09, 1 },
        border = { 0.24, 0.24, 0.28, 0.65 },
        text = { 0.72, 0.72, 0.74 },
    },
}

local function setTextureColor(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

local function applyButtonStyle(button)
    if not button or not button.bg then return end
    local style = BUTTON_STYLES[button.apogeeButtonStyle] or BUTTON_STYLES.neutral
    local enabled = not button.IsEnabled or button:IsEnabled()
    if enabled then
        setTextureColor(button.bg, style.bg)
        for _, edge in ipairs(button.borders or { button.border }) do
            setTextureColor(edge, style.border)
        end
        if button.label then button.label:SetTextColor(unpack(style.text)) end
    else
        button.bg:SetColorTexture(style.bg[1] * 0.50, style.bg[2] * 0.50,
            style.bg[3] * 0.50, style.bg[4] or 1)
        for _, edge in ipairs(button.borders or { button.border }) do
            edge:SetColorTexture(style.border[1] * 0.58, style.border[2] * 0.58,
                style.border[3] * 0.58, 0.52)
        end
        if button.label then
            button.label:SetTextColor(style.text[1] * 0.62, style.text[2] * 0.62,
                style.text[3] * 0.62)
        end
    end
end

function H.EscapeText(value)
    return tostring(value or ""):gsub("|", "||")
end

function H.CloseActiveDropdown()
    if activeDropdown then activeDropdown:Close() end
end

function H.StyleTabButton(button, active, supported)
    supported = supported ~= false
    button.bg:SetColorTexture(active and 0.22 or 0.10, active and 0.22 or 0.10, active and 0.26 or 0.12, 1)
    if not supported then
        button.label:SetTextColor(0.38, 0.38, 0.38)
    elseif active then
        button.label:SetTextColor(1, 0.82, 0)
    else
        button.label:SetTextColor(0.75, 0.75, 0.75)
    end
    button.accent:SetShown(active and supported)
end

function H.CreateButton(parent, labelText, width, height, style)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or C.CONFIG_CONTENT_W, height or C.CONFIG_BTN_H)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(); highlight:SetColorTexture(1, 1, 1, 0.08)
    local pushed = button:CreateTexture(nil, "ARTWORK")
    pushed:SetAllPoints(); pushed:SetColorTexture(0, 0, 0, 0.18)
    if button.SetPushedTexture then button:SetPushedTexture(pushed) end
    local borders = {}
    for _, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local border = button:CreateTexture(nil, "BORDER")
        if edge == "TOP" or edge == "BOTTOM" then
            border:SetPoint(edge .. "LEFT", button, edge .. "LEFT")
            border:SetPoint(edge .. "RIGHT", button, edge .. "RIGHT")
            border:SetHeight(1)
        else
            border:SetPoint("TOP" .. edge, button, "TOP" .. edge)
            border:SetPoint("BOTTOM" .. edge, button, "BOTTOM" .. edge)
            border:SetWidth(1)
        end
        borders[#borders + 1] = border
    end
    local label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("CENTER"); label:SetText(labelText)
    button.bg, button.label, button.border = bg, label, borders[1]
    button.borders, button.pushed = borders, pushed
    button.apogeeButtonStyle = BUTTON_STYLES[style] and style or "neutral"
    button:SetScript("OnEnable", applyButtonStyle)
    button:SetScript("OnDisable", applyButtonStyle)
    applyButtonStyle(button)
    return button
end

function H.SetButtonStyle(button, style)
    assert(BUTTON_STYLES[style], "unknown button style: " .. tostring(style))
    button.apogeeButtonStyle = style
    applyButtonStyle(button)
    return button
end

local ARROW_TEXTURES = {
    up = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up",
    down = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up",
}

function H.SetArrowDirection(arrow, direction)
    assert(arrow and ARROW_TEXTURES[direction],
        "arrow direction must be up or down")
    arrow.direction = direction
    arrow:SetTexture(ARROW_TEXTURES[direction])
    arrow:SetTexCoord(0.20, 0.80, 0.25, 0.75)
    return arrow
end

function H.CreateArrowIndicator(parent, direction, width, height)
    local arrow = parent:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(width or 12, height or 10)
    H.SetArrowDirection(arrow, direction)
    return arrow
end

function H.CreateArrowButton(parent, direction, width, height)
    local button = H.CreateButton(parent, "", width, height, "quiet")
    local arrow = H.CreateArrowIndicator(button, direction)
    arrow:SetPoint("CENTER")
    button.arrow = arrow
    return button
end

function H.SetButtonEnabled(button, enabled)
    if enabled then button:Enable() else button:Disable() end
    applyButtonStyle(button)
end

local function tooltipAnchor(frame)
    if not frame or not frame.GetCenter or not UIParent or not UIParent.GetCenter then
        return "ANCHOR_RIGHT"
    end
    local frameX = frame:GetCenter()
    local parentX = UIParent:GetCenter()
    if not frameX or not parentX then return "ANCHOR_RIGHT" end
    return frameX >= parentX and "ANCHOR_RIGHT" or "ANCHOR_LEFT"
end

local function setTooltipOwner(frame)
    GameTooltip:SetOwner(frame, tooltipAnchor(frame))
end

function H.SetTooltip(frame, title, body)
    if not frame then return end
    frame.apogeeTooltipTitle = title
    frame.apogeeTooltipBody = body
    if not title or title == "" then
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
        return
    end
    frame:SetScript("OnEnter", function(self)
        if not GameTooltip or not GameTooltip.SetOwner then return end
        if GameTooltip.ClearLines then GameTooltip:ClearLines() end
        setTooltipOwner(self)
        if GameTooltip.SetText then GameTooltip:SetText(title, 1, 0.82, 0.15) end
        if body and body ~= "" and GameTooltip.AddLine then
            GameTooltip:AddLine(body, 0.85, 0.85, 0.85, true)
        end
        if GameTooltip.Show then GameTooltip:Show() end
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
    end)
end

function H.SetUnavailableTooltip(frame, reason)
    if not frame then return end
    frame.apogeeUnavailableReason = reason
    if not reason or reason == "" then
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
        return
    end
    if frame.EnableMouse then frame:EnableMouse(true) end
    frame:SetScript("OnEnter", function(self)
        if not GameTooltip or not GameTooltip.SetOwner then return end
        if GameTooltip.ClearLines then GameTooltip:ClearLines() end
        setTooltipOwner(self)
        if GameTooltip.SetText then
            GameTooltip:SetText("Unavailable on this client", 1, 0.82, 0.15)
        end
        if GameTooltip.AddLine then GameTooltip:AddLine(reason, 1, 0.45, 0.35, true) end
        if GameTooltip.Show then GameTooltip:Show() end
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
    end)
end


function H.PrepareAvailabilityRow(frame, label, control, leftInset)
    if not frame or not label then return frame end
    local status = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    status:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", leftInset or 8, 3)
    status:SetPoint("BOTTOMRIGHT", control or frame, control and "BOTTOMLEFT" or "BOTTOMRIGHT",
        control and -5 or -8, 3)
    status:SetJustifyH("LEFT"); status:SetWordWrap(false)
    status:SetTextColor(1, 0.48, 0.36)
    status:Hide()
    frame.apogeeAvailabilityLabel = status
    frame.apogeeAvailabilityMainLabel = label
    frame.apogeeAvailabilityControl = control
    frame.apogeeAvailabilityLeftInset = leftInset or 8
    return frame
end

function H.SetControlAvailability(frame, control, available, reason)
    if not frame then return available ~= false end
    control = control or frame.check or frame.value or frame
    if control then
        if available ~= false then control:Enable() else control:Disable() end
    end
    local label = frame.apogeeAvailabilityMainLabel or frame.label
    if label then
        local color = available ~= false and 0.90 or 0.55
        label:SetTextColor(color, color, color)
    end
    local status = frame.apogeeAvailabilityLabel
    if status then
        if available == false and reason and reason ~= "" then
            status:SetText("Unavailable — " .. tostring(reason))
            status:Show()
            label:ClearAllPoints()
            label:SetPoint("TOPLEFT", frame, "TOPLEFT",
                frame.apogeeAvailabilityLeftInset or 8, -4)
            label:SetPoint("TOPRIGHT", control or frame,
                control and "TOPLEFT" or "TOPRIGHT", control and -5 or -8, -4)
        else
            status:Hide()
            label:ClearAllPoints()
            label:SetPoint("LEFT", frame, "LEFT", frame.apogeeAvailabilityLeftInset or 8, 0)
            label:SetPoint("RIGHT", control or frame,
                control and "LEFT" or "RIGHT", control and -5 or -8, 0)
        end
    end
    H.SetUnavailableTooltip(frame, available == false and reason or nil)
    return available ~= false
end

-- Keep spell-icon tooltips compact and consistent without modifying Blizzard's
-- shared tooltip frame styling or protected UI state.
local function showNativeTooltip(anchor, identifier, title, setterName, fallbackTitle)
    if not GameTooltip then return end
    if GameTooltip.ClearLines then GameTooltip:ClearLines() end
    setTooltipOwner(anchor)
    local setter = GameTooltip[setterName]
    local rendered = identifier and setter
        and setter(GameTooltip, identifier) == true
    if not rendered then
        GameTooltip:SetText(title or fallbackTitle, 1, 0.82, 0.15)
    end
    GameTooltip:Show()
end

function H.ShowNativeSpellTooltip(anchor, spellId, title)
    showNativeTooltip(anchor, spellId, title, "SetSpellByID", "Spell")
end

function H.ShowNativeItemTooltip(anchor, itemId, title)
    showNativeTooltip(anchor, itemId, title, "SetItemByID", "Item")
end

function H.ShowSpellTooltip(anchor, spellId, title, stateLabel, reason, contextLines)
    if not GameTooltip then return end
    if GameTooltip.ClearLines then GameTooltip:ClearLines() end
    setTooltipOwner(anchor)
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
    setTooltipOwner(anchor)
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

    local arrow = H.CreateArrowIndicator(dropdown, "down")
    arrow:SetPoint("RIGHT", dropdown, "RIGHT", -6, 0)

    local dismiss = CreateFrame("Button", nil, UIParent)
    dismiss:SetAllPoints(UIParent)
    dismiss:SetFrameStrata("DIALOG")
    dismiss:SetFrameLevel(100)
    if dismiss.SetToplevel then dismiss:SetToplevel(true) end
    dismiss:EnableMouse(true)
    dismiss:Hide()

    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetWidth(popupWidth)
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(101)
    if popup.SetToplevel then popup:SetToplevel(true) end
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
        local arrowColor = enabled and 0.90 or 0.42
        arrow:SetVertexColor(arrowColor, arrowColor, arrowColor)
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
        H.SetArrowDirection(arrow, "down")
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
                -- Classic Era does not consistently inherit a parent's raised
                -- frame level for newly-created child frames. Keep menu choices
                -- explicitly above both the popup backdrop and dismissal layer.
                optionButton:SetFrameStrata("DIALOG")
                optionButton:SetFrameLevel(102)
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
        if dismiss.Raise then dismiss:Raise() end
        popup:Show()
        if popup.Raise then popup:Raise() end
        H.SetArrowDirection(arrow, "up")
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
        H.SetArrowDirection(arrow, "down")
        if activeDropdown == dropdown then activeDropdown = nil end
    end)

    dropdown:SetArrowShown(true)
    styleEnabled(true)
    return dropdown
end

function H.CreateTabButton(parent, text, xOffset, width)
    local button = H.CreateButton(parent, text, width, C.CONFIG_PAGE_SELECTOR_H)
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

function H.AttachOverflowCue(scroll, parent)
    if not scroll or scroll.apogeeOverflowCue then return scroll and scroll.apogeeOverflowCue end
    parent = parent or scroll
    local cue = CreateFrame("Frame", nil, parent)
    if cue.SetFrameLevel and scroll.GetFrameLevel then
        cue:SetFrameLevel(scroll:GetFrameLevel() + 20)
    end
    cue:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    cue:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -FORM_SCROLLBAR_W, 0)
    cue:SetHeight(10)
    local shade = cue:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints(); shade:SetColorTexture(0.04, 0.04, 0.055, 0.72)
    local arrow = H.CreateArrowIndicator(cue, "down", 10, 6)
    arrow:SetPoint("CENTER", cue, "CENTER", 0, 0)
    arrow:SetVertexColor(0.90, 0.74, 0.18)
    cue:EnableMouse(false); cue:Hide()

    local function refresh()
        local range = scroll.GetVerticalScrollRange and scroll:GetVerticalScrollRange() or 0
        local current = scroll.GetVerticalScroll and scroll:GetVerticalScroll() or 0
        local overflowing = range > 0
        if scroll.ScrollBar then
            scroll.ScrollBar:SetShown(overflowing)
            if scroll.ScrollBar.SetAlpha then scroll.ScrollBar:SetAlpha(0.92) end
        end
        cue:SetShown(overflowing and current < range - 1)
    end
    scroll:HookScript("OnScrollRangeChanged", refresh)
    scroll:HookScript("OnVerticalScroll", refresh)
    scroll.apogeeOverflowCue = cue
    scroll.apogeeRefreshOverflow = refresh
    refresh()
    return cue
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
    form.overflowCue = H.AttachOverflowCue(scroll, parent)
    H.AttachScrollWheel(scroll, FORM_ROW_H * 2)
    return form
end

function H.CreateFormSection(parent, width, labelText)
    local section = CreateFrame("Frame", nil, parent)
    section:SetSize(width, FORM_SECTION_H)
    local label = section:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    label:SetPoint("LEFT", section, "LEFT", 1, 0)
    label:SetWidth(math.min(width * 0.62, 250))
    label:SetJustifyH("LEFT"); label:SetWordWrap(false)
    label:SetText(labelText or "")
    label:SetTextColor(0.82, 0.74, 0.48)
    local rule = section:CreateTexture(nil, "ARTWORK")
    rule:SetPoint("LEFT", label, "RIGHT", 8, 0)
    rule:SetPoint("RIGHT", section, "RIGHT", -1, 0)
    rule:SetHeight(1); rule:SetColorTexture(0.45, 0.35, 0.08, 0.70)
    section.label, section.rule = label, rule
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
    local y = form.headerManaged and 0 or FORM_HINT_H
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

    if form.scroll.apogeeRefreshOverflow then form.scroll.apogeeRefreshOverflow() end
end
