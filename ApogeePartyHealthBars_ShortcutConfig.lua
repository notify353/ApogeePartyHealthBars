local C = ApogeePartyHealthBars_C
local AC = ApogeePartyHealthBars_ActionConfig

ApogeePartyHealthBars_ShortcutConfig = {}
local SC = ApogeePartyHealthBars_ShortcutConfig

local D, tab, list
local slotRows = {}

local function setStatus(message, good)
    AC.SetActionListStatus(list, message, good)
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
        onSaved = function(message) setStatus(message, true); SC.Refresh() end,
    })
end

function SC.Refresh(assignedSlot)
    if not tab then return end
    if assignedSlot then AC.CloseEditor() end
    local shortcuts = D.ShortcutBar
    local entries = shortcuts.GetSlots() or {}
    local visibleRows = {}
    local visibleCount = math.min(#entries + (#entries < C.SHORTCUT_MAX_SLOTS and 1 or 0),
        C.SHORTCUT_MAX_SLOTS)

    for index = 1, C.SHORTCUT_MAX_SLOTS do
        local row = slotRows[index]
        local entry = entries[index]
        local visible = index <= visibleCount
        row:SetShown(visible)
        if visible then
            visibleRows[#visibleRows + 1] = row
            if entry then
                local name, icon, available = shortcuts.GetSlotDisplay(index)
                local kindLabel = entry.kind == "item" and "Item" or "Spell"
                AC.SetActionRowState(row, {
                    active = true,
                    available = available,
                    icon = icon,
                    name = name or ApogeePartyHealthBars_ActionMacros.GetName(entry)
                        or "Unknown Shortcut",
                    detail = "Shortcut " .. index .. " — " .. kindLabel,
                    soundKey = shortcuts.GetSlotSoundKey(index),
                    macroCustomized = shortcuts.IsMacroCustomized(index),
                    canMoveUp = index > 1,
                    canMoveDown = index < #entries,
                })
            else
                AC.SetActionRowState(row, {
                    detail = "Shortcut " .. index .. " — Empty",
                })
            end
        end
    end
    AC.LayoutActionList(list, visibleRows)
end

function SC.Build(parent, deps)
    D = deps
    local shortcuts = D.ShortcutBar
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    list = AC.CreateActionList(tab, "ApogeePartyHealthBarsShortcutConfigScroll")

    for index = 1, C.SHORTCUT_MAX_SLOTS do
        local slot = index
        local row = AC.CreateActionRow(list.content, list.rowWidth)
        row.sound:SetOptions(D.Sounds.GetOptions(true))
        row:SetScript("OnClick", function()
            local cursorType = GetCursorInfo and GetCursorInfo()
            if (cursorType == "spell" or cursorType == "item") and D.AssignCursorDrop then
                D.AssignCursorDrop("shortcuts", slot)
            end
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
            local moved, message = shortcuts.MoveSlot(slot, -1)
            if not moved and message then setStatus(message, false) end
            SC.Refresh()
        end)
        row.down:SetScript("OnClick", function()
            local moved, message = shortcuts.MoveSlot(slot, 1)
            if not moved and message then setStatus(message, false) end
            SC.Refresh()
        end)
        row.clear:SetScript("OnClick", function()
            local ok, message = shortcuts.ClearSlot(slot)
            AC.CloseEditor(); setStatus(message, ok); SC.Refresh()
        end)
        slotRows[index] = row
    end
    SC.Refresh()
    return tab
end

SC.GetRows = function() return slotRows end
SC.GetList = function() return list end
