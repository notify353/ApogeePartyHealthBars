local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers
local AC = ApogeePartyHealthBars_ActionConfig

ApogeePartyHealthBars_WheelConfig = {}
local WC = ApogeePartyHealthBars_WheelConfig

local tab, W, D, list, layoutSelector
local lastSpecKey, lastLayoutKey
local slotRows = {}
local DISPLAY_LABELS = {
    ctrlUp = "Ctrl + Wheel Up",
    shiftUp = "Shift + Wheel Up",
    normalUp = "Wheel Up",
    normalDown = "Wheel Down",
    shiftDown = "Shift + Wheel Down",
    ctrlDown = "Ctrl + Wheel Down",
}

local function setStatus(message, good)
    AC.SetActionListStatus(list, message, good)
end

local function selectedLayout()
    if not W.IsKnownLayout(S.selectedWheelLayout) then
        S.selectedWheelLayout = W.GetActiveLayoutKey()
    end
    return S.selectedWheelLayout
end

local function openMacroEditor(slotId)
    local layoutKey = selectedLayout()
    local entry = W.GetSlot(layoutKey, slotId)
    if not entry then return end
    AC.OpenEditor({
        title = "Edit " .. (DISPLAY_LABELS[slotId] or "Wheel") .. " macro",
        actionName = ApogeePartyHealthBars_ActionMacros.GetName(entry),
        macroText = W.GetMacro(layoutKey, slotId),
        resetText = W.ResetMacro(layoutKey, slotId),
        onSave = function(body) return W.ApplyMacro(layoutKey, slotId, body) end,
        onSaved = function(message) setStatus(message, true); WC.Refresh() end,
    })
end

function WC.Refresh(assignedSlot)
    if not tab then return end
    if assignedSlot then AC.CloseEditor() end
    local specKey = W.GetActiveSpecKey()
    local layoutKey = selectedLayout()
    if (lastSpecKey and lastSpecKey ~= specKey)
        or (lastLayoutKey and lastLayoutKey ~= layoutKey) then
        AC.CloseEditor()
    end
    lastSpecKey, lastLayoutKey = specKey, layoutKey

    local hasStates = W.HasStateLayouts()
    layoutSelector:SetOptions(W.GetLayoutOptions())
    layoutSelector:SetSelectedKey(layoutKey)
    layoutSelector:SetShown(hasStates)

    local rows = {}
    local order = W.GetDisplayOrder()
    for index, slotId in ipairs(order) do
        local row = slotRows[slotId]
        local entry = W.GetSlot(layoutKey, slotId)
        local name, icon = W.GetSlotDisplay(layoutKey, slotId)
        local kindLabel = entry and (entry.kind == "item" and "Item" or "Spell") or "Empty"
        AC.SetActionRowState(row, {
            active = entry ~= nil,
            icon = icon,
            name = name or "Empty",
            detail = (DISPLAY_LABELS[slotId] or slotId) .. " — " .. kindLabel,
            soundKey = entry and W.GetSlotSoundKey(layoutKey, slotId),
            macroCustomized = entry and W.IsMacroCustomized(layoutKey, slotId),
            canMoveUp = entry ~= nil and index > 1,
            canMoveDown = entry ~= nil and index < #order,
        })
        rows[#rows + 1] = row
    end
    AC.LayoutActionList(list, rows, hasStates and layoutSelector or nil)
end

function WC.Build(parent, deps)
    D, W = deps, deps.WheelMacros
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    list = AC.CreateActionList(tab, "ApogeePartyHealthBarsWheelConfigScroll")
    layoutSelector = UIH.CreateDropdown(list.content, list.rowWidth, 22, list.rowWidth)
    layoutSelector:SetSelectionCallback(function(layoutKey)
        if not W.IsKnownLayout(layoutKey) then return end
        S.selectedWheelLayout = layoutKey
        AC.CloseEditor(); setStatus(""); WC.Refresh()
    end)

    for _, slotId in ipairs(W.GetDisplayOrder()) do
        local boundSlotId = slotId
        local row = AC.CreateActionRow(list.content, list.rowWidth)
        row.sound:SetOptions(D.Sounds.GetOptions(true))
        row:SetScript("OnClick", function()
            local cursorType = GetCursorInfo and GetCursorInfo()
            if (cursorType == "spell" or cursorType == "item") and D.AssignCursorDrop then
                D.AssignCursorDrop("wheel", boundSlotId, selectedLayout())
            end
        end)
        row:SetScript("OnReceiveDrag", function()
            if D.AssignCursorDrop then
                D.AssignCursorDrop("wheel", boundSlotId, selectedLayout())
            end
        end)
        row.sound:SetSelectionCallback(function(soundKey)
            local layoutKey = selectedLayout()
            if not W.GetSlot(layoutKey, boundSlotId) then return end
            W.SetSlotSound(layoutKey, boundSlotId, soundKey)
            W.PreviewSound(layoutKey, boundSlotId)
            WC.Refresh()
        end)
        row.macro:SetScript("OnClick", function() openMacroEditor(boundSlotId) end)
        row.up:SetScript("OnClick", function()
            local moved, message = W.MoveSlot(selectedLayout(), boundSlotId, -1)
            if not moved and message then setStatus(message, false) end
            WC.Refresh()
        end)
        row.down:SetScript("OnClick", function()
            local moved, message = W.MoveSlot(selectedLayout(), boundSlotId, 1)
            if not moved and message then setStatus(message, false) end
            WC.Refresh()
        end)
        row.clear:SetScript("OnClick", function()
            local ok, message = W.ClearSlot(selectedLayout(), boundSlotId)
            AC.CloseEditor(); setStatus(message, ok); WC.Refresh()
        end)
        slotRows[slotId] = row
    end
    WC.Refresh()
    return tab
end

WC.GetRows = function() return slotRows end
WC.GetList = function() return list end
