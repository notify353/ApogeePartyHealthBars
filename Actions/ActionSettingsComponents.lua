local C = ApogeePartyHealthBars_C
local UIH = ApogeePartyHealthBars_UIHelpers
local Actions = ApogeePartyHealthBars_ActionMacros
local EquipmentSets = ApogeePartyHealthBars_EquipmentSets or {
    NONE_KEY = "\001no-loadout",
    GetOptions = function()
        return { { key = "\001no-loadout", label = "No loadout" } }
    end,
}

ApogeePartyHealthBars_ActionSettingsComponents = {}
local AC = ApogeePartyHealthBars_ActionSettingsComponents

local overlay, dialog, title, actionName, editor, byteCount, statusText
local resetButton, cancelButton, saveButton
local current

local LIST_SCROLLBAR_W = 24
local LIST_HINT_H = 18
local LIST_ROW_H = 48
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
    local reserved = current and tonumber(current.prefixBytes) or 0
    local maximum = math.max(0, Actions.MAX_BODY_BYTES - reserved)
    local valid = body:find("%S") ~= nil and #body <= maximum
    byteCount:SetText(#body .. " / " .. maximum .. " action bytes"
        .. (reserved > 0 and ("; " .. reserved .. " gear") or ""))
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
    local showGear = options.showGear ~= false and showMacro
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width or C.CONFIG_CONTENT_W, LIST_ROW_H)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(0.075, 0.075, 0.09, 1)
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(); highlight:SetColorTexture(1, 1, 1, 0.05)
    local dropAccent = row:CreateTexture(nil, "OVERLAY")
    dropAccent:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    dropAccent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    dropAccent:SetWidth(2); dropAccent:SetColorTexture(1, 0.82, 0, 0.85)
    dropAccent:Hide()
    local iconSlot = CreateFrame("Frame", nil, row)
    iconSlot:SetSize(30, 30); iconSlot:SetPoint("LEFT", row, "LEFT", 6, 0)
    local iconOutline = iconSlot:CreateTexture(nil, "BACKGROUND")
    iconOutline:SetAllPoints(); iconOutline:SetColorTexture(0.22, 0.22, 0.24, 1)
    local iconFill = iconSlot:CreateTexture(nil, "BORDER")
    iconFill:SetPoint("TOPLEFT", iconSlot, "TOPLEFT", 1, -1)
    iconFill:SetPoint("BOTTOMRIGHT", iconSlot, "BOTTOMRIGHT", -1, 1)
    iconFill:SetColorTexture(0.025, 0.025, 0.03, 1)
    local icon = iconSlot:CreateTexture(nil, "ARTWORK")
    icon:SetSize(26, 26); icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local clear = UIH.CreateButton(row, "Clear", 38, 20, "quiet")
    clear:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 4)
    local down = UIH.CreateArrowButton(row, "down", 24, 20)
    down:SetPoint("RIGHT", clear, "LEFT", -2, 0)
    local up = UIH.CreateArrowButton(row, "up", 24, 20)
    up:SetPoint("RIGHT", down, "LEFT", -2, 0)
    local previous = up
    local macro = UIH.CreateButton(row, "Macro", 46, 20)
    macro:SetShown(showMacro)
    if showMacro then macro:SetPoint("RIGHT", previous, "LEFT", -2, 0); previous = macro end
    local gear = UIH.CreateDropdown(row, 46, 20, 190)
    gear:SetArrowShown(false)
    gear:SetShown(showGear)
    if showGear then gear:SetPoint("RIGHT", previous, "LEFT", -2, 0); previous = gear end
    local sound = UIH.CreateDropdown(row, 50, 20, 150)
    sound:SetArrowShown(false)
    sound:SetShown(showSound)
    if showSound then sound:SetPoint("RIGHT", previous, "LEFT", -2, 0); previous = sound end
    local function createStateMarker(control)
        local marker = control:CreateTexture(nil, "OVERLAY")
        marker:SetPoint("BOTTOMLEFT", control, "BOTTOMLEFT", 2, 1)
        marker:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", -2, 1)
        marker:SetHeight(2); marker:SetColorTexture(1, 0.82, 0, 0.95); marker:Hide()
        return marker
    end
    sound.stateMarker = createStateMarker(sound)
    gear.stateMarker = createStateMarker(gear)
    macro.stateMarker = createStateMarker(macro)
    if showSound then
        UIH.SetTooltip(sound, "Ready sound",
            "Plays when this action becomes ready after a meaningful cooldown or depleted charges.")
    end
    UIH.SetTooltip(up, "Previous trigger",
        "Swap this complete assignment with the previous trigger.")
    UIH.SetTooltip(down, "Next trigger",
        "Swap this complete assignment with the next trigger.")
    UIH.SetTooltip(clear, "Clear assignment",
        "Remove this spell or item from the trigger.")
    if showMacro then
        UIH.SetTooltip(macro, "Edit macro",
            "Review or customize the macro text used by this action.")
    end
    if showGear then
        UIH.SetTooltip(gear, "Equipment loadout",
            "Choose a native equipment loadout to run before this action.")
    end
    local primary = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    primary:SetPoint("TOPLEFT", iconSlot, "TOPRIGHT", 6, 0)
    primary:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -8)
    primary:SetJustifyH("LEFT"); primary:SetWordWrap(false)
    local secondary = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    secondary:SetPoint("BOTTOMLEFT", iconSlot, "BOTTOMRIGHT", 6, 2)
    secondary:SetPoint("BOTTOMRIGHT", previous, "BOTTOMLEFT", -5, 3)
    secondary:SetJustifyH("LEFT"); secondary:SetWordWrap(false)

    row:SetScript("OnEnter", function()
        if GetCursorInfo and GetCursorInfo() then dropAccent:Show() end
    end)
    row:SetScript("OnLeave", function() dropAccent:SetShown(row.apogeeActive ~= true) end)

    row.bg, row.iconSlot, row.icon = bg, iconSlot, icon
    row.dropAccent = dropAccent
    row.iconOutline, row.iconFill = iconOutline, iconFill
    row.primary, row.secondary = primary, secondary
    row.sound, row.gear, row.macro, row.up, row.down, row.clear =
        sound, gear, macro, up, down, clear
    row.showSound, row.showGear, row.showMacro = showSound, showGear, showMacro
    return row
end

local function selectedOptionLabel(dropdown, key, fallback)
    for _, option in ipairs(dropdown.options or {}) do
        if option.key == key then return option.label end
    end
    return fallback
end

function AC.SetActionRowState(row, options)
    if not row then return end
    options = options or {}
    local active = options.active == true
    row.apogeeActive = active
    local available = options.available ~= false
    row.icon:SetTexture(options.icon)
    row.icon:SetDesaturated(not active or not available)
    local displayName = options.name
    if not active and (not displayName or displayName == "Empty") then
        displayName = "Drop spell or item"
    end
    row.primary:SetText(displayName or "Action")
    if active and available then
        row.primary:SetTextColor(0.86, 0.86, 1)
    elseif active then
        row.primary:SetTextColor(0.48, 0.48, 0.50)
    else
        row.primary:SetTextColor(0.43, 0.43, 0.45)
    end
    local selectedLoadout = active and options.equipmentSetName or nil
    local loadoutMissing = selectedLoadout and EquipmentSets.Resolve
        and not EquipmentSets.Resolve(selectedLoadout)
    row.secondary:SetText((options.detail or "Empty")
        .. (selectedLoadout and (" · Gear: " .. selectedLoadout
            .. (loadoutMissing and " (missing)" or "")) or ""))
    local soundKey = active and (options.soundKey or "none") or "none"
    row.sound:SetSelectedKey(soundKey)
    local soundLabel = selectedOptionLabel(row.sound, soundKey, "None")
    row.sound.label:SetText("Sound")
    row.sound.stateMarker:SetShown(active and soundKey ~= "none")
    if row.showSound then
        UIH.SetTooltip(row.sound, "Ready sound: " .. soundLabel,
            "Choose the sound played when this action becomes ready.")
    end
    if row.showSound and active then row.sound:Enable() else row.sound:Disable() end
    if row.showGear then
        local selectedName = selectedLoadout
        if row.gear.SetOptions then
            row.gear:SetOptions(EquipmentSets.GetOptions(selectedName))
        end
        row.gear:SetSelectedKey(selectedName or EquipmentSets.NONE_KEY)
        row.gear.label:SetText("Gear")
        row.gear.stateMarker:SetShown(selectedName ~= nil)
        UIH.SetTooltip(row.gear,
            selectedName and ("Equipment loadout: " .. selectedName) or "Equipment loadout",
            selectedName
                and ((loadoutMissing and "This native loadout is missing. " or "")
                    .. "Runs before the saved action macro.")
                or "No loadout. The saved action macro runs unchanged.")
        if active then row.gear:Enable() else row.gear:Disable() end
    end
    UIH.SetButtonEnabled(row.macro, row.showMacro and active)
    UIH.SetButtonEnabled(row.clear, active)
    UIH.SetButtonEnabled(row.up, active and options.canMoveUp == true)
    UIH.SetButtonEnabled(row.down, active and options.canMoveDown == true)
    row.macro.label:SetText("Macro")
    row.macro.stateMarker:SetShown(active and options.macroCustomized == true)
    row.dropAccent:SetShown(not active)
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
    hint:SetText("Drop spell/item on a row. Shift-drop preserves spell rank.")

    local status = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    status:SetWidth(rowWidth); status:SetJustifyH("LEFT"); status:SetWordWrap(false)

    local list = {
        scroll = scroll,
        content = content,
        hint = hint,
        status = status,
        rowWidth = rowWidth,
    }
    local bodyAnchor = CreateFrame("Frame", nil, content)
    bodyAnchor:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    bodyAnchor:SetSize(rowWidth, 1)
    list.bodyAnchor = bodyAnchor
    if UIH.AttachOverflowCue then
        list.overflowCue = UIH.AttachOverflowCue(scroll, parent)
    elseif scroll.ScrollBar then
        scroll.ScrollBar:Hide()
        scroll:HookScript("OnScrollRangeChanged", function(_, _, verticalRange)
            scroll.ScrollBar:SetShown((verticalRange or 0) > 0)
        end)
    end
    if UIH.AttachScrollWheel then UIH.AttachScrollWheel(scroll, LIST_ROW_H * 2) end
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
    local anchor = list.headerManaged and list.bodyAnchor or list.hint
    local contentHeight = list.headerManaged and 0 or LIST_HINT_H

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

    if list.scroll.apogeeRefreshOverflow then list.scroll.apogeeRefreshOverflow() end
end

function AC.Initialize(parent, applyBackdrop)
    if overlay then return overlay end
    overlay = CreateFrame("Frame", nil, parent)
    -- Leave the tabs and close button reachable so either action can discard
    -- the draft through the normal settings lifecycle.
    overlay:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_PAGE_SELECTOR_H + 4))
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
    saveButton = UIH.CreateButton(dialog, "Save", 86, 22, "primary")
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
