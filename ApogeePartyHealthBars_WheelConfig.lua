local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_WheelConfig = {}
local WC = ApogeePartyHealthBars_WheelConfig

local tab, W, D, enableButton, statusText, hint, editor, byteCount, selectionTitle
local applyButton, clearSlotButton
local readySound, previewSound
local slotButtons = {}
local slotDefinitions = {}
local configurationControls = {}
local collapsedMessage
local editorDirty, loadingEditor, lastEditorSlot = false, false, nil
local SLOT_RAIL_W = 128
local COLUMN_GAP = 10
local EDITOR_W = C.CONFIG_CONTENT_W - SLOT_RAIL_W - COLUMN_GAP
local SLOT_H = 31
local DISPLAY_ORDER = { "ctrlUp", "shiftUp", "normalUp", "normalDown", "shiftDown", "ctrlDown" }
local DISPLAY_LABELS = {
    ctrlUp = "|cffFFD700^|r  Ctrl", shiftUp = "|cffFFD700^|r  Shift",
    normalUp = "|cffFFD700^|r  Normal", normalDown = "|cffFFD700v|r  Normal",
    shiftDown = "|cffFFD700v|r  Shift", ctrlDown = "|cffFFD700v|r  Ctrl",
}

local function setStatus(message, good)
    if not statusText then return end
    statusText:SetText((good and "|cff00ff00" or "|cffffaa00") .. tostring(message or "") .. "|r")
end

local function selectedEntry()
    return S.selectedWheelSlot and W.GetSlot(S.selectedWheelSlot)
end

local function renderSelected()
    local entry = selectedEntry()
    if lastEditorSlot ~= S.selectedWheelSlot then
        lastEditorSlot, editorDirty = S.selectedWheelSlot, false
    end
    if not editorDirty then
        loadingEditor = true
        editor:SetText(entry and entry.macroText or "")
        loadingEditor = false
    end
    local body = editor:GetText() or ""
    byteCount:SetText(#body .. " / " .. W.GetMaxBodyBytes() .. " bytes")
    if entry and entry.displaySpellName then applyButton:Enable() else applyButton:Disable() end
    if entry and entry.displaySpellName then clearSlotButton:Enable() else clearSlotButton:Disable() end
    local soundKey = entry and W.GetSlotSoundKey(S.selectedWheelSlot) or "none"
    readySound:SetSelectedKey(soundKey)
    if entry and entry.displaySpellName then readySound:Enable() else readySound:Disable() end
    UIH.SetButtonEnabled(previewSound, entry and entry.displaySpellName and soundKey ~= "none")
    local slot = slotDefinitions[S.selectedWheelSlot]
    selectionTitle:SetText(slot and entry and entry.displaySpellName
        and ("|cffFFD700" .. slot.label .. "|r  " .. entry.displaySpellName)
        or "SELECT A SLOT")
    hint:SetText(S.selectedWheelSlot
        and "Shift-click a Spellbook spell to replace this slot."
        or "Choose a slot in scroll order.")
end

function WC.Refresh(forceEditorReload)
    if not tab then return end
    if forceEditorReload then editorDirty = false end
    local enabled = W.IsEnabled()
    if enabled then enableButton.label:SetText("Disable Wheel Bindings")
    else enableButton.label:SetText("Enable Wheel Bindings") end
    for _, control in ipairs(configurationControls) do control:SetShown(enabled) end
    if not enabled then
        S.selectedWheelSlot = nil
        editorDirty = false
        hint:SetText(collapsedMessage
            or "Enable this feature to configure its six normal gameplay wheel macros and HUD.")
        return
    end
    for _, slotId in ipairs(DISPLAY_ORDER) do
        local button = slotButtons[slotId]
        local name = W.GetSlotDisplay(slotId)
        button.label:SetText(DISPLAY_LABELS[slotId] .. "\n" .. (name or "|cff777777Empty|r"))
        button.bg:SetColorTexture(S.selectedWheelSlot == slotId and 0.22 or 0.08,
            S.selectedWheelSlot == slotId and 0.22 or 0.08,
            S.selectedWheelSlot == slotId and 0.22 or 0.08, 1)
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
    heading:SetPoint("TOPLEFT"); heading:SetText("|cffFFD700Mouse-Wheel Macros|r")
    hint = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -3)
    hint:SetWidth(C.CONFIG_CONTENT_W); hint:SetJustifyH("LEFT")

    enableButton = UIH.CreateButton(tab, "Enable Wheel Bindings", C.CONFIG_CONTENT_W, 22)
    enableButton:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -7)
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
        if ok then setStatus("Enabled.", true) end
    end)

    for _, slot in ipairs(W.GetDefinitions()) do slotDefinitions[slot.id] = slot end

    local slotHeader = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    slotHeader:SetPoint("TOPLEFT", enableButton, "BOTTOMLEFT", 0, -9)
    slotHeader:SetText("SCROLL ORDER")
    configurationControls[#configurationControls + 1] = slotHeader

    for displayIndex, slotId in ipairs(DISPLAY_ORDER) do
        local slot = slotDefinitions[slotId]
        local boundSlot = slot
        local button = UIH.CreateButton(tab, slot.label, SLOT_RAIL_W, SLOT_H)
        local extraGap = displayIndex > 3 and 5 or 0
        button:SetPoint("TOPLEFT", slotHeader, "BOTTOMLEFT", 0,
            -4 - (displayIndex - 1) * (SLOT_H + 2) - extraGap)
        button.label:SetJustifyH("CENTER")
        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(); bg:SetColorTexture(0.08, 0.08, 0.08, 1)
        button:SetScript("OnClick", function()
            S.selectedWheelSlot = boundSlot.id
            S.selectedBindingKey = nil
            S.selectedTrackerSlot = nil
            editorDirty = false
            statusText:SetText("")
            WC.Refresh()
        end)
        button.bg = bg
        slotButtons[slotId] = button
        configurationControls[#configurationControls + 1] = button
    end

    local directionDivider = tab:CreateTexture(nil, "ARTWORK")
    directionDivider:SetSize(SLOT_RAIL_W - 12, 1)
    directionDivider:SetPoint("TOPLEFT", slotHeader, "BOTTOMLEFT", 6, -102)
    directionDivider:SetColorTexture(0.4, 0.4, 0.42, 0.8)
    configurationControls[#configurationControls + 1] = directionDivider

    selectionTitle = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    selectionTitle:SetPoint("TOPLEFT", slotHeader, "TOPLEFT", SLOT_RAIL_W + COLUMN_GAP, 0)
    selectionTitle:SetWidth(EDITOR_W); selectionTitle:SetJustifyH("LEFT")
    selectionTitle:SetText("SELECT A SLOT")
    configurationControls[#configurationControls + 1] = selectionTitle

    local soundLabel = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    soundLabel:SetPoint("TOPLEFT", selectionTitle, "BOTTOMLEFT", 0, -5)
    soundLabel:SetText("READY SOUND")
    readySound = UIH.CreateDropdown(tab, 145, 20, 170)
    readySound:SetOptions(D.Sounds.GetOptions(true))
    readySound:SetPoint("LEFT", soundLabel, "RIGHT", 8, 0)
    previewSound = UIH.CreateButton(tab, "Play", 34, 20)
    previewSound:SetPoint("LEFT", readySound, "RIGHT", 4, 0)
    readySound:SetSelectionCallback(function(soundKey)
        if S.selectedWheelSlot then W.SetSlotSound(S.selectedWheelSlot, soundKey); WC.Refresh() end
    end)
    previewSound:SetScript("OnClick", function()
        if S.selectedWheelSlot then W.PreviewSound(S.selectedWheelSlot) end
    end)

    local macroLabel = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    macroLabel:SetPoint("TOPLEFT", selectionTitle, "BOTTOMLEFT", 0, -30)
    macroLabel:SetText("MACRO  |cff777777blank = no action|r")
    byteCount = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    byteCount:SetPoint("TOPRIGHT", selectionTitle, "BOTTOMRIGHT", 0, -30)

    local editorFrame = CreateFrame("Frame", nil, tab, "BackdropTemplate")
    editorFrame:SetSize(EDITOR_W, 118)
    editorFrame:SetPoint("TOPLEFT", macroLabel, "BOTTOMLEFT", 0, -4)
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

    local actionWidth = (EDITOR_W - 6) / 2
    applyButton = UIH.CreateButton(tab, "Apply Macro", actionWidth, 22)
    applyButton:SetPoint("TOPLEFT", editorFrame, "BOTTOMLEFT", 0, -6)
    clearSlotButton = UIH.CreateButton(tab, "Clear Slot", actionWidth, 22)
    clearSlotButton:SetPoint("LEFT", applyButton, "RIGHT", 6, 0)
    applyButton:SetScript("OnClick", function()
        local ok, message = W.ApplyMacro(S.selectedWheelSlot, editor:GetText() or "")
        setStatus(message, ok)
        if ok then WC.Refresh(true) end
    end)
    clearSlotButton:SetScript("OnClick", function()
        local ok, message = W.ClearSlot(S.selectedWheelSlot)
        setStatus(message, ok)
        if ok then editorDirty = false end
        WC.Refresh(true)
    end)
    statusText = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    statusText:SetPoint("TOPLEFT", applyButton, "BOTTOMLEFT", 0, -7)
    statusText:SetWidth(EDITOR_W); statusText:SetJustifyH("LEFT")
    configurationControls[#configurationControls + 1] = macroLabel
    configurationControls[#configurationControls + 1] = soundLabel
    configurationControls[#configurationControls + 1] = readySound
    configurationControls[#configurationControls + 1] = previewSound
    configurationControls[#configurationControls + 1] = byteCount
    configurationControls[#configurationControls + 1] = editorFrame
    configurationControls[#configurationControls + 1] = applyButton
    configurationControls[#configurationControls + 1] = clearSlotButton
    configurationControls[#configurationControls + 1] = statusText
    WC.Refresh()
    return tab
end
