local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers
local AC = ApogeePartyHealthBars_ActionConfig

ApogeePartyHealthBars_ShortcutConfig = {}
local SC = ApogeePartyHealthBars_ShortcutConfig

local D, tab, scroll, content, hint, addRow
local slotRows = {}
local HINT_HEIGHT = 28
local FIRST_ROW_GAP = 9
local ROW_HEIGHT = 36
local ROW_GAP = 3
local ADD_ROW_HEIGHT = 34

local function selectRow(slot)
    local entries = D.ShortcutBar.GetSlots() or {}
    if not entries[slot] then return end
    S.selectedShortcutSlot = S.selectedShortcutSlot == slot and nil or slot
    S.selectedBindingKey = nil
    S.selectedWheelSlot = nil
    SC.Refresh()
end

local function openMacroEditor(slot)
    local shortcuts = D.ShortcutBar
    local entry = shortcuts.GetSlots() and shortcuts.GetSlots()[slot]
    if not entry then return end
    AC.OpenEditor({
        title = "Edit Shortcut macro",
        actionName = ApogeePartyHealthBars_ActionMacros.GetName(entry),
        macroText = shortcuts.GetMacro(slot),
        resetText = shortcuts.ResetMacro(slot),
        onSave = function(body) return shortcuts.ApplyMacro(slot, body) end,
        onSaved = SC.Refresh,
    })
end

function SC.Refresh(assignedSlot)
    if not tab then return end
    if assignedSlot then AC.CloseEditor() end
    local shortcuts = D.ShortcutBar
    local entries = shortcuts.GetSlots() or {}
    if S.selectedShortcutSlot and not entries[S.selectedShortcutSlot] then S.selectedShortcutSlot = nil end

    if S.selectedShortcutSlot then
        hint:SetText("|cff00ff00Selected.|r Drop a Spellbook spell or bag item onto this row, or edit its macro and sound.")
    elseif #entries >= C.SHORTCUT_MAX_SLOTS then
        hint:SetText("All " .. C.SHORTCUT_MAX_SLOTS
            .. " Shortcuts are assigned. Drop onto a row to replace it or Clear one.")
    else
        hint:SetText("Drag a Spellbook spell or bag item onto a row, or use the empty position to add one.")
    end

    local anchor = hint
    for i = 1, C.SHORTCUT_MAX_SLOTS do
        local row, entry = slotRows[i], entries[i]
        if entry then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, i == 1 and -9 or -3)
            anchor = row
            row:Show()
            local name, icon, available = shortcuts.GetSlotDisplay(i)
            row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.icon:SetDesaturated(not available)
            row.primary:SetText(name or ApogeePartyHealthBars_ActionMacros.GetName(entry) or "Unknown Shortcut")
            row.primary:SetTextColor(available and 0.84 or 0.48, available and 0.84 or 0.48,
                available and 1 or 0.50)
            local kindLabel = entry.kind == "item" and "Item" or "Spell"
            row.secondary:SetText(S.selectedShortcutSlot == i
                and (kindLabel .. " — Selected") or kindLabel)
            row.sound:SetSelectedKey(shortcuts.GetSlotSoundKey(i) or "none")
            row.sound:Enable(); row.macro:Enable(); row.clear:Enable()
            row.macro.label:SetText(shortcuts.IsMacroCustomized(i) and "Macro*" or "Macro")
            UIH.SetButtonEnabled(row.up, i > 1)
            UIH.SetButtonEnabled(row.down, i < #entries)
            AC.SetRowSelected(row, S.selectedShortcutSlot == i)
        else
            row:Hide()
        end
    end

    addRow:ClearAllPoints()
    addRow:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, #entries == 0 and -9 or -3)
    addRow:SetShown(#entries < C.SHORTCUT_MAX_SLOTS)
    addRow.label:SetText(#entries == 0
        and "Drop a spell or bag item here to add your first Shortcut"
        or "Drop another spell or bag item here")

    local contentHeight = HINT_HEIGHT
    if #entries > 0 then
        contentHeight = contentHeight + FIRST_ROW_GAP
            + #entries * ROW_HEIGHT + (#entries - 1) * ROW_GAP
    end
    if #entries < C.SHORTCUT_MAX_SLOTS then
        contentHeight = contentHeight + (#entries == 0 and FIRST_ROW_GAP or ROW_GAP)
            + ADD_ROW_HEIGHT
    end
    content:SetHeight(contentHeight)
end

function SC.Build(parent, deps)
    D = deps
    local shortcuts = D.ShortcutBar
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    scroll, content = UIH.CreateScrollFrame(tab)
    UIH.AttachScrollWheel(scroll, (ROW_HEIGHT + ROW_GAP) * 2)

    hint = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    hint:SetWidth(C.CONFIG_CONTENT_W); hint:SetHeight(HINT_HEIGHT)
    hint:SetJustifyH("LEFT"); hint:SetJustifyV("TOP")

    for i = 1, C.SHORTCUT_MAX_SLOTS do
        local slot = i
        local row = AC.CreateActionRow(content, C.CONFIG_CONTENT_W)
        row.sound:SetOptions(D.Sounds.GetOptions(true))
        row:SetScript("OnClick", function()
            local cursorType = GetCursorInfo and GetCursorInfo()
            if (cursorType == "spell" or cursorType == "item") and D.AssignCursorDrop then
                D.AssignCursorDrop("shortcuts", slot)
                return
            end
            selectRow(slot)
        end)
        row:SetScript("OnReceiveDrag", function()
            if D.AssignCursorDrop then D.AssignCursorDrop("shortcuts", slot) end
        end)
        row.sound:SetSelectionCallback(function(soundKey)
            if not shortcuts.GetSlots()[slot] then return end
            local selected = shortcuts.SetSlotSound(slot, soundKey)
            shortcuts.PreviewSound(selected)
            SC.Refresh()
        end)
        row.macro:SetScript("OnClick", function() openMacroEditor(slot) end)
        row.up:SetScript("OnClick", function()
            local moved, nextSlot = shortcuts.MoveSlot(slot, -1)
            if moved and S.selectedShortcutSlot == slot then S.selectedShortcutSlot = nextSlot end
            SC.Refresh()
        end)
        row.down:SetScript("OnClick", function()
            local moved, nextSlot = shortcuts.MoveSlot(slot, 1)
            if moved and S.selectedShortcutSlot == slot then S.selectedShortcutSlot = nextSlot end
            SC.Refresh()
        end)
        row.clear:SetScript("OnClick", function()
            shortcuts.ClearSlot(slot)
            S.selectedShortcutSlot = nil
            AC.CloseEditor()
            SC.Refresh()
        end)
        slotRows[i] = row
    end

    addRow = UIH.CreateButton(content, "", C.CONFIG_CONTENT_W, ADD_ROW_HEIGHT)
    addRow.bg:SetColorTexture(0.045, 0.045, 0.055, 1)
    addRow:SetScript("OnReceiveDrag", function()
        if D.AssignCursorDrop then D.AssignCursorDrop("shortcuts", nil) end
    end)
    addRow:SetScript("OnClick", function()
        local cursorType = GetCursorInfo and GetCursorInfo()
        if (cursorType == "spell" or cursorType == "item") and D.AssignCursorDrop then
            D.AssignCursorDrop("shortcuts", nil)
        end
    end)
    local icon = addRow:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22); icon:SetPoint("LEFT", addRow, "LEFT", 8, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); icon:SetDesaturated(true)
    addRow.label:ClearAllPoints()
    addRow.label:SetPoint("LEFT", icon, "RIGHT", 7, 0)
    addRow.label:SetPoint("RIGHT", addRow, "RIGHT", -8, 0)
    addRow.label:SetJustifyH("LEFT"); addRow.label:SetWordWrap(false)
    SC.Refresh()
    return tab
end
