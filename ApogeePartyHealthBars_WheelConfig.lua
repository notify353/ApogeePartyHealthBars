local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_WheelConfig = {}
local WC = ApogeePartyHealthBars_WheelConfig

local tab, W, D, enableButton, statusText, hint, editor, byteCount, selectionTitle, selectionSpell
local layoutSelector
local applyButton
local readySound
local slotButtons = {}
local slotDefinitions = {}
local configurationControls = {}
local collapsedMessage
local editorDirty, loadingEditor, lastEditorContext = false, false, nil
local editorDrafts = {}
local SLOT_RAIL_W = 142
local COLUMN_GAP = 12
local EDITOR_W = C.CONFIG_CONTENT_W - SLOT_RAIL_W - COLUMN_GAP
local SLOT_H = 28
local SLOT_GAP = 4
local GROUP_GAP = 12
local CONTENT_TOP_GAP = 10
local CONTROL_GAP = 7
local CONTROL_H = 22
local EDITOR_H = 112
local CARD_PAD = 10
local DISPLAY_ORDER = { "ctrlUp", "shiftUp", "normalUp", "normalDown", "shiftDown", "ctrlDown" }
local DISPLAY_GROUPS = {
    { "ctrlUp", "shiftUp", "normalUp" },
    { "normalDown", "shiftDown", "ctrlDown" },
}
local SLOT_PRESENTATION = {
    ctrlUp = { direction = "WHEEL UP", modifier = "Ctrl" },
    shiftUp = { direction = "WHEEL UP", modifier = "Shift" },
    normalUp = { direction = "WHEEL UP", modifier = "" },
    normalDown = { direction = "WHEEL DOWN", modifier = "" },
    shiftDown = { direction = "WHEEL DOWN", modifier = "Shift" },
    ctrlDown = { direction = "WHEEL DOWN", modifier = "Ctrl" },
}

local function setStatus(message, good)
    if not statusText then return end
    statusText:SetText((good and "|cff00ff00" or "|cffffaa00") .. tostring(message or "") .. "|r")
end

local function selectedEntry()
    return S.selectedWheelLayout and S.selectedWheelSlot
        and W.GetSlot(S.selectedWheelLayout, S.selectedWheelSlot)
end

local function selectedContext()
    if not S.selectedWheelLayout or not S.selectedWheelSlot then return nil end
    return W.GetActiveSpecKey() .. ":" .. S.selectedWheelLayout .. ":" .. S.selectedWheelSlot
end

local function captureEditorDraft()
    if editorDirty and editor and lastEditorContext then
        editorDrafts[lastEditorContext] = editor:GetText() or ""
    end
end

local function displaySpellLabel(name)
    if not name then return nil end
    return (name:gsub("%s*%([Rr]ank%s+[%dIVX]+%)$", ""))
end

local function renderSelected()
    local entry = selectedEntry()
    local context = selectedContext()
    if lastEditorContext ~= context then
        captureEditorDraft()
        lastEditorContext = context
        if statusText then statusText:SetText("") end
        local draft = context and editorDrafts[context]
        loadingEditor = true
        editor:SetText(draft ~= nil and draft or (entry and entry.macroText or ""))
        loadingEditor = false
        editorDirty = draft ~= nil
    elseif not editorDirty then
        loadingEditor = true
        editor:SetText(entry and entry.macroText or "")
        loadingEditor = false
    end
    local body = editor:GetText() or ""
    byteCount:SetText(#body .. " / " .. W.GetMaxBodyBytes() .. " bytes")
    if entry and entry.displaySpellName then applyButton:Enable() else applyButton:Disable() end
    local soundKey = entry and W.GetSlotSoundKey(S.selectedWheelLayout, S.selectedWheelSlot) or "none"
    readySound:SetSelectedKey(soundKey)
    if entry and entry.displaySpellName then readySound:Enable() else readySound:Disable() end
    local slot = slotDefinitions[S.selectedWheelSlot]
    local presentation = SLOT_PRESENTATION[S.selectedWheelSlot]
    if slot and presentation and entry then
        selectionTitle:SetText(presentation.modifier == "" and presentation.direction
            or ("|cffFFD700" .. string.upper(presentation.modifier) .. "|r  ·  " .. presentation.direction))
        selectionSpell:SetText(displaySpellLabel(entry.displaySpellName) or "Empty slot")
        selectionSpell:SetTextColor(entry.displaySpellName and 1 or 0.58,
            entry.displaySpellName and 0.82 or 0.58, entry.displaySpellName and 0 or 0.62)
    else
        selectionTitle:SetText("SELECTED SLOT")
        selectionSpell:SetText("Choose a wheel binding")
        selectionSpell:SetTextColor(0.58, 0.58, 0.62)
    end
    hint:SetText(S.selectedWheelSlot
        and "Shift-click a Spellbook spell to replace this slot."
        or "Choose a slot in scroll order.")
end

function WC.Refresh(forceEditorReload)
    if not tab then return end
    if forceEditorReload then
        if lastEditorContext then editorDrafts[lastEditorContext] = nil end
        editorDirty = false
    end
    local enabled = W.IsEnabled()
    if enabled then enableButton.label:SetText("DISABLE")
    else enableButton.label:SetText("ENABLE") end
    enableButton:ClearAllPoints()
    if enabled then
        enableButton:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
    else
        enableButton:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -12)
    end
    for _, control in ipairs(configurationControls) do control:SetShown(enabled) end
    if not enabled then
        S.selectedWheelSlot = nil
        S.selectedWheelLayout = nil
        editorDirty = false
        lastEditorContext = nil
        editorDrafts = {}
        if layoutSelector then layoutSelector:Hide() end
        hint:SetText(collapsedMessage
            or "Enable this feature to configure its six normal gameplay wheel macros and HUD.")
        return
    end
    local hasStances = W.HasStanceLayouts()
    layoutSelector:SetOptions(W.GetLayoutOptions())
    if not W.IsKnownLayout(S.selectedWheelLayout) then
        S.selectedWheelLayout = W.GetActiveLayoutKey()
    end
    layoutSelector:SetSelectedKey(S.selectedWheelLayout)
    layoutSelector:SetShown(hasStances)
    local railAnchor = hasStances and layoutSelector or hint
    local firstButton = slotButtons[DISPLAY_ORDER[1]]
    if firstButton then
        firstButton:ClearAllPoints()
        firstButton:SetPoint("TOPLEFT", railAnchor, "BOTTOMLEFT", 0, -CONTENT_TOP_GAP)
    end
    selectionTitle:ClearAllPoints()
    selectionTitle:SetPoint("TOPLEFT", railAnchor, "BOTTOMLEFT",
        SLOT_RAIL_W + COLUMN_GAP, -CONTENT_TOP_GAP)
    if not slotDefinitions[S.selectedWheelSlot] then
        S.selectedWheelSlot = "normalUp"
    end
    for _, slotId in ipairs(DISPLAY_ORDER) do
        local button = slotButtons[slotId]
        local name = W.GetSlotDisplay(S.selectedWheelLayout, slotId)
        local selected = S.selectedWheelSlot == slotId
        button.spell:SetText(displaySpellLabel(name) or "Empty")
        button.spell:SetTextColor(name and (selected and 1 or 0.86) or 0.42,
            name and (selected and 1 or 0.86) or 0.42,
            name and (selected and 1 or 0.88) or 0.44)
        button.bg:SetColorTexture(selected and 0.12 or 0.045, selected and 0.12 or 0.045,
            selected and 0.145 or 0.055, 1)
        button.border:SetColorTexture(selected and 0.34 or 0.22, selected and 0.34 or 0.22,
            selected and 0.38 or 0.25, selected and 0.9 or 0.7)
        button.accent:SetShown(selected)
    end
    renderSelected()
end

function WC.Build(parent, deps)
    D, W = deps, deps.WheelMacros
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    local heading = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    heading:SetPoint("TOPLEFT"); heading:SetText("|cffFFD700Mouse wheel macros|r")
    hint = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -3)
    hint:SetWidth(C.CONFIG_CONTENT_W); hint:SetJustifyH("LEFT")

    enableButton = UIH.CreateButton(tab, "ENABLE", C.CONFIG_CONTENT_W, 22)
    enableButton:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
    enableButton:SetScript("OnClick", function()
        if W.IsEnabled() then
            local ok, message = W.Disable()
            collapsedMessage = not ok and ("|cffffaa00" .. tostring(message) .. "|r") or nil
            WC.Refresh()
            if not ok then setStatus(message, false) end
            return
        end
        local ok, _, detail = W.Enable()
        collapsedMessage = not ok and ("|cffffaa00" .. tostring(detail) .. "|r") or nil
        WC.Refresh()
    end)

    layoutSelector = UIH.CreateDropdown(tab, C.CONFIG_CONTENT_W, CONTROL_H, C.CONFIG_CONTENT_W)
    layoutSelector:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -CONTENT_TOP_GAP)
    layoutSelector:SetSelectionCallback(function(layoutKey)
        if not W.IsKnownLayout(layoutKey) then return end
        S.selectedWheelLayout = layoutKey
        statusText:SetText("")
        WC.Refresh()
    end)
    layoutSelector:Hide()

    for _, slot in ipairs(W.GetDefinitions()) do slotDefinitions[slot.id] = slot end

    local previousControl = hint
    for groupIndex, group in ipairs(DISPLAY_GROUPS) do
        for slotIndex, slotId in ipairs(group) do
            local slot = slotDefinitions[slotId]
            local boundSlot = slot
            local button = UIH.CreateButton(tab, "", SLOT_RAIL_W, SLOT_H)
            local gap = slotIndex > 1 and SLOT_GAP
                or (groupIndex == 1 and CONTENT_TOP_GAP or GROUP_GAP)
            button:SetPoint("TOPLEFT", previousControl, "BOTTOMLEFT", 0, -gap)
            local bg = button:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(); bg:SetColorTexture(0.055, 0.055, 0.065, 1)
            local accent = button:CreateTexture(nil, "OVERLAY")
            accent:SetWidth(3)
            accent:SetPoint("TOPLEFT", button, "TOPLEFT")
            accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT")
            accent:SetColorTexture(1, 0.82, 0, 1)
            accent:Hide()
            local spell = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            spell:SetPoint("LEFT", button, "LEFT", CARD_PAD, 0)
            spell:SetPoint("RIGHT", button, "RIGHT", -CARD_PAD, 0)
            spell:SetJustifyH("LEFT"); spell:SetWordWrap(false)
            button:SetScript("OnClick", function()
                S.selectedWheelSlot = boundSlot.id
                S.selectedBindingKey = nil
                S.selectedTrackerSlot = nil
                statusText:SetText("")
                WC.Refresh()
            end)
            button.bg, button.accent = bg, accent
            button.spell = spell
            slotButtons[slotId] = button
            configurationControls[#configurationControls + 1] = button
            previousControl = button
        end
    end

    selectionTitle = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    selectionTitle:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", SLOT_RAIL_W + COLUMN_GAP, -CONTENT_TOP_GAP)
    selectionTitle:SetWidth(EDITOR_W); selectionTitle:SetJustifyH("LEFT")
    selectionTitle:SetText("SELECTED SLOT")
    selectionTitle:SetTextColor(0.58, 0.58, 0.62)
    configurationControls[#configurationControls + 1] = selectionTitle

    selectionSpell = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    selectionSpell:SetPoint("TOPLEFT", selectionTitle, "BOTTOMLEFT", 0, -2)
    selectionSpell:SetWidth(EDITOR_W); selectionSpell:SetJustifyH("LEFT"); selectionSpell:SetWordWrap(false)
    selectionSpell:SetText("Choose a wheel binding")
    selectionSpell:SetTextColor(1, 0.82, 0)
    configurationControls[#configurationControls + 1] = selectionSpell

    byteCount = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    byteCount:SetPoint("TOPRIGHT", selectionSpell, "BOTTOMRIGHT", 0, -8)

    local editorFrame = CreateFrame("Frame", nil, tab, "BackdropTemplate")
    editorFrame:SetSize(EDITOR_W, EDITOR_H)
    editorFrame:SetPoint("TOPLEFT", selectionSpell, "BOTTOMLEFT", 0, -22)
    D.ApplyBackdrop(editorFrame, 0.92, { 0.35, 0.35, 0.38, 1 })
    editor = CreateFrame("EditBox", nil, editorFrame)
    editor:SetMultiLine(true); editor:SetAutoFocus(false); editor:SetFontObject("ChatFontNormal")
    editor:SetJustifyH("LEFT"); editor:SetJustifyV("TOP")
    editor:SetPoint("TOPLEFT", editorFrame, "TOPLEFT", 8, -7)
    editor:SetPoint("BOTTOMRIGHT", editorFrame, "BOTTOMRIGHT", -8, 7)
    editor:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editor:SetScript("OnTextChanged", function(self)
        if not loadingEditor then editorDirty = true end
        local body = self:GetText() or ""
        byteCount:SetText(#body .. " / " .. W.GetMaxBodyBytes() .. " bytes")
        byteCount:SetTextColor(#body > W.GetMaxBodyBytes() and 1 or 0.6,
            #body > W.GetMaxBodyBytes() and 0.2 or 0.6, 0.6)
    end)

    local soundRow = CreateFrame("Frame", nil, tab)
    soundRow:SetSize(EDITOR_W, CONTROL_H)
    soundRow:SetPoint("TOPLEFT", editorFrame, "BOTTOMLEFT", 0, -CONTROL_GAP)
    readySound = UIH.CreateDropdown(soundRow, EDITOR_W, CONTROL_H, EDITOR_W)
    readySound:SetOptions(D.Sounds.GetOptions(true))
    readySound:SetArrowShown(false)
    readySound:SetPoint("TOPLEFT", soundRow, "TOPLEFT", 0, 0)
    readySound:SetSelectionCallback(function(soundKey)
        if not S.selectedWheelLayout or not S.selectedWheelSlot then return end
        W.SetSlotSound(S.selectedWheelLayout, S.selectedWheelSlot, soundKey)
        W.PreviewSound(S.selectedWheelLayout, S.selectedWheelSlot)
        WC.Refresh()
    end)

    applyButton = UIH.CreateButton(tab, "Save", EDITOR_W, CONTROL_H)
    applyButton:SetPoint("TOPLEFT", soundRow, "BOTTOMLEFT", 0, -CONTROL_GAP)
    applyButton:SetScript("OnClick", function()
        local ok, message = W.ApplyMacro(S.selectedWheelLayout,
            S.selectedWheelSlot, editor:GetText() or "")
        setStatus(message, ok)
        if ok then WC.Refresh(true) end
    end)
    statusText = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    statusText:SetPoint("TOPLEFT", applyButton, "BOTTOMLEFT", 0, -7)
    statusText:SetWidth(EDITOR_W); statusText:SetJustifyH("LEFT")
    configurationControls[#configurationControls + 1] = byteCount
    configurationControls[#configurationControls + 1] = editorFrame
    configurationControls[#configurationControls + 1] = soundRow
    configurationControls[#configurationControls + 1] = applyButton
    configurationControls[#configurationControls + 1] = statusText
    WC.Refresh()
    return tab
end
