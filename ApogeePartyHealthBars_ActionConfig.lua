local C = ApogeePartyHealthBars_C
local UIH = ApogeePartyHealthBars_UIHelpers
local Actions = ApogeePartyHealthBars_ActionMacros

ApogeePartyHealthBars_ActionConfig = {}
local AC = ApogeePartyHealthBars_ActionConfig

local overlay, dialog, title, actionName, editor, byteCount, statusText
local resetButton, cancelButton, saveButton
local current

local LIST_SCROLLBAR_W = 24
local LIST_HINT_H = 18
local LIST_ROW_H = 36
local LIST_ROW_GAP = 3
local LIST_FIRST_ROW_GAP = 9
local LIST_STATUS_GAP = 7
local LIST_STATUS_H = 16
local function setStatus(message, good)
    if not statusText then return end
    statusText:SetText((good and "|cff00ff00" or "|cffffaa00") .. tostring(message or "") .. "|r")
end

local function refreshEditorState()
    if not editor then return end
    local body = editor:GetText() or ""
    local valid = body:find("%S") ~= nil and #body <= Actions.MAX_BODY_BYTES
    byteCount:SetText(#body .. " / " .. Actions.MAX_BODY_BYTES .. " bytes")
    byteCount:SetTextColor(valid and 0.62 or 1, valid and 0.62 or 0.25, valid and 0.64 or 0.25)
    UIH.SetButtonEnabled(saveButton, valid)
end

function AC.CloseEditor()
    current = nil
    if overlay then overlay:Hide() end
    if editor then editor:SetText(""); editor:ClearFocus() end
    if statusText then statusText:SetText("") end
end

function AC.OpenEditor(options)
    if not overlay or type(options) ~= "table" or type(options.onSave) ~= "function" then return false end
    current = options
    title:SetText(options.title or "Edit macro")
    actionName:SetText(options.actionName or "Shortcut")
    statusText:SetText("")
    editor:SetText(options.macroText or "")
    refreshEditorState()
    overlay:Show()
    editor:SetFocus()
    return true
end

function AC.CreateActionRow(parent, width, options)
    options = options or {}
    local showSound = options.showSound ~= false
    local showMacro = options.showMacro ~= false
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width or C.CONFIG_CONTENT_W, 36)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(0.075, 0.075, 0.09, 1)
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(); highlight:SetColorTexture(1, 1, 1, 0.05)
    local iconSlot = CreateFrame("Frame", nil, row)
    iconSlot:SetSize(26, 26); iconSlot:SetPoint("LEFT", row, "LEFT", 6, 0)
    local iconOutline = iconSlot:CreateTexture(nil, "BACKGROUND")
    iconOutline:SetAllPoints(); iconOutline:SetColorTexture(0.22, 0.22, 0.24, 1)
    local iconFill = iconSlot:CreateTexture(nil, "BORDER")
    iconFill:SetPoint("TOPLEFT", iconSlot, "TOPLEFT", 1, -1)
    iconFill:SetPoint("BOTTOMRIGHT", iconSlot, "BOTTOMRIGHT", -1, 1)
    iconFill:SetColorTexture(0.025, 0.025, 0.03, 1)
    local icon = iconSlot:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22); icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local clear = UIH.CreateButton(row, "Clear", 40, 22)
    clear:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    local down = UIH.CreateButton(row, "Dn", 26, 22)
    down:SetPoint("RIGHT", clear, "LEFT", -2, 0)
    local up = UIH.CreateButton(row, "Up", 26, 22)
    up:SetPoint("RIGHT", down, "LEFT", -2, 0)
    local macro = UIH.CreateButton(row, "Macro", 48, 22)
    macro:SetPoint("RIGHT", up, "LEFT", -2, 0)
    local sound = UIH.CreateDropdown(row, 62, 22, 150)
    sound:SetArrowShown(false)
    sound:SetPoint("RIGHT", macro, "LEFT", -2, 0)
    sound:SetShown(showSound)
    macro:SetShown(showMacro)

    local primary = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    primary:SetPoint("LEFT", iconSlot, "RIGHT", 6, 5)
    local textControl = showSound and sound or (showMacro and macro or up)
    primary:SetPoint("RIGHT", textControl, "LEFT", -5, 5)
    primary:SetJustifyH("LEFT"); primary:SetWordWrap(false)
    local secondary = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    secondary:SetPoint("LEFT", primary, "LEFT", 0, -12)
    secondary:SetPoint("RIGHT", primary, "RIGHT", 0, -12)
    secondary:SetJustifyH("LEFT"); secondary:SetWordWrap(false)

    row.bg, row.iconSlot, row.icon = bg, iconSlot, icon
    row.iconOutline, row.iconFill = iconOutline, iconFill
    row.primary, row.secondary = primary, secondary
    row.sound, row.macro, row.up, row.down, row.clear = sound, macro, up, down, clear
    row.showSound, row.showMacro = showSound, showMacro
    return row
end

function AC.SetActionRowState(row, options)
    if not row then return end
    options = options or {}
    local active = options.active == true
    local available = options.available ~= false
    row.icon:SetTexture(options.icon)
    row.icon:SetDesaturated(not active or not available)
    row.primary:SetText(options.name or "Empty")
    if active and available then
        row.primary:SetTextColor(0.86, 0.86, 1)
    elseif active then
        row.primary:SetTextColor(0.48, 0.48, 0.50)
    else
        row.primary:SetTextColor(0.43, 0.43, 0.45)
    end
    row.secondary:SetText(options.detail or "Empty")
    row.sound:SetSelectedKey(active and (options.soundKey or "none") or "none")
    if row.showSound and active then row.sound:Enable() else row.sound:Disable() end
    UIH.SetButtonEnabled(row.macro, row.showMacro and active)
    UIH.SetButtonEnabled(row.clear, active)
    UIH.SetButtonEnabled(row.up, active and options.canMoveUp == true)
    UIH.SetButtonEnabled(row.down, active and options.canMoveDown == true)
    row.macro.label:SetText(active and options.macroCustomized and "Macro*" or "Macro")
end

function AC.CreateActionList(parent, frameName)
    local scroll = CreateFrame("ScrollFrame", frameName, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -LIST_SCROLLBAR_W, 0)

    local content = CreateFrame("Frame", nil, scroll)
    local rowWidth = C.CONFIG_CONTENT_W - LIST_SCROLLBAR_W
    content:SetWidth(rowWidth)
    scroll:SetScrollChild(content)

    local hint = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    hint:SetWidth(rowWidth); hint:SetHeight(LIST_HINT_H)
    hint:SetJustifyH("LEFT"); hint:SetJustifyV("TOP"); hint:SetWordWrap(false)
    hint:SetText("Drag a spell or bag item onto a row.")

    local status = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    status:SetWidth(rowWidth); status:SetJustifyH("LEFT"); status:SetWordWrap(false)

    local list = {
        scroll = scroll,
        content = content,
        hint = hint,
        status = status,
        rowWidth = rowWidth,
    }

    local scrollBar = scroll.ScrollBar
    if scrollBar then
        scrollBar:Hide()
        scroll:HookScript("OnScrollRangeChanged", function(_, _, verticalRange)
            scrollBar:SetShown((verticalRange or 0) > 0)
        end)
    end
    return list
end

function AC.SetActionListStatus(list, message, good)
    if not list or not list.status then return end
    if not message or message == "" then
        list.status:SetText("")
        return
    end
    list.status:SetText((good and "|cff00ff00" or "|cffffaa00")
        .. tostring(message) .. "|r")
end

function AC.LayoutActionList(list, rows, layoutControl)
    if not list then return end
    rows = rows or {}
    local anchor = list.hint
    local contentHeight = LIST_HINT_H

    if layoutControl then
        layoutControl:ClearAllPoints()
        layoutControl:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
        anchor = layoutControl
        contentHeight = contentHeight + 8 + 22
    end

    for index, row in ipairs(rows) do
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0,
            index == 1 and -LIST_FIRST_ROW_GAP or -LIST_ROW_GAP)
        anchor = row
    end
    if #rows > 0 then
        contentHeight = contentHeight + LIST_FIRST_ROW_GAP
            + #rows * LIST_ROW_H + (#rows - 1) * LIST_ROW_GAP
    end

    list.status:ClearAllPoints()
    list.status:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -LIST_STATUS_GAP)
    contentHeight = contentHeight + LIST_STATUS_GAP + LIST_STATUS_H
    list.content:SetHeight(contentHeight)

    local scrollBar = list.scroll.ScrollBar
    if scrollBar and list.scroll.GetVerticalScrollRange then
        scrollBar:SetShown((list.scroll:GetVerticalScrollRange() or 0) > 0)
    end
end

function AC.Initialize(parent, applyBackdrop)
    if overlay then return overlay end
    overlay = CreateFrame("Frame", nil, parent)
    -- Leave the tabs and close button reachable so either action can discard
    -- the draft through the normal settings lifecycle.
    overlay:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    overlay:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    overlay:SetFrameStrata("DIALOG"); overlay:SetFrameLevel(110)
    overlay:EnableMouse(true); overlay:Hide()
    local shade = overlay:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints(); shade:SetColorTexture(0, 0, 0, 0.72)

    dialog = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
    dialog:SetSize(C.CONFIG_CONTENT_W - 24, 278)
    dialog:SetPoint("CENTER", overlay, "CENTER", 0, -8)
    applyBackdrop(dialog, 0.98, { 0.42, 0.42, 0.46, 1 })

    title = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, -12); title:SetTextColor(1, 0.82, 0)
    actionName = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    actionName:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    actionName:SetWidth(C.CONFIG_CONTENT_W - 52); actionName:SetJustifyH("LEFT"); actionName:SetWordWrap(false)

    byteCount = dialog:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    byteCount:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -12, -42)
    local editorFrame = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
    editorFrame:SetPoint("TOPLEFT", actionName, "BOTTOMLEFT", 0, -18)
    editorFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 72)
    applyBackdrop(editorFrame, 0.94, { 0.32, 0.32, 0.36, 1 })
    editor = CreateFrame("EditBox", nil, editorFrame)
    editor:SetMultiLine(true); editor:SetAutoFocus(false); editor:SetFontObject("ChatFontNormal")
    editor:SetJustifyH("LEFT"); editor:SetJustifyV("TOP")
    editor:SetPoint("TOPLEFT", editorFrame, "TOPLEFT", 8, -7)
    editor:SetPoint("BOTTOMRIGHT", editorFrame, "BOTTOMRIGHT", -8, 7)
    editor:SetScript("OnTextChanged", refreshEditorState)
    editor:SetScript("OnEscapePressed", AC.CloseEditor)

    resetButton = UIH.CreateButton(dialog, "Reset", 74, 22)
    resetButton:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 12, 38)
    resetButton:SetScript("OnClick", function()
        if current and current.resetText then editor:SetText(current.resetText); editor:SetFocus() end
    end)
    cancelButton = UIH.CreateButton(dialog, "Cancel", 74, 22)
    cancelButton:SetPoint("LEFT", resetButton, "RIGHT", 6, 0)
    cancelButton:SetScript("OnClick", AC.CloseEditor)
    saveButton = UIH.CreateButton(dialog, "Save", 86, 22)
    saveButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 38)
    saveButton:SetScript("OnClick", function()
        if not current then return end
        local ok, message = current.onSave(editor:GetText() or "")
        if not ok then setStatus(message, false); return end
        local onSaved = current.onSaved
        AC.CloseEditor()
        if onSaved then onSaved(message) end
    end)
    statusText = dialog:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    statusText:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 12, 12)
    statusText:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 12)
    statusText:SetJustifyH("LEFT"); statusText:SetWordWrap(false)
    return overlay
end

AC.GetEditor = function() return editor end
AC.GetOverlay = function() return overlay end
