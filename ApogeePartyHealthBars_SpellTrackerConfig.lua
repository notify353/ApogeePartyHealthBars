local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers
local AC = ApogeePartyHealthBars_ActionConfig

ApogeePartyHealthBars_SpellTrackerConfig = {}
local SC = ApogeePartyHealthBars_SpellTrackerConfig

local D, tab, hint, addRow
local slotRows = {}

local function armReplacement(slot)
    local entries = D.SpellTracker.GetSlots() or {}
    if not entries[slot] then return end
    S.selectedTrackerSlot = S.selectedTrackerSlot == slot and nil or slot
    S.selectedBindingKey = nil
    S.selectedWheelSlot = nil
    SC.Refresh()
end

local function openMacroEditor(slot)
    local tracker = D.SpellTracker
    local entry = tracker.GetSlots() and tracker.GetSlots()[slot]
    if not entry then return end
    AC.OpenEditor({
        title = "Edit Spell macro",
        spellName = entry.spellName,
        macroText = tracker.GetMacro(slot),
        resetText = tracker.ResetMacro(slot),
        onSave = function(body) return tracker.ApplyMacro(slot, body) end,
        onSaved = SC.Refresh,
    })
end

function SC.Refresh(assignedSlot)
    if not tab then return end
    if assignedSlot then AC.CloseEditor() end
    local tracker = D.SpellTracker
    local entries = tracker.GetSlots() or {}
    if S.selectedTrackerSlot and not entries[S.selectedTrackerSlot] then S.selectedTrackerSlot = nil end

    if S.selectedTrackerSlot then
        hint:SetText("|cff00ff00Selected for replacement.|r Shift-click a Spellbook spell.")
    elseif #entries >= C.TRACKER_MAX_SLOTS then
        hint:SetText("All " .. C.TRACKER_MAX_SLOTS
            .. " Spell actions are assigned. Select a row to replace it or Clear one.")
    else
        hint:SetText("Shift-click a Spellbook spell to add it. Select a row first to replace it.")
    end

    local anchor = hint
    for i = 1, C.TRACKER_MAX_SLOTS do
        local row, entry = slotRows[i], entries[i]
        if entry then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, i == 1 and -9 or -3)
            anchor = row
            row:Show()
            local name, icon, available = tracker.GetSlotDisplay(i)
            row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.icon:SetDesaturated(not available)
            row.primary:SetText(name or entry.spellName or "Unknown Spell")
            row.primary:SetTextColor(available and 0.84 or 0.48, available and 0.84 or 0.48,
                available and 1 or 0.50)
            row.secondary:SetText(S.selectedTrackerSlot == i and "Shift-click to replace" or "Tracked Spell")
            row.sound:SetSelectedKey(tracker.GetSlotSoundKey(i) or "none")
            row.sound:Enable(); row.macro:Enable(); row.clear:Enable()
            row.macro.label:SetText(tracker.IsMacroCustomized(i) and "Macro*" or "Macro")
            UIH.SetButtonEnabled(row.up, i > 1)
            UIH.SetButtonEnabled(row.down, i < #entries)
            AC.SetRowSelected(row, S.selectedTrackerSlot == i)
        else
            row:Hide()
        end
    end

    addRow:ClearAllPoints()
    addRow:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, #entries == 0 and -9 or -3)
    addRow:SetShown(#entries < C.TRACKER_MAX_SLOTS)
    addRow.label:SetText(#entries == 0
        and "Shift-click a Spellbook spell to add your first action"
        or "Shift-click another Spellbook spell to add it")
end

function SC.Build(parent, deps)
    D = deps
    local tracker = D.SpellTracker
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    hint = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
    hint:SetWidth(C.CONFIG_CONTENT_W); hint:SetJustifyH("LEFT")

    for i = 1, C.TRACKER_MAX_SLOTS do
        local slot = i
        local row = AC.CreateActionRow(tab, C.CONFIG_CONTENT_W)
        row.sound:SetOptions(D.Sounds.GetOptions(true))
        row:SetScript("OnClick", function() armReplacement(slot) end)
        row.sound:SetSelectionCallback(function(soundKey)
            if not tracker.GetSlots()[slot] then return end
            local selected = tracker.SetSlotSound(slot, soundKey)
            tracker.PreviewSound(selected)
            SC.Refresh()
        end)
        row.macro:SetScript("OnClick", function() openMacroEditor(slot) end)
        row.up:SetScript("OnClick", function()
            local moved, nextSlot = tracker.MoveSlot(slot, -1)
            if moved and S.selectedTrackerSlot == slot then S.selectedTrackerSlot = nextSlot end
            SC.Refresh()
        end)
        row.down:SetScript("OnClick", function()
            local moved, nextSlot = tracker.MoveSlot(slot, 1)
            if moved and S.selectedTrackerSlot == slot then S.selectedTrackerSlot = nextSlot end
            SC.Refresh()
        end)
        row.clear:SetScript("OnClick", function()
            tracker.ClearSlot(slot)
            S.selectedTrackerSlot = nil
            AC.CloseEditor()
            SC.Refresh()
        end)
        slotRows[i] = row
    end

    addRow = UIH.CreateButton(tab, "", C.CONFIG_CONTENT_W, 34)
    addRow.bg:SetColorTexture(0.045, 0.045, 0.055, 1)
    addRow:Disable()
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
